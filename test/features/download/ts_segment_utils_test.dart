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
      // Avoid accidental long runs; payload content is irrelevant for this test.
    }
  }
  return data;
}

void main() {
  final key = enc.Key(Uint8List.fromList(List.generate(16, (i) => i + 1)));
  final iv = enc.IV(Uint8List.fromList(List.generate(16, (i) => 16 - i)));

  group('TsSegmentUtils.stripPaddingAndAlign', () {
    test('removes PKCS7 padding left by padding:null AES-CBC decryption', () {
      final original = _buildTsSegment(1117, 3); // 209996 bytes, like real vixsrc segments
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final cipher = encrypter.encryptBytes(original, iv: iv).bytes;
      expect(cipher.length % 16, 0);

      final raw = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc, padding: null))
          .decryptBytes(enc.Encrypted(cipher), iv: iv);
      expect(raw.length, greaterThan(original.length)); // padding still attached

      final cleaned = TsSegmentUtils.stripPaddingAndAlign(raw);
      expect(cleaned.length, original.length);
      expect(cleaned.length % TsSegmentUtils.tsPacketSize, 0);
      expect(Uint8List.fromList(cleaned), original);
    });

    test('concatenated segments stay TS-aligned (every 188th byte is 0x47)', () {
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final raw = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc, padding: null));
      final merged = <int>[];

      for (int seg = 0; seg < 5; seg++) {
        final original = _buildTsSegment(40 + seg * 13, seg);
        final cipher = encrypter.encryptBytes(original, iv: iv).bytes;
        merged.addAll(
          TsSegmentUtils.stripPaddingAndAlign(
            raw.decryptBytes(enc.Encrypted(cipher), iv: iv),
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
      // Force an ending that coincidentally looks like padding (0x01).
      original[original.length - 1] = 0x01;
      final cleaned = TsSegmentUtils.stripPaddingAndAlign(original);
      expect(cleaned.length, original.length);
    });

    test('handles empty input', () {
      expect(TsSegmentUtils.stripPaddingAndAlign(<int>[]), isEmpty);
    });
  });
}
