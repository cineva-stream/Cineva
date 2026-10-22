import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/models/download_item.dart';
import '../providers/download_provider.dart';
import '../../data/repositories/download_repository.dart';

/// Screen displaying movies and TV series currently downloading and finished.
class DownloadListScreen extends ConsumerStatefulWidget {
  const DownloadListScreen({super.key});

  @override
  ConsumerState<DownloadListScreen> createState() => _DownloadListScreenState();
}

class _DownloadListScreenState extends ConsumerState<DownloadListScreen> {
  int _selectedTab = 0; // 0 = Sedang Diunduh, 1 = Selesai

  @override
  Widget build(BuildContext context) {
    final allDownloads = ref.watch(downloadManagerProvider);
    final inProgress = allDownloads.where((i) => !i.isCompleted).toList();
    final completed = allDownloads.where((i) => i.isCompleted).toList();
    final repo = ref.watch(downloadRepositoryProvider);
    final totalUsedBytes = repo.getTotalDownloadedBytes();

    String formatBytes(int b) {
      if (b >= 1073741824) return '${(b / 1073741824).toStringAsFixed(2)} GB';
      if (b >= 1048576) return '${(b / 1048576).toStringAsFixed(1)} MB';
      if (b >= 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
      return '$b B';
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
        title: Text(
          'Daftar Unduhan',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surfaceElevated),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.folder_favorite, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  formatBytes(totalUsedBytes),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Modern Minimalist Underline Tabs
          Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.surfaceElevated.withValues(alpha: 0.8),
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _TabButton(
                    label: 'Sedang Diunduh',
                    count: inProgress.length,
                    isSelected: _selectedTab == 0,
                    onTap: () => setState(() => _selectedTab = 0),
                  ),
                ),
                Expanded(
                  child: _TabButton(
                    label: 'Selesai',
                    count: completed.length,
                    isSelected: _selectedTab == 1,
                    onTap: () => setState(() => _selectedTab = 1),
                  ),
                ),
              ],
            ),
          ),

          // Content List
          Expanded(
            child: _selectedTab == 0
                ? _buildInProgressList(inProgress)
                : _buildCompletedList(completed),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildInProgressList(List<DownloadItem> items) {
    if (items.isEmpty) {
      return _buildEmptyState(
        icon: Iconsax.document_download,
        title: 'Tidak Ada Unduhan Aktif',
        description: 'Pilih Film atau Serial TV favorit Anda lalu tekan tombol Unduh.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return _InProgressCard(item: item);
      },
    );
  }

  Widget _buildCompletedList(List<DownloadItem> items) {
    if (items.isEmpty) {
      return _buildEmptyState(
        icon: Iconsax.video_tick,
        title: 'Belum Ada Unduhan Selesai',
        description: 'Semua Film & Serial TV yang telah selesai diunduh akan muncul di sini untuk ditonton secara offline.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return _CompletedCard(item: item);
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surfaceElevated),
              ),
              child: Icon(icon, color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Iconsax.play, size: 16),
              label: const Text('Jelajahi Konten'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.primary.withValues(alpha: 0.08),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? AppColors.primary : Colors.white70,
                      letterSpacing: 0.2,
                    ),
                    child: Text(label),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.16)
                            : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.4)
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '$count',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppColors.primary : Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Smooth thin bottom border indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              height: 2.5,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.45),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card item for actively downloading media.
class _InProgressCard extends ConsumerWidget {
  final DownloadItem item;
  const _InProgressCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(downloadManagerProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceElevated),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: ApiConstants.imageUrl(item.posterPath, size: ApiConstants.posterSmall),
                  width: 55,
                  height: 80,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => Container(
                    width: 55,
                    height: 80,
                    color: AppColors.surface,
                    child: const Icon(Icons.movie, color: AppColors.textMuted),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.videoFileName,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.resolution,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${item.formattedDownloadedSize} / ${item.formattedTotalSize}',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Pause / Resume & Cancel
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      if (item.isDownloading) {
                        notifier.pauseDownload(item.id);
                      } else {
                        notifier.resumeDownload(item.id);
                      }
                    },
                    icon: Icon(
                      item.isDownloading ? Icons.pause_circle_rounded : Icons.play_circle_fill_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                    tooltip: item.isDownloading ? 'Jeda' : 'Lanjutkan',
                  ),
                  IconButton(
                    onPressed: () => notifier.deleteDownload(item.id),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                    tooltip: 'Batalkan',
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.progress.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                item.isPaused ? Colors.amber : AppColors.primary,
              ),
              minHeight: 6,
            ),
          ),

          const SizedBox(height: 6),

          // Speed & Subtitle Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(item.progress * 100).toStringAsFixed(1)}% • ${item.speed}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: item.isPaused ? Colors.amber : AppColors.primary,
                ),
              ),
              Text(
                item.subtitleStatus == 'translated'
                    ? 'Subtitle ID (Terjemahan)'
                    : item.subtitleStatus == 'ready'
                        ? 'Subtitle ID (Asli)'
                        : 'Subtitle: ${item.selectedSubtitleLang}',
                style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Card item for completed media ready for offline playback.
class _CompletedCard extends ConsumerWidget {
  final DownloadItem item;
  const _CompletedCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(downloadManagerProvider.notifier);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        // Launch Player Screen offline directly!
        context.push('/player', extra: {
          'title': item.title,
          'episodeTitle': item.episodeTitle,
          'mediaType': item.mediaType,
          'tmdbId': item.tmdbId,
          'posterPath': item.posterPath,
          'backdropPath': item.backdropPath,
          'localVideoPath': item.videoPath,
          'localSubtitlePath': item.subtitlePath,
          'magnetLink': '',
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceElevated),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with Play Overlay
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CachedNetworkImage(
                    imageUrl: ApiConstants.imageUrl(item.posterPath, size: ApiConstants.posterSmall),
                    width: 60,
                    height: 88,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Container(
                      width: 60,
                      height: 88,
                      color: AppColors.surface,
                      child: const Icon(Icons.movie, color: AppColors.textMuted),
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 88,
                    color: Colors.black.withValues(alpha: 0.35),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 18),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 14),

            // Video Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.videoFileName,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.resolution,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.formattedTotalSize,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (item.subtitlePath != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Iconsax.subtitle, size: 10, color: AppColors.primary),
                              const SizedBox(width: 3),
                              Text(
                                item.subtitleStatus == 'translated'
                                    ? 'SRT ID (Kau/Aku)'
                                    : 'SRT ID',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Delete Button
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surfaceVariant,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Text('Hapus Unduhan?', style: GoogleFonts.outfit(color: Colors.white)),
                    content: Text(
                      'File video "${item.videoFileName}" dan subtitle akan dihapus dari perangkat untuk menghemat ruang.',
                      style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          notifier.deleteDownload(item.id);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Iconsax.trash, size: 18, color: AppColors.textMuted),
              tooltip: 'Hapus file',
            ),
          ],
        ),
      ),
    );
  }
}
