import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:cineva/core/constants/app_constants.dart';
import 'package:cineva/core/localization/app_language.dart';
import 'package:cineva/core/localization/app_language_provider.dart';
import 'package:cineva/features/settings/data/settings_service.dart';
import 'package:cineva/features/updater/data/legacy_migration_service.dart';
import 'package:cineva/features/updater/presentation/widgets/legacy_migration_dialog.dart';

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
    tempDir = await Directory.systemTemp.createTemp('cineva_migration_test_');
    Hive.init(tempDir.path);
    await Hive.openBox(AppConstants.settingsBox);
  });

  setUp(() async {
    final box = Hive.box(AppConstants.settingsBox);
    await box.delete(SettingsService.keyLegacyMigrationDismissed);
  });

  Widget buildSubject({
    AppLanguage language = AppLanguage.id,
    String targetLegacyPackage = LegacyMigrationService.legacyPackageName,
  }) {
    return ProviderScope(
      overrides: [
        appLanguageProvider
            .overrideWith((ref) => _TestLanguageNotifier(language)),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LegacyMigrationDialog(
              targetLegacyPackage: targetLegacyPackage,
            ),
          ),
        ),
      ),
    );
  }

  group('LegacyMigration Settings & Service Tests', () {
    test('SettingsService: default hasDismissedLegacyMigration is false', () {
      expect(SettingsService.hasDismissedLegacyMigration(), isFalse);
    });

    test('SettingsService: setDismissedLegacyMigration saves true properly',
        () async {
      await SettingsService.setDismissedLegacyMigration(true);
      expect(SettingsService.hasDismissedLegacyMigration(), isTrue);
    });

    test(
        'LegacyMigrationService: shouldShowMigrationModal returns true when force is true',
        () async {
      final shouldShow =
          await LegacyMigrationService.shouldShowMigrationModal(force: true);
      expect(shouldShow, isTrue);
    });

    test(
        'LegacyMigrationService: findInstalledLegacyPackage returns legacy name when force is true',
        () async {
      final pkg =
          await LegacyMigrationService.findInstalledLegacyPackage(force: true);
      expect(pkg, equals(LegacyMigrationService.legacyPackageName));
    });
  });

  group('LegacyMigrationDialog Widget Tests', () {
    testWidgets('Renders borderless container and all Indonesian strings',
        (tester) async {
      await tester.pumpWidget(buildSubject(language: AppLanguage.id));
      await tester.pumpAndSettle();

      // Verify border is strictly null on dialog background
      final containerFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).borderRadius != null &&
            (widget.decoration as BoxDecoration).border == null &&
            (widget.decoration as BoxDecoration).color ==
                const Color(0xFF14141B).withValues(alpha: 0.94),
      );
      expect(containerFinder, findsOneWidget);

      // Verify Indonesian badges and headers
      expect(find.text('IDENTITAS RESMI'), findsOneWidget);
      expect(
          find.text('Pembaruan Identitas & Keamanan Resmi'), findsOneWidget);
      expect(find.text('Migrasi Data Otomatis'), findsOneWidget);
      expect(find.text('Bebas Aplikasi Ganda'), findsOneWidget);
      expect(find.text('Tanda Tangan Terverifikasi'), findsOneWidget);

      // Verify Action Buttons
      expect(find.text('Copot Versi Lama Sekarang'), findsOneWidget);
      expect(find.text('Gunakan Versi Ini'), findsOneWidget);
    });

    testWidgets('Renders English strings when language is set to English',
        (tester) async {
      await tester.pumpWidget(buildSubject(language: AppLanguage.en));
      await tester.pumpAndSettle();

      expect(find.text('OFFICIAL IDENTITY'), findsOneWidget);
      expect(
          find.text('Official Identity & Security Update'), findsOneWidget);
      expect(find.text('Automatic Data Migration'), findsOneWidget);
      expect(find.text('Uninstall Previous Version'), findsOneWidget);
      expect(find.text('Continue with This Version'), findsOneWidget);
    });

    testWidgets('Dismiss button sets dismissal flag in settings',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      expect(SettingsService.hasDismissedLegacyMigration(), isFalse);

      await tester.pumpWidget(buildSubject(language: AppLanguage.id));
      await tester.pumpAndSettle();

      final dismissBtn = find.text('Gunakan Versi Ini');
      expect(dismissBtn, findsOneWidget);

      await tester.ensureVisible(dismissBtn);
      await tester.tap(dismissBtn);
      await tester.pumpAndSettle();

      expect(SettingsService.hasDismissedLegacyMigration(), isTrue);
    });
  });
}
