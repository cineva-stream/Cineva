import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../settings/data/settings_service.dart';
import '../presentation/widgets/legacy_migration_bottom_sheet.dart';

/// Scenarios for duplicate package detection between legacy Cineva and
/// the new official signed release.
enum MigrationScenario {
  none,

  /// User is running the old package (e.g. 1.1.9, com.primadev.cineva),
  /// but the new official package (com.cinevagroup.cinevastream) is already installed.
  runningOldWithNewInstalled,

  /// User is running the new official package (com.cinevagroup.cinevastream),
  /// but the legacy package (com.primadev.cineva) is still installed.
  runningNewWithOldInstalled,
}

/// Service responsible for detecting legacy vs new Cineva packages and coordinating
/// seamless identity migration and uninstallation via modern borderless bottom sheets.
class LegacyMigrationService {
  static const MethodChannel _updaterChannel = MethodChannel(
    'com.cinevagroup.cinevastream/updater',
  );

  /// Previous baseline package name of Cineva
  static const String legacyPackageName = 'com.primadev.cineva';

  /// New official signed release package name of Cineva
  static const String newOfficialPackageName = 'com.cinevagroup.cinevastream';

  /// Known legacy package names that can be cleaned up
  static const List<String> knownLegacyPackages = [
    'com.primadev.cineva',
    'com.example.cineva',
    'com.cineva.app',
  ];

  /// Checks if a package is currently installed on the Android device.
  static Future<bool> isPackageInstalled(String packageName) async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final res = await _updaterChannel.invokeMethod<bool>('isPackageInstalled', {
        'packageName': packageName,
      });
      return res == true;
    } catch (e) {
      debugPrint('[LegacyMigrationService] isPackageInstalled note: $e');
      return false;
    }
  }

  /// Launches an installed app package directly.
  static Future<bool> openPackage(String packageName) async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final res = await _updaterChannel.invokeMethod<bool>('openPackage', {
        'packageName': packageName,
      });
      return res == true;
    } catch (e) {
      debugPrint('[LegacyMigrationService] openPackage note: $e');
      return false;
    }
  }

  /// Triggers the Android system uninstallation dialog for the given package.
  static Future<bool> uninstallPackage(String packageName) async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final res = await _updaterChannel.invokeMethod<bool>('uninstallPackage', {
        'packageName': packageName,
      });
      return res == true;
    } catch (e) {
      debugPrint('[LegacyMigrationService] uninstallPackage note: $e');
      return false;
    }
  }

  /// Detects whether duplicate Cineva apps are installed and determines the migration direction.
  static Future<MigrationScenario> detectMigrationScenario({
    bool force = false,
    MigrationScenario? forcedScenario,
  }) async {
    if (force && forcedScenario != null) return forcedScenario;
    if (kIsWeb || !Platform.isAndroid) {
      if (force) return MigrationScenario.runningOldWithNewInstalled;
      return MigrationScenario.none;
    }

    try {
      final info = await PackageInfo.fromPlatform();
      final currentPackage = info.packageName.trim();

      // Case 1: Running Old App (or any non-official app) while new official package is installed
      if (currentPackage != newOfficialPackageName) {
        final isNewInstalled = await isPackageInstalled(newOfficialPackageName);
        if (isNewInstalled) {
          return MigrationScenario.runningOldWithNewInstalled;
        }
      }

      // Case 2: Running New Official App while legacy app is still installed
      if (currentPackage == newOfficialPackageName) {
        for (final legacy in knownLegacyPackages) {
          final isLegacyInstalled = await isPackageInstalled(legacy);
          if (isLegacyInstalled) {
            return MigrationScenario.runningNewWithOldInstalled;
          }
        }
      }
    } catch (e) {
      debugPrint('[LegacyMigrationService] detectMigrationScenario note: $e');
    }

    if (force) return MigrationScenario.runningOldWithNewInstalled;
    return MigrationScenario.none;
  }

  /// Checks whether the migration modal should be presented.
  static Future<bool> shouldShowMigrationModal({
    bool force = false,
    MigrationScenario? forcedScenario,
  }) async {
    if (force) return true;
    if (kIsWeb || !Platform.isAndroid) return false;
    if (SettingsService.hasDismissedLegacyMigration()) return false;

    final scenario = await detectMigrationScenario(
      force: force,
      forcedScenario: forcedScenario,
    );
    return scenario != MigrationScenario.none;
  }

  /// Checks and automatically presents the modern borderless 24dp bottom sheet if applicable.
  static Future<void> checkAndShow(
    BuildContext context, {
    bool force = false,
    MigrationScenario? forcedScenario,
  }) async {
    if (!context.mounted) return;
    if (!force && SettingsService.hasDismissedLegacyMigration()) return;

    final scenario = await detectMigrationScenario(
      force: force,
      forcedScenario: forcedScenario,
    );

    if (scenario != MigrationScenario.none && context.mounted) {
      await LegacyMigrationBottomSheet.show(context, scenario: scenario);
    }
  }
}
