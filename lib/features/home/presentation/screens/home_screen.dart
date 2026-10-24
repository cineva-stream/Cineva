import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/content_preference.dart';
import '../../../../core/constants/genre_constants.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../providers/home_providers.dart';
import '../widgets/movie_carousel.dart';
import '../widgets/movie_card.dart';
import '../widgets/section_header.dart';
import '../../domain/entities/movie.dart';
import '../../domain/entities/tv_series.dart';
import '../../../history/presentation/widgets/continue_watching_section.dart';
import '../../../download/presentation/providers/download_provider.dart';
import '../widgets/genre_selection_bottom_sheet.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/app_language_provider.dart';

/// Active category filter on the Home Screen.
enum HomeCategoryFilter {
  all('Semua', Icons.auto_awesome_rounded),
  movies('Film', Icons.movie_outlined),
  tv('Serial TV', Icons.tv_rounded);

  final String label;
  final IconData icon;
  const HomeCategoryFilter(this.label, this.icon);

  String localizedLabel(AppStrings s) {
    switch (this) {
      case HomeCategoryFilter.all:
        return s.homeAllCategory;
      case HomeCategoryFilter.movies:
        return s.isIndonesian ? 'Film' : 'Movies';
      case HomeCategoryFilter.tv:
        return s.isIndonesian ? 'Serial TV' : 'TV Shows';
    }
  }
}

final homeFilterProvider = StateProvider<HomeCategoryFilter>((ref) => HomeCategoryFilter.all);

