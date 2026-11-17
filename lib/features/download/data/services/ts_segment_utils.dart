import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Helpers for unwrapping disguised HLS segments (WebP EXIF, PNG after IEND,
/// PNG TIKTIKPX pixel steganography + Gzip, TIKTIKRAW / TIKTIKTSGZ markers)
/// and cleaning decrypted MPEG-TS / fMP4 segments.
///
/// Full port of `DisguisedSegmentUnwrapper.kt` from `flixquest-betterplayer`
/// and `looksLikeDocument` from `flixquest-add-language`.
class TsSegmentUtils {
  static const int tsPacketSize = 188;
  static const int tsSyncByte = 0x47;

  static const List<int> _pngSignature = <int>[
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
  ];
  static const List<int> _riffBytes = <int>[0x52, 0x49, 0x46, 0x46]; // RIFF
  static const List<int> _webpBytes = <int>[0x57, 0x45, 0x42, 0x50]; // WEBP
  static const List<int> _exifBytes = <int>[0x45, 0x58, 0x49, 0x46]; // EXIF
  static const List<int> _ihdrBytes = <int>[0x49, 0x48, 0x44, 0x52]; // IHDR
  static const List<int> _idatBytes = <int>[0x49, 0x44, 0x41, 0x54]; // IDAT
  static const List<int> _iendBytes = <int>[0x49, 0x45, 0x4E, 0x44]; // IEND

  static const List<int> _tiktikRawMarker = <int>[
    0x54, 0x49, 0x4B, 0x54, 0x49, 0x4B, 0x52, 0x41, 0x57, // TIKTIKRAW
  ];
  static const List<int> _tiktikGzipMarker = <int>[
    0x54, 0x49, 0x4B, 0x54, 0x49, 0x4B, 0x54, 0x53, 0x47, 0x5A, // TIKTIKTSGZ
  ];
  static const List<int> _tiktikPxMarker = <int>[
    0x54, 0x49, 0x4B, 0x54, 0x49, 0x4B, 0x50, 0x58, // TIKTIKPX
  ];

  /// Returns true if [bytes] at [offset] begins with a valid MPEG-TS sync pattern
  /// (`0x47` at `offset` and `0x47` at `offset + 188`).
  static bool isTsSync(List<int> bytes, [int offset = 0]) {
    if (offset < 0 || offset >= bytes.length) return false;
    if ((bytes[offset] & 0xFF) != tsSyncByte) return false;
    if (offset + tsPacketSize < bytes.length) {
      return (bytes[offset + tsPacketSize] & 0xFF) == tsSyncByte;
    }
    return true;
  }

  /// Returns true if [bytes] has [packets] consecutive MPEG-TS packets starting at
  /// [offset] (each beginning with `0x47`, spaced 188 bytes apart). When fewer than
  /// [packets] full packets fit in the buffer, every available packet must be in sync.
  ///
  /// A single `0x47 ... 0x47` pair matches random data once every ~65k bytes, so the
  /// previous two-packet check produced false positives on garbage (undecryptable or
  /// compressed) payloads. A run of several packets makes false positives negligible.
  static bool isTsSyncRun(List<int> bytes, int offset, {int packets = 5}) {
    if (offset < 0 || offset >= bytes.length) return false;
    final available = (bytes.length - offset + tsPacketSize - 1) ~/ tsPacketSize;
    final required = available < packets ? available : packets;
    if (required <= 0) return false;
    for (int i = 0; i < required; i++) {
      final pos = offset + i * tsPacketSize;
      if (pos >= bytes.length) return false;
      if ((bytes[pos] & 0xFF) != tsSyncByte) return false;
    }
    return true;
  }

  /// True when [bytes] starts with a raw ADTS AAC frame, an MP3 frame or an ID3 tag
  /// (audio-only HLS renditions that are not wrapped in MPEG-TS).
  static bool isRawAudioSegment(List<int> bytes) {
    if (bytes.length < 4) return false;
    final b0 = bytes[0] & 0xFF;
    final b1 = bytes[1] & 0xFF;
    if (b0 == 0x49 && b1 == 0x44 && (bytes[2] & 0xFF) == 0x33) return true; // ID3
    // ADTS / MPEG audio frame sync: 12 set bits.
    return b0 == 0xFF && (b1 & 0xF0) == 0xF0;
  }

  /// Strict "is this really media?" check applied to every downloaded segment after
  /// decryption / unwrapping. Accepts MPEG-TS (a run of in-sync packets from the very
  /// first byte), fMP4 box headers and, when [allowRawAudio] is set, raw AAC/MP3.
  ///
  /// Anything else (HTML/JSON error pages, undecrypted ciphertext, fake images, brotli
  /// blobs...) is rejected so that a broken download fails loudly and gets retried
  /// instead of silently producing a black-screen, 00:00 video.
  static bool isValidMediaSegment(List<int> bytes, {bool allowRawAudio = false}) {
    if (bytes.isEmpty) return false;
    if (isFmp4Segment(bytes)) return true;
    if (bytes.length >= tsPacketSize * 2 && isTsSyncRun(bytes, 0)) return true;
    if (allowRawAudio && isRawAudioSegment(bytes)) return true;
    return false;
  }

  /// Returns true if [bytes] is a fragmented MP4 (fMP4 / ISO BMFF) segment
  /// starting with a standard box header (`ftyp`, `styp`, `moof`, `sidx`, `moov`, `emsg`, `free`, `mdat`).
  static bool isFmp4Segment(List<int> bytes) {
    if (bytes.length < 8) return false;
    final b4 = bytes[4] & 0xFF;
    final b5 = bytes[5] & 0xFF;
    final b6 = bytes[6] & 0xFF;
    final b7 = bytes[7] & 0xFF;
    final tag = String.fromCharCodes([b4, b5, b6, b7]);
    return const {
      'ftyp',
      'styp',
      'moof',
      'sidx',
      'moov',
      'emsg',
      'free',
      'mdat',
    }.contains(tag);
  }

  /// Detects if an HTTP 200 segment response is actually an HTML or JSON error page
  /// returned by an upstream proxy/CDN instead of binary media data.
  /// Ported from `DownloadCacheReuse.kt` (`looksLikeDocument`).
  ///
  /// Note: Never reject based on `Content-Type: text/html` alone because upstream
  /// CDNs (e.g. VixSrc `secretanchor.boats`) intentionally serve AES-128 encrypted
  /// video segments with `.html` extensions and `Content-Type: text/html`.
  static bool looksLikeErrorDocument(List<int> bytes, {String? contentType}) {
    if (bytes.isEmpty) return true;

    // Skip leading ASCII whitespace
    int start = 0;
    final maxCheck = bytes.length < 512 ? bytes.length : 512;
    while (start < maxCheck) {
      final b = bytes[start] & 0xFF;
      if (b == 0x20 || b == 0x09 || b == 0x0A || b == 0x0D) {
        start++;
      } else {
        break;
      }
    }
    if (start >= maxCheck) return false;

    final end = (start + 64) < bytes.length ? (start + 64) : bytes.length;
    try {
      final prefix = ascii
          .decode(bytes.sublist(start, end), allowInvalid: true)
          .toLowerCase();
      if (prefix.startsWith('<!doctype html') ||
          prefix.startsWith('<html') ||
          prefix.startsWith('<head') ||
          prefix.startsWith('<body') ||
          prefix.startsWith('{"error"') ||
          prefix.startsWith('{"success":false') ||
          prefix.startsWith('{"status":4') ||
          prefix.startsWith('{"status":5') ||
          prefix.startsWith('error:')) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Unwraps disguised segments that hide MPEG-TS inside fake image containers
  /// (WebP EXIF, PNG after IEND, PNG TIKTIKPX pixel steganography + Gzip,
  /// TIKTIKRAW / TIKTIKTSGZ markers, or leading junk bytes).
  static List<int> unwrapDisguisedSegment(List<int> rawBytes) {
    if (rawBytes.isEmpty) return rawBytes;
    if (isTsSync(rawBytes, 0) || isFmp4Segment(rawBytes)) return rawBytes;

    final Uint8List bytes = rawBytes is Uint8List
        ? rawBytes
        : Uint8List.fromList(rawBytes);

    final unwrapped =
        _unwrapWebpExif(bytes) ??
        _unwrapPngAfterIend(bytes) ??
        _unwrapPngPixelPayload(bytes) ??
        _unwrapByMarkerOrSync(bytes);

    return unwrapped ?? rawBytes;
  }

  /// 1. Extracts MPEG-TS embedded in a WebP `EXIF` chunk (`RIFF....WEBP`).
  static Uint8List? _unwrapWebpExif(Uint8List bytes) {
    if (bytes.length < 20) return null;
    if (!_matchesAscii(bytes, 0, _riffBytes) ||
        !_matchesAscii(bytes, 8, _webpBytes)) {
      return null;
    }

    int offset = 12;
    while (offset + 8 <= bytes.length) {
      final chunkSize = _readLeInt32(bytes, offset + 4);
      if (chunkSize < 0) return null;
      final payloadStart = offset + 8;
      final payloadEnd = (payloadStart + chunkSize).clamp(0, bytes.length);

      if (_matchesAscii(bytes, offset, _exifBytes)) {
        if (isTsSync(bytes, payloadStart) && payloadEnd > payloadStart) {
          return Uint8List.sublistView(bytes, payloadStart, payloadEnd);
        }
        return null;
      }

      final padded = chunkSize + (chunkSize.isOdd ? 1 : 0);
      offset = payloadStart + padded;
    }
    return null;
  }

  /// 2. Extracts MPEG-TS appended immediately after a PNG `IEND` chunk.
  static Uint8List? _unwrapPngAfterIend(Uint8List bytes) {
    if (!_hasPngSignature(bytes)) return null;
    int offset = 8;
    while (offset + 12 <= bytes.length) {
      final length = _readBeInt32(bytes, offset);
      if (length < 0) return null;
      final typeStart = offset + 4;
      final dataStart = offset + 8;
      final chunkEnd = dataStart + length + 4; // +4 for CRC
      if (chunkEnd > bytes.length || chunkEnd < offset) return null;

      if (_matchesAscii(bytes, typeStart, _iendBytes)) {
        if (chunkEnd < bytes.length && isTsSync(bytes, chunkEnd)) {
          return Uint8List.sublistView(bytes, chunkEnd);
        }
        return null;
      }
      offset = chunkEnd;
    }
    return null;
  }

  /// 3. Extracts MPEG-TS steganographically encoded inside 8-bit RGB/RGBA PNG
  /// pixels (`IHDR` + `IDAT` -> zlib inflate -> PNG scanline unfiltering ->
  /// `TIKTIKPX` + 32-bit length + Gzip -> raw MPEG-TS).
  static Uint8List? _unwrapPngPixelPayload(Uint8List bytes) {
    if (!_hasPngSignature(bytes)) return null;

    int width = 0;
    int height = 0;
    int bitDepth = 0;
    int colorType = -1;
    int interlace = -1;
    final idatBuffer = BytesBuilder(copy: false);

    int offset = 8;
    while (offset + 12 <= bytes.length) {
      final length = _readBeInt32(bytes, offset);
      if (length < 0) return null;
      final typeStart = offset + 4;
      final dataStart = offset + 8;
      final dataEnd = dataStart + length;
      final chunkEnd = dataEnd + 4;
      if (chunkEnd > bytes.length || dataEnd < dataStart) return null;

      if (_matchesAscii(bytes, typeStart, _ihdrBytes) && length >= 13) {
        width = _readBeInt32(bytes, dataStart);
        height = _readBeInt32(bytes, dataStart + 4);
        bitDepth = bytes[dataStart + 8] & 0xFF;
        colorType = bytes[dataStart + 9] & 0xFF;
        interlace = bytes[dataStart + 12] & 0xFF;
      } else if (_matchesAscii(bytes, typeStart, _idatBytes)) {
        idatBuffer.add(Uint8List.sublistView(bytes, dataStart, dataEnd));
      } else if (_matchesAscii(bytes, typeStart, _iendBytes)) {
        break;
      }

      offset = chunkEnd;
    }

    if (width <= 0 || height <= 0 || bitDepth != 8 || interlace != 0) {
      return null;
    }
    final channels = colorType == 2 ? 3 : (colorType == 6 ? 4 : -1);
    if (channels < 0 || idatBuffer.isEmpty) return null;

    final Uint8List inflated;
    try {
      final decoded = zlib.decode(idatBuffer.takeBytes());
      inflated = decoded is Uint8List ? decoded : Uint8List.fromList(decoded);
    } catch (_) {
      return null;
    }

    final stride = width * channels;
    if (inflated.length < height * (1 + stride)) return null;

    final rgb = Uint8List(width * height * 3);
    final prevRow = Uint8List(stride);
    final currRow = Uint8List(stride);
    int rgbPos = 0;

    for (int y = 0; y < height; y++) {
      final rowStart = y * (1 + stride);
      final filter = inflated[rowStart] & 0xFF;
      final srcOffset = rowStart + 1;

      for (int i = 0; i < stride; i++) {
        final raw = inflated[srcOffset + i] & 0xFF;
        final left = i >= channels ? (currRow[i - channels] & 0xFF) : 0;
        final up = prevRow[i] & 0xFF;
        final upLeft = i >= channels ? (prevRow[i - channels] & 0xFF) : 0;

        int recon;
        switch (filter) {
          case 0:
            recon = raw;
            break;
          case 1:
            recon = (raw + left) & 0xFF;
            break;
          case 2:
            recon = (raw + up) & 0xFF;
            break;
          case 3:
            recon = (raw + ((left + up) >> 1)) & 0xFF;
            break;
          case 4:
            recon = (raw + _paeth(left, up, upLeft)) & 0xFF;
            break;
          default:
            return null;
        }
        currRow[i] = recon;
      }

      if (channels == 3) {
        rgb.setRange(rgbPos, rgbPos + stride, currRow);
        rgbPos += stride;
      } else {
        int px = 0;
        while (px < stride) {
          rgb[rgbPos++] = currRow[px];
          rgb[rgbPos++] = currRow[px + 1];
          rgb[rgbPos++] = currRow[px + 2];
          px += 4;
        }
      }

      prevRow.setRange(0, stride, currRow);
    }

    if (!_matchesAscii(rgb, 0, _tiktikPxMarker) || rgb.length < 12) {
      return null;
    }
    final payloadLen = _readBeInt32(rgb, 8);
    final payloadEnd = 12 + payloadLen;
    if (payloadLen <= 0 || payloadEnd > rgb.length) return null;

    final compressed = Uint8List.sublistView(rgb, 12, payloadEnd);
    final gunzipped = _gunzipIfNeeded(compressed);
    return isTsSync(gunzipped, 0) ? gunzipped : null;
  }

  /// 4. Extracts MPEG-TS from `TIKTIKRAW`, `TIKTIKTSGZ` (Gzip), raw Gzip,
  /// or full-buffer 188-byte sync byte scan (for non-PNG inputs).
  static Uint8List? _unwrapByMarkerOrSync(Uint8List bytes) {
    final rawMarkerIndex = _indexOfMarker(bytes, _tiktikRawMarker);
    if (rawMarkerIndex >= 0) {
      final start = rawMarkerIndex + _tiktikRawMarker.length;
      if (isTsSync(bytes, start)) {
        return Uint8List.sublistView(bytes, start);
      }
    }

    final gzipMarkerIndex = _indexOfMarker(bytes, _tiktikGzipMarker);
    if (gzipMarkerIndex >= 0) {
      final start = gzipMarkerIndex + _tiktikGzipMarker.length;
      if (start < bytes.length) {
        final inflated = _gunzipIfNeeded(Uint8List.sublistView(bytes, start));
        if (isTsSync(inflated, 0)) return inflated;
      }
    }

    // Raw gzipped TS segment (`1F 8B`)
    if (bytes.length >= 2 &&
        (bytes[0] & 0xFF) == 0x1F &&
        (bytes[1] & 0xFF) == 0x8B) {
      final inflated = _gunzipIfNeeded(bytes);
      if (!identical(inflated, bytes) && isTsSync(inflated, 0)) {
        return inflated;
      }
    }

    // Never scan inside compressed PNG IDAT bytes for random 0x47 matches!
    if (_hasPngSignature(bytes) && _indexOfMarker(bytes, _idatBytes) >= 0) {
      return null;
    }

    // Require a run of consecutive in-sync packets (not just two) so random bytes of an
    // undecryptable payload are never mistaken for an MPEG-TS stream. The run must fit
    // completely inside the buffer: near the tail a shortened run would match noise.
    final totalPackets = bytes.length ~/ tsPacketSize;
    if (totalPackets < 5) {
      // Tiny buffers cannot hold a long run; fall back to the classic two-packet check.
      final limit = bytes.length - tsPacketSize;
      for (int i = 0; i <= limit; i++) {
        if (isTsSync(bytes, i)) {
          return i == 0 ? bytes : Uint8List.sublistView(bytes, i);
        }
      }
      return null;
    }
    const need = 5;
    final lastStart = bytes.length - need * tsPacketSize;
    for (int i = 0; i <= lastStart; i++) {
      if ((bytes[i] & 0xFF) != tsSyncByte) continue;
      if (isTsSyncRun(bytes, i, packets: need)) {
        return i == 0 ? bytes : Uint8List.sublistView(bytes, i);
      }
    }
    return null;
  }

  /// Removes PKCS7 padding (if valid) left behind by AES-128-CBC decryption with
  /// `padding: null`, unwraps any disguised container, and trims trailing bytes
  /// on MPEG-TS segments so that concatenated segments remain 188-byte aligned.
  /// Leaves fMP4 segments untouched.
  static List<int> stripPaddingAndAlign(
    List<int> rawOrDecrypted, {
    bool isEncrypted = false,
  }) {
    var out = rawOrDecrypted;

    // 1. If encrypted with AES-128-CBC, strip PKCS7 padding first so any outer
    // container (or raw TS) has its exact original byte length before unwrapping.
    if (isEncrypted && out.isNotEmpty) {
      out = _stripPkcs7IfValid(out);
    }

    // 2. Unwrap disguised container (WebP EXIF, PNG IEND, PNG TIKTIKPX, Gzip, etc.)
    out = unwrapDisguisedSegment(out);

    // 3. If it's a fragmented MP4 (fMP4) segment, do NOT align to 188-byte TS!
    if (isFmp4Segment(out)) {
      return out;
    }

    // 4. Also check PKCS7 after unwrap in case an unencrypted wrapper held padded TS
    if (!isEncrypted && out.isNotEmpty) {
      out = _stripPkcs7IfValid(out);
    }

    // 5. Align MPEG-TS segment to a whole number of 188-byte packets
    if (out.isNotEmpty &&
        (out.first & 0xFF) == tsSyncByte &&
        out.length % tsPacketSize != 0) {
      final aligned = (out.length ~/ tsPacketSize) * tsPacketSize;
      if (aligned > 0 && (out[aligned - tsPacketSize] & 0xFF) == tsSyncByte) {
        out = out.sublist(0, aligned);
      }
    }

    return out;
  }

  static List<int> _stripPkcs7IfValid(List<int> data) {
    if (data.isEmpty) return data;
    final n = data.last & 0xFF;
    if (n >= 1 && n <= 16 && data.length >= n) {
      bool valid = true;
      for (int i = data.length - n; i < data.length; i++) {
        if ((data[i] & 0xFF) != n) {
          valid = false;
          break;
        }
      }
      if (valid) {
        final stripped = data.sublist(0, data.length - n);
        final alreadyAligned =
            data.length % tsPacketSize == 0 && (data.first & 0xFF) == tsSyncByte;
        if (!(alreadyAligned && stripped.length % tsPacketSize != 0)) {
          return stripped;
        }
      }
    }
    return data;
  }

  static Uint8List _gunzipIfNeeded(Uint8List bytes) {
    if (bytes.length < 2) return bytes;
    if ((bytes[0] & 0xFF) != 0x1F || (bytes[1] & 0xFF) != 0x8B) {
      return bytes;
    }
    try {
      final decoded = gzip.decode(bytes);
      return decoded is Uint8List ? decoded : Uint8List.fromList(decoded);
    } catch (_) {
      return bytes;
    }
  }

  static bool _hasPngSignature(Uint8List bytes) {
    if (bytes.length < _pngSignature.length) return false;
    for (int i = 0; i < _pngSignature.length; i++) {
      if ((bytes[i] & 0xFF) != _pngSignature[i]) return false;
    }
    return true;
  }

  static bool _matchesAscii(Uint8List bytes, int offset, List<int> expected) {
    if (offset < 0 || offset + expected.length > bytes.length) return false;
    for (int i = 0; i < expected.length; i++) {
      if ((bytes[offset + i] & 0xFF) != expected[i]) return false;
    }
    return true;
  }

  static int _indexOfMarker(Uint8List bytes, List<int> marker) {
    if (marker.isEmpty || bytes.length < marker.length) return -1;
    final limit = bytes.length - marker.length;
    for (int i = 0; i <= limit; i++) {
      bool match = true;
      for (int j = 0; j < marker.length; j++) {
        if ((bytes[i + j] & 0xFF) != marker[j]) {
          match = false;
          break;
        }
      }
      if (match) return i;
    }
    return -1;
  }

  static int _readBeInt32(Uint8List bytes, int offset) {
    return ((bytes[offset] & 0xFF) << 24) |
        ((bytes[offset + 1] & 0xFF) << 16) |
        ((bytes[offset + 2] & 0xFF) << 8) |
        (bytes[offset + 3] & 0xFF);
  }

  static int _readLeInt32(Uint8List bytes, int offset) {
    return (bytes[offset] & 0xFF) |
        ((bytes[offset + 1] & 0xFF) << 8) |
        ((bytes[offset + 2] & 0xFF) << 16) |
        ((bytes[offset + 3] & 0xFF) << 24);
  }

  static int _paeth(int a, int b, int c) {
    final p = a + b - c;
    final pa = (p - a).abs();
    final pb = (p - b).abs();
    final pc = (p - c).abs();
    if (pa <= pb && pa <= pc) return a;
    if (pb <= pc) return b;
    return c;
  }
}
