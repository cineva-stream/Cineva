import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/watch_history_item.dart';
import '../../data/repositories/watch_history_repository.dart';

/// Full screen displaying user watch history with filters and quick playback resume.
class WatchHistoryScreen extends ConsumerStatefulWidget {
  const WatchHistoryScreen({super.key});

  @override
  ConsumerState<WatchHistoryScreen> createState() => _WatchHistoryScreenState();
}

class _WatchHistoryScreenState extends ConsumerState<WatchHistoryScreen> {
  String _activeFilter = 'all'; // 'all', 'in_progress', 'completed'

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays == 0) {
      return 'Hari ini, ${DateFormat('HH:mm').format(dt)}';
    } else if (diff.inDays == 1) {
      return 'Kemarin, ${DateFormat('HH:mm').format(dt)}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} hari yang lalu';
    }
    return DateFormat('d MMM yyyy').format(dt);
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus Semua Riwayat?',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Semua catatan tontonan dan titik akhir pemutaran akan dihapus secara permanen.',
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.inter(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(watchHistoryProvider.notifier).clearAll();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.surfaceElevated,
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'Riwayat tontonan berhasil dibersihkan',
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allHistory = ref.watch(watchHistoryProvider);

    final filteredList = allHistory.where((item) {
      if (_activeFilter == 'in_progress') return item.isInProgress;
      if (_activeFilter == 'completed') return item.isCompleted;
      return true;
    }).toList();

    final inProgressCount = allHistory.where((item) => item.isInProgress).length;
    final completedCount = allHistory.where((item) => item.isCompleted).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top App Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceVariant,
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 3.5,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Riwayat Tontonan',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  if (allHistory.isNotEmpty)
                    IconButton(
                      onPressed: _confirmClearAll,
                      icon: const Icon(Iconsax.trash, color: AppColors.textMuted, size: 20),
                      tooltip: 'Hapus Semua',
                    ),
                ],
              ),
            ),

            // ── Filter Chips ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildFilterChip('all', 'Semua (${allHistory.length})'),
                  const SizedBox(width: 8),
                  _buildFilterChip('in_progress', 'Sedang Ditonton ($inProgressCount)'),
                  const SizedBox(width: 8),
                  _buildFilterChip('completed', 'Selesai ($completedCount)'),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── History List or Empty State ──
            Expanded(
              child: filteredList.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 84),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final item = filteredList[index];
                        return _buildHistoryTile(item);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _activeFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.black : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTile(WatchHistoryItem item) {
    final imagePath = item.backdropPath ?? item.posterPath;
    final imageUrl = imagePath != null ? 'https://image.tmdb.org/t/p/w780$imagePath' : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 0.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await context.push('/player', extra: {
              'title': item.title,
              'episodeTitle': item.episodeTitle,
              'imdbId': item.imdbId,
              'season': item.season,
              'episode': item.episode,
              'tmdbId': item.id,
              'mediaType': item.mediaType,
              'posterPath': item.posterPath,
              'backdropPath': item.backdropPath,
              'initialPositionMs': item.positionMs,
              'magnetLink': '',
            });
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ]);
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // ── Thumbnail with Progress Bar ──
                SizedBox(
                  width: 120,
                  height: 72,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (imageUrl != null)
                          CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            memCacheWidth: 240,
                            placeholder: (_, _) => Container(color: AppColors.surfaceVariant),
                            errorWidget: (_, _, _) => Container(
                              color: AppColors.surfaceVariant,
                              child: const Icon(Icons.movie_rounded, color: AppColors.textMuted),
                            ),
                          )
                        else
                          Container(
                            color: AppColors.surfaceVariant,
                            child: const Icon(Icons.movie_rounded, color: AppColors.textMuted),
                          ),

                        // Dark vignette
                        Container(
                          color: Colors.black.withValues(alpha: 0.35),
                        ),

                        // Mini Play Halo
                        Center(
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 18),
                          ),
                        ),

                        // Bottom Progress Bar
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            height: 3,
                            color: Colors.white.withValues(alpha: 0.2),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: item.progress,
                              child: Container(color: AppColors.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // ── Info Details ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      if (item.episodeTitle != null) ...[
                        Text(
                          item.episodeTitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: AppColors.primaryLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                      ],
                      Row(
                        children: [
                          Icon(
                            item.isCompleted ? Icons.check_circle_rounded : Icons.schedule_rounded,
                            size: 13,
                            color: item.isCompleted ? AppColors.success : AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.isCompleted ? 'Selesai ditonton' : item.positionTimestamp,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: item.isCompleted ? AppColors.success : AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(item.lastWatchedAt),
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Delete Button ──
                IconButton(
                  onPressed: () {
                    ref.read(watchHistoryProvider.notifier).removeItem(item.key);
                  },
                  icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                  tooltip: 'Hapus dari riwayat',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              child: const Icon(Iconsax.clock, color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 18),
            Text(
              'Belum Ada Riwayat Tontonan',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Film dan serial yang Anda putar akan otomatis tercatat di sini sehingga Anda dapat melanjutkannya kapan saja.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 20),
              label: Text(
                'Jelajahi Film',
                style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
