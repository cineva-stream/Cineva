import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_test/flutter_test.dart';

import 'package:cineva/features/download/data/services/ts_segment_utils.dart';

Uint8List _buildTsSegment(int packets, int seed) {
  final data = Uint8List(packets * 188);
  for (int p = 0; p < packets; p++) {
    data[p * 188] = 0x47;
    for (int i = 1; i < 188; i++) {
      data[p * 188 + i] = (p * 31 + i * 7 + seed) & 0xFF;
    }
  }
  return data;
}

Uint8List _be32(int v) => Uint8List.fromList([
      (v >> 24) & 0xFF,
      (v >> 16) & 0xFF,
      (v >> 8) & 0xFF,
      v & 0xFF,
    ]);

Uint8List _le32(int v) => Uint8List.fromList([
      v & 0xFF,
      (v >> 8) & 0xFF,
      (v >> 16) & 0xFF,
      (v >> 24) & 0xFF,
    ]);

Uint8List _pngChunk(String type, List<int> data) {
  final b = BytesBuilder();
  b.add(_be32(data.length));
  b.add(ascii.encode(type));
  b.add(data);
  b.add(const [0, 0, 0, 0]); // dummy CRC
  return b.toBytes();
}

void main() {
  final key = enc.Key(Uint8List.fromList(List.generate(16, (i) => i + 1)));
  final iv = enc.IV(Uint8List.fromList(List.generate(16, (i) => 16 - i)));

  group('TsSegmentUtils.stripPaddingAndAlign', () {
    test('removes PKCS7 padding left by padding:null AES-CBC decryption', () {
      final original = _buildTsSegment(1117, 3);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final cipher = encrypter.encryptBytes(original, iv: iv).bytes;
      expect(cipher.length % 16, 0);

      final raw = enc.Encrypter(
        enc.AES(key, mode: enc.AESMode.cbc, padding: null),
      ).decryptBytes(enc.Encrypted(cipher), iv: iv);
      expect(raw.length, greaterThan(original.length));

      final cleaned = TsSegmentUtils.stripPaddingAndAlign(
        raw,
        isEncrypted: true,
      );
      expect(cleaned.length, original.length);
      expect(cleaned.length % TsSegmentUtils.tsPacketSize, 0);
      expect(Uint8List.fromList(cleaned), original);
    });

    test('concatenated segments stay TS-aligned (every 188th byte is 0x47)', () {
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final raw = enc.Encrypter(
        enc.AES(key, mode: enc.AESMode.cbc, padding: null),
      );
      final merged = <int>[];

      for (int seg = 0; seg < 5; seg++) {
        final original = _buildTsSegment(40 + seg * 13, seg);
        final cipher = encrypter.encryptBytes(original, iv: iv).bytes;
        merged.addAll(
          TsSegmentUtils.stripPaddingAndAlign(
            raw.decryptBytes(enc.Encrypted(cipher), iv: iv),
            isEncrypted: true,
          ),
        );
      }

      expect(merged.length % 188, 0);
      for (int i = 0; i < merged.length; i += 188) {
        expect(merged[i], 0x47, reason: 'sync byte lost at offset $i');
      }
    });

    test('does not truncate data that has no valid padding and is already aligned', () {
      final original = _buildTsSegment(10, 9);
      original[original.length - 1] = 0x01;
      final cleaned = TsSegmentUtils.stripPaddingAndAlign(original);
      expect(cleaned.length, original.length);
    });

    test('handles empty input', () {
      expect(TsSegmentUtils.stripPaddingAndAlign(<int>[]), isEmpty);
    });
  });

  group('DisguisedSegmentUnwrapper (FlixQuest port)', () {
    test('unwraps WebP EXIF chunk containing MPEG-TS', () {
      final ts = _buildTsSegment(4, 11);
      final b = BytesBuilder();
      b.add(ascii.encode('RIFF'));
      b.add(_le32(4 + 8 + ts.length));
      b.add(ascii.encode('WEBP'));
      b.add(ascii.encode('EXIF'));
      b.add(_le32(ts.length));
      b.add(ts);
      b.add(const [0xAA, 0xBB, 0xCC]); // trailing junk outside EXIF chunk

      final unwrapped = TsSegmentUtils.unwrapDisguisedSegment(b.toBytes());
      expect(Uint8List.fromList(unwrapped), ts);
    });

    test('unwraps PNG with MPEG-TS appended after IEND chunk', () {
      final ts = _buildTsSegment(5, 22);
      final b = BytesBuilder();
      b.add(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
      final ihdr = BytesBuilder()
        ..add(_be32(1))
        ..add(_be32(1))
        ..add(const [8, 2, 0, 0, 0]);
      b.add(_pngChunk('IHDR', ihdr.toBytes()));
      b.add(_pngChunk('IEND', const []));
      b.add(ts);

      final unwrapped = TsSegmentUtils.unwrapDisguisedSegment(b.toBytes());
      expect(Uint8List.fromList(unwrapped), ts);
    });

    test('unwraps PNG TIKTIKPX pixel steganography with gzipped MPEG-TS', () {
      final ts = _buildTsSegment(6, 33);
      final gz = Uint8List.fromList(gzip.encode(ts));

      final payload = BytesBuilder()
        ..add(ascii.encode('TIKTIKPX'))
        ..add(_be32(gz.length))
        ..add(gz);
      final payloadBytes = payload.toBytes();

      // Pack into an 8-bit RGB image of width=64, height enough to hold payloadBytes
      const width = 64;
      const channels = 3;
      const stride = width * channels;
      final height = ((payloadBytes.length + stride - 1) ~/ stride).clamp(1, 4096);

      final rawScanlines = Uint8List(height * (1 + stride));
      int srcIdx = 0;
      for (int y = 0; y < height; y++) {
        final rowStart = y * (1 + stride);
        rawScanlines[rowStart] = 0; // Filter 0 (None)
        for (int i = 0; i < stride && srcIdx < payloadBytes.length; i++) {
          rawScanlines[rowStart + 1 + i] = payloadBytes[srcIdx++];
        }
      }

      final idatCompressed = zlib.encode(rawScanlines);
      final png = BytesBuilder()
        ..add(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
      final ihdr = BytesBuilder()
        ..add(_be32(width))
        ..add(_be32(height))
        ..add(const [8, 2, 0, 0, 0]);
      png.add(_pngChunk('IHDR', ihdr.toBytes()));
      png.add(_pngChunk('IDAT', idatCompressed));
      png.add(_pngChunk('IEND', const []));

      final unwrapped = TsSegmentUtils.unwrapDisguisedSegment(png.toBytes());
      expect(Uint8List.fromList(unwrapped), ts);
    });

    test('unwraps TIKTIKRAW and TIKTIKTSGZ markers', () {
      final ts = _buildTsSegment(3, 44);

      final rawDisguised = BytesBuilder()
        ..add(const [0x00, 0x01, 0x02])
        ..add(ascii.encode('TIKTIKRAW'))
        ..add(ts);
      expect(
        Uint8List.fromList(
          TsSegmentUtils.unwrapDisguisedSegment(rawDisguised.toBytes()),
        ),
        ts,
      );

      final gzDisguised = BytesBuilder()
        ..add(const [0xFF, 0xFE])
        ..add(ascii.encode('TIKTIKTSGZ'))
        ..add(gzip.encode(ts));
      expect(
        Uint8List.fromList(
          TsSegmentUtils.unwrapDisguisedSegment(gzDisguised.toBytes()),
        ),
        ts,
      );
    });

    test('detects HTML and JSON error documents disguised as HTTP 200 segments', () {
      final htmlBytes = utf8.encode('<!DOCTYPE html><html><body>502 Bad Gateway</body></html>');
      expect(TsSegmentUtils.looksLikeErrorDocument(htmlBytes), isTrue);

      final jsonErr = utf8.encode('{"error":"token expired"}');
      expect(TsSegmentUtils.looksLikeErrorDocument(jsonErr), isTrue);

      final validTs = _buildTsSegment(2, 55);
      expect(TsSegmentUtils.looksLikeErrorDocument(validTs), isFalse);
    });

    test('preserves fMP4 segments without 188-byte TS truncation', () {
      final fmp4 = Uint8List.fromList([
        0x00, 0x00, 0x00, 0x18,
        0x66, 0x74, 0x79, 0x70, // 'ftyp'
        0x69, 0x73, 0x6F, 0x6D,
        ...List.filled(200, 0x11), // 212 bytes total (not divisible by 188)
      ]);
      expect(TsSegmentUtils.isFmp4Segment(fmp4), isTrue);
      final out = TsSegmentUtils.stripPaddingAndAlign(fmp4);
      expect(out.length, fmp4.length);
    });
  });
}
