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
    final moviesAsync = ref.watch(platformMoviesProvider(platform.providerId));
    final tvAsync = ref.watch(platformTvProvider(platform.providerId));

    final screenWidth = MediaQuery.sizeOf(context).width;
    final crossAxisCount = screenWidth < 340 ? 2 : 3;
    final childAspectRatio = screenWidth < 360 ? 0.52 : 0.55;
    final spacing = screenWidth < 360 ? 10.0 : 12.0;
    final bottomPadding = MediaQuery.of(context).padding.bottom + 32;

    return Scaffold(
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
                    onTap: () => context.pop(),
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
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: platform.brandColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: platform.brandColor.withValues(alpha: 0.5),
                        width: 1.0,
                      ),
                    ),
                    child: Icon(
                      platform.icon,
                      color: platform.brandColor,
                      size: 20,
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
                  ? _buildAllSections(
                      moviesAsync: moviesAsync,
                      tvAsync: tvAsync,
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: childAspectRatio,
                      spacing: spacing,
                      bottomPadding: bottomPadding,
                      s: s,
                      ref: ref,
                    )
                  : activeTab == 1
                      ? _buildMoviesGrid(
                          moviesAsync: moviesAsync,
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: childAspectRatio,
                          spacing: spacing,
                          bottomPadding: bottomPadding,
                          s: s,
                          ref: ref,
                        )
                      : _buildTvGrid(
                          tvAsync: tvAsync,
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
    );
  }

  Widget _buildAllSections({
    required AsyncValue<List<Movie>> moviesAsync,
    required AsyncValue<List<TvSeries>> tvAsync,
    required int crossAxisCount,
    required double childAspectRatio,
    required double spacing,
    required double bottomPadding,
    required dynamic s,
    required WidgetRef ref,
  }) {
    if (moviesAsync.isLoading && tvAsync.isLoading) {
      return const _CatalogShimmerGrid();
    }

    final movies = moviesAsync.valueOrNull ?? [];
    final tvShows = tvAsync.valueOrNull ?? [];

    if (movies.isEmpty && tvShows.isEmpty && !moviesAsync.isLoading && !tvAsync.isLoading) {
      return AppErrorWidget.empty(
        message: s.searchNoResults(platform.name),
      );
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Movies Section ──
        if (movies.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: Row(
                children: [
                  const Icon(Icons.movie_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    s.searchTabMovies,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${movies.length}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
        ],

        // ── Section Divider ──
        if (movies.isNotEmpty && tvShows.isNotEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(
                color: Colors.white10,
                height: 1,
                indent: 16,
                endIndent: 16,
              ),
            ),
          ),

        // ── TV Shows Section ──
        if (tvShows.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: Row(
                children: [
                  const Icon(Icons.tv_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    s.searchTabTv,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${tvShows.length}',
                      style: TextStyle(
                        color: Colors.blue.shade300,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
        ],

        SliverToBoxAdapter(
          child: SizedBox(height: bottomPadding),
        ),
      ],
    );
  }

  Widget _buildMoviesGrid({
    required AsyncValue<List<Movie>> moviesAsync,
    required int crossAxisCount,
    required double childAspectRatio,
    required double spacing,
    required double bottomPadding,
    required dynamic s,
    required WidgetRef ref,
  }) {
    return moviesAsync.when(
      data: (movies) {
        if (movies.isEmpty) {
          return AppErrorWidget.empty(message: s.searchNoMovies(platform.name));
        }
        return GridView.builder(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 6, 16, bottomPadding),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: movies.length,
          itemBuilder: (context, index) => _PlatformMovieCard(
            movie: movies[index],
            index: index,
          ),
        );
      },
      loading: () => const _CatalogShimmerGrid(),
      error: (e, _) => AppErrorWidget(
        message: s.searchFailed,
        onRetry: () => ref.invalidate(platformMoviesProvider(platform.providerId)),
      ),
    );
  }

  Widget _buildTvGrid({
    required AsyncValue<List<TvSeries>> tvAsync,
    required int crossAxisCount,
    required double childAspectRatio,
    required double spacing,
    required double bottomPadding,
    required dynamic s,
    required WidgetRef ref,
  }) {
    return tvAsync.when(
      data: (tvShows) {
        if (tvShows.isEmpty) {
          return AppErrorWidget.empty(message: s.searchNoTv(platform.name));
        }
        return GridView.builder(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 6, 16, bottomPadding),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: tvShows.length,
          itemBuilder: (context, index) => _PlatformTvCard(
            tv: tvShows[index],
            index: index,
          ),
        );
      },
      loading: () => const _CatalogShimmerGrid(),
      error: (e, _) => AppErrorWidget(
        message: s.searchFailed,
        onRetry: () => ref.invalidate(platformTvProvider(platform.providerId)),
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

/// Poster card representing a movie with 2:3 aspect ratio and metadata.
class _PlatformMovieCard extends StatelessWidget {
  final Movie movie;
  final int index;

  const _PlatformMovieCard({
    required this.movie,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/movie/${movie.id}'),
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
                      child: const Center(
                        child: Icon(Icons.movie_rounded, color: AppColors.textMuted, size: 22),
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
