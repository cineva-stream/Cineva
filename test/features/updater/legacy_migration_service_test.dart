import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:cineva/core/constants/app_constants.dart';
import 'package:cineva/features/settings/data/settings_service.dart';
import 'package:cineva/features/updater/data/legacy_migration_service.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('cineva_service_test_');
    Hive.init(tempDir.path);
    await Hive.openBox(AppConstants.settingsBox);
  });

  setUp(() async {
    final box = Hive.box(AppConstants.settingsBox);
    await box.delete(SettingsService.keyLegacyMigrationDismissed);
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('LegacyMigration Dual-Direction Settings & Service Tests', () {
    test('SettingsService: default hasDismissedLegacyMigration is false', () {
      expect(SettingsService.hasDismissedLegacyMigration(), isFalse);
    });

    test('SettingsService: setDismissedLegacyMigration saves true properly',
        () async {
      await SettingsService.setDismissedLegacyMigration(true);
      expect(SettingsService.hasDismissedLegacyMigration(), isTrue);
    });

    test(
        'LegacyMigrationService: shouldShowMigrationModal returns true when forced',
        () async {
      final shouldShow =
          await LegacyMigrationService.shouldShowMigrationModal(force: true);
      expect(shouldShow, isTrue);
    });

    test('LegacyMigrationService: detects forced runningOldWithNewInstalled',
        () async {
      final scenario =
          await LegacyMigrationService.detectMigrationScenario(
        force: true,
        forcedScenario: MigrationScenario.runningOldWithNewInstalled,
      );
      expect(scenario, equals(MigrationScenario.runningOldWithNewInstalled));
    });

    test('LegacyMigrationService: detects forced runningNewWithOldInstalled',
        () async {
      final scenario =
          await LegacyMigrationService.detectMigrationScenario(
        force: true,
        forcedScenario: MigrationScenario.runningNewWithOldInstalled,
      );
      expect(scenario, equals(MigrationScenario.runningNewWithOldInstalled));
    });
  });
}

