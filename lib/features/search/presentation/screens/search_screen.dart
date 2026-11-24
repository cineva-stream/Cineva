import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../core/constants/content_preference.dart';
import '../../../../core/constants/genre_constants.dart';
import '../../../home/domain/entities/movie.dart';
import '../../../home/domain/entities/tv_series.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../providers/search_history_provider.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/platform/device_form_factor.dart';
import '../../../../shared/widgets/media_filter_bottom_sheet.dart';
import '../../../../shared/widgets/tv_focusable.dart';
import '../../domain/entities/streaming_platform.dart';

// ── Search Providers ──

final searchQueryProvider = StateProvider<String>((ref) => '');

/// Selected release year filter for search results (`null` = Default "Semua Tahun").
final selectedSearchYearProvider = StateProvider<int?>((ref) => null);

/// Selected sort option for search results (default: [MediaSortOption.latest]).
final searchSortOptionProvider =
    StateProvider<MediaSortOption>((ref) => MediaSortOption.latest);

/// Sorts [movies] by [sort] (defaulting to newest first), optionally filtering by [year].
List<Movie> sortAndFilterMoviesNewestFirst(
  List<Movie> movies, {
  int? year,
  MediaSortOption sort = MediaSortOption.latest,
}) {
  final filtered = year == null
      ? List<Movie>.from(movies)
      : movies.where((m) => m.year == '$year').toList();
  switch (sort) {
    case MediaSortOption.latest:
      filtered.sort((a, b) {
        final dateA = a.releaseDate.trim();
        final dateB = b.releaseDate.trim();
        if (dateA.isEmpty && dateB.isEmpty) {
          return b.popularity.compareTo(a.popularity);
        }
        if (dateA.isEmpty) return 1;
        if (dateB.isEmpty) return -1;
        final cmp = dateB.compareTo(dateA);
        if (cmp != 0) return cmp;
        return b.popularity.compareTo(a.popularity);
      });
      break;
    case MediaSortOption.popular:
      filtered.sort((a, b) => b.popularity.compareTo(a.popularity));
      break;
    case MediaSortOption.topRated:
      filtered.sort((a, b) {
        final cmp = b.voteAverage.compareTo(a.voteAverage);
        if (cmp != 0) return cmp;
        return b.popularity.compareTo(a.popularity);
      });
      break;
  }
  return filtered;
}

/// Sorts [tvShows] by [sort] (defaulting to newest first), optionally filtering by [year].
List<TvSeries> sortAndFilterTvNewestFirst(
  List<TvSeries> tvShows, {
  int? year,
  MediaSortOption sort = MediaSortOption.latest,
}) {
  final filtered = year == null
      ? List<TvSeries>.from(tvShows)
      : tvShows.where((t) => t.year == '$year').toList();
  switch (sort) {
    case MediaSortOption.latest:
      filtered.sort((a, b) {
        final dateA = a.firstAirDate.trim();
        final dateB = b.firstAirDate.trim();
        if (dateA.isEmpty && dateB.isEmpty) {
          return b.popularity.compareTo(a.popularity);
        }
        if (dateA.isEmpty) return 1;
        if (dateB.isEmpty) return -1;
        final cmp = dateB.compareTo(dateA);
        if (cmp != 0) return cmp;
        return b.popularity.compareTo(a.popularity);
      });
      break;
    case MediaSortOption.popular:
      filtered.sort((a, b) => b.popularity.compareTo(a.popularity));
      break;
    case MediaSortOption.topRated:
      filtered.sort((a, b) {
        final cmp = b.voteAverage.compareTo(a.voteAverage);
        if (cmp != 0) return cmp;
        return b.popularity.compareTo(a.popularity);
      });
      break;
  }
  return filtered;
}

final searchMovieResultsProvider = FutureProvider<List<Movie>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  final pref = ref.watch(contentPreferenceProvider);
  final selectedYear = ref.watch(selectedSearchYearProvider);
  final sortOption = ref.watch(searchSortOptionProvider);
  final movies = await ref
      .watch(movieRepositoryProvider)
      .searchMovies(query, year: selectedYear);
  final sorted = sortAndFilterMoviesNewestFirst(
    movies,
    year: selectedYear,
    sort: sortOption,
  );
  if (pref == ContentPreference.all) return sorted;

  final matches = sorted.where((m) => pref.matchesMovie(m)).toList();
  final others = sorted.where((m) => !pref.matchesMovie(m)).toList();
  return [...matches, ...others];
});

