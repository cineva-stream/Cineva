import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/services/subtitle_service.dart';
import '../providers/player_providers.dart';

/// Modal dialog for customizing subtitle styles, vertical position,
/// real-time time synchronization, and free auto-translation to Indonesian.
class SubtitleSettingsDialog extends ConsumerStatefulWidget {
  final String imdbId;
  final SubtitleInfo? currentSubtitleInfo;
  final VoidCallback? onSubtitleTranslated;

  const SubtitleSettingsDialog({
    super.key,
    required this.imdbId,
    this.currentSubtitleInfo,
    this.onSubtitleTranslated,
  });

  @override
  ConsumerState<SubtitleSettingsDialog> createState() => _SubtitleSettingsDialogState();
}

class _SubtitleSettingsDialogState extends ConsumerState<SubtitleSettingsDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isTranslating = false;
  double _translationProgress = 0.0;
  String _translationStatus = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _startAutoTranslate() async {
    final currentCues = ref.read(activeSubtitleCuesProvider);
    if (currentCues.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih subtitle terlebih dahulu sebelum menerjemahkan.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isTranslating = true;
      _translationProgress = 0.0;
      _translationStatus = 'Memulai penerjemahan ke Bahasa Indonesia...';
    });

    try {
      final translator = ref.read(subtitleTranslatorServiceProvider);
      final cacheKey = 'sub_${widget.imdbId}_id_${widget.currentSubtitleInfo?.id ?? "custom"}';

      final translated = await translator.translateCuesToIndonesian(
        cues: currentCues,
        cacheKey: cacheKey,
        onProgress: (p) {
          if (mounted) {
            setState(() {
              _translationProgress = p;
              _translationStatus = 'Menerjemahkan baris subtitle: ${(p * 100).toInt()}%';
            });
          }
        },
      );

      if (mounted) {
        ref.read(activeSubtitleCuesProvider.notifier).state = translated;
        widget.onSubtitleTranslated?.call();
        setState(() {
          _isTranslating = false;
          _translationStatus = 'Berhasil diterjemahkan ke Bahasa Indonesia!';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subtitle berhasil diterjemahkan ke Bahasa Indonesia!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTranslating = false;
          _translationStatus = 'Gagal menerjemahkan: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = ref.watch(subtitleStyleProvider);
    final notifier = ref.read(subtitleStyleProvider.notifier);

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 440),
        child: Column(
          children: [
            // ── Dialog Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Iconsax.subtitle, color: AppColors.primary, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'Pengaturan Subtitle',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                  ),
                ],
              ),
            ),

            // ── Tab Bar ──
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(icon: Icon(Iconsax.clock, size: 16), text: 'Waktu (Sync)'),
                Tab(icon: Icon(Iconsax.brush_1, size: 16), text: 'Tampilan'),
                Tab(icon: Icon(Iconsax.translate, size: 16), text: 'Auto-Translate'),
              ],
            ),

            // ── Tab Content ──
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ── Tab 1: Sync (Waktu) ──
                  _buildSyncTab(style, notifier),

                  // ── Tab 2: Style (Tampilan & Posisi) ──
                  _buildStyleTab(style, notifier),

                  // ── Tab 3: Auto-Translate ──
                  _buildTranslateTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncTab(dynamic style, dynamic notifier) {
    final offsetMs = style.syncOffsetMs as int;
    final offsetSec = (offsetMs / 1000.0).toStringAsFixed(2);
    final isDelayed = offsetMs > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          const Text(
            'Sesuaikan kemunculan subtitle agar pas dengan suara aktor',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // ── Current Offset Display ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: offsetMs != 0 ? AppColors.primary : AppColors.surfaceElevated,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Text(
                  offsetMs == 0 ? 'Tepat Waktu (0.00 detik)' : '${isDelayed ? "+" : ""}$offsetSec detik',
                  style: TextStyle(
                    color: offsetMs != 0 ? AppColors.primary : Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  offsetMs == 0
                      ? 'Sinkronisasi default'
                      : isDelayed
                          ? 'Subtitle ditunda (muncul lebih lambat)'
                          : 'Subtitle dipercepat (muncul lebih awal)',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Fine Tuning Buttons ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSyncButton('-1.0s', () => notifier.adjustSyncOffset(-1000)),
              const SizedBox(width: 8),
              _buildSyncButton('-250ms', () => notifier.adjustSyncOffset(-250)),
              const SizedBox(width: 8),
              _buildSyncButton('-100ms', () => notifier.adjustSyncOffset(-100)),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => notifier.resetSyncOffset(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  side: const BorderSide(color: AppColors.surfaceElevated),
                ),
                child: const Text('Reset', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ),
              const SizedBox(width: 12),
              _buildSyncButton('+100ms', () => notifier.adjustSyncOffset(100)),
              const SizedBox(width: 8),
              _buildSyncButton('+250ms', () => notifier.adjustSyncOffset(250)),
              const SizedBox(width: 8),
              _buildSyncButton('+1.0s', () => notifier.adjustSyncOffset(1000)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSyncButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.surfaceVariant,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: const Size(54, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildStyleTab(dynamic style, dynamic notifier) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Live Preview Box ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceElevated),
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (style.strokeWidth > 0)
                    Text(
                      'Pratinjau Tampilan Subtitle Cineva',
                      style: TextStyle(
                        fontSize: style.fontSize,
                        fontWeight: FontWeight.w700,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = style.strokeWidth * 2
                          ..color = style.strokeColor,
                      ),
                    ),
                  Text(
                    'Pratinjau Tampilan Subtitle Cineva',
                    style: TextStyle(
                      fontSize: style.fontSize,
                      fontWeight: FontWeight.w700,
                      color: style.textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── Ketebalan Stroke (Outline) ──
          Row(
            children: [
              const SizedBox(
                width: 120,
                child: Text('Tebal Stroke:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ),
              Expanded(
                child: Slider(
                  value: style.strokeWidth,
                  min: 0.0,
                  max: 5.0,
                  divisions: 10,
                  activeColor: AppColors.primary,
                  onChanged: (v) => notifier.updateStrokeWidth(v),
                ),
              ),
              Text('${style.strokeWidth.toStringAsFixed(1)}px',
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),

          // ── Posisi Vertikal ──
          Row(
            children: [
              const SizedBox(
                width: 120,
                child: Text('Posisi Vertikal:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ),
              Expanded(
                child: Slider(
                  value: style.bottomOffset,
                  min: 15.0,
                  max: 120.0,
                  divisions: 21,
                  activeColor: AppColors.primary,
                  onChanged: (v) => notifier.updateBottomOffset(v),
                ),
              ),
              Text('${style.bottomOffset.toInt()}px',
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),

          // ── Ukuran Huruf ──
          Row(
            children: [
              const SizedBox(
                width: 120,
                child: Text('Ukuran Huruf:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ),
              Expanded(
                child: Slider(
                  value: style.fontSize,
                  min: 14.0,
                  max: 30.0,
                  divisions: 8,
                  activeColor: AppColors.primary,
                  onChanged: (v) => notifier.updateFontSize(v),
                ),
              ),
              Text('${style.fontSize.toInt()}pt',
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),

          // ── Pilihan Warna Teks ──
          Row(
            children: [
              const SizedBox(
                width: 120,
                child: Text('Warna Huruf:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ),
              const SizedBox(width: 8),
              _buildColorChip(const Color(0xFFFFFFFF), 'Putih', style.textColor, notifier),
              const SizedBox(width: 8),
              _buildColorChip(const Color(0xFFFFD700), 'Kuning', style.textColor, notifier),
              const SizedBox(width: 8),
              _buildColorChip(const Color(0xFF00E5FF), 'Cyan', style.textColor, notifier),
              const SizedBox(width: 8),
              _buildColorChip(const Color(0xFF00E676), 'Hijau', style.textColor, notifier),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorChip(Color color, String label, Color current, dynamic notifier) {
    final isSelected = color.toARGB32() == current.toARGB32();
    return GestureDetector(
      onTap: () => notifier.updateTextColor(color),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildTranslateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Iconsax.translate, size: 40, color: AppColors.primary),
          const SizedBox(height: 12),
          const Text(
            'Auto-Translate ke Bahasa Indonesia (Gratis)',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Jika subtitle bahasa Indonesia tidak tersedia, fitur ini akan menerjemahkan subtitle bahasa asing saat ini ke Bahasa Indonesia secara gratis dan otomatis.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          if (_isTranslating) ...[
            SizedBox(
              width: 260,
              child: LinearProgressIndicator(
                value: _translationProgress > 0 ? _translationProgress : null,
                color: AppColors.primary,
                backgroundColor: AppColors.surfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _translationStatus,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ] else ...[
            if (_translationStatus.isNotEmpty) ...[
              Text(
                _translationStatus,
                style: const TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
            ],
            ElevatedButton.icon(
              onPressed: _startAutoTranslate,
              icon: const Icon(Iconsax.magic_star, size: 18),
              label: const Text('Terjemahkan Subtitle Sekarang'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