/// Modern, informative Home Screen inspired by elite streaming platforms (Apple TV+, Netflix, HBO Max).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final activeFilter = ref.watch(homeFilterProvider);
    final activeGenre = ref.watch(selectedHomeGenreProvider);
    final pref = ref.watch(contentPreferenceProvider);
    final trending = ref.watch(trendingMoviesProvider);
    final popular = ref.watch(popularMoviesProvider);
    final topRated = ref.watch(topRatedMoviesProvider);
    final upcoming = ref.watch(upcomingMoviesProvider);
    final popularTv = ref.watch(popularTvProvider);

    List<Movie> filterMovies(List<Movie> list) {
      if (activeGenre.id == 'all') return list;
      return list.where((m) => activeGenre.matchesMovie(m)).toList();
    }

    List<TvSeries> filterTv(List<TvSeries> list) {
      if (activeGenre.id == 'all') return list;
      return list.where((t) => activeGenre.matchesTv(t)).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Modern Floating / Pinned App Bar ──
          SliverAppBar(
            floating: true,
            pinned: false,
            snap: true,
            backgroundColor: AppColors.background.withValues(alpha: 0.95),
            elevation: 0,
            scrolledUnderElevation: 0,
            titleSpacing: 16,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CINEVA',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3.0,
                    color: Colors.white,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 3, top: 4),
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            actions: [
              Consumer(
                builder: (context, ref, _) {
                  final activeCount = ref.watch(activeDownloadsCountProvider);
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        onPressed: () => context.push('/downloads'),
                        icon: const Icon(Icons.download_rounded, color: AppColors.textPrimary, size: 22),
                        tooltip: s.navDownloads,
                      ),
                      if (activeCount > 0)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              IconButton(
                onPressed: () => context.go('/watchlist'),
                icon: const Icon(Icons.bookmark_border_rounded, color: AppColors.textPrimary, size: 22),
                tooltip: 'Daftar Tontonan',
              ),
              const SizedBox(width: 8),
            ],
          ),

          // ── Category Filter Pills Row ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    if (pref != ContentPreference.all)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => context.go('/settings'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primary,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(pref.icon, size: 14, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text(
                                  pref.label,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ...HomeCategoryFilter.values.map((filter) {
                    final isSelected = activeFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          ref.read(homeFilterProvider.notifier).state = filter;
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.white.withValues(alpha: 0.08),
                              width: 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                filter.icon,
                                size: 14,
                                color: isSelected ? Colors.black : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                filter.localizedLabel(s),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? Colors.black : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  // ── Integrated Genre Filter Chip (Tapping opens Bottom Sheet) ──
                  Builder(
                    builder: (context) {
                      final isGenreActive = activeGenre.id != 'all';
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => GenreSelectionBottomSheet.show(context),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isGenreActive ? AppColors.primary : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isGenreActive
                                    ? AppColors.primary
                                    : Colors.white.withValues(alpha: 0.08),
                                width: 1,
                              ),
                              boxShadow: isGenreActive
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isGenreActive ? (activeGenre.icon ?? Icons.tune_rounded) : Icons.tune_rounded,
                                  size: 14,
                                  color: isGenreActive ? Colors.black : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isGenreActive ? activeGenre.getLocalizedLabel(s.isIndonesian) : 'Genre',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: isGenreActive ? FontWeight.w700 : FontWeight.w500,
                                    color: isGenreActive ? Colors.black : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                if (isGenreActive)
                                  GestureDetector(
                                    onTap: () {
                                      ref.read(selectedHomeGenreProvider.notifier).state =
                                          GenreConstants.filters.first;
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.only(left: 2),
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                  )
                                else
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 16,
                                    color: AppColors.textSecondary,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          ),

          // ── Hero Billboard Carousel (Trending) ──
          if (activeFilter == HomeCategoryFilter.all ||
              activeFilter == HomeCategoryFilter.movies)
            SliverToBoxAdapter(
              child: trending.when(
                data: (movies) {
                  final filtered = filterMovies(movies);
                  if (filtered.isEmpty) return const SizedBox.shrink();
                  return MovieCarousel(movies: filtered)
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.04, end: 0, duration: 500.ms);
                },
                loading: () => const ShimmerHeroCarousel(),
                error: (e, _) => AppErrorWidget(
                  message: s.isIndonesian ? 'Gagal memuat film trending' : 'Failed to load trending movies',
                  onRetry: () => ref.invalidate(trendingMoviesProvider),
                ),
              ),
            ),

          // ── CONTINUE WATCHING SECTION (In-Progress Movies & TV Series) ──
          if (activeGenre.id == 'all' &&
              (activeFilter == HomeCategoryFilter.all ||
                  activeFilter == HomeCategoryFilter.movies ||
                  activeFilter == HomeCategoryFilter.tv))
            const SliverToBoxAdapter(
              child: ContinueWatchingSection(),
            ),

          if (activeFilter == HomeCategoryFilter.all ||
              activeFilter == HomeCategoryFilter.movies)
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── TOP 10 SECTION (Netflix-style Giant Rank Numbers) ──
          if (activeFilter == HomeCategoryFilter.all ||
              activeFilter == HomeCategoryFilter.movies)
            SliverToBoxAdapter(
              child: _SectionWithHeader<Movie>(
                title: s.homeTop10,
                icon: Iconsax.crown,
                asyncData: popular,
                filter: filterMovies,
                onRetry: () => ref.invalidate(popularMoviesProvider),
                onSeeAll: () => context.go('/search'),
                builder: (movies) => _Top10HorizontalList(movies: movies),
              ),
            ),

          // ── POPULAR MOVIES SECTION ──
          if (activeFilter == HomeCategoryFilter.all ||
              activeFilter == HomeCategoryFilter.movies)
            SliverToBoxAdapter(
              child: _SectionWithHeader<Movie>(
                title: s.homePopularMovies,
                icon: Iconsax.trend_up,
                asyncData: popular,
                filter: filterMovies,
                onRetry: () => ref.invalidate(popularMoviesProvider),
                onSeeAll: () => context.go('/search'),
                builder: (movies) => _MovieHorizontalList(movies: movies),
              ),
            ),

          // ── POPULAR TV SERIES SECTION ──
          if (activeFilter == HomeCategoryFilter.all ||
              activeFilter == HomeCategoryFilter.tv)
            SliverToBoxAdapter(
              child: _SectionWithHeader<TvSeries>(
                title: s.homePopularTv,
                icon: Iconsax.monitor,
                asyncData: popularTv,
                filter: filterTv,
                onRetry: () => ref.invalidate(popularTvProvider),
                onSeeAll: () => context.go('/search'),
                builder: (tvShows) => _TvHorizontalList(tvShows: tvShows),
              ),
            ),

          // ── TOP RATED MOVIES SECTION ──
          if (activeFilter == HomeCategoryFilter.all ||
              activeFilter == HomeCategoryFilter.movies)
            SliverToBoxAdapter(
              child: _SectionWithHeader<Movie>(
                title: s.isIndonesian ? 'Rating Tertinggi' : 'Top Rated',
                icon: Iconsax.star_1,
                asyncData: topRated,
                filter: filterMovies,
                onRetry: () => ref.invalidate(topRatedMoviesProvider),
                onSeeAll: () => context.go('/search'),
                builder: (movies) => _MovieHorizontalList(movies: movies),
              ),
            ),

          // ── UPCOMING MOVIES SECTION ──
          if (activeFilter == HomeCategoryFilter.all ||
              activeFilter == HomeCategoryFilter.movies)
            SliverToBoxAdapter(
              child: _SectionWithHeader<Movie>(
                title: s.isIndonesian ? 'Segera Tayang di Bioskop' : 'Coming Soon in Theaters',
                icon: Iconsax.calendar,
                asyncData: upcoming,
                filter: filterMovies,
                onRetry: () => ref.invalidate(upcomingMoviesProvider),
                onSeeAll: () => context.go('/search'),
                builder: (movies) => _MovieHorizontalList(movies: movies),
              ),
            ),

          // ── Empty State if No Media matches Selected Genre ──
          if (activeGenre.id != 'all')
            Builder(
              builder: (context) {
                final hasTrending = filterMovies(trending.valueOrNull ?? []).isNotEmpty;
                final hasPopular = filterMovies(popular.valueOrNull ?? []).isNotEmpty;
                final hasTopRated = filterMovies(topRated.valueOrNull ?? []).isNotEmpty;
                final hasUpcoming = filterMovies(upcoming.valueOrNull ?? []).isNotEmpty;
                final hasTv = filterTv(popularTv.valueOrNull ?? []).isNotEmpty;

                final anyLoaded = popular.hasValue || trending.hasValue;
                final noneMatches = anyLoaded &&
                    !hasTrending &&
                    !hasPopular &&
                    !hasTopRated &&
                    !hasUpcoming &&
                    !hasTv;

                if (!noneMatches) return const SliverToBoxAdapter(child: SizedBox.shrink());

                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              genreIcon(activeGenre),
                              size: 40,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            s.isIndonesian
                                ? 'Belum Ada Tayangan Genre ${activeGenre.label}'
                                : 'No Content in ${activeGenre.getLocalizedLabel(false)}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            s.isIndonesian
                                ? 'Coba pilih genre lain atau atur ulang ke Semua Genre.'
                                : 'Try picking another genre or reset to All Genres.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () {
                              ref.read(selectedHomeGenreProvider.notifier).state =
                                  GenreConstants.filters.first;
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: Text(s.isIndonesian ? 'Tampilkan Semua Genre' : 'Show All Genres'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

          // Clean spacing for bottom navigation bar
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.bottom + 48),
          ),
        ],
      ),
    );
  }
}

