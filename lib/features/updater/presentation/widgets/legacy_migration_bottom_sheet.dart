import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../settings/data/settings_service.dart';
import '../../data/legacy_migration_service.dart';

/// Modern minimalist 24dp borderless BottomSheet displayed when duplicate Cineva
/// apps (legacy vs new official package) are detected on the Android device.
/// Uses Cineva's primary OLED black background with smooth animations.
class LegacyMigrationBottomSheet extends ConsumerStatefulWidget {
  final MigrationScenario scenario;

  const LegacyMigrationBottomSheet({
    super.key,
    required this.scenario,
  });

  /// Displays the migration bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required MigrationScenario scenario,
  }) async {
    if (!context.mounted) return;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      builder: (context) => LegacyMigrationBottomSheet(scenario: scenario),
    );
  }

  @override
  ConsumerState<LegacyMigrationBottomSheet> createState() =>
      _LegacyMigrationBottomSheetState();
}

class _LegacyMigrationBottomSheetState
    extends ConsumerState<LegacyMigrationBottomSheet> {
  bool _isProcessing = false;

  Future<void> _handleOpenNewApp() async {
    setState(() => _isProcessing = true);
    await LegacyMigrationService.openPackage(
      LegacyMigrationService.newOfficialPackageName,
    );
    await SettingsService.setDismissedLegacyMigration(true);
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Future<void> _handleUninstallLegacy() async {
    setState(() => _isProcessing = true);
    await LegacyMigrationService.uninstallPackage(
      LegacyMigrationService.legacyPackageName,
    );
    await SettingsService.setDismissedLegacyMigration(true);
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Future<void> _handleDismiss() async {
    await SettingsService.setDismissedLegacyMigration(true);
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final isOldApp =
        widget.scenario == MigrationScenario.runningOldWithNewInstalled;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            // Primary Cineva Pitch Black Background as requested
            color: AppColors.background.withValues(alpha: 0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            // Strictly borderless
            border: null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.9),
                blurRadius: 32,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            bottom: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(22, 12, 22, 18 + bottomInset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Drag Handle Pill ──
                  Center(
                    child: Container(
                      width: 44,
                      height: 4.5,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),

                  // ── Header Icon & Glow ──
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                (isOldApp ? AppColors.primary : const Color(0xFFE50914))
                                    .withValues(alpha: 0.35),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: isOldApp
                                  ? [AppColors.primary, AppColors.primaryDark]
                                  : [
                                      const Color(0xFFE50914),
                                      const Color(0xFF900C11)
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isOldApp
                                        ? AppColors.primary
                                        : const Color(0xFFE50914))
                                    .withValues(alpha: 0.45),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              isOldApp
                                  ? Icons.stars_rounded
                                  : Icons.verified_user_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Badge Tag ──
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: (isOldApp
                                ? AppColors.primary
                                : const Color(0xFFE50914))
                            .withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isOldApp
                            ? s.migrationOldAppBadge
                            : s.migrationDialogBadge,
                        style: GoogleFonts.jetBrainsMono(
                          color: isOldApp
                              ? AppColors.primary
                              : const Color(0xFFFF4D4D),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── Title ──
                  Text(
                    isOldApp
                        ? s.migrationOldAppTitle
                        : s.migrationDialogTitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 18.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.2,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Description ──
                  Text(
                    isOldApp ? s.migrationOldAppDesc : s.migrationDialogDesc,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Feature Highlights (Dark Charcoal Cards) ──
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildFeatureRow(
                          icon: Iconsax.refresh_2,
                          iconColor: const Color(0xFF4CAF50),
                          title: s.migrationFeature1Title,
                          desc: s.migrationFeature1Desc,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(
                            color: Colors.white10,
                            height: 1,
                            thickness: 0.6,
                          ),
                        ),
                        _buildFeatureRow(
                          icon: Iconsax.trash,
                          iconColor: const Color(0xFFFF9800),
                          title: s.migrationFeature2Title,
                          desc: s.migrationFeature2Desc,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(
                            color: Colors.white10,
                            height: 1,
                            thickness: 0.6,
                          ),
                        ),
                        _buildFeatureRow(
                          icon: Iconsax.shield_tick,
                          iconColor: const Color(0xFF29B6F6),
                          title: s.migrationFeature3Title,
                          desc: s.migrationFeature3Desc,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── Action Buttons Based on Scenario ──
                  if (isOldApp) ...[
                    // Button 1: Open Latest Cineva
                    SizedBox(
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _handleOpenNewApp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 3,
                          shadowColor:
                              AppColors.primary.withValues(alpha: 0.4),
                        ),
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(
                                Icons.launch_rounded,
                                size: 19,
                              ),
                        label: Text(
                          s.migrationOpenNewAppBtn,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Button 2: Uninstall This Legacy App
                    SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed:
                            _isProcessing ? null : _handleUninstallLegacy,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF5252),
                          side: const BorderSide(
                            color: Color(0x33FF5252),
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(
                          Icons.delete_sweep_rounded,
                          size: 18,
                        ),
                        label: Text(
                          s.migrationUninstallThisAppBtn,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Dismiss / Later
                    TextButton(
                      onPressed: _handleDismiss,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text(
                        s.migrationDismissLaterBtn,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ] else ...[
                    // Button 1: Uninstall Old Version Now
                    SizedBox(
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed:
                            _isProcessing ? null : _handleUninstallLegacy,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 4,
                          shadowColor:
                              AppColors.primary.withValues(alpha: 0.5),
                        ),
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.delete_sweep_rounded,
                                size: 19,
                              ),
                        label: Text(
                          s.migrationUninstallBtn,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Button 2: Continue using this version
                    TextButton(
                      onPressed: _handleDismiss,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text(
                        s.migrationDismissBtn,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              icon,
              color: iconColor,
              size: 15,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 1.5),
              Text(
                desc,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

