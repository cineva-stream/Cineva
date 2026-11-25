import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/platform/device_form_factor.dart';
import '../../../../shared/widgets/tv_focusable.dart';
import '../../domain/entities/app_update_info.dart';
import '../providers/app_update_provider.dart';
import '../widgets/install_permission_dialog.dart';

/// Full-screen minimalist, badge-free mandatory update gate displayed when the
/// user's installed version has missed 3 or more updates.
///
/// Provides informative version comparison, changelog summary, real-time download
/// progress, and strictly two actions:
/// - **Unduh (Download)**: Downloads and launches the native package installer.
/// - **Batal (Cancel)**: Immediately closes the application.
class MandatoryUpdateScreen extends ConsumerWidget {
  /// Optional override for testing the app-exit action without terminating the test runner.
  final VoidCallback? onExitOverride;

  const MandatoryUpdateScreen({
    super.key,
    this.onExitOverride,
  });

  Future<void> _closeApplication() async {
    if (onExitOverride != null) {
      onExitOverride!();
      return;
    }
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      try {
        await windowManager.close();
      } catch (_) {}
      exit(0);
    } else {
      await SystemNavigator.pop();
    }
  }

  Future<void> _handlePrimaryAction(
    BuildContext context,
    AppUpdateState updateState,
    AppUpdateNotifier notifier,
  ) async {
    final isDownloading = updateState.status == AppUpdateStatus.downloading;
    if (isDownloading) return;

    final isReadyToInstall =
        updateState.status == AppUpdateStatus.readyToInstall ||
        updateState.status == AppUpdateStatus.installing;

    if (isReadyToInstall) {
      final allowed = await notifier.canRequestPackageInstalls();
      if (!allowed && context.mounted) {
        final granted = await InstallPermissionDialog.show(context);
        if (granted == true) {
          await notifier.triggerInstall();
        }
      } else {
        await notifier.triggerInstall();
      }
      return;
    }

    await notifier.startDownload();
  }

  static String _formatMegabytes(int bytes) {
    if (bytes <= 0) return '0.0 MB';
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final updateState = ref.watch(appUpdateProvider);
    final notifier = ref.read(appUpdateProvider.notifier);
    final info = updateState.updateInfo;

    if (info == null) {
      return const SizedBox.shrink();
    }

    final isTv = ref.watch(isTvProvider);
    final isDesktop = ref.watch(isDesktopProvider);
    final screenSize = MediaQuery.sizeOf(context);
    final isCompact = screenSize.width < 360;

    final isDownloading = updateState.status == AppUpdateStatus.downloading;
    final isReadyToInstall =
        updateState.status == AppUpdateStatus.readyToInstall ||
        updateState.status == AppUpdateStatus.installing;
    final isError = updateState.status == AppUpdateStatus.error;

    final double maxContentWidth = (isTv || isDesktop) ? 560.0 : 460.0;
    final String changelogText = info.changelog.trim().isNotEmpty
        ? info.changelog.trim()
        : s.updateNewVersionSubtitle(info.latestVersion);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _closeApplication();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Subtle top ambient cinema spotlight glow
            Positioned(
              top: -140,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    width: 520,
                    height: 360,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.14),
                          AppColors.primary.withValues(alpha: 0.03),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 20 : 28,
                      vertical: isCompact ? 18 : 28,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Center(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // ── 1. Minimalist Brand Header (No Badges) ──
                                  Center(
                                    child: Container(
                                      width: isCompact ? 56 : 64,
                                      height: isCompact ? 56 : 64,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.10,
                                          ),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.55,
                                            ),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: Image.asset(
                                          'assets/images/cineva_icon.png',
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => Container(
                                            color: AppColors.surfaceVariant,
                                            child: const Icon(
                                              Icons.system_update_alt_rounded,
                                              color: AppColors.primary,
                                              size: 28,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: isCompact ? 18 : 22),

                                  Text(
                                    s.mandatoryUpdateTitle,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      fontSize: isCompact ? 22 : 25,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -0.3,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  Text(
                                    s.mandatoryUpdateDescription(
                                      info.currentVersion,
                                      info.latestVersion,
                                      info.missedUpdateCount,
                                    ),
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: isCompact ? 12.5 : 13.5,
                                      color: AppColors.textSecondary,
                                      height: 1.55,
                                    ),
                                  ),
                                  SizedBox(height: isCompact ? 18 : 22),

                                  // ── 2. Clean Typographic Version & Size Bar (No Badges) ──
                                  _buildVersionMetricsRow(s, info, isCompact),
                                  const SizedBox(height: 16),

                                  // ── 3. Informative Release Notes Container ──
                                  Container(
                                    constraints: const BoxConstraints(
                                      maxHeight: 240,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.025,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.08,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            18,
                                            14,
                                            18,
                                            10,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  s.mandatoryUpdateWhatsNewLabel,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                    letterSpacing: 0.1,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  info.releaseTitle,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  textAlign: TextAlign.right,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    color: AppColors.textMuted,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Divider(
                                          height: 1,
                                          color: Colors.white.withValues(
                                            alpha: 0.07,
                                          ),
                                        ),
                                        Flexible(
                                          child: SingleChildScrollView(
                                            physics:
                                                const BouncingScrollPhysics(),
                                            padding: const EdgeInsets.fromLTRB(
                                              18,
                                              14,
                                              18,
                                              16,
                                            ),
                                            child: _buildMinimalMarkdown(
                                              changelogText,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // ── 4. Inline Download Progress or Error Feedback ──
                                  if (isDownloading) ...[
                                    const SizedBox(height: 16),
                                    _buildProgressSection(s, updateState, info),
                                  ] else if (isError) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      s.updateFailed,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── 5. Strictly Two Action Buttons: Batal (Exit) & Unduh (Download) ──
                        Row(
                          children: [
                            // Batal -> Closes Application
                            Expanded(
                              child: TvFocusable(
                                focusedScale: 1.03,
                                borderRadius: BorderRadius.circular(14),
                                onTap: () {
                                  if (isDownloading) {
                                    notifier.cancelDownload();
                                  }
                                  _closeApplication();
                                },
                                child: Container(
                                  height: 48,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.12,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    s.updateCancel,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Unduh -> Downloads & Installs Update
                            Expanded(
                              child: TvFocusable(
                                autofocus: true,
                                focusedScale: 1.03,
                                borderRadius: BorderRadius.circular(14),
                                onTap: isDownloading
                                    ? null
                                    : () => _handlePrimaryAction(
                                          context,
                                          updateState,
                                          notifier,
                                        ),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  height: 48,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isDownloading
                                        ? AppColors.primary.withValues(
                                            alpha: 0.45,
                                          )
                                        : AppColors.primary,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    isReadyToInstall
                                        ? s.updateInstallAction
                                        : s.updateDownloadButton,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionMetricsRow(
    AppStrings s,
    AppUpdateInfo info,
    bool isCompact,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isCompact ? 12 : 14,
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _buildMetricColumn(
                label: s.mandatoryUpdateCurrentLabel,
                value: 'v${info.currentVersion}',
                valueColor: AppColors.textSecondary,
                isCompact: isCompact,
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: Colors.white.withValues(alpha: 0.08),
            ),
            Expanded(
              child: _buildMetricColumn(
                label: s.mandatoryUpdateLatestLabel,
                value: 'v${info.latestVersion}',
                valueColor: Colors.white,
                isCompact: isCompact,
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: Colors.white.withValues(alpha: 0.08),
            ),
            Expanded(
              child: _buildMetricColumn(
                label: s.mandatoryUpdateSizeLabel,
                value: info.formattedSize,
                valueColor: AppColors.textSecondary,
                isCompact: isCompact,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricColumn({
    required String label,
    required String value,
    required Color valueColor,
    required bool isCompact,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: isCompact ? 10.5 : 11,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontSize: isCompact ? 14 : 15.5,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(
    AppStrings s,
    AppUpdateState updateState,
    AppUpdateInfo info,
  ) {
    final pct = (updateState.progress * 100).clamp(0, 100).toInt();
    final totalBytes = updateState.totalBytes > 0
        ? updateState.totalBytes
        : info.apkSizeBytes;
    final sizeProgress = totalBytes > 0
        ? '${_formatMegabytes(updateState.receivedBytes)} / ${_formatMegabytes(totalBytes)}'
        : '$pct%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              s.updateDownloading,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$pct%  •  $sizeProgress',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: updateState.progress > 0 ? updateState.progress : null,
            minHeight: 4,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalMarkdown(String markdown) {
    return MarkdownBody(
      data: markdown,
      selectable: false,
      extensionSet: md.ExtensionSet.gitHubFlavored,
      onTapLink: (text, href, title) {
        if (href != null && href.isNotEmpty) {
          launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
        }
      },
      styleSheet: MarkdownStyleSheet(
        h1: GoogleFonts.outfit(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        h2: GoogleFonts.outfit(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        h3: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.9),
        ),
        p: GoogleFonts.inter(
          fontSize: 12.5,
          height: 1.55,
          color: AppColors.textSecondary,
        ),
        listBullet: GoogleFonts.inter(
          fontSize: 12.5,
          color: AppColors.textMuted,
        ),
        strong: GoogleFonts.inter(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.92),
        ),
        code: GoogleFonts.jetBrainsMono(
          fontSize: 11.5,
          color: Colors.white70,
          backgroundColor: Colors.white.withValues(alpha: 0.06),
        ),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
