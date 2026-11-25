import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineva/core/localization/app_language.dart';
import 'package:cineva/core/localization/app_language_provider.dart';
import 'package:cineva/core/localization/app_strings.dart';
import 'package:cineva/features/updater/data/services/app_update_service.dart';
import 'package:cineva/features/updater/domain/entities/app_update_info.dart';
import 'package:cineva/features/updater/presentation/providers/app_update_provider.dart';
import 'package:cineva/features/updater/presentation/screens/mandatory_update_screen.dart';

class _FakeAppUpdateService extends AppUpdateService {
  final AppUpdateInfo? mockInfo;
  bool downloadTriggered = false;

  _FakeAppUpdateService({this.mockInfo});

  @override
  Future<AppUpdateInfo?> checkForUpdate() async => mockInfo;

  @override
  Future<int> cleanupDownloadedApks() async => 0;

  @override
  Future<bool> scheduleBackgroundUpdateCheck() async => false;

  @override
  Future<bool> isUpdateNotified(String version) async => true;

  @override
  Future<String> downloadApk(
    String url,
    String fileName, {
    required void Function(int received, int total) onProgress,
    dynamic cancelToken,
  }) async {
    downloadTriggered = true;
    onProgress(5 * 1024 * 1024, 15 * 1024 * 1024);
    return '/tmp/$fileName';
  }
}

