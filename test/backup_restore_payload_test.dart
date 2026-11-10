import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineva/core/localization/app_language.dart';
import 'package:cineva/core/localization/app_strings.dart';
import 'package:cineva/features/backup/domain/models/cineva_backup_payload.dart';
import 'package:cineva/features/history/data/models/watch_history_item.dart';
import 'package:cineva/features/profile/domain/models/user_profile.dart';
import 'package:cineva/features/watchlist/data/watchlist_repository.dart';

void main() {
  group('CinevaBackupPayload Unit Tests', () {
    test('Lossless JSON serialization & deserialization roundtrip', () {
      final now = DateTime.now();
      final original = CinevaBackupPayload(
        version: 1,
        appVersion: '1.1.7',
        exportedAt: now,
        profile: UserProfile(
          name: 'Budi Santoso 🎬',
          username: 'budi_cine',
          avatarId: 'avatar_director',
          customAvatarPath: '/path/to/local/avatar.png',
          createdAt: now,
          isConfigured: true,
        ),
        customAvatarBase64: base64Encode(utf8.encode('fake_png_binary_data')),
        watchlist: [
          WatchlistItem(
            id: 101,
            title: 'Inception',
            posterPath: '/inception.jpg',
            voteAverage: 8.8,
            type: 'movie',
            addedAt: now,
          ),
          WatchlistItem(
            id: 202,
            title: 'Stranger Things',
            posterPath: '/stranger.jpg',
            voteAverage: 8.7,
            type: 'tv',
            addedAt: now,
          ),
        ],
        watchHistory: [
          WatchHistoryItem(
            id: 101,
            title: 'Inception',
            posterPath: '/inception.jpg',
            mediaType: 'movie',
            positionMs: 3600000,
            durationMs: 7200000,
            lastWatchedAt: now,
            isCompleted: false,
          ),
          WatchHistoryItem(
            id: 202,
            title: 'Stranger Things',
            posterPath: '/stranger.jpg',
            mediaType: 'tv',
            season: 4,
            episode: 1,
            positionMs: 2700000,
            durationMs: 3000000,
            lastWatchedAt: now,
            isCompleted: true,
          ),
        ],
        settings: {
          'app_language': 'id',
          'default_quality': '1080p',
          'default_subtitle_lang': 'id',
          'subtitle_font_size': 'Besar',
          'subtitle_background': 'Semi-Transparan',
          'hardware_acceleration': true,
        },
        searchHistory: ['Interstellar', 'Oppenheimer', 'Dune'],
      );

      final encoded = original.toEncodedString();
      expect(encoded, isNotEmpty);
      expect(encoded, contains('cineva_backup'));
      expect(encoded, contains('Inception'));
      expect(encoded, contains('Budi Santoso 🎬'));

      final restored = CinevaBackupPayload.fromEncodedString(encoded);

      // Verify Profile
      expect(restored.profile.name, equals('Budi Santoso 🎬'));
      expect(restored.profile.username, equals('budi_cine'));
      expect(restored.profile.avatarId, equals('avatar_director'));
      expect(restored.customAvatarBase64, isNotNull);

      // Verify Watchlist
      expect(restored.watchlist.length, equals(2));
      expect(restored.watchlist.first.title, equals('Inception'));
      expect(restored.watchlist.last.type, equals('tv'));

      // Verify Watch History
      expect(restored.watchHistory.length, equals(2));
      expect(restored.watchHistory.first.positionMs, equals(3600000));
      expect(restored.watchHistory.first.isCompleted, isFalse);
      expect(restored.watchHistory.last.season, equals(4));
      expect(restored.watchHistory.last.episode, equals(1));
      expect(restored.watchHistory.last.isCompleted, isTrue);

      // Verify Settings
      expect(restored.settings['default_quality'], equals('1080p'));
      expect(restored.settings['subtitle_font_size'], equals('Besar'));
      expect(restored.settings['hardware_acceleration'], isTrue);

      // Verify Search History
      expect(restored.searchHistory, equals(['Interstellar', 'Oppenheimer', 'Dune']));
    });

    test('Throws FormatException on invalid signature', () {
      const maliciousJson = '{"magic":"unknown_app","version":1}';
      expect(
        () => CinevaBackupPayload.fromEncodedString(maliciousJson),
        throwsA(isA<FormatException>()),
      );
    });

    test('All Backup & Restore AppStrings are localized in ID and EN', () {
      const sId = AppStrings(AppLanguage.id);
      const sEn = AppStrings(AppLanguage.en);

      expect(sId.backupSectionTitle, isNotEmpty);
      expect(sEn.backupSectionTitle, isNotEmpty);
      expect(sId.backupSectionTitle, isNot(equals(sEn.backupSectionTitle)));

      expect(sId.backupExportTitle, isNotEmpty);
      expect(sEn.backupExportTitle, isNotEmpty);

      expect(sId.backupImportTitle, isNotEmpty);
      expect(sEn.backupImportTitle, isNotEmpty);

      expect(sId.googleSignInTitle, isNotEmpty);
      expect(sEn.googleSignInTitle, isNotEmpty);

      expect(sId.googleConnectTitle, isNotEmpty);
      expect(sEn.googleConnectTitle, isNotEmpty);

      expect(sId.onboardingRestoreFromFile, isNotEmpty);
      expect(sEn.onboardingRestoreFromFile, isNotEmpty);

      expect(sId.onboardingContinueWithoutAccount, isNotEmpty);
      expect(sEn.onboardingContinueWithoutAccount, isNotEmpty);

      expect(sId.onboardingOrDivider, equals('atau'));
      expect(sEn.onboardingOrDivider, equals('or'));
    });
  });
}
