import 'package:flutter/material.dart';

import '../../data/legacy_migration_service.dart';
import 'legacy_migration_bottom_sheet.dart';

export 'legacy_migration_bottom_sheet.dart';

/// Backward-compatible bridge to [LegacyMigrationBottomSheet].
class LegacyMigrationDialog {
  LegacyMigrationDialog._();

  /// Displays the migration bottom sheet.
  static Future<void> show(
    BuildContext context, {
    MigrationScenario scenario = MigrationScenario.runningNewWithOldInstalled,
    String targetLegacyPackage = LegacyMigrationService.legacyPackageName,
  }) async {
    if (!context.mounted) return;
    return LegacyMigrationBottomSheet.show(context, scenario: scenario);
  }
}
