import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:cineva/core/constants/app_constants.dart';
import 'package:cineva/core/localization/app_language.dart';
import 'package:cineva/core/localization/app_language_provider.dart';
import 'package:cineva/core/platform/device_form_factor.dart';
import 'package:cineva/features/history/data/models/watch_history_item.dart';
import 'package:cineva/features/history/data/repositories/watch_history_repository.dart';
import 'package:cineva/features/profile/data/hybrid_pairing_service.dart';
import 'package:cineva/features/profile/data/profile_sync_sender.dart';
import 'package:cineva/features/profile/data/sync_crypto_service.dart';
import 'package:cineva/features/profile/presentation/screens/onboarding_profile_screen.dart';
import 'package:cineva/features/profile/presentation/widgets/tv_qr_sync_view.dart';
import 'package:cineva/features/search/presentation/providers/search_history_provider.dart';
import 'package:cineva/features/settings/data/settings_service.dart';
import 'package:cineva/features/watchlist/data/watchlist_repository.dart';

class _FakeTvNotifier extends TvModeNotifier {
  _FakeTvNotifier(bool value) {
    state = value;
  }
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('cineva_qr_sync_test_');
    Hive.init(tempDir.path);
    await Hive.openBox(AppConstants.settingsBox);
    await Hive.openBox(AppConstants.watchlistBox);
    await Hive.openBox(AppConstants.historyBox);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('SyncCryptoService AES-256 Tests', () {
    test('generatePairingKey generates a valid 32-byte Base64 key', () {
      final key1 = SyncCryptoService.generatePairingKey();
      final key2 = SyncCryptoService.generatePairingKey();

      expect(key1, isNotEmpty);
      expect(key2, isNotEmpty);
      expect(key1, isNot(equals(key2)));

      final decoded = base64Url.decode(base64Url.normalize(key1));
      expect(decoded.length, 32); // 256 bits
    });

    test('encryptPayload and decryptPayload achieve lossless roundtrip', () {
      final key = SyncCryptoService.generatePairingKey();
      const originalJson = '{"name":"Budi Santoso 🎬","username":"budi_cine","avatarId":"avatar_director"}';

      final ciphertext = SyncCryptoService.encryptPayload(originalJson, key);
      expect(ciphertext, isNotEmpty);
      expect(ciphertext, isNot(equals(originalJson)));

      final decrypted = SyncCryptoService.decryptPayload(ciphertext, key);
      expect(decrypted, equals(originalJson));
    });

    test('decryptPayload throws on incorrect key', () {
      final key1 = SyncCryptoService.generatePairingKey();
      final key2 = SyncCryptoService.generatePairingKey();
      const payload = 'Secret profile message';

      final ciphertext = SyncCryptoService.encryptPayload(payload, key1);
      expect(
        () => SyncCryptoService.decryptPayload(ciphertext, key2),
        throwsA(anything),
      );
    });
  });

  group('ParsedPairingQr URI Parser Tests', () {
    test('Parses complete cineva://sync URI properly', () {
      const uriStr = 'cineva://sync?topic=cineva_sync_test123&key=abc123key==&ip=192.168.1.88&port=50123&pin=882341';
      final parsed = ParsedPairingQr.tryParse(uriStr);

      expect(parsed, isNotNull);
      expect(parsed!.topic, 'cineva_sync_test123');
      expect(parsed.key, 'abc123key==');
      expect(parsed.ip, '192.168.1.88');
      expect(parsed.port, 50123);
      expect(parsed.pin, '882341');
    });

    test('Parses fallback plain query string', () {
      const uriStr = 'https://cineva.stream/sync?topic=topic_cloud_only&key=k999&pin=112233';
      final parsed = ParsedPairingQr.tryParse(uriStr);

      expect(parsed, isNotNull);
      expect(parsed!.topic, 'topic_cloud_only');
      expect(parsed.key, 'k999');
      expect(parsed.pin, '112233');
      expect(parsed.ip, isNull);
    });

    test('Returns null on malformed or missing key/topic', () {
      expect(ParsedPairingQr.tryParse('not_a_valid_uri'), isNull);
      expect(ParsedPairingQr.tryParse('cineva://sync?ip=192.168.1.1'), isNull);
      expect(ParsedPairingQr.tryParse(''), isNull);
    });
  });

