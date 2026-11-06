import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../domain/models/user_profile.dart';
import 'sync_crypto_service.dart';

/// Parsed data from scanning a Cineva Pairing QR Code.
class ParsedPairingQr {
  final String topic;
  final String key;
  final String? ip;
  final int? port;
  final String? pin;

  const ParsedPairingQr({
    required this.topic,
    required this.key,
    this.ip,
    this.port,
    this.pin,
  });

  /// Factory to parse from `cineva://sync?topic=...&key=...&ip=...&port=...`
  static ParsedPairingQr? tryParse(String raw) {
    try {
      final uri = Uri.parse(raw.trim());
      if (uri.scheme != 'cineva' || uri.host != 'sync') {
        // Also support plain query format
        final topic = uri.queryParameters['topic'];
        final key = uri.queryParameters['key'];
        if (topic != null && key != null) {
          return ParsedPairingQr(
            topic: topic,
            key: key,
            ip: uri.queryParameters['ip'],
            port: int.tryParse(uri.queryParameters['port'] ?? ''),
            pin: uri.queryParameters['pin'],
          );
        }
        return null;
      }

      final topic = uri.queryParameters['topic'];
      final key = uri.queryParameters['key'];
      if (topic == null || key == null) return null;

      return ParsedPairingQr(
        topic: topic,
        key: key,
        ip: uri.queryParameters['ip'],
        port: int.tryParse(uri.queryParameters['port'] ?? ''),
        pin: uri.queryParameters['pin'],
      );
    } catch (_) {
      return null;
    }
  }
}

/// Result of sending profile to TV/PC.
class SyncSendResult {
  final bool success;
  final bool usedCloudRelay;
  final String? errorMessage;

  const SyncSendResult({
    required this.success,
    this.usedCloudRelay = false,
    this.errorMessage,
  });
}

/// Dispatches profile synchronization from smartphone to TV/PC via Hybrid Mode.
class ProfileSyncSender {
  ProfileSyncSender._();

  static Future<SyncSendResult> sendProfile({
    required ParsedPairingQr qrData,
    required UserProfile profile,
  }) async {
    // 1. Prepare Base64 custom avatar if available
    String? customAvatarBase64;
    if (profile.customAvatarPath != null) {
      try {
        final file = File(profile.customAvatarPath!);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          customAvatarBase64 = base64Encode(bytes);
        }
      } catch (e) {
        debugPrint('[ProfileSyncSender] Failed reading custom avatar: $e');
      }
    }

    final payloadMap = {
      'name': profile.name,
      'username': profile.username,
      'avatarId': profile.avatarId,
      'customAvatarBase64': customAvatarBase64,
      'createdAt': profile.createdAt.toIso8601String(),
    };
    final jsonString = jsonEncode(payloadMap);

    // 2. PATH 1: Try Local LAN Direct Connection (Fast Path: ~30-50ms)
    if (qrData.ip != null &&
        qrData.port != null &&
        qrData.ip != '127.0.0.1' &&
        !qrData.ip!.startsWith('127.')) {
      try {
        final lanUri = Uri.parse('http://${qrData.ip}:${qrData.port}/sync-profile');
        final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 1200);

        final request = await client.postUrl(lanUri);
        request.headers.contentType = ContentType.json;
        request.write(jsonString);

        final response = await request.close().timeout(const Duration(milliseconds: 1500));
        client.close();

        if (response.statusCode == HttpStatus.ok) {
          return const SyncSendResult(success: true, usedCloudRelay: false);
        }
      } catch (e) {
        debugPrint('[ProfileSyncSender] Local LAN failed or different network ($e). Falling back to Cloud Relay...');
      }
    }

    // 3. PATH 2: Zero-Config End-to-End Encrypted Cloud Relay (Works on 4G/5G & different Wi-Fi)
    try {
      final encryptedPayload = SyncCryptoService.encryptPayload(jsonString, qrData.key);
      final relayUri = Uri.parse('https://ntfy.sh/${qrData.topic}');

      final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
      final request = await client.postUrl(relayUri);
      request.headers.contentType = ContentType.text;
      request.write(encryptedPayload);

      final response = await request.close().timeout(const Duration(seconds: 6));
      client.close();

      if (response.statusCode == HttpStatus.ok) {
        return const SyncSendResult(success: true, usedCloudRelay: true);
      } else {
        return SyncSendResult(
          success: false,
          errorMessage: 'Cloud relay returned HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      return SyncSendResult(
        success: false,
        errorMessage: 'Gagal mengirim profil ke TV: $e',
      );
    }
  }
}
