import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../../history/data/models/watch_history_item.dart';
import '../../../profile/domain/models/user_profile.dart';
import '../../../watchlist/data/watchlist_repository.dart';

/// Portable user dataset payload representing a complete Cineva backup.
///
/// Encapsulates:
/// - User profile info (name, username, avatar preset or custom base64 avatar)
/// - Watchlist items
/// - Watch history items (playback positions, completion status, timestamps)
/// - Application settings & preferences (quality, subtitles, content preferences)
/// - Search history keywords
class CinevaBackupPayload {
  static const int currentSchemaVersion = 1;
  static const String magicIdentifier = 'cineva_backup';

  final int version;
  final String appVersion;
  final DateTime exportedAt;
  final UserProfile profile;
  final String? customAvatarBase64;
  final List<WatchlistItem> watchlist;
  final List<WatchHistoryItem> watchHistory;
  final Map<String, dynamic> settings;
  final List<String> searchHistory;

  const CinevaBackupPayload({
    this.version = currentSchemaVersion,
    required this.appVersion,
    required this.exportedAt,
    required this.profile,
    this.customAvatarBase64,
    required this.watchlist,
    required this.watchHistory,
    required this.settings,
    this.searchHistory = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'magic': magicIdentifier,
      'version': version,
      'appVersion': appVersion,
      'exportedAt': exportedAt.toIso8601String(),
      'profile': {
        'name': profile.name,
        'username': profile.username,
        'avatarId': profile.avatarId,
        'customAvatarBase64': customAvatarBase64,
        'createdAt': profile.createdAt.toIso8601String(),
        'isConfigured': profile.isConfigured,
      },
      'watchlist': watchlist.map((w) => w.toJson()).toList(),
      'watchHistory': watchHistory.map((h) => h.toJson()).toList(),
      'settings': settings,
      'searchHistory': searchHistory,
    };
  }

  factory CinevaBackupPayload.fromJson(Map<String, dynamic> json) {
    // Validate signature
    final magic = json['magic'];
    if (magic != null && magic != magicIdentifier) {
      throw const FormatException('Invalid backup file: signature mismatch');
    }

    // 1. Profile
    UserProfile profile;
    String? customAvatarBase64;
    final rawProfile = json['profile'];
    if (rawProfile is Map) {
      final pMap = rawProfile.cast<String, dynamic>();
      customAvatarBase64 = pMap['customAvatarBase64'] as String?;
      profile = UserProfile(
        name: pMap['name'] as String? ?? 'Penikmat Film',
        username: pMap['username'] as String? ?? 'cineva_fan',
        avatarId: pMap['avatarId'] as String? ?? 'avatar_popcorn',
        customAvatarPath: null,
        createdAt: DateTime.tryParse(pMap['createdAt'] as String? ?? '') ??
            DateTime.now(),
        isConfigured: pMap['isConfigured'] as bool? ?? true,
      );
    } else {
      profile = UserProfile.defaultProfile();
    }

    // 2. Watchlist
    final watchlist = <WatchlistItem>[];
    final rawWatchlist = json['watchlist'];
    if (rawWatchlist is List) {
      for (final item in rawWatchlist) {
        if (item is Map) {
          try {
            watchlist.add(WatchlistItem.fromJson(item));
          } catch (e) {
            debugPrint('[CinevaBackupPayload] Skip invalid watchlistItem: $e');
          }
        }
      }
    }

    // 3. Watch History
    final watchHistory = <WatchHistoryItem>[];
    final rawHistory = json['watchHistory'];
    if (rawHistory is List) {
      for (final item in rawHistory) {
        if (item is Map) {
          try {
            watchHistory.add(WatchHistoryItem.fromJson(item));
          } catch (e) {
            debugPrint('[CinevaBackupPayload] Skip invalid watchHistoryItem: $e');
          }
        }
      }
    }

    // 4. Settings
    final settings = <String, dynamic>{};
    final rawSettings = json['settings'];
    if (rawSettings is Map) {
      settings.addAll(rawSettings.cast<String, dynamic>());
    }

    // 5. Search History
    final searchHistory = <String>[];
    final rawSearch = json['searchHistory'];
    if (rawSearch is List) {
      for (final q in rawSearch) {
        if (q != null) searchHistory.add(q.toString());
      }
    }

    return CinevaBackupPayload(
      version: (json['version'] as num?)?.toInt() ?? currentSchemaVersion,
      appVersion: json['appVersion'] as String? ?? '1.1.7',
      exportedAt: DateTime.tryParse(json['exportedAt'] as String? ?? '') ??
          DateTime.now(),
      profile: profile,
      customAvatarBase64: customAvatarBase64,
      watchlist: watchlist,
      watchHistory: watchHistory,
      settings: settings,
      searchHistory: searchHistory,
    );
  }

  /// Serializes payload to formatted JSON string.
  String toEncodedString() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }

  /// Deserializes payload from JSON string with safety checks.
  static CinevaBackupPayload fromEncodedString(String raw) {
    final decoded = jsonDecode(raw.trim());
    if (decoded is! Map) {
      throw const FormatException('Expected JSON map in backup content');
    }
    return CinevaBackupPayload.fromJson(decoded.cast<String, dynamic>());
  }
}

