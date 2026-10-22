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

// ── Search Providers ──

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchMovieResultsProvider = FutureProvider<List<Movie>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  final pref = ref.watch(contentPreferenceProvider);
  final movies = await ref.watch(movieRepositoryProvider).searchMovies(query);
  if (pref == ContentPreference.all) return movies;

  final matches = movies.where((m) => pref.matchesMovie(m)).toList();
  final others = movies.where((m) => !pref.matchesMovie(m)).toList();
  return [...matches, ...others];
});

final searchTvResultsProvider = FutureProvider<List<TvSeries>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  final pref = ref.watch(contentPreferenceProvider);
  final tvShows = await ref.watch(movieRepositoryProvider).searchTvSeries(query);
  if (pref == ContentPreference.all) return tvShows;

  final matches = tvShows.where((t) => pref.matchesTv(t)).toList();
  final others = tvShows.where((t) => !pref.matchesTv(t)).toList();
  return [...matches, ...others];
});

/// Search tab index: 0 = Movies, 1 = TV Series
final searchTabProvider = StateProvider<int>((ref) => 0);

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
  void dispose() {
    _controller.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debouncer.run(() {
      final clean = value.trim();
      ref.read(searchQueryProvider.notifier).state = clean;
      if (clean.isNotEmpty) {
        ref.read(searchHistoryProvider.notifier).addQuery(clean);
      }
    });
  }

  void _selectQuery(String q) {
    _controller.text = q;
    _controller.selection = TextSelection.fromPosition(TextPosition(offset: q.length));
    ref.read(searchQueryProvider.notifier).state = q;
    ref.read(searchHistoryProvider.notifier).addQuery(q);
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final tabIndex = ref.watch(searchTabProvider);
    final movieResults = ref.watch(searchMovieResultsProvider);
    final tvResults = ref.watch(searchTvResultsProvider);
    final pref = ref.watch(contentPreferenceProvider);
    final activeGenre = ref.watch(selectedSearchGenreProvider);

    return Scaffold(
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
                    'Cari',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  if (pref != ContentPreference.all)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                            'Prioritas ${pref.label}',
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
                  hintText: 'Cari film atau serial TV...',
                  prefixIcon: const Icon(Iconsax.search_normal_1, color: AppColors.textMuted),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Iconsax.close_circle, color: AppColors.textMuted, size: 20),
                          onPressed: () {
                            _controller.clear();
                            ref.read(searchQueryProvider.notifier).state = '';
                          },
                        )
                      : null,
                ),
              ),
            ),

            // ── Genre Filter Chips Row ──
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 2),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: GenreConstants.filters.map((genre) {
                    final isSelected = activeGenre.id == genre.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          ref.read(selectedSearchGenreProvider.notifier).state = genre;
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.18)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.white.withValues(alpha: 0.08),
                              width: isSelected ? 1.2 : 0.8,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (genre.icon != null) ...[
                                Icon(
                                  genre.icon,
                                  size: 13,
                                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                                ),
                                const SizedBox(width: 5),
                              ],
                              Text(
                                genre.label,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // ── Tab Filter (When query is present) ──
            if (query.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Film',
                      isSelected: tabIndex == 0,
                      onTap: () => ref.read(searchTabProvider.notifier).state = 0,
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Serial TV',
                      isSelected: tabIndex == 1,
                      onTap: () => ref.read(searchTabProvider.notifier).state = 1,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // ── Results or Discovery View ──
            Expanded(
              child: query.isEmpty
                  ? (activeGenre.id == 'all'
                      ? _SearchDiscoveryView(onSelectQuery: _selectQuery)
                      : _GenreExplorerView(activeGenre: activeGenre))
                  : tabIndex == 0
                      ? movieResults.when(
                          data: (movies) {
                            final filtered = activeGenre.id == 'all'
                                ? movies
                                : movies.where((m) => activeGenre.matchesMovie(m)).toList();
                            if (filtered.isEmpty) {
                              return AppErrorWidget.empty(
                                message: activeGenre.id == 'all'
                                    ? 'Tidak ada film ditemukan untuk "$query"'
                                    : 'Tidak ada film genre "${activeGenre.label}" untuk "$query"',
                              );
                            }
                            return _MovieGrid(movies: filtered);
                          },
                          loading: () => const _SearchLoadingGrid(),
                          error: (e, _) => AppErrorWidget(
                            message: 'Pencarian gagal',
                            onRetry: () => ref.invalidate(searchMovieResultsProvider),
                          ),
                        )
                      : tvResults.when(
                          data: (tvShows) {
                            final filtered = activeGenre.id == 'all'
                                ? tvShows
                                : tvShows.where((t) => activeGenre.matchesTv(t)).toList();
                            if (filtered.isEmpty) {
                              return AppErrorWidget.empty(
                                message: activeGenre.id == 'all'
                                    ? 'Tidak ada serial TV ditemukan untuk "$query"'
                                    : 'Tidak ada serial TV genre "${activeGenre.label}" untuk "$query"',
                              );
                            }
                            return _TvGrid(tvShows: filtered);
                          },
                          loading: () => const _SearchLoadingGrid(),
                          error: (e, _) => AppErrorWidget(
                            message: 'Pencarian gagal',
                            onRetry: () => ref.invalidate(searchTvResultsProvider),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.background : AppColors.textSecondary,
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

  static const _trendingKeywords = [
    'Deadpool & Wolverine',
    'Squid Game',
    'Arcane',
    'Dune: Part Two',
    'The Last of Us',
    'Oppenheimer',
    'Horor Indonesia',
    'Anime',
    'Action Thriller',
    'Stranger Things',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(searchHistoryProvider);
    final popularMovies = ref.watch(popularMoviesProvider);
    final popularTv = ref.watch(popularTvProvider);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      children: [
        // ── 1. RIWAYAT PENCARIAN ──
        if (history.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Iconsax.clock, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Riwayat Pencarian',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => ref.read(searchHistoryProvider.notifier).clearHistory(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Text(
                    'Hapus Semua',
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
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 0.8,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => onSelectQuery(q),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Iconsax.clock, size: 12, color: AppColors.textMuted),
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
                            onTap: () => ref.read(searchHistoryProvider.notifier).removeQuery(q),
                            child: const Icon(Icons.close_rounded, size: 14, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // ── 2. TREND PENCARIAN ──
        Row(
          children: [
            const Icon(Icons.local_fire_department_rounded, size: 17, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              'Trend Pencarian',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _trendingKeywords.map((trend) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  width: 0.8,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onSelectQuery(trend),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '#',
                          style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          trend,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 26),

        // ── 3. SERING DICARI (MOVIES & TV SERIES) ──
        Row(
          children: [
            const Icon(Iconsax.trend_up, size: 17, color: AppColors.primary),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sering Dicari',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Film & Serial TV terpopuler minggu ini',
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
                    margin: const EdgeInsets.only(bottom: 10),
                    height: 68,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
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
                items.add(_TopSearchItem(
                  id: m.id,
                  title: m.title,
                  posterPath: m.posterPath,
                  backdropPath: m.backdropPath,
                  rating: m.voteAverage,
                  year: m.year,
                  type: 'movie',
                ));
              }
              if (i < tvs.length) {
                final t = tvs[i];
                items.add(_TopSearchItem(
                  id: t.id,
                  title: t.name,
                  posterPath: t.posterPath,
                  backdropPath: t.backdropPath,
                  rating: t.voteAverage,
                  year: t.year,
                  type: 'tv',
                ));
              }
            }

            if (items.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isTop3 = index < 3;
                final isMovie = item.type == 'movie';
                final imageUrl = ApiConstants.imageUrl(
                  item.backdropPath ?? item.posterPath,
                  size: ApiConstants.backdropSmall,
                );

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                      width: 0.8,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        if (isMovie) {
                          context.push('/movie/${item.id}');
                        } else {
                          context.push('/tv/${item.id}');
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            // Rank Number Badge
                            Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isTop3
                                    ? AppColors.primary
                                    : AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: GoogleFonts.outfit(
                                  color: isTop3 ? Colors.black : AppColors.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Thumbnail
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                width: 85,
                                height: 50,
                                memCacheWidth: 200,
                                fit: BoxFit.cover,
                                placeholder: (_, _) => Container(color: AppColors.surfaceVariant),
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
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isMovie
                                              ? AppColors.primary.withValues(alpha: 0.15)
                                              : Colors.blue.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          isMovie ? 'FILM' : 'SERIAL',
                                          style: GoogleFonts.inter(
                                            color: isMovie ? AppColors.primaryLight : Colors.blue.shade300,
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
                                      const Icon(Icons.star_rounded, size: 12, color: AppColors.star),
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
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final crossAxisCount = screenWidth < 340 ? 2 : 3;
    final childAspectRatio = screenWidth < 360 ? 0.52 : 0.55;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: screenWidth < 360 ? 8 : 10,
        mainAxisSpacing: screenWidth < 360 ? 8 : 10,
      ),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        final movie = movies[index];
        final isPreferred = pref != ContentPreference.all && pref.matchesMovie(movie);

        return GestureDetector(
          onTap: () => context.push('/movie/${movie.id}'),
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
                          placeholder: (_, _) => Container(color: AppColors.surfaceVariant),
                          errorWidget: (_, _, _) => Container(
                            color: AppColors.surfaceVariant,
                            child: const Icon(Icons.movie, color: AppColors.textMuted),
                          ),
                        ),
                        if (isPreferred)
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
                                pref.label.split(' ').first,
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
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
              ),
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
        ).animate().fadeIn(delay: (30 * index).ms, duration: 300.ms);
      },
    );
  }
}

class _TvGrid extends ConsumerWidget {
  final List<TvSeries> tvShows;
  const _TvGrid({required this.tvShows});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pref = ref.watch(contentPreferenceProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final crossAxisCount = screenWidth < 340 ? 2 : 3;
    final childAspectRatio = screenWidth < 360 ? 0.52 : 0.55;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: screenWidth < 360 ? 8 : 10,
        mainAxisSpacing: screenWidth < 360 ? 8 : 10,
      ),
      itemCount: tvShows.length,
      itemBuilder: (context, index) {
        final tv = tvShows[index];
        final isPreferred = pref != ContentPreference.all && pref.matchesTv(tv);

        return GestureDetector(
          onTap: () => context.push('/tv/${tv.id}'),
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
                          placeholder: (_, _) => Container(color: AppColors.surfaceVariant),
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
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
                                pref.label.split(' ').first,
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
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
              ),
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
        ).animate().fadeIn(delay: (30 * index).ms, duration: 300.ms);
      },
    );
  }
}

class _SearchLoadingGrid extends StatelessWidget {
  const _SearchLoadingGrid();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final crossAxisCount = screenWidth < 340 ? 2 : 3;
    final childAspectRatio = screenWidth < 360 ? 0.52 : 0.55;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: screenWidth < 360 ? 8 : 10,
        mainAxisSpacing: screenWidth < 360 ? 8 : 10,
      ),
      itemCount: 9,
      itemBuilder: (_, _) => const ShimmerLoading(
        width: double.infinity,
        height: double.infinity,
        borderRadius: 12,
      ),
    );
  }
}

/// Rich Genre Explorer View shown when a specific genre is selected without search query.
class _GenreExplorerView extends ConsumerStatefulWidget {
  final GenreFilter activeGenre;
  const _GenreExplorerView({required this.activeGenre});

  @override
  ConsumerState<_GenreExplorerView> createState() => _GenreExplorerViewState();
}

class _GenreExplorerViewState extends ConsumerState<_GenreExplorerView> {
  int _tab = 0; // 0 = Film, 1 = Serial TV

  @override
  Widget build(BuildContext context) {
    final popularMovies = ref.watch(popularMoviesProvider);
    final topRatedMovies = ref.watch(topRatedMoviesProvider);
    final popularTv = ref.watch(popularTvProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _FilterChip(
                label: 'Film ${widget.activeGenre.label}',
                isSelected: _tab == 0,
                onTap: () => setState(() => _tab = 0),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Serial TV ${widget.activeGenre.label}',
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
                    final filtered = unique.values
                        .where((m) => widget.activeGenre.matchesMovie(m))
                        .toList();

                    if (filtered.isEmpty) {
                      return AppErrorWidget.empty(
                        message: 'Belum ada film untuk genre ${widget.activeGenre.label}',
                      );
                    }
                    return _MovieGrid(movies: filtered);
                  },
                  loading: () => const _SearchLoadingGrid(),
                  error: (e, _) => AppErrorWidget(
                    message: 'Gagal memuat film genre',
                    onRetry: () => ref.invalidate(popularMoviesProvider),
                  ),
                )
              : popularTv.when(
                  data: (tvShows) {
                    final filtered = tvShows
                        .where((t) => widget.activeGenre.matchesTv(t))
                        .toList();
                    if (filtered.isEmpty) {
                      return AppErrorWidget.empty(
                        message: 'Belum ada serial TV untuk genre ${widget.activeGenre.label}',
                      );
                    }
                    return _TvGrid(tvShows: filtered);
                  },
                  loading: () => const _SearchLoadingGrid(),
                  error: (e, _) => AppErrorWidget(
                    message: 'Gagal memuat serial TV genre',
                    onRetry: () => ref.invalidate(popularTvProvider),
                  ),
                ),
        ),
      ],
    );
  }
}
