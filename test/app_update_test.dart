import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cineva/core/localization/app_language.dart';
import 'package:cineva/core/localization/app_strings.dart';
import 'package:cineva/core/platform/device_form_factor.dart';
import 'package:cineva/features/updater/data/services/app_update_service.dart';
import 'package:cineva/features/updater/domain/entities/app_update_info.dart';
import 'package:cineva/features/updater/presentation/providers/app_update_provider.dart';
import 'package:cineva/features/updater/presentation/widgets/in_app_update_banner.dart';
import 'package:cineva/features/updater/presentation/widgets/install_permission_dialog.dart';
import 'package:cineva/features/updater/presentation/widgets/update_detail_modal.dart';

class _FakeTvNotifier extends TvModeNotifier {
  _FakeTvNotifier(bool value) {
    state = value;
  }
}

void main() {
  group('AppUpdateService Semver Comparison Tests', () {
    test('Correctly identifies newer minor/patch versions', () {
      expect(AppUpdateService.isVersionNewer('1.0.4', '1.0.3'), isTrue);
      expect(AppUpdateService.isVersionNewer('v1.0.4', '1.0.3'), isTrue);
      expect(AppUpdateService.isVersionNewer('1.1.0', '1.0.4'), isTrue);
      expect(AppUpdateService.isVersionNewer('2.0.0', '1.9.9'), isTrue);
    });

    test('Returns false when remote is equal or older', () {
      expect(AppUpdateService.isVersionNewer('1.0.3', '1.0.3'), isFalse);
      expect(AppUpdateService.isVersionNewer('v1.0.3', '1.0.3'), isFalse);
      expect(AppUpdateService.isVersionNewer('1.0.2', '1.0.3'), isFalse);
      expect(AppUpdateService.isVersionNewer('0.9.9', '1.0.0'), isFalse);
    });
  });

  group('AppUpdateInfo Entity Tests', () {
    test('Formats file size and short summary accurately', () {
      final info = AppUpdateInfo(
        latestVersion: '1.0.4',
        releaseTitle: 'Cineva v1.0.4',
        changelog: '## Fitur Baru\n- In-app update support.\n- Smooth border banner.',
        apkUrl: 'https://example.com/Cineva_v1.0.4.apk',
        apkFileName: 'Cineva_v1.0.4.apk',
        apkSizeBytes: 94812300,
        publishedAt: DateTime(2026, 10, 28),
        currentVersion: '1.0.3',
      );

      expect(info.formattedSize, '90.4 MB');
      expect(info.shortSummary.contains('In-app update support'), isTrue);
    });
  });

  group('AppUpdateService Architecture APK Selection Tests', () {
    final mockReleaseAssets = [
      {
        'name': 'Cineva_v1.1.2-arm64-v8a.apk',
        'browser_download_url': 'https://github.com/cineva/Cineva_v1.1.2-arm64-v8a.apk',
        'size': 16777216,
      },
      {
        'name': 'Cineva_v1.1.2-armeabi-v7a.apk',
        'browser_download_url': 'https://github.com/cineva/Cineva_v1.1.2-armeabi-v7a.apk',
        'size': 15728640,
      },
      {
        'name': 'Cineva_v1.1.2-x86_64.apk',
        'browser_download_url': 'https://github.com/cineva/Cineva_v1.1.2-x86_64.apk',
        'size': 18874368,
      },
      {
        'name': 'Cineva_v1.1.2.apk',
        'browser_download_url': 'https://github.com/cineva/Cineva_v1.1.2.apk',
        'size': 39845888,
      },
    ];

    test('Picks arm64-v8a APK when device supports arm64-v8a', () {
      final asset = AppUpdateService.selectBestApkAsset(
        assets: mockReleaseAssets,
        supportedAbis: ['arm64-v8a', 'armeabi-v7a'],
        version: '1.1.2',
      );

      expect(asset['name'], 'Cineva_v1.1.2-arm64-v8a.apk');
      expect(asset['targetAbi'], 'arm64-v8a');
    });

    test('Picks armeabi-v7a APK when device only supports 32-bit armeabi-v7a', () {
      final asset = AppUpdateService.selectBestApkAsset(
        assets: mockReleaseAssets,
        supportedAbis: ['armeabi-v7a', 'armeabi'],
        version: '1.1.2',
      );

      expect(asset['name'], 'Cineva_v1.1.2-armeabi-v7a.apk');
      expect(asset['targetAbi'], 'armeabi-v7a');
    });

    test('Picks x86_64 APK when running on x86_64 PC emulator', () {
      final asset = AppUpdateService.selectBestApkAsset(
        assets: mockReleaseAssets,
        supportedAbis: ['x86_64'],
        version: '1.1.2',
      );

      expect(asset['name'], 'Cineva_v1.1.2-x86_64.apk');
      expect(asset['targetAbi'], 'x86_64');
    });

    test('Falls back to Cineva_v{ver}.apk when ABI is unknown or empty', () {
      final asset = AppUpdateService.selectBestApkAsset(
        assets: mockReleaseAssets,
        supportedAbis: ['mips'],
        version: '1.1.2',
      );

      expect(asset['name'], 'Cineva_v1.1.2.apk');
      expect(asset['targetAbi'], 'universal');
    });
  });

  group('AppStrings In-App Updater Localization Tests', () {
    test('All updater strings are defined in ID and EN', () {
      final id = AppStrings(AppLanguage.id);
      expect(id.updateAvailableTitle, 'Pembaruan Tersedia');
      expect(id.updateAction, 'Perbarui Sekarang');
      expect(id.updateInstallAction, 'Pasang Sekarang');
      expect(id.updateDownloading, 'Mengunduh Pembaruan...');
      expect(id.updateFailed, 'Gagal mengunduh berkas pembaruan.');
      expect(id.updatePermissionTitle, 'Izin Pemasangan Diperlukan');
      expect(id.updateNotificationBody, 'Update Tersedia, Segera update sekarang untuk menikmati layanan streaming dengan lebih baik.');
      expect(id.updateSeeMore, 'Lihat Detail');
      expect(id.playerNoSynopsis, 'Tidak Ada Sinopsis Untuk Film Ini atau Episode Ini');

      final en = AppStrings(AppLanguage.en);
      expect(en.updateAvailableTitle, 'Update Available');
      expect(en.updateAction, 'Update Now');
      expect(en.updateInstallAction, 'Install Now');
      expect(en.updateNotificationBody, 'New version available, Update now to improve your streaming.');
      expect(en.updateDownloading, 'Downloading Update...');
      expect(en.updateFailed, 'Failed to download update file.');
      expect(en.updatePermissionTitle, 'Install Permission Required');
      expect(en.updateSeeMore, 'See More');
      expect(en.playerNoSynopsis, 'No Synopsis Available for this Movie or Episode');
    });
  });

  group('InAppUpdateBanner Widget Tests', () {
    final mockInfo = AppUpdateInfo(
      latestVersion: '1.0.4',
      releaseTitle: 'Cineva v1.0.4',
      changelog: 'Pembaruan fitur in-app update otomatis dan pembersihan cache.',
      apkUrl: 'https://example.com/Cineva.apk',
      apkFileName: 'Cineva_v1.0.4.apk',
      apkSizeBytes: 94812300,
      publishedAt: DateTime.now(),
      currentVersion: '1.0.3',
    );

    testWidgets('Does not render when updateInfo is null or isDismissed is true', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appUpdateProvider.overrideWith((ref) => _MockAppUpdateNotifier(
                  const AppUpdateState(updateInfo: null),
                )),
          ],
          child: const MaterialApp(
            home: Scaffold(body: InAppUpdateBanner()),
          ),
        ),
      );

      expect(find.byType(Container), findsNothing);

      // When dismissed
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appUpdateProvider.overrideWith((ref) => _MockAppUpdateNotifier(
                  AppUpdateState(updateInfo: mockInfo, isDismissed: true),
                )),
          ],
          child: const MaterialApp(
            home: Scaffold(body: InAppUpdateBanner()),
          ),
        ),
      );

      expect(find.text('Pembaruan Tersedia'), findsNothing);
    });

    testWidgets('Renders update card with version badge and button when update is available', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appUpdateProvider.overrideWith((ref) => _MockAppUpdateNotifier(
                  AppUpdateState(
                    status: AppUpdateStatus.available,
                    updateInfo: mockInfo,
                  ),
                )),
          ],
          child: const MaterialApp(
            home: Scaffold(body: InAppUpdateBanner()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Pembaruan Tersedia'), findsOneWidget);
      expect(find.text('v1.0.4'), findsOneWidget);
      expect(find.text('Perbarui Sekarang'), findsOneWidget);
      expect(find.text('90.4 MB'), findsOneWidget);
    });

    testWidgets('Renders download progress bar when status is downloading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appUpdateProvider.overrideWith((ref) => _MockAppUpdateNotifier(
                  AppUpdateState(
                    status: AppUpdateStatus.downloading,
                    updateInfo: mockInfo,
                    progress: 0.55,
                    receivedBytes: 52146765,
                    totalBytes: 94812300,
                  ),
                )),
          ],
          child: const MaterialApp(
            home: Scaffold(body: InAppUpdateBanner()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('55%'), findsOneWidget);
      expect(find.text('Mengunduh Pembaruan...'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
    });

    testWidgets('Renders "Lihat Detail" and opens UpdateDetailModal on tap', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appUpdateProvider.overrideWith((ref) => _MockAppUpdateNotifier(
                  AppUpdateState(
                    status: AppUpdateStatus.available,
                    updateInfo: mockInfo,
                  ),
                )),
          ],
          child: const MaterialApp(
            home: Scaffold(body: InAppUpdateBanner()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Lihat Detail'), findsOneWidget);
      await tester.tap(find.text('Lihat Detail'));
      await tester.pumpAndSettle();

      expect(find.text('Detail Pembaruan'), findsOneWidget);
      expect(find.text('v1.0.4'), findsWidgets);
    });

    testWidgets('Renders Install Action when status is readyToInstall', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appUpdateProvider.overrideWith((ref) => _MockAppUpdateNotifier(
                  AppUpdateState(
                    status: AppUpdateStatus.readyToInstall,
                    updateInfo: mockInfo,
                    progress: 1.0,
                    localApkPath: '/cache/Cineva_v1.0.4.apk',
                  ),
                )),
          ],
          child: const MaterialApp(
            home: Scaffold(body: InAppUpdateBanner()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Pasang Sekarang'), findsOneWidget);
    });

    testWidgets('Renders widescreen balanced horizontal layout on Android TV and Windows', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isTvProvider.overrideWith((ref) => _FakeTvNotifier(true)),
            isDesktopProvider.overrideWithValue(false),
            appUpdateProvider.overrideWith((ref) => _MockAppUpdateNotifier(
                  AppUpdateState(
                    status: AppUpdateStatus.available,
                    updateInfo: mockInfo,
                  ),
                )),
          ],
          child: const MaterialApp(
            home: Scaffold(body: InAppUpdateBanner()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Pembaruan Tersedia'), findsOneWidget);
      expect(find.text('v1.0.4'), findsOneWidget);
      expect(find.text('Perbarui Sekarang'), findsOneWidget);
      expect(find.text('Lihat Detail'), findsOneWidget);
      expect(find.byIcon(Icons.system_update_rounded), findsOneWidget);
    });

    testWidgets('UpdateDetailModal renders GitHub Markdown changelog with MarkdownBody', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const markdownInfo = AppUpdateInfo(
        latestVersion: '1.1.4',
        releaseTitle: 'Cineva Release 1.1.4',
        changelog: '## What\'s Changed\n\n- **Fix**: Resolved player subtitle crash\n- **Feat**: Support QR sync\n\n---\n*Enjoy streaming!*',
        apkUrl: 'https://github.com/.../Cineva.apk',
        apkFileName: 'Cineva.apk',
        apkSizeBytes: 50000000,
        currentVersion: '1.1.3',
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: UpdateDetailModal(info: markdownInfo),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify MarkdownBody is rendered
      expect(find.byType(MarkdownBody), findsOneWidget);
      expect(find.textContaining("What's Changed"), findsOneWidget);
      expect(find.textContaining('Support QR sync'), findsOneWidget);
    });
  });

  group('InstallPermissionDialog Widget Tests', () {
    testWidgets('Renders security icon, title, description, and settings button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: InstallPermissionDialog()),
          ),
        ),
      );

      expect(find.text('Izin Pemasangan Diperlukan'), findsOneWidget);
      expect(find.text('Buka Setelan'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
    });
  });

  group('Single Notification Dispatch Tests', () {
    test('checkForUpdate does not call showUpdateNotification if already notified', () async {
      final fakeService = _FakeNotificationAppUpdateService(alreadyNotified: true);
      final notifier = AppUpdateNotifier(fakeService, autoInit: false);

      await notifier.checkForUpdate();

      expect(notifier.state.status, AppUpdateStatus.available);
      expect(fakeService.showNotificationCallCount, 0);
    });

    test('checkForUpdate calls showUpdateNotification once if not yet notified', () async {
      final fakeService = _FakeNotificationAppUpdateService(alreadyNotified: false);
      final notifier = AppUpdateNotifier(fakeService, autoInit: false);

      await notifier.checkForUpdate();

      expect(notifier.state.status, AppUpdateStatus.available);
      expect(fakeService.showNotificationCallCount, 1);
    });
  });
}