/// Netflix-style horizontal row displaying Top 10 titles with rank numbers.
class _Top10HorizontalList extends StatelessWidget {
  final List<Movie> movies;
  const _Top10HorizontalList({required this.movies});

  @override
  Widget build(BuildContext context) {
    final top10 = movies.take(10).toList();

    return RepaintBoundary(
      child: SizedBox(
        height: 215,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: top10.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            return Top10MovieCard(
              movie: top10[index],
              rank: index + 1,
            )
                .animate()
                .fadeIn(delay: (40 * index).ms, duration: 350.ms)
                .slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
          },
        ),
      ),
    );
  }
}

/// Horizontal scrollable list of movie cards.
class _MovieHorizontalList extends StatelessWidget {
  final List<Movie> movies;
  const _MovieHorizontalList({required this.movies});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: 215,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: movies.length,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            return MovieCard(movie: movies[index])
                .animate()
                .fadeIn(delay: (40 * index).ms, duration: 350.ms)
                .slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
          },
        ),
      ),
    );
  }
}

/// Horizontal scrollable list of TV series cards.
class _TvHorizontalList extends StatelessWidget {
  final List<TvSeries> tvShows;
  const _TvHorizontalList({required this.tvShows});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: 215,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: tvShows.length,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final tv = tvShows[index];
            final adapted = Movie(
              id: tv.id,
              title: tv.name,
              overview: tv.overview,
              posterPath: tv.posterPath,
              backdropPath: tv.backdropPath,
              voteAverage: tv.voteAverage,
              releaseDate: tv.firstAirDate,
              genreIds: tv.genreIds,
              originalLanguage: tv.originalLanguage,
              originCountry: tv.originCountry,
            );
            return MovieCard(movie: adapted)
                .animate()
                .fadeIn(delay: (40 * index).ms, duration: 350.ms)
                .slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
          },
        ),
      ),
    );
  }
}

IconData genreIcon(GenreFilter genre) {
  return genre.icon ?? Iconsax.video_circle;
}

/// Generic helper to render a home section with SectionHeader and list only if not empty.
class _SectionWithHeader<T> extends StatelessWidget {
  final String title;
  final IconData icon;
  final AsyncValue<List<T>> asyncData;
  final Widget Function(List<T> filtered) builder;
  final VoidCallback onRetry;
  final VoidCallback onSeeAll;
  final List<T> Function(List<T>) filter;

  const _SectionWithHeader({
    required this.title,
    required this.icon,
    required this.asyncData,
    required this.builder,
    required this.onRetry,
    required this.onSeeAll,
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    return asyncData.when(
      data: (items) {
        final filtered = filter(items);
        if (filtered.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SectionHeader(
              title: title,
              icon: icon,
              onSeeAll: onSeeAll,
            ),
            const SizedBox(height: 12),
            builder(filtered),
            const SizedBox(height: 32),
          ],
        );
      },
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SectionHeader(title: title, icon: icon, onSeeAll: onSeeAll),
          const SizedBox(height: 12),
          const ShimmerMovieRow(),
          const SizedBox(height: 32),
        ],
      ),
      error: (e, _) => AppErrorWidget(
        message: 'Gagal memuat $title',
        onRetry: onRetry,
      ),
    );
  }
}
