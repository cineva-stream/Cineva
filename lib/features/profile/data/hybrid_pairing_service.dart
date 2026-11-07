import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../history/data/models/watch_history_item.dart';
import '../../history/data/repositories/watch_history_repository.dart';
import '../../search/presentation/providers/search_history_provider.dart';
import '../../settings/data/settings_service.dart';
import '../../watchlist/data/watchlist_repository.dart';
import '../domain/models/user_profile.dart';
import '../presentation/providers/profile_provider.dart';
import 'sync_crypto_service.dart';

/// Result of applying synchronized data from another device.
class SyncedProfileResult {
  final UserProfile profile;
  final int watchlistCount;
  final int historyCount;

  const SyncedProfileResult({
    required this.profile,
    this.watchlistCount = 0,
    this.historyCount = 0,
  });
}

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

/// Connection/synchronization lifecycle state during pairing.
enum HybridPairingStatus {
  listening,
  receiving,
  success,
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
  Timer? _pollTimer;
  bool _isClosed = false;
  bool _hasReceived = false;

  /// Starts both Local LAN server and Cloud Relay listener.
  Future<PairingSessionInfo> startSession({
    required void Function(Map<String, dynamic> profileData) onProfileReceived,
    void Function(HybridPairingStatus status)? onStatusChanged,
  }) async {
    _isClosed = false;
    _hasReceived = false;
    onStatusChanged?.call(HybridPairingStatus.listening);

    // 1. Resolve local IPv4 network address
    final localIp = await _resolveLocalIp();

    // 2. Bind local HTTP server to an available port
    _localServer = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    final port = _localServer!.port;

    // 3. Generate secure topic, AES-256 key, and 6-digit PIN
    final topic = 'cineva_sync_${_generateRandomString(12)}';
    final key = SyncCryptoService.generatePairingKey();
    final pinCode =
        '${Random().nextInt(900) + 100} ${Random().nextInt(900) + 100}';

    // 4. Construct QR payload URI
    final qrPayload =
        'cineva://sync?topic=$topic&key=$key&ip=$localIp&port=$port&pin=${pinCode.replaceAll(' ', '')}';

    // 5. Handle incoming Local LAN HTTP POST
    _localServer!.listen((HttpRequest request) async {
      request.response.headers.add('Access-Control-Allow-Origin', '*');
      request.response.headers.add(
        'Access-Control-Allow-Methods',
        'POST, OPTIONS',
      );
      request.response.headers.add(
        'Access-Control-Allow-Headers',
        'Content-Type',
      );

      if (request.method == 'OPTIONS') {
        request.response.statusCode = HttpStatus.ok;
        await request.response.close();
        return;
      }

      if (request.uri.path == '/sync-profile' && request.method == 'POST') {
        try {
          final body = await utf8.decodeStream(request);
          final Map<String, dynamic> payload;

          // Payload could be encrypted or plain (with or without gz: compression)
          if (body.contains(':') && !body.startsWith('{') && !body.startsWith('gz:')) {
            final decrypted = SyncCryptoService.decryptPayload(body, key);
            payload = _decodeAndParsePayload(decrypted);
          } else {
            payload = _decodeAndParsePayload(body);
          }

          _handleIncomingData(payload, onProfileReceived, onStatusChanged);

          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(
              jsonEncode({'status': 'ok', 'message': 'Profile received'}),
            );
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
      _listenToCloudRelay(topic, key, onProfileReceived, onStatusChanged);
      _startPeriodicPolling(topic, key, onProfileReceived, onStatusChanged);
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

  void _handleIncomingData(
    Map<String, dynamic> data,
    void Function(Map<String, dynamic>) onProfileReceived,
    void Function(HybridPairingStatus status)? onStatusChanged,
  ) {
    if (_hasReceived || _isClosed) return;
    _hasReceived = true;
    onStatusChanged?.call(HybridPairingStatus.receiving);
    try {
      onProfileReceived(data);
      onStatusChanged?.call(HybridPairingStatus.success);
    } catch (e) {
      debugPrint('[HybridPairingService] onProfileReceived error: $e');
    } finally {
      stopSession();
    }
  }

  /// Extracts ciphertext from ntfy event, retrieving attachment if payload exceeded 4KB limit.
  Future<String?> _extractCiphertextFromEvent(Map<String, dynamic> event) async {
    if (event['event'] != 'message') return null;

    // Case 1: Attachment present (> 4KB payload converted by ntfy to file)
    final attachment = event['attachment'];
    if (attachment is Map && attachment['url'] != null) {
      final urlStr = attachment['url'] as String;
      try {
        final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
        final req = await client.getUrl(Uri.parse(urlStr));
        final resp = await req.close().timeout(const Duration(seconds: 8));
        if (resp.statusCode == HttpStatus.ok) {
          final content = await utf8.decodeStream(resp);
          client.close();
          if (content.contains(':')) {
            return content.trim();
          }
        }
        client.close();
      } catch (e) {
        debugPrint('[HybridPairingService] Attachment download failed: $e');
      }
    }

    // Case 2: Inline message
    final msg = event['message'];
    if (msg is String && msg.contains(':')) {
      return msg.trim();
    }

    return null;
  }

  /// Decodes plain or gz-compressed JSON payload into a Map.
  static Map<String, dynamic> _decodeAndParsePayload(String raw) {
    final String jsonText;
    if (raw.startsWith('gz:')) {
      final compressed = base64Decode(raw.substring(3));
      final decompressed = gzip.decode(compressed);
      jsonText = utf8.decode(decompressed);
    } else {
      jsonText = raw;
    }
    return jsonDecode(jsonText) as Map<String, dynamic>;
  }

  /// Decrypts ciphertext and unpacks payload.
  static Map<String, dynamic>? _processRawCiphertext(String ciphertext, String key) {
    try {
      final decrypted = SyncCryptoService.decryptPayload(ciphertext.trim(), key);
      return _decodeAndParsePayload(decrypted);
    } catch (e) {
      debugPrint('[HybridPairingService] Decrypt error: $e');
      return null;
    }
  }

  /// Persistent SSE stream with auto-reconnect.
  void _listenToCloudRelay(
    String topic,
    String key,
    void Function(Map<String, dynamic> profileData) onProfileReceived,
    void Function(HybridPairingStatus status)? onStatusChanged,
  ) async {
    while (!_isClosed && !_hasReceived) {
      try {
        _relayClient?.close(force: true);
        _relayClient = HttpClient()..connectionTimeout = const Duration(seconds: 10);
        final url = Uri.parse('https://ntfy.sh/$topic/json');
        final request = await _relayClient!.getUrl(url).timeout(const Duration(seconds: 8));
        final response = await request.close().timeout(const Duration(seconds: 8));

        await for (final line in response.transform(utf8.decoder).transform(const LineSplitter())) {
          if (_isClosed || _hasReceived) break;
          if (line.trim().isEmpty) continue;

          try {
            final event = jsonDecode(line) as Map<String, dynamic>;
            final cipher = await _extractCiphertextFromEvent(event);
            if (cipher != null && !_hasReceived && !_isClosed) {
              onStatusChanged?.call(HybridPairingStatus.receiving);
              final data = _processRawCiphertext(cipher, key);
              if (data != null) {
                _handleIncomingData(data, onProfileReceived, onStatusChanged);
                return;
              }
            }
          } catch (e) {
            debugPrint('[HybridPairingService] SSE parse error: $e');
          }
        }
      } catch (e) {
        debugPrint('[HybridPairingService] SSE connect/stream info: $e');
      }

      if (!_isClosed && !_hasReceived) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  /// Periodic polling fallback (every 2 seconds) querying cached messages via `?poll=1&since=10m`.
  void _startPeriodicPolling(
    String topic,
    String key,
    void Function(Map<String, dynamic> profileData) onProfileReceived,
    void Function(HybridPairingStatus status)? onStatusChanged,
  ) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_isClosed || _hasReceived) {
        timer.cancel();
        return;
      }

      try {
        final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
        final pollUrl = Uri.parse('https://ntfy.sh/$topic/json?poll=1&since=10m');
        final req = await client.getUrl(pollUrl).timeout(const Duration(seconds: 4));
        final resp = await req.close().timeout(const Duration(seconds: 4));

        if (resp.statusCode == HttpStatus.ok) {
          final body = await utf8.decodeStream(resp);
          client.close();
          if (_isClosed || _hasReceived) return;

          for (final line in const LineSplitter().convert(body)) {
            if (line.trim().isEmpty) continue;
            try {
              final event = jsonDecode(line) as Map<String, dynamic>;
              final cipher = await _extractCiphertextFromEvent(event);
              if (cipher != null && !_hasReceived && !_isClosed) {
                onStatusChanged?.call(HybridPairingStatus.receiving);
                final data = _processRawCiphertext(cipher, key);
                if (data != null) {
                  _handleIncomingData(data, onProfileReceived, onStatusChanged);
                  timer.cancel();
                  return;
                }
              }
            } catch (_) {}
          }
        } else {
          client.close();
        }
      } catch (_) {
        // Polling retry on next interval
      }
    });
  }

  /// Closes both Local Server and Cloud Relay connections.
  void stopSession() {
    _isClosed = true;
    _pollTimer?.cancel();
    _pollTimer = null;

    _localServer?.close(force: true);
    _localServer = null;

    _relaySubscription?.cancel();
    _relaySubscription = null;

    _relayClient?.close(force: true);
    _relayClient = null;
  }

  /// Saves the received profile payload, watchlist, watch history, and preferences into local Hive storage and Riverpod state.
  static Future<SyncedProfileResult> applySyncedProfile({
    required dynamic ref,
    required Map<String, dynamic> data,
  }) async {
    // 1. Resolve Profile data (support both structured 'profile' map and flat legacy format)
    final profileMap = (data['profile'] is Map)
        ? (data['profile'] as Map<String, dynamic>)
        : data;

    String? localAvatarPath;
    final base64Image =
        (profileMap['customAvatarBase64'] ?? data['customAvatarBase64'])
            as String?;
    if (base64Image != null && base64Image.isNotEmpty) {
      try {
        final bytes = base64Decode(base64Image);
        final docsDir = await getApplicationDocumentsDirectory();
        final avatarFile = File(
          '${docsDir.path}/synced_avatar_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await avatarFile.writeAsBytes(bytes);
        localAvatarPath = avatarFile.path;
      } catch (e) {
        debugPrint('[HybridPairingService] Failed to save custom avatar: $e');
      }
    }

    final name = (profileMap['name'] as String?)?.trim().isNotEmpty == true
        ? profileMap['name'] as String
        : 'Penikmat Film';
    final username =
        (profileMap['username'] as String?)?.trim().isNotEmpty == true
        ? (profileMap['username'] as String).replaceAll('@', '')
        : 'cineva_fan';
    final avatarId = (profileMap['avatarId'] as String?) ?? 'avatar_popcorn';

    // Commit to Riverpod & Hive
    await ref
        .read(userProfileProvider.notifier)
        .save(
          name: name,
          username: username,
          avatarId: localAvatarPath != null ? 'custom' : avatarId,
          customAvatarPath: localAvatarPath,
        );

    // Auto-accept legal agreements since they were already accepted on mobile
    await SettingsService.setLegalAccepted(true);

    // 2. Synchronize Watchlist
    int watchlistCount = 0;
    final rawWatchlist = data['watchlist'];
    if (rawWatchlist is List && rawWatchlist.isNotEmpty) {
      final items = <WatchlistItem>[];
      for (final raw in rawWatchlist) {
        if (raw is Map) {
          try {
            items.add(WatchlistItem.fromJson(raw));
          } catch (e) {
            debugPrint(
              '[HybridPairingService] Failed parsing WatchlistItem: $e',
            );
          }
        }
      }
      if (items.isNotEmpty) {
        await ref.read(watchlistRepositoryProvider).importItems(items);
        ref.read(watchlistProvider.notifier).refresh();
        watchlistCount = items.length;
      }
    }

    // 3. Synchronize Watch History & Progress
    int historyCount = 0;
    final rawHistory = data['watchHistory'];
    if (rawHistory is List && rawHistory.isNotEmpty) {
      final items = <WatchHistoryItem>[];
      for (final raw in rawHistory) {
        if (raw is Map) {
          try {
            items.add(WatchHistoryItem.fromJson(raw));
          } catch (e) {
            debugPrint(
              '[HybridPairingService] Failed parsing WatchHistoryItem: $e',
            );
          }
        }
      }
      if (items.isNotEmpty) {
        await ref.read(watchHistoryRepositoryProvider).importItems(items);
        ref.read(watchHistoryProvider.notifier).refresh();
        historyCount = items.length;
      }
    }

    // 4. Synchronize User Preferences & Settings
    final rawSettings = data['settings'];
    if (rawSettings is Map) {
      try {
        await SettingsService.importPreferences(
          rawSettings.cast<String, dynamic>(),
        );
      } catch (e) {
        debugPrint('[HybridPairingService] Failed importing settings: $e');
      }
    }

    // 5. Synchronize Search History
    final rawSearchHistory = data['searchHistory'];
    if (rawSearchHistory is List && rawSearchHistory.isNotEmpty) {
      try {
        final queries = rawSearchHistory.map((e) => e.toString()).toList();
        await ref.read(searchHistoryProvider.notifier).importQueries(queries);
      } catch (e) {
        debugPrint(
          '[HybridPairingService] Failed importing search history: $e',
        );
      }
    }

    return SyncedProfileResult(
      profile: ref.read(userProfileProvider),
      watchlistCount: watchlistCount,
      historyCount: historyCount,
    );
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
    return List.generate(
      length,
      (_) => chars[rnd.nextInt(chars.length)],
    ).join();
  }
}