final searchTvResultsProvider = FutureProvider<List<TvSeries>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  final pref = ref.watch(contentPreferenceProvider);
  final selectedYear = ref.watch(selectedSearchYearProvider);
  final sortOption = ref.watch(searchSortOptionProvider);
  final tvShows = await ref
      .watch(movieRepositoryProvider)
      .searchTvSeries(query, year: selectedYear);
  final sorted = sortAndFilterTvNewestFirst(
    tvShows,
    year: selectedYear,
    sort: sortOption,
  );
  if (pref == ContentPreference.all) return sorted;

  final matches = sorted.where((t) => pref.matchesTv(t)).toList();
  final others = sorted.where((t) => !pref.matchesTv(t)).toList();
  return [...matches, ...others];
});

/// Search tab index: 0 = All, 1 = Movies, 2 = TV Series
final searchTabProvider = StateProvider<int>((ref) => 0);

/// Resets all search-related state (query, tab filter, genre filter, year filter, sort option) to defaults.
void resetSearchState(WidgetRef ref) {
  ref.read(searchQueryProvider.notifier).state = '';
  ref.read(searchTabProvider.notifier).state = 0;
  ref.read(selectedSearchGenreProvider.notifier).state =
      GenreConstants.filters.first;
  ref.read(selectedSearchYearProvider.notifier).state = null;
  ref.read(searchSortOptionProvider.notifier).state = MediaSortOption.latest;
}

