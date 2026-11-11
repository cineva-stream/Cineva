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
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../profile/presentation/widgets/avatar_display.dart';
import '../../../updater/presentation/widgets/in_app_update_banner.dart';
import '../widgets/airing_calendar_banner.dart';
import '../../../search/presentation/screens/search_screen.dart';
import '../../../../core/platform/device_form_factor.dart';
import '../../../../shared/widgets/tv_focusable.dart';

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

final homeFilterProvider = StateProvider<HomeCategoryFilter>(
  (ref) => HomeCategoryFilter.all,
);

/// Modern, informative Home Screen inspired by elite streaming platforms (Apple TV+, Netflix, HBO Max).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ensure search state is reset when user lands on Beranda
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(searchQueryProvider).isNotEmpty) {
        resetSearchState(ref);
      }
    });

    final s = ref.watch(appStringsProvider);
    final isTv = ref.watch(isTvProvider);
    final isWide = isWideScreenLayout(context, isTv: isTv);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final availableWidth = isWide
        ? (screenWidth - (isTv ? 96.0 : 88.0))
        : screenWidth;
    final showCompanionSideBySide = isWide && screenWidth >= 920;
    final isSuperWide = screenWidth >= 1380;

    final activeFilter = ref.watch(homeFilterProvider);
    final activeGenre = ref.watch(selectedHomeGenreProvider);
    final pref = ref.watch(contentPreferenceProvider);
    final trending = ref.watch(trendingMoviesProvider);
    final popular = ref.watch(popularMoviesProvider);
    final topRated = ref.watch(topRatedMoviesProvider);
    final upcoming = ref.watch(upcomingMoviesProvider);
    final popularTv = ref.watch(popularTvProvider);
    final paginatedMoviesState = ref.watch(paginatedPopularMoviesProvider);
    final paginatedTvState = ref.watch(paginatedPopularTvProvider);

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
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (scrollInfo.metrics.pixels >=
              scrollInfo.metrics.maxScrollExtent - 400) {
            if (activeFilter == HomeCategoryFilter.movies) {
              ref.read(paginatedPopularMoviesProvider.notifier).loadMore();
            } else if (activeFilter == HomeCategoryFilter.tv) {
              ref.read(paginatedPopularTvProvider.notifier).loadMore();
            }
          }
          return false;
        },
        child: CustomScrollView(
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
                    style: GoogleFonts.plusJakartaSans(
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
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: TvFocusable(
                        focusedScale: 1.08,
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => context.push('/downloads'),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.download_rounded,
                                color: AppColors.textPrimary,
                                size: 22,
                              ),
                            ),
                            if (activeCount > 0)
                              Positioned(
                                top: 6,
                                right: 6,
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
                        ),
                      ),
                    );
                  },
                ),
                if (!isWide)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: TvFocusable(
                      focusedScale: 1.08,
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => context.go('/watchlist'),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.bookmark_border_rounded,
                          color: AppColors.textPrimary,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                Consumer(
                  builder: (context, ref, _) {
                    final profile = ref.watch(userProfileProvider);
                    return Padding(
                      padding: const EdgeInsets.only(right: 14, left: 6),
                      child: TvFocusable(
                        focusedScale: 1.08,
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => context.go('/settings'),
                        child: AvatarDisplay(
                          avatarId: profile.avatarId,
                          customAvatarPath: profile.customAvatarPath,
                          size: 32,
                          borderWidth: 1.5,
                          borderColor: AppColors.primary,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            // ── Category Filter Pills Row ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      if (pref != ContentPreference.all)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: TvFocusable(
                            focusedScale: 1.05,
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => context.go('/settings'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    pref.icon,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
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
                          child: TvFocusable(
                            focusedScale: 1.05,
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              ref.read(homeFilterProvider.notifier).state =
                                  filter;
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.surfaceVariant,
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
                                          color: AppColors.primary.withValues(
                                            alpha: 0.35,
                                          ),
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
                                    color: isSelected
                                        ? Colors.black
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    filter.localizedLabel(s),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.black
                                          : AppColors.textPrimary,
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
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(
                                  right: isGenreActive ? 4 : 8,
                                ),
                                child: TvFocusable(
                                  focusedScale: 1.05,
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () =>
                                      GenreSelectionBottomSheet.show(context),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeOutCubic,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isGenreActive
                                          ? AppColors.primary
                                          : AppColors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isGenreActive
                                            ? AppColors.primary
                                            : Colors.white.withValues(
                                                alpha: 0.08,
                                              ),
                                        width: 1,
                                      ),
                                      boxShadow: isGenreActive
                                          ? [
                                              BoxShadow(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.35),
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
                                          isGenreActive
                                              ? (activeGenre.icon ??
                                                    Icons.tune_rounded)
                                              : Icons.tune_rounded,
                                          size: 14,
                                          color: isGenreActive
                                              ? Colors.black
                                              : AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          isGenreActive
                                              ? activeGenre.getLocalizedLabel(
                                                  s.isIndonesian,
                                                )
                                              : 'Genre',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: isGenreActive
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: isGenreActive
                                                ? Colors.black
                                                : AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 16,
                                          color: isGenreActive
                                              ? Colors.black
                                              : AppColors.textSecondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (isGenreActive)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: TvFocusable(
                                    focusedScale: 1.08,
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      ref
                                          .read(
                                            selectedHomeGenreProvider.notifier,
                                          )
                                          .state = GenreConstants
                                          .filters
                                          .first;
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceVariant,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.12,
                                          ),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        size: 15,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── In-App Update Notification Banner ──
            const SliverToBoxAdapter(child: InAppUpdateBanner()),

            // ── Hero Billboard Carousel (Trending Movies or Popular TV Series) ──
            if (activeFilter == HomeCategoryFilter.all ||
                activeFilter == HomeCategoryFilter.movies)
              SliverToBoxAdapter(
                child: trending.when(
                  data: (movies) {
                    final filtered = filterMovies(movies);
                    if (filtered.isEmpty) return const SizedBox.shrink();
                    if (showCompanionSideBySide) {
                      return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: isSuperWide ? 72 : 67,
                                  child: MovieCarousel(movies: filtered),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  flex: isSuperWide ? 28 : 33,
                                  child: const AiringCalendarBanner(
                                    isCompanion: true,
                                  ),
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 500.ms)
                          .slideY(begin: 0.04, end: 0, duration: 500.ms);
                    }
                    return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isWide ? 16 : 0,
                          ),
                          child: MovieCarousel(movies: filtered),
                        )
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.04, end: 0, duration: 500.ms);
                  },
                  loading: () {
                    if (showCompanionSideBySide) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: isSuperWide ? 72 : 67,
                              child: const ShimmerHeroCarousel(
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: isSuperWide ? 28 : 33,
                              child: const AiringCalendarBanner(
                                isCompanion: true,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const ShimmerHeroCarousel();
                  },
                  error: (e, _) => AppErrorWidget(
                    message: s.isIndonesian
                        ? 'Gagal memuat film trending'
                        : 'Failed to load trending movies',
                    onRetry: () => ref.invalidate(trendingMoviesProvider),
                  ),
                ),
              )
            else if (activeFilter == HomeCategoryFilter.tv)
              SliverToBoxAdapter(
                child: popularTv.when(
                  data: (tvShows) {
                    final filtered = filterTv(tvShows);
                    if (filtered.isEmpty) return const SizedBox.shrink();
                    final adaptedMovies = filtered
                        .map((t) => t.toMovie())
                        .toList();
                    if (showCompanionSideBySide) {
                      return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: isSuperWide ? 72 : 67,
                                  child: MovieCarousel(movies: adaptedMovies),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  flex: isSuperWide ? 28 : 33,
                                  child: const AiringCalendarBanner(
                                    isCompanion: true,
                                  ),
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 500.ms)
                          .slideY(begin: 0.04, end: 0, duration: 500.ms);
                    }
                    return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isWide ? 16 : 0,
                          ),
                          child: MovieCarousel(movies: adaptedMovies),
                        )
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.04, end: 0, duration: 500.ms);
                  },
                  loading: () {
                    if (showCompanionSideBySide) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: isSuperWide ? 72 : 67,
                              child: const ShimmerHeroCarousel(
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: isSuperWide ? 28 : 33,
                              child: const AiringCalendarBanner(
                                isCompanion: true,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const ShimmerHeroCarousel();
                  },
                  error: (e, _) => AppErrorWidget(
                    message: s.isIndonesian
                        ? 'Gagal memuat serial TV populer'
                        : 'Failed to load popular TV series',
                    onRetry: () => ref.invalidate(popularTvProvider),
                  ),
                ),
              ),

            // ── KONDISI 1: TAB "SEMUA" (Layout Dashboard Klasik Lengkap) ──
            if (activeFilter == HomeCategoryFilter.all) ...[
              // AIRING CALENDAR BANNER (Shown below carousel on mobile & portrait tablet)
              if (activeGenre.id == 'all' && !showCompanionSideBySide)
                const SliverToBoxAdapter(child: AiringCalendarBanner()),

              // CONTINUE WATCHING SECTION
              if (activeGenre.id == 'all')
                const SliverToBoxAdapter(child: ContinueWatchingSection()),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // TOP 10 SECTION (Netflix-style Giant Rank Numbers)
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

              // POPULAR MOVIES SECTION
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

              // POPULAR TV SERIES SECTION
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

              // TOP RATED MOVIES SECTION
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

              // UPCOMING MOVIES SECTION
              SliverToBoxAdapter(
                child: _SectionWithHeader<Movie>(
                  title: s.isIndonesian
                      ? 'Segera Tayang di Bioskop'
                      : 'Coming Soon in Theaters',
                  icon: Iconsax.calendar,
                  asyncData: upcoming,
                  filter: filterMovies,
                  onRetry: () => ref.invalidate(upcomingMoviesProvider),
                  onSeeAll: () => context.go('/search'),
                  builder: (movies) => _MovieHorizontalList(movies: movies),
                ),
              ),
            ],

            // ── KONDISI 2: TAB "FILM" (Grid Responsif SELURUH Film dengan Infinite Scroll) ──
            if (activeFilter == HomeCategoryFilter.movies) ...[
              Builder(
                builder: (context) {
                  final moviesList = filterMovies(paginatedMoviesState.items);
                  final gridCrossAxisCount = adaptivePosterGridColumns(
                    availableWidth,
                    isTv: isTv,
                  );
                  final gridAspectRatio = isWide ? 0.62 : 0.58;
                  final gridSpacing = isWide ? 14.0 : 10.0;

                  return SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.movie_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                s.isIndonesian ? 'Seluruh Film' : 'All Movies',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${moviesList.length}${paginatedMoviesState.hasMore ? '+' : ''}',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (paginatedMoviesState.isLoading && moviesList.isEmpty)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: _MediaShimmerGrid(),
                          ),
                        )
                      else if (moviesList.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: AppErrorWidget.empty(
                              message: s.isIndonesian
                                  ? 'Tidak ada film ditemukan'
                                  : 'No movies found',
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: gridCrossAxisCount,
                                  childAspectRatio: gridAspectRatio,
                                  crossAxisSpacing: gridSpacing,
                                  mainAxisSpacing: gridSpacing,
                                ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => MovieCard(
                                movie: moviesList[index],
                                isTv: false,
                              ),
                              childCount: moviesList.length,
                            ),
                          ),
                        ),
                      if (paginatedMoviesState.isLoadingMore)
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
                    ],
                  );
                },
              ),
            ],

            // ── KONDISI 3: TAB "SERIAL TV" (Grid Responsif SELURUH Serial TV dengan Infinite Scroll) ──
            if (activeFilter == HomeCategoryFilter.tv) ...[
              Builder(
                builder: (context) {
                  final tvList = filterTv(paginatedTvState.items);
                  final gridCrossAxisCount = adaptivePosterGridColumns(
                    availableWidth,
                    isTv: isTv,
                  );
                  final gridAspectRatio = isWide ? 0.62 : 0.58;
                  final gridSpacing = isWide ? 14.0 : 10.0;

                  return SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.tv_rounded,
                                size: 18,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                s.isIndonesian
                                    ? 'Seluruh Serial TV'
                                    : 'All TV Shows',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${tvList.length}${paginatedTvState.hasMore ? '+' : ''}',
                                  style: TextStyle(
                                    color: Colors.blue.shade300,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (paginatedTvState.isLoading && tvList.isEmpty)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: _MediaShimmerGrid(),
                          ),
                        )
                      else if (tvList.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: AppErrorWidget.empty(
                              message: s.isIndonesian
                                  ? 'Tidak ada serial TV ditemukan'
                                  : 'No TV shows found',
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: gridCrossAxisCount,
                                  childAspectRatio: gridAspectRatio,
                                  crossAxisSpacing: gridSpacing,
                                  mainAxisSpacing: gridSpacing,
                                ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => MovieCard(
                                movie: tvList[index].toMovie(),
                                isTv: true,
                              ),
                              childCount: tvList.length,
                            ),
                          ),
                        ),
                      if (paginatedTvState.isLoadingMore)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],

            // ── Empty State if No Media matches Selected Genre ──
            if (activeGenre.id != 'all')
              Builder(
                builder: (context) {
                  final hasTrending = filterMovies(
                    trending.valueOrNull ?? [],
                  ).isNotEmpty;
                  final hasPopular = filterMovies(
                    popular.valueOrNull ?? [],
                  ).isNotEmpty;
                  final hasTopRated = filterMovies(
                    topRated.valueOrNull ?? [],
                  ).isNotEmpty;
                  final hasUpcoming = filterMovies(
                    upcoming.valueOrNull ?? [],
                  ).isNotEmpty;
                  final hasTv = filterTv(
                    popularTv.valueOrNull ?? [],
                  ).isNotEmpty;

                  final anyLoaded = popular.hasValue || trending.hasValue;
                  final noneMatches =
                      anyLoaded &&
                      !hasTrending &&
                      !hasPopular &&
                      !hasTopRated &&
                      !hasUpcoming &&
                      !hasTv;

                  if (!noneMatches)
                    return const SliverToBoxAdapter(child: SizedBox.shrink());

                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 48,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.12,
                                ),
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
                                ref
                                    .read(selectedHomeGenreProvider.notifier)
                                    .state = GenreConstants
                                    .filters
                                    .first;
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: Text(
                                s.isIndonesian
                                    ? 'Tampilkan Semua Genre'
                                    : 'Show All Genres',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
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
              child: SizedBox(
                height: MediaQuery.of(context).padding.bottom + 48,
              ),
            ),
          ],
        ),
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
            return Top10MovieCard(movie: top10[index], rank: index + 1)
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
            return MovieCard(
                  movie: adapted,
                  isTv: true,
                  onTap: () => context.push('/tv/${tv.id}'),
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
            SectionHeader(title: title, icon: icon, onSeeAll: onSeeAll),
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
      error: (e, _) =>
          AppErrorWidget(message: 'Gagal memuat $title', onRetry: onRetry),
    );
  }
}

/// Shimmer grid placeholder for the paginated catalog view.
class _MediaShimmerGrid extends StatelessWidget {
  const _MediaShimmerGrid();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final crossAxisCount = adaptivePosterGridColumns(screenWidth);
    final childAspectRatio = screenWidth >= 600 ? 0.62 : 0.58;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 12,
      itemBuilder: (_, _) =>
          const ShimmerLoading(width: 135, height: 205, borderRadius: 16),
    );
  }
}