void main() {
  group('3-Missed-Updates Mandatory Update Logic Tests', () {
    test(
      'calculateVersionDistance and isMandatoryUpdate trigger only when >= 3 updates are missed',
      () {
        // User on v1.2.1:
        // 1 update missed (v1.2.2) -> NOT mandatory
        expect(AppUpdateService.calculateVersionDistance('1.2.2', '1.2.1'), 1);
        // 2 updates missed (v1.2.3) -> NOT mandatory
        expect(AppUpdateService.calculateVersionDistance('1.2.3', '1.2.1'), 2);
        // 3 updates missed (v1.2.4) -> MANDATORY
        expect(AppUpdateService.calculateVersionDistance('1.2.4', '1.2.1'), 3);
        // 4 updates missed (v1.2.5) -> MANDATORY
        expect(AppUpdateService.calculateVersionDistance('1.2.5', '1.2.1'), 4);
        // Same or older version -> 0
        expect(AppUpdateService.calculateVersionDistance('1.2.1', '1.2.1'), 0);
        expect(AppUpdateService.calculateVersionDistance('1.2.0', '1.2.1'), 0);

        const optionalUpdate = AppUpdateInfo(
          latestVersion: '1.2.3',
          releaseTitle: 'Cineva v1.2.3',
          changelog: '- Minor fixes',
          apkUrl: 'https://example.com/Cineva_v1.2.3.apk',
          apkFileName: 'Cineva_v1.2.3.apk',
          apkSizeBytes: 16 * 1024 * 1024,
          currentVersion: '1.2.1',
          missedUpdateCount: 2,
        );
        expect(optionalUpdate.isMandatoryUpdate, isFalse);

        const mandatoryUpdate = AppUpdateInfo(
          latestVersion: '1.2.4',
          releaseTitle: 'Cineva v1.2.4',
          changelog: '- Major streaming & security improvements',
          apkUrl: 'https://example.com/Cineva_v1.2.4.apk',
          apkFileName: 'Cineva_v1.2.4.apk',
          apkSizeBytes: 17301504,
          currentVersion: '1.2.1',
          missedUpdateCount: 3,
        );
        expect(mandatoryUpdate.isMandatoryUpdate, isTrue);
      },
    );

    test(
      'countMissedReleases accurately counts published GitHub releases newer than currentVersion',
      () {
        final mockReleases = [
          {'tag_name': 'v1.2.4', 'draft': false, 'prerelease': false},
          {'tag_name': 'v1.2.3', 'draft': false, 'prerelease': false},
          {'tag_name': 'v1.2.2', 'draft': false, 'prerelease': false},
          {'tag_name': 'v1.2.2-beta', 'draft': false, 'prerelease': true},
          {'tag_name': 'v1.2.1', 'draft': false, 'prerelease': false},
          {'tag_name': 'v1.2.0', 'draft': false, 'prerelease': false},
        ];

        expect(
          AppUpdateService.countMissedReleases(mockReleases, '1.2.1'),
          3,
        );
        expect(
          AppUpdateService.countMissedReleases(mockReleases, '1.2.2'),
          2,
        );
        expect(
          AppUpdateService.countMissedReleases(mockReleases, '1.2.4'),
          0,
        );
      },
    );

    test(
      '3-language localization strings exist for MandatoryUpdateScreen (ID, EN, HI)',
      () {
        const sId = AppStrings(AppLanguage.id);
        const sEn = AppStrings(AppLanguage.en);
        const sHi = AppStrings(AppLanguage.hi);

        expect(sId.mandatoryUpdateTitle, 'Pembaruan Aplikasi Diperlukan');
        expect(sEn.mandatoryUpdateTitle, 'App Update Required');
        expect(sHi.mandatoryUpdateTitle, 'ऐप अपडेट आवश्यक है');

        expect(sId.updateDownloadButton, 'Unduh');
        expect(sEn.updateDownloadButton, 'Download');
        expect(sHi.updateDownloadButton, 'डाउनलोड करें');

        expect(sId.updateCancel, 'Batal');
        expect(sEn.updateCancel, 'Cancel');
        expect(sHi.updateCancel, 'रद्द करें');

        expect(
          sId.mandatoryUpdateDescription('1.2.1', '1.2.4', 3),
          contains('3'),
        );
        expect(
          sEn.mandatoryUpdateDescription('1.2.1', '1.2.4', 3),
          contains('3'),
        );
        expect(
          sHi.mandatoryUpdateDescription('1.2.1', '1.2.4', 3),
          contains('3'),
        );
      },
    );

    test(
      'extractCoreFeatures extracts only concise key features in ID and EN from full RELEASE.md markdown',
      () {
        const sampleReleaseBody = '''
# Cineva v1.2.1 - Release Notes 🎬

Pembaruan besar Cineva v1.2.1 menghadirkan fitur baru.

---

## Ringkasan Fitur Baru & Peningkatan Utama (v1.2.1)

### 1. Dukungan Penuh Bahasa India / Hindi (*Full Trilingual Localization: Indonesia, English & Hindi*)
* **Ekspansi Lokalisasi 3 Bahasa Menyeluruh**:
  * Menambahkan bahasa Hindi.

### 2. Rekomendasi Personal Berdasarkan Tontonan (*"Because You Watched..." Personalized Section*)
* **Saran Konten Cerdas**:
  * Menampilkan section dinamis.

### 3. Optimalisasi Mesin Unduhan Offline (*High-Speed Background Isolate Download Engine*)
* **Zero UI Lag**:
  * Memindahkan unduhan ke Isolate.

---

## Riwayat Versi Sebelumnya

### Cineva v1.2.0
* Fitur lama yang tidak boleh ikut tampil.
''';

        const info = AppUpdateInfo(
          latestVersion: '1.2.1',
          releaseTitle: 'Cineva v1.2.1',
          changelog: sampleReleaseBody,
          apkUrl: 'https://example.com/Cineva_v1.2.1.apk',
          apkFileName: 'Cineva_v1.2.1.apk',
          apkSizeBytes: 17301504,
          currentVersion: '1.2.0',
        );

        final idFeatures = info.extractCoreFeatures(preferEnglish: false);
        expect(idFeatures.length, 3);
        expect(idFeatures[0], 'Dukungan Penuh Bahasa India / Hindi');
        expect(idFeatures[1], 'Rekomendasi Personal Berdasarkan Tontonan');
        expect(idFeatures[2], 'Optimalisasi Mesin Unduhan Offline');

        final enFeatures = info.extractCoreFeatures(preferEnglish: true);
        expect(enFeatures.length, 3);
        expect(
          enFeatures[0],
          'Full Trilingual Localization: Indonesia, English & Hindi',
        );
        expect(
          enFeatures[1],
          '"Because You Watched..." Personalized Section',
        );
        expect(
          enFeatures[2],
          'High-Speed Background Isolate Download Engine',
        );
      },
    );

    testWidgets(
      'MandatoryUpdateScreen renders minimalist UI with Unduh and Batal buttons and exits on Batal',
      (tester) async {
        const info = AppUpdateInfo(
          latestVersion: '1.2.4',
          releaseTitle: 'Cineva v1.2.4',
          changelog: '• Peningkatan kompatibilitas server streaming\n• Optimasi pemutar video 4K',
          apkUrl: 'https://example.com/Cineva_v1.2.4.apk',
          apkFileName: 'Cineva_v1.2.4.apk',
          apkSizeBytes: 17301504,
          currentVersion: '1.2.1',
          missedUpdateCount: 3,
        );

        final fakeService = _FakeAppUpdateService(mockInfo: info);
        final notifier = AppUpdateNotifier(fakeService, autoInit: false);
        await notifier.checkForUpdate();

        bool didExit = false;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appLanguageProvider.overrideWith(
                (ref) => AppLanguageNotifier()..setLanguage(AppLanguage.id),
              ),
              appUpdateProvider.overrideWith((ref) => notifier),
            ],
            child: MaterialApp(
              home: MandatoryUpdateScreen(
                onExitOverride: () {
                  didExit = true;
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verifies title, versions, changelog, and strictly Unduh & Batal buttons
        expect(find.text('Pembaruan Aplikasi Diperlukan'), findsOneWidget);
        expect(find.text('v1.2.1'), findsOneWidget);
        expect(find.text('v1.2.4'), findsOneWidget);
        expect(find.text('16.5 MB'), findsOneWidget);
        expect(find.text('Unduh'), findsOneWidget);
        expect(find.text('Batal'), findsOneWidget);

        // Tap Batal -> triggers application close
        await tester.tap(find.text('Batal'));
        await tester.pump();
        expect(didExit, isTrue);

        // Tap Unduh -> starts download
        await tester.tap(find.text('Unduh'));
        await tester.pump();
        expect(fakeService.downloadTriggered, isTrue);
      },
    );
  });
}
