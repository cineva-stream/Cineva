import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;

/// Zero-config, End-to-End Encryption (E2EE) helper using AES-256-CBC.
///
/// Ensures profile synchronization payloads sent over public relays (e.g. ntfy.sh)
/// are mathematically secure and readable ONLY by the device displaying the QR Code.
class SyncCryptoService {
  SyncCryptoService._();

  static const String _magicPrefix = 'cv1:';

  /// Generates a cryptographically strong 256-bit (32-byte) key formatted as URL-safe string.
  static String generatePairingKey() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(32, (_) => rnd.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// Encrypts plain text (e.g. JSON string) using AES-256 with a random 16-byte IV.
  /// Returns a compact string in format: `<ivBase64>:<cipherBase64>`
  static String encryptPayload(String plainText, String keyString) {
    // Pad or trim key to exactly 32 bytes
    final keyBytes = _normalizeKey(keyString);
    final key = enc.Key(keyBytes);
    final iv = enc.IV.fromSecureRandom(16);

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt('$_magicPrefix$plainText', iv: iv);

    return '${iv.base64}:${encrypted.base64}';
  }

  /// Decrypts a payload formatted as `<ivBase64>:<cipherBase64>`.
  static String decryptPayload(String payload, String keyString) {
    final parts = payload.trim().split(':');
    if (parts.length != 2) {
      throw const FormatException('Invalid encrypted payload format (expected iv:cipher)');
    }

    final iv = enc.IV.fromBase64(parts[0]);
    final encrypted = enc.Encrypted.fromBase64(parts[1]);

    final keyBytes = _normalizeKey(keyString);
    final key = enc.Key(keyBytes);

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final decryptedBytes = encrypter.decryptBytes(encrypted, iv: iv);

    // Strict UTF-8 validation: throws FormatException on invalid UTF-8 sequences
    final rawText = utf8.decode(decryptedBytes, allowMalformed: false);

    // Validate integrity header
    if (rawText.startsWith(_magicPrefix)) {
      return rawText.substring(_magicPrefix.length);
    }

    // Backward compatibility for legacy v1.1.5 payloads (raw JSON or gz compressed)
    if (rawText.startsWith('{') || rawText.startsWith('gz:')) {
      return rawText;
    }

    throw const FormatException('Decryption integrity check failed: invalid key or corrupted payload');
  }

  static Uint8List _normalizeKey(String keyString) {
    try {
      final decoded = base64Url.decode(base64Url.normalize(keyString));
      if (decoded.length == 32) return Uint8List.fromList(decoded);
    } catch (_) {}

    // Fallback: UTF-8 bytes padded or sliced to 32 bytes
    final utf8Bytes = utf8.encode(keyString);
    if (utf8Bytes.length >= 32) {
      return Uint8List.fromList(utf8Bytes.sublist(0, 32));
    }
    return Uint8List.fromList(List<int>.generate(32, (i) => i < utf8Bytes.length ? utf8Bytes[i] : 42));
  }
}
