import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/platform/device_form_factor.dart';
import '../../data/auto_backup_service.dart';

/// Dedicated full-screen page for configuring local scheduled Auto-Backups
/// (`Off`, `Weekly`, `Monthly`) saved to `Documents/Cineva`, triggering an
/// immediate backup, and restoring from saved local snapshots in one tap.
class AutoBackupScreen extends ConsumerStatefulWidget {
  const AutoBackupScreen({super.key});

  @override
  ConsumerState<AutoBackupScreen> createState() => _AutoBackupScreenState();
}

class _AutoBackupScreenState extends ConsumerState<AutoBackupScreen> {
  late AutoBackupFrequency _frequency;
  DateTime? _lastBackupAt;
  List<AutoBackupFileEntry> _savedFiles = const [];
  bool _isBackingUp = false;
  bool _isLoadingFiles = true;

  @override
  void initState() {
    super.initState();
    _frequency = AutoBackupService.getFrequency();
    _lastBackupAt = AutoBackupService.getLastBackupTime();
    _refreshFiles();
  }

  Future<void> _refreshFiles() async {
    final files = await AutoBackupService.listSavedAutoBackups();
    if (!mounted) return;
    setState(() {
      _savedFiles = files;
      _lastBackupAt = AutoBackupService.getLastBackupTime();
      _isLoadingFiles = false;
    });
  }

  Future<void> _selectFrequency(AutoBackupFrequency freq) async {
    await AutoBackupService.setFrequency(freq);
    if (!mounted) return;
    setState(() {
      _frequency = freq;
    });
    // If enabling auto-backup for the first time and no backup has ever run,
    // trigger an initial backup automatically.
    if (freq != AutoBackupFrequency.off && _lastBackupAt == null) {
      await _runBackupNow();
    }
  }

  Future<void> _runBackupNow() async {
    if (_isBackingUp) return;
    final s = ref.read(appStringsProvider);
    setState(() => _isBackingUp = true);

    final result = await AutoBackupService.runAutoBackupNow(ref);
    await _refreshFiles();

    if (!mounted) return;
    setState(() => _isBackingUp = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.autoBackupSuccessToast,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (result.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          content: Text(
            result.errorMessage!,
            style: GoogleFonts.inter(color: Colors.white),
          ),
        ),
      );
    }
  }

  Future<void> _restoreFile(AutoBackupFileEntry entry) async {
    final s = ref.read(appStringsProvider);
    final result = await AutoBackupService.restoreFromFile(
      ref,
      entry.filePath,
    );
    if (!mounted) return;
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.backupImportSuccessSummary(
                    result.watchlistCount,
                    result.historyCount,
                  ),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _deleteFile(AutoBackupFileEntry entry) async {
    final s = ref.read(appStringsProvider);
    final ok = await AutoBackupService.deleteBackupFile(entry.filePath);
    if (ok) {
      await _refreshFiles();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          content: Text(
            s.autoBackupDeletedToast,
            style: GoogleFonts.inter(color: Colors.white),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatDateTime(DateTime? dt, AppStrings s) {
    if (dt == null) return s.autoBackupNever;
    return DateFormat('dd/MM/yyyy HH:mm').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final isTv = ref.watch(isTvProvider);
    final isDesktop = ref.watch(isDesktopProvider);
    final isWide = isTv || isDesktop;

    final nextScheduled = AutoBackupService.getNextScheduledTime(
      frequency: _frequency,
      lastRunAt: _lastBackupAt,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 19,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/settings');
            }
          },
        ),
        title: Text(
          s.autoBackupScreenTitle,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWide ? 680 : double.infinity,
            ),
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 36),
              children: [
                // ── Description ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
                  child: Text(
                    s.autoBackupScreenDesc,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ),

                // ── Section 1: Schedule Picker (Flat borderless rows, active text in Cineva Orange + Checkmark) ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Text(
                    s.autoBackupScheduleSection,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                ...AutoBackupFrequency.values.map((freq) {
                  final isSelected = _frequency == freq;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _selectFrequency(freq),
                        splashColor: Colors.transparent,
                        highlightColor: Colors.white.withValues(alpha: 0.03),
                        hoverColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      freq.localizedTitle(s),
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? AppColors.primary
                                            : Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      freq.localizedDescription(s),
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: isSelected
                                            ? AppColors.primary.withValues(
                                                alpha: 0.8,
                                              )
                                            : AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_rounded,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                            ],
                          ),
                        ),
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ],
                  );
                }),

                const SizedBox(height: 22),

                // ── Section 2: Storage Location, Status & "Back Up Now" Button ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildInfoRow(
                        icon: Iconsax.folder_2,
                        label: s.autoBackupLocationLabel,
                        value: AutoBackupService.displayFolderPath,
                        highlightValue: true,
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow(
                        icon: Iconsax.clock,
                        label: s.autoBackupLastRunLabel,
                        value: _formatDateTime(_lastBackupAt, s),
                      ),
                      if (_frequency != AutoBackupFrequency.off) ...[
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          icon: Iconsax.calendar_1,
                          label: s.autoBackupNextRunLabel,
                          value: _formatDateTime(nextScheduled, s),
                        ),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: _isBackingUp ? null : _runBackupNow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          icon: _isBackingUp
                              ? const SizedBox(
                                  width: 17,
                                  height: 17,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Icon(
                                  Icons.backup_outlined,
                                  size: 19,
                                ),
                          label: Text(
                            s.autoBackupRunNowBtn,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Section 3: Saved Auto-Backup Files (1-Tap Restore) ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Text(
                    s.autoBackupSavedFilesSection,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                if (_isLoadingFiles)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  )
                else if (_savedFiles.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: Text(
                      s.autoBackupEmptyFiles,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  )
                else
                  ..._savedFiles.map((entry) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Iconsax.document_code,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.fileName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${entry.formattedDate} • ${entry.formattedSize}',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => _restoreFile(entry),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                ),
                                child: Text(
                                  s.autoBackupRestoreBtn,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _deleteFile(entry),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.white38,
                                  size: 19,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ],
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool highlightValue = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.textMuted),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: highlightValue ? AppColors.primary : Colors.white,
          ),
        ),
      ],
    );
  }
}
