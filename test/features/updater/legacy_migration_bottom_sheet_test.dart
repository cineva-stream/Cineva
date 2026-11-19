import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:cineva/app/theme/app_colors.dart';
import 'package:cineva/core/constants/app_constants.dart';
import 'package:cineva/core/localization/app_language.dart';
import 'package:cineva/core/localization/app_language_provider.dart';
import 'package:cineva/features/settings/data/settings_service.dart';
import 'package:cineva/features/updater/data/legacy_migration_service.dart';
import 'package:cineva/features/updater/presentation/widgets/legacy_migration_bottom_sheet.dart';

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
    tempDir = await Directory.systemTemp.createTemp('cineva_sheet_test_');
    Hive.init(tempDir.path);
    await Hive.openBox(AppConstants.settingsBox);
  });

  setUp(() async {
    final box = Hive.box(AppConstants.settingsBox);
    await box.delete(SettingsService.keyLegacyMigrationDismissed);
  });

  Widget buildSubject({
    AppLanguage language = AppLanguage.id,
    MigrationScenario scenario = MigrationScenario.runningOldWithNewInstalled,
  }) {
    return ProviderScope(
      overrides: [
        appLanguageProvider
            .overrideWith((ref) => _TestLanguageNotifier(language)),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LegacyMigrationBottomSheet(scenario: scenario),
          ),
        ),
      ),
    );
  }

  group('LegacyMigrationBottomSheet Widget Presentation Tests', () {
    testWidgets(
        'Renders 24dp borderless container with Cineva black background and ID strings',
        (tester) async {
      await tester.pumpWidget(buildSubject(
        language: AppLanguage.id,
        scenario: MigrationScenario.runningOldWithNewInstalled,
      ));
      await tester.pumpAndSettle();

      final containerFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).borderRadius ==
                const BorderRadius.vertical(top: Radius.circular(24)) &&
            (widget.decoration as BoxDecoration).border == null &&
            (widget.decoration as BoxDecoration).color ==
                AppColors.background.withValues(alpha: 0.98),
      );
      expect(containerFinder, findsOneWidget);

      expect(find.text('VERSI RESMI TERPASANG'), findsOneWidget);
      expect(
          find.text('Aplikasi Cineva Terbaru Telah Terpasang'), findsOneWidget);
      expect(find.text('Buka Cineva Terbaru'), findsOneWidget);
      expect(find.text('Copot Versi Lama Ini'), findsOneWidget);
      expect(find.text('Nanti Saja'), findsOneWidget);
    });

    testWidgets('Renders English strings when language is set to English',
        (tester) async {
      await tester.pumpWidget(buildSubject(
        language: AppLanguage.en,
        scenario: MigrationScenario.runningOldWithNewInstalled,
      ));
      await tester.pumpAndSettle();

      expect(find.text('OFFICIAL APP INSTALLED'), findsOneWidget);
      expect(
          find.text('Latest Cineva App is Already Installed'), findsOneWidget);
      expect(find.text('Open Latest Cineva'), findsOneWidget);
      expect(find.text('Uninstall This Legacy Version'), findsOneWidget);
      expect(find.text('Later'), findsOneWidget);
    });

    testWidgets('Renders official identity update strings for new app scenario',
        (tester) async {
      await tester.pumpWidget(buildSubject(
        language: AppLanguage.id,
        scenario: MigrationScenario.runningNewWithOldInstalled,
      ));
      await tester.pumpAndSettle();

      expect(find.text('IDENTITAS RESMI'), findsOneWidget);
      expect(
          find.text('Pembaruan Identitas & Keamanan Resmi'), findsOneWidget);
      expect(find.text('Copot Versi Lama Sekarang'), findsOneWidget);
      expect(find.text('Gunakan Versi Ini'), findsOneWidget);
    });
  });
}

