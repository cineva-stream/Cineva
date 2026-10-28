import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cineva/core/localization/app_language.dart';
import 'package:cineva/core/localization/app_strings.dart';
import 'package:cineva/features/updater/data/services/app_update_service.dart';
import 'package:cineva/features/updater/domain/entities/app_update_info.dart';
import 'package:cineva/features/updater/presentation/providers/app_update_provider.dart';
import 'package:cineva/features/updater/presentation/widgets/in_app_update_banner.dart';
import 'package:cineva/features/updater/presentation/widgets/install_permission_dialog.dart';

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

  group('AppStrings In-App Updater Localization Tests', () {
    test('All updater strings are defined in ID and EN', () {
      final id = AppStrings(AppLanguage.id);
      expect(id.updateAvailableTitle, 'Pembaruan Tersedia');
      expect(id.updateAction, 'Perbarui Sekarang');
      expect(id.updateInstallAction, 'Pasang Sekarang');
      expect(id.updateDownloading, 'Mengunduh Pembaruan...');
      expect(id.updateFailed, 'Gagal mengunduh berkas pembaruan.');
      expect(id.updatePermissionTitle, 'Izin Pemasangan Diperlukan');

      final en = AppStrings(AppLanguage.en);
      expect(en.updateAvailableTitle, 'Update Available');
      expect(en.updateAction, 'Update Now');
      expect(en.updateInstallAction, 'Install Now');
      expect(en.updateDownloading, 'Downloading Update...');
      expect(en.updateFailed, 'Failed to download update file.');
      expect(en.updatePermissionTitle, 'Install Permission Required');
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
  Future<AppUpdateInfo?> checkForUpdate() async => null;
}
