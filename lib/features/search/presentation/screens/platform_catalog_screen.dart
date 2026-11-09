import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../home/domain/entities/movie.dart';
import '../../../home/domain/entities/tv_series.dart';
import '../../domain/entities/streaming_platform.dart';
import '../providers/platform_catalog_provider.dart';

/// Full-screen responsive catalog showcasing movies and TV series
/// belonging to a specific streaming platform (e.g. Netflix, Prime Video, Disney+).
/// Features pure smooth black theme, elegant brand headers, and 2:3 poster grid layouts.
class PlatformCatalogScreen extends ConsumerWidget {
  final StreamingPlatform platform;

  const PlatformCatalogScreen({
    super.key,
    required this.platform,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final activeTab = ref.watch(platformTabProvider);
    final moviesState = ref.watch(paginatedPlatformMoviesProvider(platform.watchProviderQuery));
    final tvState = ref.watch(paginatedPlatformTvProvider(platform.watchProviderQuery));

    final screenWidth = MediaQuery.sizeOf(context).width;
    final crossAxisCount = screenWidth < 340 ? 2 : 3;
    final childAspectRatio = screenWidth < 360 ? 0.52 : 0.55;
    final spacing = screenWidth < 360 ? 10.0 : 12.0;
    final bottomPadding = MediaQuery.of(context).padding.bottom + 84;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/search');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── 1. Brand Header with Back Button ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/search');
                        }
                      },
                      child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 0.8,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    width: 42,
                    height: 42,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      platform.logoAsset,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Icon(
                        platform.icon,
                        color: platform.brandColor,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          platform.name,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          platform.tagline,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── 2. Filter Chips: All, Movies, TV Shows ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _CatalogFilterChip(
                      label: s.searchTabAll,
                      isSelected: activeTab == 0,
                      activeColor: platform.brandColor,
                      onTap: () => ref.read(platformTabProvider.notifier).state = 0,
                    ),
                    const SizedBox(width: 8),
                    _CatalogFilterChip(
                      label: s.searchTabMovies,
                      isSelected: activeTab == 1,
                      activeColor: platform.brandColor,
                      onTap: () => ref.read(platformTabProvider.notifier).state = 1,
                    ),
                    const SizedBox(width: 8),
                    _CatalogFilterChip(
                      label: s.searchTabTv,
                      isSelected: activeTab == 2,
                      activeColor: platform.brandColor,
                      onTap: () => ref.read(platformTabProvider.notifier).state = 2,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── 3. Catalog Content ──
            Expanded(
              child: activeTab == 0
                  ? _buildAllGrid(
                      moviesState: moviesState,
                      tvState: tvState,
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: childAspectRatio,
                      spacing: spacing,
                      bottomPadding: bottomPadding,
                      s: s,
                      ref: ref,
                    )
                  : activeTab == 1
                      ? _buildMoviesGrid(
                          moviesState: moviesState,
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: childAspectRatio,
                          spacing: spacing,
                          bottomPadding: bottomPadding,
                          s: s,
                          ref: ref,
                        )
                      : _buildTvGrid(
                          tvState: tvState,
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: childAspectRatio,
                          spacing: spacing,
                          bottomPadding: bottomPadding,
                          s: s,
                          ref: ref,
                        ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildAllGrid({
    required PaginatedPlatformState<Movie> moviesState,
    required PaginatedPlatformState<TvSeries> tvState,
    required int crossAxisCount,
    required double childAspectRatio,
    required double spacing,
    required double bottomPadding,
    required dynamic s,
    required WidgetRef ref,
  }) {
    if (moviesState.isLoading && tvState.isLoading && moviesState.items.isEmpty && tvState.items.isEmpty) {
      return const _CatalogShimmerGrid();
    }

    if (moviesState.error != null && tvState.error != null && moviesState.items.isEmpty && tvState.items.isEmpty) {
      return AppErrorWidget(
        message: s.searchFailed,
        onRetry: () {
          ref.read(paginatedPlatformMoviesProvider(platform.watchProviderQuery).notifier).refresh();
          ref.read(paginatedPlatformTvProvider(platform.watchProviderQuery).notifier).refresh();
        },
      );
    }

    final movies = moviesState.items;
    final tvShows = tvState.items;

    if (movies.isEmpty && tvShows.isEmpty && !moviesState.isLoading && !tvState.isLoading) {
      return AppErrorWidget.empty(
        message: s.searchNoResults(platform.name),
      );
    }

    // Merge movies and TV series into a single unified stream, ordered by popularity
    final allMedia = <Movie>[
      ...movies,
      ...tvShows.map((t) => t.toMovie()),
    ];
    allMedia.sort((a, b) => b.popularity.compareTo(a.popularity));

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 400) {
          ref.read(paginatedPlatformMoviesProvider(platform.watchProviderQuery).notifier).loadMore();
          ref.read(paginatedPlatformTvProvider(platform.watchProviderQuery).notifier).loadMore();
        }
        return false;
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _PlatformMovieCard(
                  movie: allMedia[index],
                  index: index,
                  showTypeBadge: true,
                ),
                childCount: allMedia.length,
              ),
            ),
          ),
          if (moviesState.isLoadingMore || tvState.isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: SizedBox(height: bottomPadding),
          ),
        ],
      ),
    );
  }

  Widget _buildMoviesGrid({
    required PaginatedPlatformState<Movie> moviesState,
    required int crossAxisCount,
    required double childAspectRatio,
    required double spacing,
    required double bottomPadding,
    required dynamic s,
    required WidgetRef ref,
  }) {
    if (moviesState.isLoading && moviesState.items.isEmpty) {
      return const _CatalogShimmerGrid();
    }

    if (moviesState.error != null && moviesState.items.isEmpty) {
      return AppErrorWidget(
        message: s.searchFailed,
        onRetry: () => ref.read(paginatedPlatformMoviesProvider(platform.watchProviderQuery).notifier).refresh(),
      );
    }

    final movies = moviesState.items;
    if (movies.isEmpty) {
      return AppErrorWidget.empty(message: s.searchNoMovies(platform.name));
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 400) {
          ref.read(paginatedPlatformMoviesProvider(platform.watchProviderQuery).notifier).loadMore();
        }
        return false;
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _PlatformMovieCard(
                  movie: movies[index],
                  index: index,
                ),
                childCount: movies.length,
              ),
            ),
          ),
          if (moviesState.isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: SizedBox(height: bottomPadding),
          ),
        ],
      ),
    );
  }

  Widget _buildTvGrid({
    required PaginatedPlatformState<TvSeries> tvState,
    required int crossAxisCount,
    required double childAspectRatio,
    required double spacing,
    required double bottomPadding,
    required dynamic s,
    required WidgetRef ref,
  }) {
    if (tvState.isLoading && tvState.items.isEmpty) {
      return const _CatalogShimmerGrid();
    }

    if (tvState.error != null && tvState.items.isEmpty) {
      return AppErrorWidget(
        message: s.searchFailed,
        onRetry: () => ref.read(paginatedPlatformTvProvider(platform.watchProviderQuery).notifier).refresh(),
      );
    }

    final tvShows = tvState.items;
    if (tvShows.isEmpty) {
      return AppErrorWidget.empty(message: s.searchNoTv(platform.name));
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 400) {
          ref.read(paginatedPlatformTvProvider(platform.watchProviderQuery).notifier).loadMore();
        }
        return false;
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _PlatformTvCard(
                  tv: tvShows[index],
                  index: index,
                ),
                childCount: tvShows.length,
              ),
            ),
          ),
          if (tvState.isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: SizedBox(height: bottomPadding),
          ),
        ],
      ),
    );
  }
}

