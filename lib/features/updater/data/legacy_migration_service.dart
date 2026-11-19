import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../settings/data/settings_service.dart';
import '../presentation/widgets/legacy_migration_dialog.dart';

/// Service responsible for detecting legacy Cineva packages and coordinating
/// seamless identity migration and uninstallation.
class LegacyMigrationService {
  static const MethodChannel _updaterChannel = MethodChannel(
    'com.primadev.cineva/updater',
  );

  /// Previous baseline package name of Cineva
  static const String legacyPackageName = 'com.primadev.cineva';

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
      final res = await _updaterChannel.invokeMethod<bool>(
        'isPackageInstalled',
        {'packageName': packageName},
      );
      return res == true;
    } catch (e) {
      debugPrint('[LegacyMigrationService] isPackageInstalled note: $e');
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

  /// Finds which legacy package (if any) is currently installed on the device
  /// while running under a different package name.
  static Future<String?> findInstalledLegacyPackage({
    bool force = false,
  }) async {
    if (kIsWeb || !Platform.isAndroid) {
      if (force) return legacyPackageName;
      return null;
    }

    try {
      final info = await PackageInfo.fromPlatform();
      final currentPackage = info.packageName.trim();

      // If running under a package name different from legacy:
      for (final legacy in knownLegacyPackages) {
        if (currentPackage != legacy) {
          final isInstalled = await isPackageInstalled(legacy);
          if (isInstalled) {
            return legacy;
          }
        }
      }
    } catch (e) {
      debugPrint(
        '[LegacyMigrationService] findInstalledLegacyPackage note: $e',
      );
    }

    if (force) return legacyPackageName;
    return null;
  }

  /// Checks whether the migration modal should be presented.
  static Future<bool> shouldShowMigrationModal({bool force = false}) async {
    if (force) return true;
    if (kIsWeb || !Platform.isAndroid) return false;
    if (SettingsService.hasDismissedLegacyMigration()) return false;

    final legacyInstalled = await findInstalledLegacyPackage();
    return legacyInstalled != null;
  }

  /// Checks and automatically presents the modern borderless migration dialog if applicable.
  static Future<void> checkAndShow(
    BuildContext context, {
    bool force = false,
  }) async {
    if (!context.mounted) return;
    if (!force && SettingsService.hasDismissedLegacyMigration()) return;
    final legacyPackage = await findInstalledLegacyPackage(force: force);
    if ((legacyPackage != null || force) && context.mounted) {
      await LegacyMigrationDialog.show(
        context,
        targetLegacyPackage: legacyPackage ?? legacyPackageName,
      );
    }
  }
}