  group('OnboardingProfileScreen Platform Routing Tests', () {
    testWidgets('Android TV mode shows TvQrSyncView and no manual text field', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isTvProvider.overrideWith((ref) => _FakeTvNotifier(true)),
            isDesktopProvider.overrideWithValue(false),
          ],
          child: const MaterialApp(
            home: OnboardingProfileScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Should render the 10-Foot QR pairing screen
      expect(find.byType(TvQrSyncView), findsOneWidget);
      expect(find.text('CINEVA TV SYNC'), findsOneWidget);
      expect(find.textContaining('Tautkan Akun Cineva'), findsOneWidget);

      // Must NOT contain the smartphone/manual text input fields
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('Windows Desktop shows Dual-Mode and can switch between QR and Manual', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isTvProvider.overrideWith((ref) => _FakeTvNotifier(false)),
            isDesktopProvider.overrideWithValue(true),
          ],
          child: const MaterialApp(
            home: OnboardingProfileScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Desktop starts with QR mode and selector tabs
      expect(find.text('Tautkan via QR (dari HP)'), findsOneWidget);
      expect(find.text('Setup Profil di PC'), findsOneWidget);
      expect(find.byType(TvQrSyncView), findsOneWidget);

      // Tap "Setup Profil di PC" tab to switch to manual input
      await tester.tap(find.text('Setup Profil di PC'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Now manual textfields and avatar selectors are visible!
      expect(find.byType(TvQrSyncView), findsNothing);
      expect(find.byType(TextField), findsNWidgets(2)); // Name & username

      // Switch back to QR mode
      await tester.tap(find.text('Tautkan via QR (dari HP)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(TvQrSyncView), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('Mobile smartphone mode directly displays manual profile creation', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isTvProvider.overrideWith((ref) => _FakeTvNotifier(false)),
            isDesktopProvider.overrideWithValue(false),
          ],
          child: const MaterialApp(
            home: OnboardingProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Mobile does not show TV QR view or dual-mode tab selector
      expect(find.byType(TvQrSyncView), findsNothing);
      expect(find.text('Tautkan via QR (dari HP)'), findsNothing);

      // Mobile directly shows manual setup fields
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('English localization renders translated texts for TV sync and desktop modes', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appLanguageProvider.overrideWith((ref) => AppLanguageNotifier(AppLanguage.en)),
            isTvProvider.overrideWith((ref) => _FakeTvNotifier(false)),
            isDesktopProvider.overrideWithValue(true),
          ],
          child: const MaterialApp(
            home: OnboardingProfileScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // In English, tabs and TV Sync show English labels
      expect(find.text('Link via QR (from Phone)'), findsOneWidget);
      expect(find.text('Set Up Profile on PC'), findsOneWidget);
      expect(find.text('Connect Your Cineva Account'), findsOneWidget);
      expect(find.text('Continue as Guest'), findsOneWidget);
      expect(find.text('Manual PC Setup'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('Multi-Device Full Dataset Sync (Watchlist, History, Preferences) Tests', () {
    test('HybridPairingService.applySyncedProfile seamlessly imports profile, watchlist, history, and preferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final payload = {
        'profile': {
          'name': 'Reza Rahadian',
          'username': 'reza_films',
          'avatarId': 'avatar_popcorn',
        },
        'watchlist': [
          {
            'id': 872585,
            'title': 'Oppenheimer',
            'posterPath': '/ptpr0kGAckfQkJeJItAcst5qY66.jpg',
            'voteAverage': 8.9,
            'type': 'movie',
            'addedAt': DateTime.now().toIso8601String(),
          },
          {
            'id': 1396,
            'title': 'Breaking Bad',
            'posterPath': '/ggFHVNu6YYI5L9pCfOacjizRGt.jpg',
            'voteAverage': 9.5,
            'type': 'tv',
            'addedAt': DateTime.now().toIso8601String(),
          },
        ],
        'watchHistory': [
          {
            'id': 27205,
            'mediaType': 'movie',
            'title': 'Inception',
            'positionMs': 2700000, // 45 mins in
            'durationMs': 8880000, // ~148 mins
            'lastWatchedAt': DateTime.now().toIso8601String(),
            'isCompleted': false,
          },
          {
            'id': 1396,
            'mediaType': 'tv',
            'title': 'Breaking Bad',
            'season': 1,
            'episode': 1,
            'episodeTitle': 'Pilot',
            'positionMs': 3480000,
            'durationMs': 3500000,
            'lastWatchedAt': DateTime.now().toIso8601String(),
            'isCompleted': true,
          },
        ],
        'settings': {
          SettingsService.keyAppLanguage: 'en',
          SettingsService.keyDefaultSubtitleLang: 'en',
          SettingsService.keyDefaultQuality: '1080p',
          SettingsService.keyAutoTranslate: false,
        },
        'searchHistory': ['Christopher Nolan', 'Vince Gilligan'],
      };

      final result = await HybridPairingService.applySyncedProfile(
        ref: container,
        data: payload,
      );

      // Verify returned counts
      expect(result.watchlistCount, 2);
      expect(result.historyCount, 2);
      expect(result.profile.name, 'Reza Rahadian');
      expect(result.profile.username, 'reza_films');

      // Verify Watchlist state
      final watchlist = container.read(watchlistProvider);
      expect(watchlist.length, 2);
      expect(watchlist.any((w) => w.id == 872585 && w.type == 'movie'), isTrue);
      expect(watchlist.any((w) => w.id == 1396 && w.type == 'tv'), isTrue);
      expect(container.read(isInWatchlistProvider((id: 872585, type: 'movie'))), isTrue);

      // Verify Watch History state
      final history = container.read(watchHistoryProvider);
      expect(history.length, 2);
      expect(history.any((h) => h.id == 27205 && h.title == 'Inception'), isTrue);

      // Verify In-Progress history for Home Screen "Lanjutkan Menonton"
      final inProgress = container.read(inProgressWatchHistoryProvider);
      expect(inProgress.any((h) => h.id == 27205), isTrue);

      // Verify Settings
      expect(SettingsService.getAppLanguage(), 'en');
      expect(SettingsService.getDefaultSubtitleLang(), 'en');
      expect(SettingsService.getDefaultQuality(), '1080p');
      expect(SettingsService.getAutoTranslate(), isFalse);

      // Verify Search History
      final searches = container.read(searchHistoryProvider);
      expect(searches.contains('Christopher Nolan'), isTrue);
      expect(searches.contains('Vince Gilligan'), isTrue);
    });

    test('WatchHistoryRepository.importItems conflict resolution keeps higher progress or newer watch state', () async {
      final repo = WatchHistoryRepository();
      await repo.clearAll();

      final oldItem = WatchHistoryItem(
        id: 550,
        mediaType: 'movie',
        title: 'Fight Club',
        positionMs: 100000,
        durationMs: 7000000,
        lastWatchedAt: DateTime.now().subtract(const Duration(days: 2)),
        isCompleted: false,
      );
      await repo.saveProgress(oldItem);

      // Incoming item from another device has 80% progress
      final incomingItem = WatchHistoryItem(
        id: 550,
        mediaType: 'movie',
        title: 'Fight Club',
        positionMs: 5600000,
        durationMs: 7000000,
        lastWatchedAt: DateTime.now(),
        isCompleted: false,
      );
      await repo.importItems([incomingItem]);

      final resolved = repo.getItem('movie', 550);
      expect(resolved, isNotNull);
      expect(resolved!.positionMs, 5600000);
    });
  });
}
