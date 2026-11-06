import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../settings/data/settings_service.dart';
import '../domain/models/user_profile.dart';
import '../presentation/providers/profile_provider.dart';
import 'sync_crypto_service.dart';

/// Metadata representing an active pairing session.
class PairingSessionInfo {
  final String localIp;
  final int localPort;
  final String topic;
  final String key;
  final String pinCode;
  final String qrPayload;

  const PairingSessionInfo({
    required this.localIp,
    required this.localPort,
    required this.topic,
    required this.key,
    required this.pinCode,
    required this.qrPayload,
  });
}

/// Service that manages the receiving end of the QR pairing flow on Android TV & Windows.
///
/// Implements Hybrid Mode:
/// - Fast Local Path: Lightweight [HttpServer] on ephemeral port.
/// - Universal Remote Path: Zero-config end-to-end encrypted pub-sub stream via ntfy.sh.
class HybridPairingService {
  HttpServer? _localServer;
  HttpClient? _relayClient;
  StreamSubscription? _relaySubscription;
  bool _isClosed = false;

  /// Starts both Local LAN server and Cloud Relay listener.
  Future<PairingSessionInfo> startSession({
    required void Function(Map<String, dynamic> profileData) onProfileReceived,
  }) async {
    _isClosed = false;

    // 1. Resolve local IPv4 network address
    final localIp = await _resolveLocalIp();

    // 2. Bind local HTTP server to an available port
    _localServer = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    final port = _localServer!.port;

    // 3. Generate secure topic, AES-256 key, and 6-digit PIN
    final topic = 'cineva_sync_${_generateRandomString(12)}';
    final key = SyncCryptoService.generatePairingKey();
    final pinCode = '${Random().nextInt(900) + 100} ${Random().nextInt(900) + 100}';

    // 4. Construct QR payload URI
    final qrPayload = 'cineva://sync?topic=$topic&key=$key&ip=$localIp&port=$port&pin=${pinCode.replaceAll(' ', '')}';

    // 5. Handle incoming Local LAN HTTP POST
    _localServer!.listen((HttpRequest request) async {
      request.response.headers.add('Access-Control-Allow-Origin', '*');
      request.response.headers.add('Access-Control-Allow-Methods', 'POST, OPTIONS');
      request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');

      if (request.method == 'OPTIONS') {
        request.response.statusCode = HttpStatus.ok;
        await request.response.close();
        return;
      }

      if (request.uri.path == '/sync-profile' && request.method == 'POST') {
        try {
          final body = await utf8.decodeStream(request);
          final Map<String, dynamic> payload;

          // Payload could be encrypted or plain JSON
          if (body.contains(':') && !body.startsWith('{')) {
            final decrypted = SyncCryptoService.decryptPayload(body, key);
            payload = jsonDecode(decrypted) as Map<String, dynamic>;
          } else {
            payload = jsonDecode(body) as Map<String, dynamic>;
          }

          if (!_isClosed) {
            onProfileReceived(payload);
            stopSession();
          }

          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'status': 'ok', 'message': 'Profile received'}));
          await request.response.close();
        } catch (e) {
          request.response
            ..statusCode = HttpStatus.badRequest
            ..write(jsonEncode({'status': 'error', 'message': e.toString()}));
          await request.response.close();
        }
      } else {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      }
    });

    // 6. Listen to Cloud Relay stream in background (for 4G/5G / cross-network)
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      _listenToCloudRelay(topic, key, onProfileReceived);
    }

    return PairingSessionInfo(
      localIp: localIp,
      localPort: port,
      topic: topic,
      key: key,
      pinCode: pinCode,
      qrPayload: qrPayload,
    );
  }

  void _listenToCloudRelay(
    String topic,
    String key,
    void Function(Map<String, dynamic> profileData) onProfileReceived,
  ) async {
    try {
      _relayClient = HttpClient()..connectionTimeout = const Duration(seconds: 6);
      final url = Uri.parse('https://ntfy.sh/$topic/json');
      final request = await _relayClient!.getUrl(url).timeout(const Duration(seconds: 5));
      final response = await request.close().timeout(const Duration(seconds: 5));

      _relaySubscription = response
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        if (_isClosed || line.trim().isEmpty) return;
        try {
          final event = jsonDecode(line) as Map<String, dynamic>;
          if (event['event'] == 'message') {
            final encryptedMessage = event['message'] as String;
            final decrypted = SyncCryptoService.decryptPayload(encryptedMessage, key);
            final data = jsonDecode(decrypted) as Map<String, dynamic>;

            if (!_isClosed) {
              onProfileReceived(data);
              stopSession();
            }
          }
        } catch (e) {
          debugPrint('[HybridPairingService] Relay parse non-fatal: $e');
        }
      }, onError: (e) {
        debugPrint('[HybridPairingService] Relay stream error: $e');
      });
    } catch (e) {
      debugPrint('[HybridPairingService] Non-fatal relay connect error: $e');
    }
  }

  /// Closes both Local Server and Cloud Relay connections.
  void stopSession() {
    _isClosed = true;
    _localServer?.close(force: true);
    _localServer = null;

    _relaySubscription?.cancel();
    _relaySubscription = null;

    _relayClient?.close(force: true);
    _relayClient = null;
  }

  /// Saves the received profile payload into local Hive storage and Riverpod state.
  static Future<UserProfile> applySyncedProfile({
    required WidgetRef ref,
    required Map<String, dynamic> data,
  }) async {
    String? localAvatarPath;

    // Save base64 custom avatar image if provided
    final base64Image = data['customAvatarBase64'] as String?;
    if (base64Image != null && base64Image.isNotEmpty) {
      try {
        final bytes = base64Decode(base64Image);
        final docsDir = await getApplicationDocumentsDirectory();
        final avatarFile = File('${docsDir.path}/synced_avatar_${DateTime.now().millisecondsSinceEpoch}.png');
        await avatarFile.writeAsBytes(bytes);
        localAvatarPath = avatarFile.path;
      } catch (e) {
        debugPrint('[HybridPairingService] Failed to save custom avatar: $e');
      }
    }

    final name = (data['name'] as String?)?.trim().isNotEmpty == true
        ? data['name'] as String
        : 'Penikmat Film';
    final username = (data['username'] as String?)?.trim().isNotEmpty == true
        ? (data['username'] as String).replaceAll('@', '')
        : 'cineva_fan';
    final avatarId = (data['avatarId'] as String?) ?? 'avatar_popcorn';

    // Commit to Riverpod & Hive
    await ref.read(userProfileProvider.notifier).save(
          name: name,
          username: username,
          avatarId: localAvatarPath != null ? 'custom' : avatarId,
          customAvatarPath: localAvatarPath,
        );

    // Auto-accept legal agreements since they were already accepted on mobile
    await SettingsService.setLegalAccepted(true);

    return ref.read(userProfileProvider);
  }

  Future<String> _resolveLocalIp() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return '127.0.0.1';
    }
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      ).timeout(const Duration(seconds: 2));

      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback && !addr.address.startsWith('127.')) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return '127.0.0.1';
  }

  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random.secure();
    return List.generate(length, (_) => chars[rnd.nextInt(chars.length)]).join();
  }
}
