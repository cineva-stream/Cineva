import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/content_preference.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/platform/device_form_factor.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/media_filter_bottom_sheet.dart';
import '../../../../shared/widgets/tv_focusable.dart';
import '../../domain/entities/movie.dart';
import '../../domain/entities/tv_series.dart';
import '../providers/home_providers.dart';
import '../widgets/movie_card.dart';

/// Identifies which Home section's "See All" catalog is being viewed.
enum HomeCatalogSection {
  anime('anime', Iconsax.video_play, ContentPreference.anime, true),
  kdrama('kdrama', Iconsax.heart, ContentPreference.korea, true),
  indonesia('indonesia', Icons.flag_rounded, ContentPreference.indonesia, true),
  hollywood('hollywood', Iconsax.video, ContentPreference.hollywood, true),
  bollywood('bollywood', Iconsax.music, ContentPreference.bollywood, true),
  popularMovies('popular_movies', Iconsax.trend_up, ContentPreference.all, false),
  popularTv('popular_tv', Iconsax.monitor, ContentPreference.all, false),
  topRated('top_rated', Iconsax.star_1, ContentPreference.all, false),
  upcoming('upcoming', Iconsax.calendar, ContentPreference.all, false);

  final String key;
  final IconData icon;
  final ContentPreference preference;
  final bool supportsMediaTypeToggle;

  const HomeCatalogSection(
    this.key,
    this.icon,
    this.preference,
    this.supportsMediaTypeToggle,
  );

  static HomeCatalogSection fromKey(String? rawKey) {
    final clean = (rawKey ?? '').trim().toLowerCase();
    for (final s in HomeCatalogSection.values) {
      if (s.key == clean) return s;
    }
    return HomeCatalogSection.popularMovies;
  }

  String localizedTitle(AppStrings s) {
    switch (this) {
      case HomeCatalogSection.anime:
        return s.homeSectionAnime;
      case HomeCatalogSection.kdrama:
        return s.homeSectionKDrama;
      case HomeCatalogSection.indonesia:
        return s.homeSectionIndonesia;
      case HomeCatalogSection.hollywood:
        return s.homeSectionHollywood;
      case HomeCatalogSection.bollywood:
        return s.homeSectionBollywood;
      case HomeCatalogSection.popularMovies:
        return s.homePopularMovies;
      case HomeCatalogSection.popularTv:
        return s.homePopularTv;
      case HomeCatalogSection.topRated:
        return s.homeTopRated;
      case HomeCatalogSection.upcoming:
        return s.homeUpcoming;
    }
  }
}

/// Full-screen infinite-scroll catalog screen opened when tapping "See All" on any Home section.
/// Includes a Release Year Filter (defaulting to "Latest / Terbaru") and Media Type toggle.
class SectionCatalogScreen extends ConsumerStatefulWidget {
  final String sectionKey;

  const SectionCatalogScreen({
    super.key,
    required this.sectionKey,
  });

  @override
  ConsumerState<SectionCatalogScreen> createState() =>
      _SectionCatalogScreenState();
}

class _SectionCatalogScreenState extends ConsumerState<SectionCatalogScreen> {
  /// `null` means "Semua Tahun" (default). Otherwise a specific release year (e.g. 2026, 2025...).
  int? _selectedYear;

  /// Active sort order (default: [MediaSortOption.latest]).
  MediaSortOption _selectedSort = MediaSortOption.latest;

  /// `0` = All (Movies + TV), `1` = Movies only, `2` = TV Shows only.
  int _selectedMediaTab = 0;

  final List<Movie> _items = <Movie>[];
  int _currentPage = 1;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  int _requestGeneration = 0;

