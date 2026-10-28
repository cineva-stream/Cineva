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
import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/app_language_provider.dart';

/// Screen displaying movies and TV series currently downloading and finished.
/// Supports YouTube-style in-app offline playback and Season-based TV Series management.
class DownloadListScreen extends ConsumerStatefulWidget {
  const DownloadListScreen({super.key});

  @override
  ConsumerState<DownloadListScreen> createState() => _DownloadListScreenState();
}

class _DownloadListScreenState extends ConsumerState<DownloadListScreen> {
  int _selectedTab = 0; // 0 = Sedang Diunduh, 1 = Selesai
  int _completedFilter = 0; // 0 = Semua, 1 = Film, 2 = Serial TV
  final Set<String> _expandedSeries = {};

  String _formatBytes(int b) {
    if (b >= 1073741824) return '${(b / 1073741824).toStringAsFixed(2)} GB';
    if (b >= 1048576) return '${(b / 1048576).toStringAsFixed(1)} MB';
    if (b >= 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
    return '$b B';
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final allDownloads = ref.watch(downloadManagerProvider);
    final inProgress = allDownloads.where((i) => !i.isCompleted).toList();
    final completed = allDownloads.where((i) => i.isCompleted).toList();
    final repo = ref.watch(downloadRepositoryProvider);
    final totalUsedBytes = repo.getTotalDownloadedBytes();

    final completedMovies = completed.where((i) => i.isMovie).toList();
    final completedTv = completed.where((i) => i.isTv).toList();

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
            s.downloadTitle,
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
                    _formatBytes(totalUsedBytes),
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
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
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
                      label: s.downloadTabInProgress,
                      count: inProgress.length,
                      isSelected: _selectedTab == 0,
                      onTap: () => setState(() => _selectedTab = 0),
                    ),
                  ),
                  Expanded(
                    child: _TabButton(
                      label: s.downloadTabCompleted,
                      count: completed.length,
                      isSelected: _selectedTab == 1,
                      onTap: () => setState(() => _selectedTab = 1),
                    ),
                  ),
                ],
              ),
            ),

            // Content Body
            Expanded(
              child: _selectedTab == 0
                  ? _buildInProgressList(inProgress)
                  : _buildCompletedView(
                      allCompleted: completed,
                      movies: completedMovies,
                      tvList: completedTv,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInProgressList(List<DownloadItem> items) {
    final s = ref.watch(appStringsProvider);
    if (items.isEmpty) {
      return _buildEmptyState(
        icon: Icons.download_rounded,
        title: s.isIndonesian ? 'Tidak Ada Unduhan Aktif' : 'No Active Downloads',
        description: s.isIndonesian ? 'Pilih Film atau Serial TV favorit Anda lalu tekan tombol Unduh.' : 'Select a movie or TV show and tap Download.',
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

  Widget _buildCompletedView({
    required List<DownloadItem> allCompleted,
    required List<DownloadItem> movies,
    required List<DownloadItem> tvList,
  }) {
    final s = ref.watch(appStringsProvider);
    if (allCompleted.isEmpty) {
      return _buildEmptyState(
        icon: Iconsax.video_tick,
        title: s.isIndonesian ? 'Belum Ada Konten Tersimpan' : 'No Saved Content Yet',
        description: s.isIndonesian
            ? 'Semua Film & Serial TV yang diunduh akan tersimpan di sini dan siap ditonton kapan saja tanpa internet.'
            : 'All downloaded movies and shows will be stored here ready for offline viewing.',
      );
    }

    // Group TV Series by tmdbId or Title
    final tvSeriesMap = <String, List<DownloadItem>>{};
    for (final item in tvList) {
      final key = item.tmdbId > 0 ? '${item.tmdbId}' : item.title;
      tvSeriesMap.putIfAbsent(key, () => []).add(item);
    }

    return Column(
      children: [
        // Filter Chips: Semua, Film, Serial TV
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildFilterChip(
                label: s.homeAllCategory,
                count: allCompleted.length,
                isSelected: _completedFilter == 0,
                onTap: () => setState(() => _completedFilter = 0),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: s.searchTabMovies,
                count: movies.length,
                isSelected: _completedFilter == 1,
                onTap: () => setState(() => _completedFilter = 1),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: s.searchTabTv,
                count: tvSeriesMap.length,
                isSelected: _completedFilter == 2,
                onTap: () => setState(() => _completedFilter = 2),
              ),
            ],
          ),
        ),

        // Scrollable List of Completed Media
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            physics: const BouncingScrollPhysics(),
            children: [
              // 1. Movie Section (if filter is 0 or 1)
              if ((_completedFilter == 0 || _completedFilter == 1) && movies.isNotEmpty) ...[
                if (_completedFilter == 0) ...[
                  _buildSectionHeader(
                    s.isIndonesian ? 'Film Offline' : 'Offline Movies',
                    s.isIndonesian ? '${movies.length} Film' : '${movies.length} Movies',
                  ),
                  const SizedBox(height: 8),
                ],
                ...movies.map((movie) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CompletedMovieCard(item: movie),
                    )),
                if (_completedFilter == 0 && tvSeriesMap.isNotEmpty) const SizedBox(height: 12),
              ],

              // 2. TV Series Section (if filter is 0 or 2)
              if ((_completedFilter == 0 || _completedFilter == 2) && tvSeriesMap.isNotEmpty) ...[
                if (_completedFilter == 0) ...[
                  _buildSectionHeader(
                    s.isIndonesian ? 'Serial TV Offline' : 'Offline TV Series',
                    s.isIndonesian ? '${tvSeriesMap.length} Judul' : '${tvSeriesMap.length} Series',
                  ),
                  const SizedBox(height: 8),
                ],
                ...tvSeriesMap.entries.map((entry) {
                  final seriesKey = entry.key;
                  final episodes = entry.value;
                  final isExpanded = _expandedSeries.contains(seriesKey);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _TvSeriesSeasonCard(
                      seriesKey: seriesKey,
                      episodes: episodes,
                      isExpanded: isExpanded,
                      onToggleExpand: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedSeries.remove(seriesKey);
                          } else {
                            _expandedSeries.add(seriesKey);
                          }
                        });
                      },
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceElevated,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.black : Colors.white70,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black.withValues(alpha: 0.15) : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.black : AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
        Text(
          subtitle,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
      ],
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
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB BUTTON
// ─────────────────────────────────────────────────────────────────────────────

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
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.18)
                      : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// IN PROGRESS CARD
// ─────────────────────────────────────────────────────────────────────────────

class _InProgressCard extends ConsumerWidget {
  final DownloadItem item;
  const _InProgressCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final notifier = ref.read(downloadManagerProvider.notifier);
    final percent = (item.progress * 100).toInt();

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
              // Poster Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: ApiConstants.imageUrl(item.posterPath, size: ApiConstants.posterSmall),
                  width: 54,
                  height: 76,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => Container(
                    width: 54,
                    height: 76,
                    color: AppColors.surface,
                    child: const Icon(Icons.movie, color: AppColors.textMuted),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title and details
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
                      item.isTv
                          ? 'S${item.seasonNumber} E${item.episodeNumber}${item.episodeTitle != null ? ' • ${item.episodeTitle}' : ''}'
                          : '${item.releaseYear} • ${item.resolution}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.speed,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${item.formattedDownloadedSize} / ${item.formattedTotalSize}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Cancel button
              IconButton(
                onPressed: () => notifier.cancelDownload(item.id),
                icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                tooltip: s.dialogCancel,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Progress Bar with Percentage
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: item.progress.clamp(0.0, 1.0),
                    backgroundColor: AppColors.surfaceElevated,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$percent%',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPLETED MOVIE CARD
// ─────────────────────────────────────────────────────────────────────────────

class _CompletedMovieCard extends ConsumerWidget {
  final DownloadItem item;
  const _CompletedMovieCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final notifier = ref.read(downloadManagerProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceElevated),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail with Play overlay
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _playOffline(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CachedNetworkImage(
                    imageUrl: ApiConstants.imageUrl(item.posterPath, size: ApiConstants.posterSmall),
                    width: 64,
                    height: 92,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Container(
                      width: 64,
                      height: 92,
                      color: AppColors.surface,
                      child: const Icon(Icons.movie, color: AppColors.textMuted),
                    ),
                  ),
                  Container(
                    width: 64,
                    height: 92,
                    color: Colors.black.withValues(alpha: 0.35),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 20),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Details
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
                  item.releaseYear.isNotEmpty ? 'Film • ${item.releaseYear}' : 'Film',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
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
                              'SUB ID',
                              style: GoogleFonts.jetBrainsMono(
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

          // Actions: Play & Delete
          Column(
            children: [
              IconButton(
                onPressed: () => _playOffline(context),
                icon: const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 28),
                tooltip: s.isIndonesian ? 'Putar' : 'Play',
              ),
              IconButton(
                onPressed: () => _showDeleteDialog(context, notifier, s),
                icon: const Icon(Iconsax.trash, size: 18, color: AppColors.textMuted),
                tooltip: s.dialogDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _playOffline(BuildContext context) {
    context.push('/player', extra: {
      'title': item.title,
      'episodeTitle': item.episodeTitle,
      'mediaType': item.mediaType,
      'season': item.seasonNumber,
      'episode': item.episodeNumber,
      'tmdbId': item.tmdbId,
      'posterPath': item.posterPath,
      'backdropPath': item.backdropPath,
      'localVideoPath': item.videoPath,
      'localSubtitlePath': item.subtitlePath,
      'magnetLink': '',
    });
  }

  void _showDeleteDialog(BuildContext context, DownloadNotifier notifier, AppStrings s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(s.isIndonesian ? 'Hapus Unduhan?' : 'Delete Download?', style: GoogleFonts.outfit(color: Colors.white)),
        content: Text(
          s.isIndonesian
              ? 'Film "${item.title}" akan dihapus dari penyimpanan perangkat Anda.'
              : '"${item.title}" will be deleted from your device storage.',
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.dialogCancel, style: const TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              notifier.deleteDownload(item.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(s.dialogDelete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TV SERIES SEASON CARD (GROUPED BY SHOW & SEASON)
// ─────────────────────────────────────────────────────────────────────────────

class _TvSeriesSeasonCard extends ConsumerWidget {
  final String seriesKey;
  final List<DownloadItem> episodes;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  const _TvSeriesSeasonCard({
    required this.seriesKey,
    required this.episodes,
    required this.isExpanded,
    required this.onToggleExpand,
  });

  String _formatBytes(int b) {
    if (b >= 1073741824) return '${(b / 1073741824).toStringAsFixed(2)} GB';
    if (b >= 1048576) return '${(b / 1048576).toStringAsFixed(1)} MB';
    if (b >= 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
    return '$b B';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appStrings = ref.watch(appStringsProvider);
    final first = episodes.first;
    final notifier = ref.read(downloadManagerProvider.notifier);

    // Group episodes by seasonNumber
    final seasonsMap = <int, List<DownloadItem>>{};
    int totalBytes = 0;
    for (final ep in episodes) {
      final s = ep.seasonNumber ?? 1;
      seasonsMap.putIfAbsent(s, () => []).add(ep);
      totalBytes += ep.downloadedBytes > 0 ? ep.downloadedBytes : ep.totalBytes;
    }

    // Sort seasons ascending and sort episodes inside each season ascending
    final sortedSeasonKeys = seasonsMap.keys.toList()..sort();
    for (final s in sortedSeasonKeys) {
      seasonsMap[s]!.sort((a, b) => (a.episodeNumber ?? 1).compareTo(b.episodeNumber ?? 1));
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded ? AppColors.primary.withValues(alpha: 0.5) : AppColors.surfaceElevated,
        ),
      ),
      child: Column(
        children: [
          // Header Card (Tap to Expand/Collapse)
          InkWell(
            onTap: onToggleExpand,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Poster Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: ApiConstants.imageUrl(first.posterPath, size: ApiConstants.posterSmall),
                      width: 58,
                      height: 84,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Container(
                        width: 58,
                        height: 84,
                        color: AppColors.surface,
                        child: const Icon(Icons.tv_rounded, color: AppColors.textMuted),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Series Title and Stats
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          first.title,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${sortedSeasonKeys.length} Season • ${episodes.length} Episode',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _formatBytes(totalBytes),
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isExpanded ? 'Tutup Daftar' : 'Buka Episode',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Expand Icon
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: isExpanded ? AppColors.primary : AppColors.textMuted,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Season-by-Season Episode List
          if (isExpanded) ...[
            const Divider(color: AppColors.surfaceElevated, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final seasonNum in sortedSeasonKeys) ...[
                    _buildSeasonHeader(
                      context,
                      seasonNum: seasonNum,
                      episodes: seasonsMap[seasonNum]!,
                      seriesTitle: first.title,
                      notifier: notifier,
                      s: appStrings,
                    ),
                    const SizedBox(height: 6),
                    for (final ep in seasonsMap[seasonNum]!) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _EpisodeCard(item: ep),
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSeasonHeader(
    BuildContext context, {
    required int seasonNum,
    required List<DownloadItem> episodes,
    required String seriesTitle,
    required DownloadNotifier notifier,
    required AppStrings s,
  }) {
    int seasonBytes = 0;
    for (final ep in episodes) {
      seasonBytes += ep.downloadedBytes > 0 ? ep.downloadedBytes : ep.totalBytes;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.video_library_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Season $seasonNum',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${episodes.length} Ep • ${_formatBytes(seasonBytes)})',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Iconsax.trash, size: 14, color: AppColors.textMuted),
            tooltip: s.isIndonesian ? 'Hapus Season $seasonNum' : 'Delete Season $seasonNum',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surfaceVariant,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Text(
                    s.isIndonesian ? 'Hapus Season $seasonNum?' : 'Delete Season $seasonNum?',
                    style: GoogleFonts.outfit(color: Colors.white),
                  ),
                  content: Text(
                    s.isIndonesian
                        ? 'Semua ${episodes.length} episode di Season $seasonNum ($seriesTitle) akan dihapus.'
                        : 'All ${episodes.length} episodes in Season $seasonNum ($seriesTitle) will be deleted.',
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(s.dialogCancel, style: const TextStyle(color: AppColors.textMuted)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        for (final ep in episodes) {
                          notifier.deleteDownload(ep.id);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      child: Text(s.isIndonesian ? 'Hapus Semua' : 'Delete All', style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EPISODE CARD (INSIDE A SEASON)
// ─────────────────────────────────────────────────────────────────────────────

class _EpisodeCard extends ConsumerWidget {
  final DownloadItem item;
  const _EpisodeCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final notifier = ref.read(downloadManagerProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceElevated.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          // Episode Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Eps ${item.episodeNumber ?? 1}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Title & Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.episodeTitle != null && item.episodeTitle!.isNotEmpty
                      ? item.episodeTitle!
                      : 'Episode ${item.episodeNumber ?? 1}',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${item.resolution} • ${item.formattedTotalSize}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (item.subtitlePath != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '• SUB ID',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Play Button
          IconButton(
            onPressed: () {
              context.push('/player', extra: {
                'title': item.title,
                'episodeTitle': item.episodeTitle,
                'mediaType': item.mediaType,
                'season': item.seasonNumber,
                'episode': item.episodeNumber,
                'tmdbId': item.tmdbId,
                'posterPath': item.posterPath,
                'backdropPath': item.backdropPath,
                'localVideoPath': item.videoPath,
                'localSubtitlePath': item.subtitlePath,
                'magnetLink': '',
              });
            },
            icon: const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 26),
            tooltip: s.isIndonesian ? 'Putar Episode' : 'Play Episode',
          ),

          // Delete Button
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Iconsax.trash, size: 16, color: AppColors.textMuted),
            tooltip: s.isIndonesian ? 'Hapus Episode' : 'Delete Episode',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surfaceVariant,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Text(
                    s.isIndonesian ? 'Hapus Episode?' : 'Delete Episode?',
                    style: GoogleFonts.outfit(color: Colors.white),
                  ),
                  content: Text(
                    s.isIndonesian
                        ? 'Episode ${item.episodeNumber ?? 1} (${item.title}) akan dihapus.'
                        : 'Episode ${item.episodeNumber ?? 1} (${item.title}) will be deleted.',
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(s.dialogCancel, style: const TextStyle(color: AppColors.textMuted)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        notifier.deleteDownload(item.id);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      child: Text(s.dialogDelete, style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