class _FakeNotificationAppUpdateService extends AppUpdateService {
  final bool alreadyNotified;
  int showNotificationCallCount = 0;

  _FakeNotificationAppUpdateService({required this.alreadyNotified});

  @override
  Future<int> cleanupDownloadedApks() async => 0;

  @override
  Future<bool> scheduleBackgroundUpdateCheck() async => true;

  @override
  Future<AppUpdateInfo?> checkForUpdate() async {
    return AppUpdateInfo(
      latestVersion: '1.1.2',
      releaseTitle: 'Cineva v1.1.2',
      changelog: 'Changelog',
      apkUrl: 'https://example.com/app.apk',
      apkFileName: 'app.apk',
      apkSizeBytes: 1000,
      currentVersion: '1.1.1',
    );
  }

  @override
  Future<bool> isUpdateNotified(String version) async => alreadyNotified;

  @override
  Future<bool> showUpdateNotification(AppUpdateInfo info, {String? customBody}) async {
    showNotificationCallCount++;
    return true;
  }
}

class _MockAppUpdateNotifier extends AppUpdateNotifier {
  _MockAppUpdateNotifier(AppUpdateState initialState) : super(_FakeAppUpdateService()) {
    state = initialState;
  }

  @override
  Future<void> checkForUpdate() async {}
}

class _FakeAppUpdateService extends AppUpdateService {
  @override
  Future<int> cleanupDownloadedApks() async => 0;

  @override
  Future<bool> scheduleBackgroundUpdateCheck() async => true;

  @override
  Future<AppUpdateInfo?> checkForUpdate() async => null;
}