  HomeCatalogSection get _section =>
      HomeCatalogSection.fromKey(widget.sectionKey);

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _loadInitial();
  }

  @override
  void didUpdateWidget(covariant SectionCatalogScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sectionKey != widget.sectionKey) {
      _selectedYear = null;
      _selectedSort = MediaSortOption.latest;
      _selectedMediaTab = 0;
      _loadInitial();
    }
  }

  String _movieTmdbSortParam() {
    switch (_selectedSort) {
      case MediaSortOption.latest:
        return 'popularity.desc';
      case MediaSortOption.popular:
        return 'popularity.desc';
      case MediaSortOption.topRated:
        return 'vote_average.desc';
    }
  }

  String _tvTmdbSortParam() {
    switch (_selectedSort) {
      case MediaSortOption.latest:
        return 'popularity.desc';
      case MediaSortOption.popular:
        return 'popularity.desc';
      case MediaSortOption.topRated:
        return 'vote_average.desc';
    }
  }

  List<Movie> _applyLocalSort(List<Movie> list) {
    final sorted = List<Movie>.from(list);
    switch (_selectedSort) {
      case MediaSortOption.latest:
        sorted.sort((a, b) {
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
        sorted.sort((a, b) => b.popularity.compareTo(a.popularity));
        break;
      case MediaSortOption.topRated:
        sorted.sort((a, b) {
          final cmp = b.voteAverage.compareTo(a.voteAverage);
          if (cmp != 0) return cmp;
          return b.popularity.compareTo(a.popularity);
        });
        break;
    }
    return sorted;
  }

  Future<List<Movie>> _fetchPage(int page) async {
    final repo = ref.read(movieRepositoryProvider);
    final section = _section;
    final year = _selectedYear;

    if (section.supportsMediaTypeToggle) {
      final fetchMovies = _selectedMediaTab == 0 || _selectedMediaTab == 1;
      final fetchTv = _selectedMediaTab == 0 || _selectedMediaTab == 2;

      final futures = <Future<dynamic>>[
        if (fetchMovies)
          repo.getCuratedSectionMovies(
            category: section.preference,
            page: page,
            releaseYear: year,
            sortBy: _movieTmdbSortParam(),
          ),
        if (fetchTv)
          repo.getCuratedSectionTvSeries(
            category: section.preference,
            page: page,
            releaseYear: year,
            sortBy: _tvTmdbSortParam(),
          ),
      ];

      final results = await Future.wait(futures);
      List<Movie> movies = const [];
      List<Movie> tvAdapted = const [];

      if (fetchMovies && fetchTv) {
        movies = results[0] as List<Movie>;
        tvAdapted = (results[1] as List<TvSeries>)
            .map((t) => t.toMovie())
            .toList();
      } else if (fetchMovies) {
        movies = results[0] as List<Movie>;
      } else if (fetchTv) {
        tvAdapted = (results[0] as List<TvSeries>)
            .map((t) => t.toMovie())
            .toList();
      }

      return _applyLocalSort([...movies, ...tvAdapted]);
    }

    // Standard global sections
    switch (section) {
      case HomeCatalogSection.popularMovies:
        final list = await repo.getCuratedSectionMovies(
          category: ContentPreference.all,
          page: page,
          releaseYear: year,
          sortBy: _movieTmdbSortParam(),
        );
        return _applyLocalSort(list);
      case HomeCatalogSection.popularTv:
        final list = await repo.getCuratedSectionTvSeries(
          category: ContentPreference.all,
          page: page,
          releaseYear: year,
          sortBy: _tvTmdbSortParam(),
        );
        return _applyLocalSort(list.map((t) => t.toMovie()).toList());
      case HomeCatalogSection.topRated:
        final list = await repo.getTopRatedMovies(page: page);
        final yearFiltered = year != null
            ? list.where((m) => m.year == '$year').toList()
            : list;
        return _applyLocalSort(yearFiltered);
      case HomeCatalogSection.upcoming:
        final list = await repo.getUpcomingMovies(page: page);
        final yearFiltered = year != null
            ? list.where((m) => m.year == '$year').toList()
            : list;
        return _applyLocalSort(yearFiltered);
      default:
        return const [];
    }
  }

  Future<void> _loadInitial() async {
    final gen = ++_requestGeneration;
    setState(() {
      _isLoading = true;
      _isLoadingMore = false;
      _errorMessage = null;
      _items.clear();
      _currentPage = 1;
      _hasMore = true;
    });

    try {
      final fetched = await _fetchPage(1);
      if (!mounted || gen != _requestGeneration) return;
      final valid = fetched
          .where((m) => m.posterPath != null && m.posterPath!.isNotEmpty)
          .toList();
      setState(() {
        _items.addAll(valid);
        _currentPage = 1;
        _isLoading = false;
        _hasMore = fetched.isNotEmpty;
      });
    } catch (e) {
      if (!mounted || gen != _requestGeneration) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    final gen = _requestGeneration;
    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final fetched = await _fetchPage(nextPage);
      if (!mounted || gen != _requestGeneration) return;

      if (fetched.isEmpty) {
        setState(() {
          _isLoadingMore = false;
          _hasMore = false;
        });
        return;
      }

      final existingKeys = _items
          .map((m) => '${m.mediaType ?? 'movie'}_${m.id}')
          .toSet();
      final newItems = fetched
          .where(
            (m) =>
                m.posterPath != null &&
                m.posterPath!.isNotEmpty &&
                existingKeys.add('${m.mediaType ?? 'movie'}_${m.id}'),
          )
          .toList();

      setState(() {
        _items.addAll(newItems);
        _currentPage = nextPage;
        _isLoadingMore = false;
        _hasMore = fetched.length >= 10;
      });
    } catch (_) {
      if (!mounted || gen != _requestGeneration) return;
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final isTv = ref.watch(isTvProvider);
    final section = _section;
    final title = section.localizedTitle(s);
    final systemPadding = MediaQuery.paddingOf(context);

    const edgeToEdgeOverlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: edgeToEdgeOverlayStyle,
      child: PopScope(
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
          extendBody: true,
          extendBodyBehindAppBar: true,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Top Header Bar (Applies top system status bar inset directly) ──
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16 + systemPadding.left,
                  systemPadding.top + 12,
                  16 + systemPadding.right,
                  8,
                ),
                child: Row(
                  children: [
                    TvFocusable(
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/');
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      scaleOnFocus: 1.08,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                            width: 1.0,
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.45),
                          width: 1.0,
                        ),
                      ),
                      child: Icon(
                        section.icon,
                        color: AppColors.primary,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.outfit(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${_selectedSort.localizedLabel(s)} • ${_selectedYear?.toString() ?? s.filterAllYears}',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // ── Unified Filter & Sort Button ──
                    Builder(
                      builder: (context) {
                        final isFilterActive =
                            _selectedYear != null ||
                            _selectedSort != MediaSortOption.latest;
                        return TvFocusable(
                          focusedScale: 1.05,
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            MediaFilterBottomSheet.show(
                              context,
                              initialSort: _selectedSort,
                              initialYear: _selectedYear,
                              showGenreFilter: false,
                              onApply: (selection) {
                                if (_selectedSort != selection.sortOption ||
                                    _selectedYear != selection.releaseYear) {
                                  setState(() {
                                    _selectedSort = selection.sortOption;
                                    _selectedYear = selection.releaseYear;
                                  });
                                  _loadInitial();
                                }
                              },
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isFilterActive
                                    ? AppColors.primary
                                    : Colors.white.withValues(alpha: 0.16),
                                width: isFilterActive ? 1.3 : 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.tune_rounded,
                                  size: 15,
                                  color: isFilterActive
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  s.filterButtonShort,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: isFilterActive
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isFilterActive
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                  color: isFilterActive
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // ── 2. Single Centered Media Type Filter Row (All / Movies / TV Shows) ──
              if (section.supportsMediaTypeToggle)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildMediaTypeChip(
                            label: s.searchTabAll,
                            index: 0,
                          ),
                          const SizedBox(width: 10),
                          _buildMediaTypeChip(
                            label: s.searchTabMovies,
                            index: 1,
                          ),
                          const SizedBox(width: 10),
                          _buildMediaTypeChip(
                            label: s.searchTabTv,
                            index: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── 3. Edge-to-Edge Infinite Scroll Responsive Poster Grid ──
              Expanded(
                child: LayoutBuilder(
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
                        : (availableWidth < 360 ? 10.0 : 12.0);
                    final bottomInsetPadding = systemPadding.bottom + 28;

                    if (_isLoading && _items.isEmpty) {
                      return GridView.builder(
                        padding: EdgeInsets.fromLTRB(
                          16 + systemPadding.left,
                          8,
                          16 + systemPadding.right,
                          bottomInsetPadding,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: childAspectRatio,
                          crossAxisSpacing: spacing,
                          mainAxisSpacing: spacing,
                        ),
                        itemCount: 12,
                        itemBuilder: (_, _) => Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      );
                    }

                    if (_errorMessage != null && _items.isEmpty) {
                      return AppErrorWidget(
                        message: s.searchFailed,
                        onRetry: _loadInitial,
                      );
                    }

                    if (_items.isEmpty) {
                      return AppErrorWidget.empty(
                        message: _selectedYear != null
                            ? s.catalogEmptyForYear('$_selectedYear')
                            : s.searchNoResults(title),
                      );
                    }

                    return NotificationListener<ScrollNotification>(
                      onNotification: (scrollInfo) {
                        if (scrollInfo.metrics.pixels >=
                            scrollInfo.metrics.maxScrollExtent - 450) {
                          _loadMore();
                        }
                        return false;
                      },
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              16 + systemPadding.left,
                              6,
                              16 + systemPadding.right,
                              12,
                            ),
                            sliver: SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    childAspectRatio: childAspectRatio,
                                    crossAxisSpacing: spacing,
                                    mainAxisSpacing: spacing,
                                  ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final item = _items[index];
                                  return MovieCard(
                                    movie: item,
                                    isTv: item.mediaType == 'tv',
                                  );
                                },
                                childCount: _items.length,
                              ),
                            ),
                          ),
                          if (_isLoadingMore)
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
                            child: SizedBox(height: bottomInsetPadding),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaTypeChip({
    required String label,
    required int index,
  }) {
    final isSelected = _selectedMediaTab == index;
    return TvFocusable(
      onTap: () {
        if (_selectedMediaTab != index) {
          setState(() => _selectedMediaTab = index);
          _loadInitial();
        }
      },
      borderRadius: BorderRadius.circular(20),
      scaleOnFocus: 1.05,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7.5),
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
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
