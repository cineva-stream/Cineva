import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:cineva/core/constants/app_constants.dart';
import 'package:cineva/core/localization/app_language.dart';
import 'package:cineva/core/localization/app_language_provider.dart';
import 'package:cineva/features/download/presentation/widgets/download_feature_announcement_dialog.dart';
import 'package:cineva/features/settings/data/settings_service.dart';

class _TestLanguageNotifier extends AppLanguageNotifier {
  _TestLanguageNotifier(super.initialLanguage);

  @override
  Future<void> setLanguage(AppLanguage language) async {
    state = language;
  }
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('cineva_announcement_test_');
    Hive.init(tempDir.path);
    await Hive.openBox(AppConstants.settingsBox);
  });

  setUp(() async {
    final box = Hive.box(AppConstants.settingsBox);
    await box.delete(SettingsService.keyDownloadAnnouncementDismissed);
    await box.delete(SettingsService.keyDownloadAnnouncementLastShown);
  });

  Widget buildSubject({AppLanguage language = AppLanguage.id}) {
    return ProviderScope(
      overrides: [
        appLanguageProvider.overrideWith((ref) => _TestLanguageNotifier(language)),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DownloadFeatureAnnouncementDialog(),
          ),
        ),
      ),
    );
  }

  group('Download Feature Announcement SettingsService Throttling Tests', () {
    test('Returns true initially when not dismissed and never shown', () {
      expect(
        SettingsService.shouldShowDownloadAnnouncement(bypassTestCheck: true),
        isTrue,
      );
    });

    test('Returns false once user marks as dismissed', () async {
      await SettingsService.setDismissedDownloadAnnouncement(true);
      expect(SettingsService.hasDismissedDownloadAnnouncement(), isTrue);
      expect(
        SettingsService.shouldShowDownloadAnnouncement(bypassTestCheck: true),
        isFalse,
      );
    });

    test('Throttles correctly within 12-hour window and re-enables after 12 hours', () async {
      final now = DateTime(2026, 11, 17, 10, 0);
      final twoHoursLater = now.add(const Duration(hours: 2));
      final thirteenHoursLater = now.add(const Duration(hours: 13));

      await SettingsService.setDownloadAnnouncementLastShown(now.millisecondsSinceEpoch);

      // Within 12 hours -> Should NOT show
      expect(
        SettingsService.shouldShowDownloadAnnouncement(
          now: twoHoursLater,
          bypassTestCheck: true,
        ),
        isFalse,
      );

      // After 12 hours -> Should show again
      expect(
        SettingsService.shouldShowDownloadAnnouncement(
          now: thirteenHoursLater,
          bypassTestCheck: true,
        ),
        isTrue,
      );
    });
  });

  group('DownloadFeatureAnnouncementDialog Presentation & Interaction Tests', () {
    testWidgets('Renders Indonesian poster header, title, description, and disclaimer', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildSubject(language: AppLanguage.id));
      await tester.pumpAndSettle();

      expect(find.text('FITUR BARU'), findsOneWidget);
      expect(find.text('UNDUH & TONTON OFFLINE'), findsOneWidget);
      expect(find.text('Tonton film & serial favorit tanpa kuota internet'), findsOneWidget);
      expect(find.text('Fitur Unduhan Offline Siap Dicoba!'), findsOneWidget);
      expect(find.textContaining('Catatan: Kami tidak dapat memastikan'), findsOneWidget);
      expect(find.text('Jangan tampilkan lagi'), findsOneWidget);
      expect(find.text('Bagus, Coba Sekarang'), findsOneWidget);
    });

    testWidgets('Renders English poster header, title, description, and disclaimer', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildSubject(language: AppLanguage.en));
      await tester.pumpAndSettle();

      expect(find.text('NEW FEATURE'), findsOneWidget);
      expect(find.text('DOWNLOAD & WATCH OFFLINE'), findsOneWidget);
      expect(find.text('Watch movies & series anytime without internet'), findsOneWidget);
      expect(find.text('Offline Downloads Are Ready to Try!'), findsOneWidget);
      expect(find.textContaining('Note: We cannot guarantee'), findsOneWidget);
      expect(find.text("Don't show again"), findsOneWidget);
      expect(find.text('Great, Try Now'), findsOneWidget);
    });

    testWidgets('Toggles "Don\'t Show Again" checkbox reactively', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildSubject(language: AppLanguage.id));
      await tester.pumpAndSettle();

      // Checkbox is initially unchecked
      var checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isFalse);

      // Tap checkbox row to check
      await tester.tap(find.text('Jangan tampilkan lagi'));
      await tester.pumpAndSettle();

      checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);

      // Tap again to uncheck
      await tester.tap(find.text('Jangan tampilkan lagi'));
      await tester.pumpAndSettle();

      checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isFalse);
    });
  });
}