class _CatalogFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _CatalogFilterChip({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Poster card representing a movie or unified media item with 2:3 aspect ratio and metadata.
class _PlatformMovieCard extends ConsumerWidget {
  final Movie movie;
  final int index;
  final bool showTypeBadge;

  const _PlatformMovieCard({
    required this.movie,
    required this.index,
    this.showTypeBadge = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final isTv = movie.mediaType == 'tv';

    return GestureDetector(
      onTap: () => context.push(isTv ? '/tv/${movie.id}' : '/movie/${movie.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: ApiConstants.imageUrl(movie.posterPath),
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.surfaceVariant,
                      child: Center(
                        child: Icon(
                          isTv ? Icons.tv_rounded : Icons.movie_rounded,
                          color: AppColors.textMuted,
                          size: 22,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.surfaceVariant,
                      child: const Center(
                        child: Icon(Icons.broken_image_rounded, color: AppColors.textMuted, size: 24),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 0.8,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  if (showTypeBadge)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isTv ? Colors.blue.shade700 : AppColors.primary).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          isTv ? 'TV' : s.searchBadgeMovie,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            movie.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.star, size: 12, color: AppColors.star),
              const SizedBox(width: 3),
              Text(
                movie.voteAverage.toStringAsFixed(1),
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              if (movie.year.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  movie.year,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (25 * index).ms, duration: 250.ms);
  }
}

/// Poster card representing a TV series with 2:3 aspect ratio and metadata.
class _PlatformTvCard extends StatelessWidget {
  final TvSeries tv;
  final int index;

  const _PlatformTvCard({
    required this.tv,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/tv/${tv.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: ApiConstants.imageUrl(tv.posterPath),
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.surfaceVariant,
                      child: const Center(
                        child: Icon(Icons.tv_rounded, color: AppColors.textMuted, size: 22),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.surfaceVariant,
                      child: const Center(
                        child: Icon(Icons.broken_image_rounded, color: AppColors.textMuted, size: 24),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 0.8,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tv.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.star, size: 12, color: AppColors.star),
              const SizedBox(width: 3),
              Text(
                tv.voteAverage.toStringAsFixed(1),
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              if (tv.year.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  tv.year,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (25 * index).ms, duration: 250.ms);
  }
}

class _CatalogShimmerGrid extends StatelessWidget {
  const _CatalogShimmerGrid();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final crossAxisCount = screenWidth < 340 ? 2 : 3;
    final childAspectRatio = screenWidth < 360 ? 0.52 : 0.55;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 9,
      itemBuilder: (context, index) => const ShimmerLoading(
        width: double.infinity,
        height: double.infinity,
        borderRadius: 10,
      ),
    );
  }
}