/// Search screen with real-time TMDB search, history, trends, and top searches.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _debouncer = Debouncer(delay: AppConstants.searchDebounce);

  @override
  void initState() {
    super.initState();
    _controller.text = ref.read(searchQueryProvider);
  }

  @override
  void dispose() {
    _controller.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debouncer.run(() {
      final clean = value.trim();
      ref.read(searchQueryProvider.notifier).state = clean;
    });
  }

  void _selectQuery(String q) {
    _controller.text = q;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: q.length),
    );
    ref.read(searchQueryProvider.notifier).state = q;
    ref.read(searchHistoryProvider.notifier).addQuery(q);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(searchQueryProvider, (previous, next) {
      if (next.isEmpty) {
        _debouncer.cancel();
      }
      if (_controller.text != next) {
        _controller.text = next;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: next.length),
        );
      }
    });

    final s = ref.watch(appStringsProvider);
    final query = ref.watch(searchQueryProvider);
    final tabIndex = ref.watch(searchTabProvider);
    final movieResults = ref.watch(searchMovieResultsProvider);
    final tvResults = ref.watch(searchTvResultsProvider);
    final pref = ref.watch(contentPreferenceProvider);
    final activeGenre = ref.watch(selectedSearchGenreProvider);
    final selectedYear = ref.watch(selectedSearchYearProvider);
    final sortOption = ref.watch(searchSortOptionProvider);
    final hasActiveSearchFilters =
        activeGenre.id != 'all' ||
        selectedYear != null ||
        sortOption != MediaSortOption.latest;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s.searchTitle,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  if (pref != ContentPreference.all)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(pref.icon, size: 13, color: AppColors.primary),
                          const SizedBox(width: 5),
                          Text(
                            s.searchPriority(
                              pref.getLocalizedLabel(
                                s.isIndonesian,
                                s.language,
                              ),
                            ),
                            style: GoogleFonts.inter(
                              color: AppColors.primaryLight,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Search Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                onSubmitted: (value) {
                  final clean = value.trim();
                  if (clean.isNotEmpty) {
                    ref.read(searchQueryProvider.notifier).state = clean;
                    ref.read(searchHistoryProvider.notifier).addQuery(clean);
                  }
                },
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: s.searchHint,
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textMuted,
                  ),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Iconsax.close_circle,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                          onPressed: () {
                            _controller.clear();
                            ref.read(searchQueryProvider.notifier).state = '';
                          },
                        )
                      : null,
                ),
              ),
            ),

            // ── Single Centered Smart Filter & Media Type Bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (query.isNotEmpty) ...[
                        _FilterChip(
                          label: s.searchTabAll,
                          isSelected: tabIndex == 0,
                          onTap: () =>
                              ref.read(searchTabProvider.notifier).state = 0,
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: s.searchTabMovies,
                          isSelected: tabIndex == 1,
                          onTap: () =>
                              ref.read(searchTabProvider.notifier).state = 1,
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: s.searchTabTv,
                          isSelected: tabIndex == 2,
                          onTap: () =>
                              ref.read(searchTabProvider.notifier).state = 2,
                        ),
                        const SizedBox(width: 8),
                      ],
                      TvFocusable(
                        focusedScale: 1.04,
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          MediaFilterBottomSheet.show(
                            context,
                            initialSort: sortOption,
                            initialYear: selectedYear,
                            initialGenre: activeGenre,
                            showGenreFilter: true,
                            onApply: (selection) {
                              ref
                                      .read(searchSortOptionProvider.notifier)
                                      .state =
                                  selection.sortOption;
                              ref
                                      .read(
                                        selectedSearchYearProvider.notifier,
                                      )
                                      .state =
                                  selection.releaseYear;
                              if (selection.genre != null) {
                                ref
                                        .read(
                                          selectedSearchGenreProvider.notifier,
                                        )
                                        .state =
                                    selection.genre!;
                              }
                            },
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: hasActiveSearchFilters
                                  ? AppColors.primary
                                  : Colors.white.withValues(alpha: 0.14),
                              width: hasActiveSearchFilters ? 1.3 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                size: 14,
                                color: hasActiveSearchFilters
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                hasActiveSearchFilters
                                    ? '${sortOption.localizedLabel(s)}${selectedYear != null ? ' • $selectedYear' : ''}${activeGenre.id != 'all' ? ' • ${activeGenre.getLocalizedLabel(s.isIndonesian, s.language)}' : ''}'
                                    : s.filterAndSortTitle,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: hasActiveSearchFilters
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: hasActiveSearchFilters
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 16,
                                color: hasActiveSearchFilters
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (hasActiveSearchFilters) ...[
                        const SizedBox(width: 6),
                        TvFocusable(
                          focusedScale: 1.08,
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            ref
                                    .read(
                                      selectedSearchGenreProvider.notifier,
                                    )
                                    .state =
                                GenreConstants.filters.first;
                            ref
                                    .read(selectedSearchYearProvider.notifier)
                                    .state =
                                null;
                            ref.read(searchSortOptionProvider.notifier).state =
                                MediaSortOption.latest;
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.16),
                              ),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ── Results or Discovery View ──
            Expanded(
              child: query.isEmpty
                  ? (activeGenre.id == 'all' && selectedYear == null
                        ? _SearchDiscoveryView(onSelectQuery: _selectQuery)
                        : _GenreExplorerView(
                            activeGenre: activeGenre,
                            selectedYear: selectedYear,
                            sortOption: sortOption,
                          ))
                  : tabIndex == 0
                  ? _buildAllResults(
                      movieResults: movieResults,
                      tvResults: tvResults,
                      activeGenre: activeGenre,
                      selectedYear: selectedYear,
                      sortOption: sortOption,
                      query: query,
                      s: s,
                      ref: ref,
                    )
                  : tabIndex == 1
                  ? movieResults.when(
                      data: (movies) {
                        final genreFiltered = activeGenre.id == 'all'
                            ? movies
                            : movies
                                  .where((m) => activeGenre.matchesMovie(m))
                                  .toList();
                        final filtered = sortAndFilterMoviesNewestFirst(
                          genreFiltered,
                          year: selectedYear,
                          sort: sortOption,
                        );
                        if (filtered.isEmpty) {
                          return AppErrorWidget.empty(
                            message: selectedYear != null
                                ? s.catalogEmptyForYear('$selectedYear')
                                : s.searchNoMovies(query),
                          );
                        }
                        return _MovieGrid(movies: filtered);
                      },
                      loading: () => const _SearchLoadingGrid(),
                      error: (e, _) => AppErrorWidget(
                        message: s.searchFailed,
                        onRetry: () =>
                            ref.invalidate(searchMovieResultsProvider),
                      ),
                    )
                  : tvResults.when(
                      data: (tvShows) {
                        final genreFiltered = activeGenre.id == 'all'
                            ? tvShows
                            : tvShows
                                  .where((t) => activeGenre.matchesTv(t))
                                  .toList();
                        final filtered = sortAndFilterTvNewestFirst(
                          genreFiltered,
                          year: selectedYear,
                          sort: sortOption,
                        );
                        if (filtered.isEmpty) {
                          return AppErrorWidget.empty(
                            message: selectedYear != null
                                ? s.catalogEmptyForYear('$selectedYear')
                                : s.searchNoTv(query),
                          );
                        }
                        return _TvGrid(tvShows: filtered);
                      },
                      loading: () => const _SearchLoadingGrid(),
                      error: (e, _) => AppErrorWidget(
                        message: s.searchFailed,
                        onRetry: () => ref.invalidate(searchTvResultsProvider),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllResults({
    required AsyncValue<List<Movie>> movieResults,
    required AsyncValue<List<TvSeries>> tvResults,
    required GenreFilter activeGenre,
    required int? selectedYear,
    required MediaSortOption sortOption,
    required String query,
    required AppStrings s,
    required WidgetRef ref,
  }) {
    if (movieResults.isLoading || tvResults.isLoading) {
      return const _SearchLoadingGrid();
    }
    if (movieResults.hasError && tvResults.hasError) {
      return AppErrorWidget(
        message: s.searchFailed,
        onRetry: () {
          ref.invalidate(searchMovieResultsProvider);
          ref.invalidate(searchTvResultsProvider);
        },
      );
    }

    final movies = movieResults.valueOrNull ?? [];
    final tvShows = tvResults.valueOrNull ?? [];

    final genreMovies = activeGenre.id == 'all'
        ? movies
        : movies.where((m) => activeGenre.matchesMovie(m)).toList();
    final genreTv = activeGenre.id == 'all'
        ? tvShows
        : tvShows.where((t) => activeGenre.matchesTv(t)).toList();

    final filteredMovies = sortAndFilterMoviesNewestFirst(
      genreMovies,
      year: selectedYear,
      sort: sortOption,
    );
    final filteredTv = sortAndFilterTvNewestFirst(
      genreTv,
      year: selectedYear,
      sort: sortOption,
    );

    if (filteredMovies.isEmpty && filteredTv.isEmpty) {
      return AppErrorWidget.empty(
        message: selectedYear != null
            ? s.catalogEmptyForYear('$selectedYear')
            : s.searchNoResults(query),
      );
    }

    return _AllSearchResultsView(movies: filteredMovies, tvShows: filteredTv);
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      scaleOnFocus: 1.04,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.14),
            width: isSelected ? 1.3 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Rich Discovery View shown when search query is empty.
/// Features:
/// 1. Riwayat Pencarian (Recent searches with quick delete & clear all)
/// 2. Trend Pencarian (Trending tags)
/// 3. Sering Dicari (Ranked top movies & TV series with instant play / detail access)
class _SearchDiscoveryView extends ConsumerWidget {
  final void Function(String query) onSelectQuery;

  const _SearchDiscoveryView({required this.onSelectQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final history = ref.watch(searchHistoryProvider);
    final popularMovies = ref.watch(popularMoviesProvider);
    final popularTv = ref.watch(popularTvProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final isWide = availableWidth >= 680;

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            isWide ? 24 : 16,
            4,
            isWide ? 24 : 16,
            MediaQuery.of(context).padding.bottom + 84,
          ),
          children: [
            // ── 1. RIWAYAT PENCARIAN ──
            if (history.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Iconsax.clock,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        s.searchHistory,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  TvFocusable(
                    onTap: () =>
                        ref.read(searchHistoryProvider.notifier).clearHistory(),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 6,
                      ),
                      child: Text(
                        s.searchClearAll,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: history.map((q) {
                  return TvFocusable(
                    onTap: () => onSelectQuery(q),
                    onLongPress: () =>
                        ref.read(searchHistoryProvider.notifier).removeQuery(q),
                    borderRadius: BorderRadius.circular(20),
                    scaleOnFocus: 1.04,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 0.8,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Iconsax.clock,
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            q,
                            style: GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => ref
                                .read(searchHistoryProvider.notifier)
                                .removeQuery(q),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // ── 2. PILIH SESUAI PLATFORM ──
            Row(
              children: [
                const Icon(
                  Icons.subscriptions_rounded,
                  size: 17,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.searchPlatforms,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      s.searchPlatformsSub,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isWide)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: StreamingPlatform.supportedPlatforms
                    .map((p) => _buildPlatformChip(context, p))
                    .toList(),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        for (int i = 0; i < 4; i++)
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: _buildPlatformChip(
                              context,
                              StreamingPlatform.supportedPlatforms[i],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (int i = 4; i < 8; i++)
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: _buildPlatformChip(
                              context,
                              StreamingPlatform.supportedPlatforms[i],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 26),

            // ── 3. SERING DICARI (MOVIES & TV SERIES) ──
            Row(
              children: [
                const Icon(
                  Iconsax.trend_up,
                  size: 17,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.searchTopSearched,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      s.searchTopSearchedSub,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Top searched items combined
            Builder(
              builder: (context) {
                final movies = popularMovies.valueOrNull ?? [];
                final tvs = popularTv.valueOrNull ?? [];

                if (popularMovies.isLoading && popularTv.isLoading) {
                  return Column(
                    children: List.generate(
                      4,
                      (index) => Container(
                        height: 68,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white.withValues(alpha: 0.08),
                              width: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                final items = <_TopSearchItem>[];
                const maxItems = 5;
                for (int i = 0; i < maxItems; i++) {
                  if (i < movies.length) {
                    final m = movies[i];
                    items.add(
                      _TopSearchItem(
                        id: m.id,
                        title: m.title,
                        posterPath: m.posterPath,
                        backdropPath: m.backdropPath,
                        rating: m.voteAverage,
                        year: m.year,
                        type: 'movie',
                      ),
                    );
                  }
                  if (i < tvs.length) {
                    final t = tvs[i];
                    items.add(
                      _TopSearchItem(
                        id: t.id,
                        title: t.name,
                        posterPath: t.posterPath,
                        backdropPath: t.backdropPath,
                        rating: t.voteAverage,
                        year: t.year,
                        type: 'tv',
                      ),
                    );
                  }
                }

                if (items.isEmpty) {
                  return const SizedBox.shrink();
                }

                if (isWide) {
                  final gridCols = availableWidth >= 1200 ? 3 : 2;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridCols,
                      mainAxisExtent: 76,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) => _buildTopSearchTile(
                      context,
                      item: items[index],
                      index: index,
                      s: s,
                      isCardStyle: true,
                    ),
                  );
                }

                return Column(
                  children: items.asMap().entries.map((entry) {
                    return _buildTopSearchTile(
                      context,
                      item: entry.value,
                      index: entry.key,
                      s: s,
                      isCardStyle: false,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopSearchTile(
    BuildContext context, {
    required _TopSearchItem item,
    required int index,
    required AppStrings s,
    required bool isCardStyle,
  }) {
    final isTop3 = index < 3;
    final isMovie = item.type == 'movie';
    final imageUrl = ApiConstants.imageUrl(
      item.backdropPath ?? item.posterPath,
      size: ApiConstants.backdropSmall,
    );

    return TvFocusable(
      onTap: () {
        if (isMovie) {
          context.push('/movie/${item.id}');
        } else {
          context.push('/tv/${item.id}');
        }
      },
      borderRadius: BorderRadius.circular(12),
      scaleOnFocus: 1.02,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: 12,
          horizontal: isCardStyle ? 12 : 4,
        ),
        decoration: BoxDecoration(
          color: isCardStyle
              ? AppColors.surface.withValues(alpha: 0.7)
              : Colors.transparent,
          borderRadius: isCardStyle ? BorderRadius.circular(12) : null,
          border: isCardStyle
              ? Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 0.8,
                )
              : Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 0.8,
                  ),
                ),
        ),
        child: Row(
          children: [
            // Rank Number Badge
            SizedBox(
              width: 24,
              child: Text(
                '${index + 1}',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: isTop3 ? AppColors.primary : AppColors.textMuted,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: 85,
                height: 50,
                memCacheWidth: 200,
                fit: BoxFit.cover,
                placeholder: (_, _) =>
                    Container(color: AppColors.surfaceVariant),
                errorWidget: (_, _, _) => Container(
                  color: AppColors.surfaceVariant,
                  width: 85,
                  height: 50,
                  child: Icon(
                    isMovie ? Icons.movie_rounded : Icons.tv_rounded,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Title & Metadata
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isMovie
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : Colors.blue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isMovie ? s.searchBadgeMovie : s.searchBadgeTv,
                          style: GoogleFonts.inter(
                            color: isMovie
                                ? AppColors.primaryLight
                                : Colors.blue.shade300,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (item.year.isNotEmpty) ...[
                        Text(
                          item.year,
                          style: GoogleFonts.inter(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      const Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: AppColors.star,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        item.rating.toStringAsFixed(1),
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Quick Play / Arrow Action
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(
                Iconsax.play_cricle,
                color: AppColors.primary,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformChip(BuildContext context, StreamingPlatform platform) {
    return TvFocusable(
      onTap: () => context.push('/platform/${platform.id}'),
      borderRadius: BorderRadius.circular(14),
      scaleOnFocus: 1.05,
      child: Container(
        width: 104,
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Image.asset(
            platform.logoAsset,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) =>
                Icon(platform.icon, color: platform.brandColor, size: 24),
          ),
        ),
      ),
    );
  }
}

class _TopSearchItem {
  final int id;
  final String title;
  final String? posterPath;
  final String? backdropPath;
  final double rating;
  final String year;
  final String type;

  const _TopSearchItem({
    required this.id,
    required this.title,
    this.posterPath,
    this.backdropPath,
    required this.rating,
    required this.year,
    required this.type,
  });
}

class _MovieGrid extends ConsumerWidget {
  final List<Movie> movies;
  const _MovieGrid({required this.movies});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pref = ref.watch(contentPreferenceProvider);
    final isTv = ref.watch(isTvProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final crossAxisCount = adaptivePosterGridColumns(
          availableWidth,
          isTv: isTv,
        );
        final childAspectRatio = adaptivePosterGridAspectRatio(
          availableWidth,
          isTv: isTv,
        );
        final spacing = availableWidth >= 600
            ? 14.0
            : (availableWidth < 360 ? 8.0 : 10.0);

        return GridView.builder(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            MediaQuery.of(context).padding.bottom + 84,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: movies.length,
          itemBuilder: (context, index) {
            final movie = movies[index];
            final isPreferred =
                pref != ContentPreference.all && pref.matchesMovie(movie);
            return _MovieSearchCard(
              movie: movie,
              isPreferred: isPreferred,
              index: index,
            );
          },
        );
      },
    );
  }
}

class _MovieSearchCard extends ConsumerWidget {
  final Movie movie;
  final bool isPreferred;
  final int index;

  const _MovieSearchCard({
    required this.movie,
    required this.isPreferred,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pref = ref.watch(contentPreferenceProvider);
    final s = ref.watch(appStringsProvider);

    return TvFocusable(
      onTap: () {
        final currentQuery = ref.read(searchQueryProvider).trim();
        if (currentQuery.isNotEmpty) {
          ref.read(searchHistoryProvider.notifier).addQuery(currentQuery);
        }
        context.push('/movie/${movie.id}');
      },
      borderRadius: BorderRadius.circular(12),
      scaleOnFocus: 1.04,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: isPreferred
                    ? Border.all(color: AppColors.primary, width: 1.2)
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: ApiConstants.imageUrl(movie.posterPath),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (_, _) =>
                          Container(color: AppColors.surfaceVariant),
                      errorWidget: (_, _, _) => Container(
                        color: AppColors.surfaceVariant,
                        child: const Icon(
                          Icons.movie,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    if (isPreferred)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            pref
                                .getLocalizedLabel(s.isIndonesian, s.language)
                                .split(' ')
                                .first,
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
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
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          Row(
            children: [
              const Icon(Icons.star, size: 12, color: AppColors.star),
              const SizedBox(width: 3),
              Text(
                movie.voteAverage.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
              if (movie.year.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  movie.year,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (30 * index).ms, duration: 300.ms);
  }
}

class _TvGrid extends ConsumerWidget {
  final List<TvSeries> tvShows;
  const _TvGrid({required this.tvShows});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pref = ref.watch(contentPreferenceProvider);
    final isTv = ref.watch(isTvProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final crossAxisCount = adaptivePosterGridColumns(
          availableWidth,
          isTv: isTv,
        );
        final childAspectRatio = adaptivePosterGridAspectRatio(
          availableWidth,
          isTv: isTv,
        );
        final spacing = availableWidth >= 600
            ? 14.0
            : (availableWidth < 360 ? 8.0 : 10.0);

        return GridView.builder(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            MediaQuery.of(context).padding.bottom + 84,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: tvShows.length,
          itemBuilder: (context, index) {
            final tv = tvShows[index];
            final isPreferred =
                pref != ContentPreference.all && pref.matchesTv(tv);
            return _TvSearchCard(
              tv: tv,
              isPreferred: isPreferred,
              index: index,
            );
          },
        );
      },
    );
  }
}

class _TvSearchCard extends ConsumerWidget {
  final TvSeries tv;
  final bool isPreferred;
  final int index;

  const _TvSearchCard({
    required this.tv,
    required this.isPreferred,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pref = ref.watch(contentPreferenceProvider);
    final s = ref.watch(appStringsProvider);

    return TvFocusable(
      onTap: () {
        final currentQuery = ref.read(searchQueryProvider).trim();
        if (currentQuery.isNotEmpty) {
          ref.read(searchHistoryProvider.notifier).addQuery(currentQuery);
        }
        context.push('/tv/${tv.id}');
      },
      borderRadius: BorderRadius.circular(12),
      scaleOnFocus: 1.04,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: isPreferred
                    ? Border.all(color: AppColors.primary, width: 1.2)
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: ApiConstants.imageUrl(tv.posterPath),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (_, _) =>
                          Container(color: AppColors.surfaceVariant),
                      errorWidget: (_, _, _) => Container(
                        color: AppColors.surfaceVariant,
                        child: const Icon(Icons.tv, color: AppColors.textMuted),
                      ),
                    ),
                    if (isPreferred)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            pref
                                .getLocalizedLabel(s.isIndonesian, s.language)
                                .split(' ')
                                .first,
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
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
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          Row(
            children: [
              const Icon(Icons.star, size: 12, color: AppColors.star),
              const SizedBox(width: 3),
              Text(
                tv.voteAverage.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
              if (tv.year.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  tv.year,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (30 * index).ms, duration: 300.ms);
  }
}

/// Rich Combined View for "All" filter chip, rendering Movies & TV Series in separate sections.
class _AllSearchResultsView extends ConsumerWidget {
  final List<Movie> movies;
  final List<TvSeries> tvShows;

  const _AllSearchResultsView({required this.movies, required this.tvShows});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final pref = ref.watch(contentPreferenceProvider);
    final isTv = ref.watch(isTvProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom + 84;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final crossAxisCount = adaptivePosterGridColumns(
          availableWidth,
          isTv: isTv,
        );
        final childAspectRatio = adaptivePosterGridAspectRatio(
          availableWidth,
          isTv: isTv,
        );
        final spacing = availableWidth >= 600
            ? 14.0
            : (availableWidth < 360 ? 8.0 : 10.0);

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── 1. Movies Section ──
            if (movies.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.movie_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
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
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final movie = movies[index];
                    final isPreferred =
                        pref != ContentPreference.all &&
                        pref.matchesMovie(movie);
                    return _MovieSearchCard(
                      movie: movie,
                      isPreferred: isPreferred,
                      index: index,
                    );
                  }, childCount: movies.length),
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

            // ── 2. TV Shows Section ──
            if (tvShows.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.tv_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
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
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final tv = tvShows[index];
                    final isPreferred =
                        pref != ContentPreference.all && pref.matchesTv(tv);
                    return _TvSearchCard(
                      tv: tv,
                      isPreferred: isPreferred,
                      index: index,
                    );
                  }, childCount: tvShows.length),
                ),
              ),
            ],

            SliverToBoxAdapter(child: SizedBox(height: bottomPadding)),
          ],
        );
      },
    );
  }
}

class _SearchLoadingGrid extends ConsumerWidget {
  const _SearchLoadingGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTv = ref.watch(isTvProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final crossAxisCount = adaptivePosterGridColumns(
          availableWidth,
          isTv: isTv,
        );
        final childAspectRatio = adaptivePosterGridAspectRatio(
          availableWidth,
          isTv: isTv,
        );
        final spacing = availableWidth >= 600
            ? 14.0
            : (availableWidth < 360 ? 8.0 : 10.0);

        return GridView.builder(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            MediaQuery.of(context).padding.bottom + 84,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: crossAxisCount * 3,
          itemBuilder: (_, _) => const ShimmerLoading(
            width: double.infinity,
            height: double.infinity,
            borderRadius: 12,
          ),
        );
      },
    );
  }
}

/// Rich Genre Explorer View shown when a specific genre is selected without search query.
class _GenreExplorerView extends ConsumerStatefulWidget {
  final GenreFilter activeGenre;
  final int? selectedYear;
  final MediaSortOption sortOption;
  const _GenreExplorerView({
    required this.activeGenre,
    this.selectedYear,
    this.sortOption = MediaSortOption.latest,
  });

  @override
  ConsumerState<_GenreExplorerView> createState() => _GenreExplorerViewState();
}

class _GenreExplorerViewState extends ConsumerState<_GenreExplorerView> {
  int _tab = 0; // 0 = Film, 1 = Serial TV

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final popularMovies = ref.watch(popularMoviesProvider);
    final topRatedMovies = ref.watch(topRatedMoviesProvider);
    final popularTv = ref.watch(popularTvProvider);
    final genreLabel = widget.activeGenre.getLocalizedLabel(
      s.isIndonesian,
      s.language,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _FilterChip(
                label: s.searchGenreMovies(genreLabel),
                isSelected: _tab == 0,
                onTap: () => setState(() => _tab = 0),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: s.searchGenreTv(genreLabel),
                isSelected: _tab == 1,
                onTap: () => setState(() => _tab = 1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _tab == 0
              ? popularMovies.when(
                  data: (movies) {
                    final allMovies = [
                      ...movies,
                      ...topRatedMovies.valueOrNull ?? [],
                    ];
                    final unique = <int, Movie>{};
                    for (final m in allMovies) {
                      unique[m.id] = m;
                    }
                    final genreMatched = widget.activeGenre.id == 'all'
                        ? unique.values.toList()
                        : unique.values
                              .where((m) => widget.activeGenre.matchesMovie(m))
                              .toList();
                    final filtered = sortAndFilterMoviesNewestFirst(
                      genreMatched,
                      year: widget.selectedYear,
                      sort: widget.sortOption,
                    );

                    if (filtered.isEmpty) {
                      return AppErrorWidget.empty(
                        message: widget.selectedYear != null
                            ? s.catalogEmptyForYear('${widget.selectedYear}')
                            : s.searchNoGenreMovies(genreLabel),
                      );
                    }
                    return _MovieGrid(movies: filtered);
                  },
                  loading: () => const _SearchLoadingGrid(),
                  error: (e, _) => AppErrorWidget(
                    message: s.searchGenreErrorMovies,
                    onRetry: () => ref.invalidate(popularMoviesProvider),
                  ),
                )
              : popularTv.when(
                  data: (tvShows) {
                    final genreMatched = widget.activeGenre.id == 'all'
                        ? tvShows
                        : tvShows
                              .where((t) => widget.activeGenre.matchesTv(t))
                              .toList();
                    final filtered = sortAndFilterTvNewestFirst(
                      genreMatched,
                      year: widget.selectedYear,
                      sort: widget.sortOption,
                    );
                    if (filtered.isEmpty) {
                      return AppErrorWidget.empty(
                        message: widget.selectedYear != null
                            ? s.catalogEmptyForYear('${widget.selectedYear}')
                            : s.searchNoGenreTv(genreLabel),
                      );
                    }
                    return _TvGrid(tvShows: filtered);
                  },
                  loading: () => const _SearchLoadingGrid(),
                  error: (e, _) => AppErrorWidget(
                    message: s.searchGenreErrorTv,
                    onRetry: () => ref.invalidate(popularTvProvider),
                  ),
                ),
        ),
      ],
    );
  }
}
