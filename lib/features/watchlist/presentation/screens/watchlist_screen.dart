import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../data/watchlist_repository.dart';

/// Watchlist screen displaying saved movies and TV series from Hive.
class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final items = ref.watch(watchlistProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    tooltip: 'Kembali',
                  ),
                  const SizedBox(width: 4),
                  Text(s.watchlistTitle, style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(width: 8),
                  if (items.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${items.length}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Content ──
            Expanded(
              child: items.isEmpty ? const _EmptyState() : _WatchlistGrid(items: items),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state widget shown when no items in watchlist.
class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bookmark_border_rounded, size: 48, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            Text(
              s.watchlistEmptyTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s.watchlistEmptyDesc,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => GoRouter.of(context).go('/search'),
              icon: const Icon(Icons.search_rounded, size: 18),
              label: Text(s.watchlistExploreButton),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms),
      ),
    );
  }
}

/// Full-width list of watchlist items with subtle divider borders (no card container).
class _WatchlistGrid extends ConsumerWidget {
  final List<WatchlistItem> items;
  const _WatchlistGrid({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom + 100;

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(0, 0, 0, bottomPadding),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Dismissible(
          key: ValueKey('${item.type}_${item.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.25),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 0.8,
                ),
              ),
            ),
            child: const Icon(Iconsax.trash, color: AppColors.error, size: 22),
          ),
          onDismissed: (_) {
            ref.read(watchlistProvider.notifier).remove(item.id, item.type);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(s.watchlistRemoved(item.title)),
                backgroundColor: AppColors.surfaceVariant,
                action: SnackBarAction(
                  label: s.watchlistUndo,
                  textColor: AppColors.primary,
                  onPressed: () {
                    ref.read(watchlistProvider.notifier).toggle(item);
                  },
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 0.8,
                ),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  final route = item.type == 'tv' ? '/tv/${item.id}' : '/movie/${item.id}';
                  context.push(route);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Poster
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: item.posterPath != null
                            ? CachedNetworkImage(
                                imageUrl: ApiConstants.imageUrl(item.posterPath!),
                                width: 65,
                                height: 95,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 65,
                                height: 95,
                                color: AppColors.surfaceElevated,
                                child: const Icon(Iconsax.video_play, color: AppColors.textMuted),
                              ),
                      ),
                      const SizedBox(width: 14),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: item.type == 'tv'
                                        ? AppColors.info.withValues(alpha: 0.15)
                                        : AppColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.type == 'tv' ? 'TV Series' : (s.isIndonesian ? 'Film' : 'Movie'),
                                    style: TextStyle(
                                      color: item.type == 'tv' ? AppColors.info : AppColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(Iconsax.star_1, size: 14, color: AppColors.star),
                                const SizedBox(width: 4),
                                Text(
                                  item.voteAverage.toStringAsFixed(1),
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s.watchlistAddedDate(_formatDate(item.addedAt)),
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),

                      // Arrow
                      const Icon(Iconsax.arrow_right_3, size: 18, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.05, end: 0),
        );
      },
    );
  }

  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
    if (diff.inDays < 1) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${date.day}/${date.month}/${date.year}';
  }
}
