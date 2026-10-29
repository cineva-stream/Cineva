/// Helpers for cleaning decrypted MPEG-TS HLS segments.
class TsSegmentUtils {
  static const int tsPacketSize = 188;
  static const int tsSyncByte = 0x47;

  /// Unwraps disguised segments that prepend fake image headers (PNG, JPEG, etc.).
  /// Searches for the first TS sync byte `0x47` that repeats at 188-byte intervals.
  static List<int> unwrapDisguisedSegment(List<int> bytes) {
    if (bytes.isEmpty) return bytes;
    if (bytes.first == tsSyncByte) return bytes;

    // Search up to the first 2048 bytes for the TS sync byte
    final searchLimit = bytes.length > 2048 ? 2048 : bytes.length;
    for (int i = 0; i < searchLimit; i++) {
      if (bytes[i] == tsSyncByte) {
        if (i + tsPacketSize < bytes.length) {
          if (bytes[i + tsPacketSize] == tsSyncByte) {
            return bytes.sublist(i);
          }
        } else {
          return bytes.sublist(i);
        }
      }
    }
    return bytes;
  }

  /// Removes PKCS7 padding (if valid) left behind by AES-128-CBC decryption with
  /// `padding: null`, then trims any trailing bytes so that the segment is a whole
  /// number of 188-byte TS packets. Without this, concatenated segments become
  /// misaligned and demuxers lose TS sync.
  static List<int> stripPaddingAndAlign(List<int> decrypted) {
    var out = unwrapDisguisedSegment(decrypted);

    if (out.isNotEmpty) {
      final n = out.last;
      if (n >= 1 && n <= 16 && out.length >= n) {
        var valid = true;
        for (int i = out.length - n; i < out.length; i++) {
          if (out[i] != n) {
            valid = false;
            break;
          }
        }
        if (valid) {
          final stripped = out.sublist(0, out.length - n);
          // If the data was already a whole number of TS packets, those bytes were real payload.
          final alreadyAligned = out.length % tsPacketSize == 0 && out.first == tsSyncByte;
          if (!(alreadyAligned && stripped.length % tsPacketSize != 0)) {
            out = stripped;
          }
        }
      }
    }

    if (out.isNotEmpty && out.first == tsSyncByte && out.length % tsPacketSize != 0) {
      final aligned = (out.length ~/ tsPacketSize) * tsPacketSize;
      if (aligned > 0 && out[aligned - tsPacketSize] == tsSyncByte) {
        out = out.sublist(0, aligned);
      }
    }

    return out;
  }
}
