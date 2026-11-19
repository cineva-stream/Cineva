import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../settings/data/settings_service.dart';
import '../../data/legacy_migration_service.dart';

/// Modern minimalist borderless dialog announcing that Cineva has migrated
/// to a new official package identity and security signing key.
/// Recommends uninstalling the legacy app and highlights seamless data preservation.
class LegacyMigrationDialog extends ConsumerStatefulWidget {
  final String targetLegacyPackage;

  const LegacyMigrationDialog({
    super.key,
    this.targetLegacyPackage = LegacyMigrationService.legacyPackageName,
  });

  /// Displays the migration dialog.
  static Future<void> show(
    BuildContext context, {
    String targetLegacyPackage = LegacyMigrationService.legacyPackageName,
  }) async {
    if (!context.mounted) return;
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      builder: (context) => LegacyMigrationDialog(
        targetLegacyPackage: targetLegacyPackage,
      ),
    );
  }

  @override
  ConsumerState<LegacyMigrationDialog> createState() =>
      _LegacyMigrationDialogState();
}

class _LegacyMigrationDialogState extends ConsumerState<LegacyMigrationDialog> {
  bool _isUninstalling = false;

  Future<void> _handleUninstall() async {
    setState(() => _isUninstalling = true);
    await LegacyMigrationService.uninstallPackage(widget.targetLegacyPackage);
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

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF14141B).withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(24),
                // Explicitly borderless as requested by user
                border: null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.75),
                    blurRadius: 36,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── 1. Header Badge & Icon ──
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.35),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFE50914), Color(0xFF900C11)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.45),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.verified_user_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Official Badge Tag
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            s.migrationDialogBadge,
                            style: GoogleFonts.jetBrainsMono(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Title
                      Text(
                        s.migrationDialogTitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 18.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Main Description
                      Text(
                        s.migrationDialogDesc,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── 2. Feature Highlights (Data Safe & Storage Clean) ──
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
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
                      const SizedBox(height: 20),

                      // ── 3. Action Buttons ──
                      SizedBox(
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: _isUninstalling ? null : _handleUninstall,
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
                          icon: _isUninstalling
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
                            _isUninstalling
                                ? 'Membuka Pencopotan...'
                                : s.migrationUninstallBtn,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      TextButton(
                        onPressed: _handleDismiss,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
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
                  ),
                ),
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

