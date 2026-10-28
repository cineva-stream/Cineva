import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../providers/app_update_provider.dart';
import 'install_permission_dialog.dart';

/// In-App Update Banner rendered cleanly on the Home screen directly above the Hero Section.
/// Features a pure smooth black background identical to the main app theme,
/// paired with an elegant smooth border, real-time download progress, and package install trigger.
class InAppUpdateBanner extends ConsumerWidget {
  const InAppUpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateState = ref.watch(appUpdateProvider);
    final notifier = ref.read(appUpdateProvider.notifier);
    final s = ref.watch(appStringsProvider);

    // If dismissed or no update available, do not render
    if (updateState.isDismissed || updateState.updateInfo == null) {
      return const SizedBox.shrink();
    }

    final info = updateState.updateInfo!;
    final isDownloading = updateState.status == AppUpdateStatus.downloading;
    final isReadyToInstall = updateState.status == AppUpdateStatus.readyToInstall ||
        updateState.status == AppUpdateStatus.installing;
    final isError = updateState.status == AppUpdateStatus.error;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.background, // Pure smooth black background matching main app
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35), // Smooth elegant border
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: Icon, Title, Version Tag & Dismiss Button ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            s.updateAvailableTitle,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.5),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            'v${info.latestVersion}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: isDownloading ? null : notifier.dismiss,
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    tooltip: s.updateDismissTooltip,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ── Description / Changelog ──
              Text(
                info.shortSummary.isNotEmpty
                    ? info.shortSummary
                    : s.updateNewVersionSubtitle(info.latestVersion),
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 14),

              // ── Dynamic State Body (Download Progress or Action Button) ──
              if (isDownloading) ...[
                // Download progress bar with live percentage and size
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          s.updateDownloading,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          '${(updateState.progress * 100).toInt()}%',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: updateState.progress,
                        minHeight: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          updateState.totalBytes > 0
                              ? '${(updateState.receivedBytes / (1024 * 1024)).toStringAsFixed(1)} MB / ${info.formattedSize}'
                              : info.formattedSize,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        GestureDetector(
                          onTap: notifier.cancelDownload,
                          child: Text(
                            s.updateCancel,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.redAccent.shade100,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ] else if (isReadyToInstall) ...[
                // Ready to Install button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 5),
                        Text(
                          info.formattedSize,
                          style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final allowed = await notifier.canRequestPackageInstalls();
                        if (!allowed && context.mounted) {
                          final granted = await InstallPermissionDialog.show(context);
                          if (granted == true) {
                            await notifier.triggerInstall();
                          }
                        } else {
                          await notifier.triggerInstall();
                        }
                      },
                      icon: const Icon(Icons.install_mobile_rounded, size: 16),
                      label: Text(s.updateInstallAction),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                        textStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ] else if (isError) ...[
                // Error state with retry
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        s.updateFailed,
                        style: GoogleFonts.inter(fontSize: 11.5, color: Colors.redAccent.shade100),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: notifier.startDownload,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      child: Text(
                        s.updateRetry,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Default available state: Size indicator + "Perbarui Sekarang"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      info.formattedSize,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: notifier.startDownload,
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: Text(s.updateAction),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                        textStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05, end: 0, duration: 400.ms);
  }
}
