import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../../core/constants/content_preference.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../../history/data/models/watch_history_item.dart';
import '../../../history/data/repositories/watch_history_repository.dart';
import '../../../settings/data/settings_service.dart';
import '../../../watchlist/data/watchlist_repository.dart';
import '../../data/datasources/tmdb_remote_datasource.dart';
import '../../data/repositories/movie_repository_impl.dart';
import '../../domain/entities/movie.dart';
import '../../domain/entities/tv_series.dart';
import '../../domain/repositories/movie_repository.dart';

// ── Dependency Providers ──

final tmdbDioProvider = Provider<Dio>((ref) {
  return DioClient.createTmdbClient();
});

final tmdbDatasourceProvider = Provider<TmdbRemoteDatasource>((ref) {
  final lang = ref.watch(appLanguageProvider);
  final tmdbLang = lang.tmdbLanguageCode;
  return TmdbRemoteDatasource(
    ref.watch(tmdbDioProvider),
    languageCode: tmdbLang,
  );
});

final movieRepositoryProvider = Provider<MovieRepository>((ref) {
  return MovieRepositoryImpl(ref.watch(tmdbDatasourceProvider));
});

// ── Content Preference Provider ──

class ContentPreferenceNotifier extends StateNotifier<ContentPreference> {
  ContentPreferenceNotifier([ContentPreference? initial])
    : super(initial ?? _safeLoadInitial());

  static ContentPreference _safeLoadInitial() {
    try {
      return ContentPreference.fromCode(SettingsService.getContentPreference());
    } catch (_) {
      return ContentPreference.all;
    }
  }

  Future<void> setPreference(ContentPreference pref) async {
    state = pref;
    try {
      await SettingsService.setContentPreference(pref.code);
    } catch (_) {}
  }
}

final contentPreferenceProvider =
    StateNotifierProvider<ContentPreferenceNotifier, ContentPreference>((ref) {
      return ContentPreferenceNotifier();
    });

// ── Data Providers (Reactively filter by user content preference) ──

final trendingMoviesProvider = FutureProvider<List<Movie>>((ref) {
  final pref = ref.watch(contentPreferenceProvider);
  return ref.watch(movieRepositoryProvider).getTrendingMovies(preference: pref);
});

final popularMoviesProvider = FutureProvider<List<Movie>>((ref) {
  final pref = ref.watch(contentPreferenceProvider);
  return ref.watch(movieRepositoryProvider).getPopularMovies(preference: pref);
});

final topRatedMoviesProvider = FutureProvider<List<Movie>>((ref) {
  final pref = ref.watch(contentPreferenceProvider);
  return ref.watch(movieRepositoryProvider).getTopRatedMovies(preference: pref);
});

final upcomingMoviesProvider = FutureProvider<List<Movie>>((ref) {
  final pref = ref.watch(contentPreferenceProvider);
  return ref.watch(movieRepositoryProvider).getUpcomingMovies(preference: pref);
});

final popularTvProvider = FutureProvider<List<TvSeries>>((ref) {
  final pref = ref.watch(contentPreferenceProvider);
  return ref
      .watch(movieRepositoryProvider)
      .getPopularTvSeries(preference: pref);
});

final topRatedTvProvider = FutureProvider<List<TvSeries>>((ref) {
  final pref = ref.watch(contentPreferenceProvider);
  return ref
      .watch(movieRepositoryProvider)
      .getTopRatedTvSeries(preference: pref);
});

// ── Curated Regional & Genre Section Providers (Latest & Available to Watch) ──

Future<List<Movie>> _loadCuratedSectionBlend(
  MovieRepository repo,
  ContentPreference category, {
  bool preferTvFirst = false,
}) async {
  final results = await Future.wait([
    repo.getCuratedSectionMovies(category: category, page: 1),
    repo.getCuratedSectionTvSeries(category: category, page: 1),
  ]);
  final movies = results[0] as List<Movie>;
  final tvShows = (results[1] as List<TvSeries>).map((t) => t.toMovie()).toList();

  final primary = preferTvFirst ? tvShows : movies;
  final secondary = preferTvFirst ? movies : tvShows;

  final blended = <Movie>[];
  final maxLen = primary.length > secondary.length
      ? primary.length
      : secondary.length;
  for (int i = 0; i < maxLen; i++) {
    if (i < primary.length &&
        primary[i].posterPath != null &&
        primary[i].posterPath!.isNotEmpty) {
      blended.add(primary[i]);
    }
    if (i < secondary.length &&
        secondary[i].posterPath != null &&
        secondary[i].posterPath!.isNotEmpty) {
      blended.add(secondary[i]);
    }
  }
  return blended;
}

final animeSectionProvider = FutureProvider<List<Movie>>((ref) {
  final repo = ref.watch(movieRepositoryProvider);
  return _loadCuratedSectionBlend(
    repo,
    ContentPreference.anime,
    preferTvFirst: true,
  );
});

final kDramaSectionProvider = FutureProvider<List<Movie>>((ref) {
  final repo = ref.watch(movieRepositoryProvider);
  return _loadCuratedSectionBlend(
    repo,
    ContentPreference.korea,
    preferTvFirst: true,
  );
});

final indonesiaSectionProvider = FutureProvider<List<Movie>>((ref) {
  final repo = ref.watch(movieRepositoryProvider);
  return _loadCuratedSectionBlend(
    repo,
    ContentPreference.indonesia,
    preferTvFirst: false,
  );
});

final hollywoodSectionProvider = FutureProvider<List<Movie>>((ref) {
  final repo = ref.watch(movieRepositoryProvider);
  return _loadCuratedSectionBlend(
    repo,
    ContentPreference.hollywood,
    preferTvFirst: false,
  );
});

final bollywoodSectionProvider = FutureProvider<List<Movie>>((ref) {
  final repo = ref.watch(movieRepositoryProvider);
  return _loadCuratedSectionBlend(
    repo,
    ContentPreference.bollywood,
    preferTvFirst: false,
  );
});

// ── Paginated Infinite Scroll Providers for Home Filter Catalog ──

class PaginatedMediaState<T> {
  final List<T> items;
  final int page;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  const PaginatedMediaState({
    this.items = const [],
    this.page = 1,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  PaginatedMediaState<T> copyWith({
    List<T>? items,
    int? page,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
  }) {
    return PaginatedMediaState<T>(
      items: items ?? this.items,
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

class PaginatedPopularMoviesNotifier
    extends StateNotifier<PaginatedMediaState<Movie>> {
  final MovieRepository _repo;
  final ContentPreference _pref;

  PaginatedPopularMoviesNotifier(this._repo, this._pref)
    : super(const PaginatedMediaState(isLoading: true)) {
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    try {
      final initial = await _repo.getPopularMovies(page: 1, preference: _pref);
      state = PaginatedMediaState(
        items: initial,
        page: 1,
        isLoading: false,
        hasMore: initial.isNotEmpty,
      );
    } catch (e) {
      state = PaginatedMediaState(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.page + 1;
      final nextItems = await _repo.getPopularMovies(
        page: nextPage,
        preference: _pref,
      );
      if (nextItems.isEmpty) {
        state = state.copyWith(isLoadingMore: false, hasMore: false);
      } else {
        final existingIds = state.items.map((m) => m.id).toSet();
        final newItems = nextItems
            .where((m) => !existingIds.contains(m.id))
            .toList();
        state = state.copyWith(
          items: [...state.items, ...newItems],
          page: nextPage,
          isLoadingMore: false,
          hasMore: nextItems.length >= 20,
        );
      }
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> refresh() async {
    state = const PaginatedMediaState(isLoading: true);
    await _loadInitial();
  }
}

class PaginatedPopularTvNotifier
    extends StateNotifier<PaginatedMediaState<TvSeries>> {
  final MovieRepository _repo;
  final ContentPreference _pref;

  PaginatedPopularTvNotifier(this._repo, this._pref)
    : super(const PaginatedMediaState(isLoading: true)) {
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    try {
      final initial = await _repo.getPopularTvSeries(
        page: 1,
        preference: _pref,
      );
      state = PaginatedMediaState(
        items: initial,
        page: 1,
        isLoading: false,
        hasMore: initial.isNotEmpty,
      );
    } catch (e) {
      state = PaginatedMediaState(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.page + 1;
      final nextItems = await _repo.getPopularTvSeries(
        page: nextPage,
        preference: _pref,
      );
      if (nextItems.isEmpty) {
        state = state.copyWith(isLoadingMore: false, hasMore: false);
      } else {
        final existingIds = state.items.map((t) => t.id).toSet();
        final newItems = nextItems
            .where((t) => !existingIds.contains(t.id))
            .toList();
        state = state.copyWith(
          items: [...state.items, ...newItems],
          page: nextPage,
          isLoadingMore: false,
          hasMore: nextItems.length >= 20,
        );
      }
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> refresh() async {
    state = const PaginatedMediaState(isLoading: true);
    await _loadInitial();
  }
}

final paginatedPopularMoviesProvider =
    StateNotifierProvider<
      PaginatedPopularMoviesNotifier,
      PaginatedMediaState<Movie>
    >((ref) {
      final repo = ref.watch(movieRepositoryProvider);
      final pref = ref.watch(contentPreferenceProvider);
      return PaginatedPopularMoviesNotifier(repo, pref);
    });

final paginatedPopularTvProvider =
    StateNotifierProvider<
      PaginatedPopularTvNotifier,
      PaginatedMediaState<TvSeries>
    >((ref) {
      final repo = ref.watch(movieRepositoryProvider);
      final pref = ref.watch(contentPreferenceProvider);
      return PaginatedPopularTvNotifier(repo, pref);
    });

// ── Personalized "Because You Watched..." Recommendations Provider ──

/// Represents a personalized recommendation row seeded by a watched or saved title.
class PersonalizedRecommendationGroup {
  final int seedId;
  final String seedTitle;
  final String seedMediaType; // 'movie' or 'tv'
  final String? seedPosterPath;
  final bool isFromWatchlist;
  final List<Movie> movies;
  final List<TvSeries> tvShows;

  const PersonalizedRecommendationGroup({
    required this.seedId,
    required this.seedTitle,
    required this.seedMediaType,
    this.seedPosterPath,
    this.isFromWatchlist = false,
    this.movies = const [],
    this.tvShows = const [],
  });

  bool get isTv => seedMediaType == 'tv';
  bool get isEmpty => movies.isEmpty && tvShows.isEmpty;
}

class RecommendationSeed {
  final int id;
  final String title;
  final String mediaType;
  final String? posterPath;
  final bool isFromWatchlist;

  const RecommendationSeed({
    required this.id,
    required this.title,
    required this.mediaType,
    this.posterPath,
    required this.isFromWatchlist,
  });
}

/// Extracts up to [maxSeeds] distinct recommendation seeds from watch history and watchlist.
List<RecommendationSeed> selectRecommendationSeeds({
  required List<WatchHistoryItem> history,
  required List<WatchlistItem> watchlist,
  int maxSeeds = 2,
}) {
  final seeds = <RecommendationSeed>[];
  final seenKeys = <String>{};

  // 1. Prioritize titles from watch history (watched >= 15s or completed first)
  final meaningfulHistory = history.where(
    (h) => h.id > 0 && h.title.trim().isNotEmpty && (h.positionMs >= 15000 || h.isCompleted),
  );
  final fallbackHistory = history.where(
    (h) => h.id > 0 && h.title.trim().isNotEmpty,
  );

  for (final item in [...meaningfulHistory, ...fallbackHistory]) {
    if (seeds.length >= maxSeeds) break;
    final type = item.mediaType == 'tv' ? 'tv' : 'movie';
    final key = '${type}_${item.id}';
    if (seenKeys.add(key)) {
      seeds.add(
        RecommendationSeed(
          id: item.id,
          title: item.title.trim(),
          mediaType: type,
          posterPath: item.posterPath,
          isFromWatchlist: false,
        ),
      );
    }
  }

  // 2. Fallback/supplement with most recently saved Watchlist items if < maxSeeds
  for (final item in watchlist) {
    if (seeds.length >= maxSeeds) break;
    if (item.id <= 0 || item.title.trim().isEmpty) continue;
    final type = item.type == 'tv' ? 'tv' : 'movie';
    final key = '${type}_${item.id}';
    if (seenKeys.add(key)) {
      seeds.add(
        RecommendationSeed(
          id: item.id,
          title: item.title.trim(),
          mediaType: type,
          posterPath: item.posterPath,
          isFromWatchlist: true,
        ),
      );
    }
  }

  return seeds;
}

final becauseYouWatchedProvider =
    FutureProvider<List<PersonalizedRecommendationGroup>>((ref) async {
      final history = ref.watch(watchHistoryProvider);
      final watchlist = ref.watch(watchlistProvider);
      final repo = ref.watch(movieRepositoryProvider);

      final seeds = selectRecommendationSeeds(
        history: history,
        watchlist: watchlist,
        maxSeeds: 2,
      );

      if (seeds.isEmpty) return const [];

      // Collect already-completed or heavily-watched IDs so we recommend fresh titles
      final completedMovieIds = <int>{};
      final completedTvIds = <int>{};
      for (final h in history) {
        if (h.isCompleted || h.progressPercent >= 0.85) {
          if (h.mediaType == 'tv') {
            completedTvIds.add(h.id);
          } else {
            completedMovieIds.add(h.id);
          }
        }
      }

      final groups = await Future.wait(
        seeds.map((seed) async {
          try {
            if (seed.mediaType == 'tv') {
              final recs = await repo.getTvRecommendations(seed.id);
              final filtered = recs
                  .where(
                    (tv) =>
                        tv.id != seed.id &&
                        !completedTvIds.contains(tv.id) &&
                        (tv.posterPath != null && tv.posterPath!.isNotEmpty),
                  )
                  .take(16)
                  .toList();
              return PersonalizedRecommendationGroup(
                seedId: seed.id,
                seedTitle: seed.title,
                seedMediaType: 'tv',
                seedPosterPath: seed.posterPath,
                isFromWatchlist: seed.isFromWatchlist,
                tvShows: filtered,
              );
            } else {
              final recs = await repo.getMovieRecommendations(seed.id);
              final filtered = recs
                  .where(
                    (m) =>
                        m.id != seed.id &&
                        !completedMovieIds.contains(m.id) &&
                        (m.posterPath != null && m.posterPath!.isNotEmpty),
                  )
                  .take(16)
                  .toList();
              return PersonalizedRecommendationGroup(
                seedId: seed.id,
                seedTitle: seed.title,
                seedMediaType: 'movie',
                seedPosterPath: seed.posterPath,
                isFromWatchlist: seed.isFromWatchlist,
                movies: filtered,
              );
            }
          } catch (_) {
            return PersonalizedRecommendationGroup(
              seedId: seed.id,
              seedTitle: seed.title,
              seedMediaType: seed.mediaType,
              seedPosterPath: seed.posterPath,
              isFromWatchlist: seed.isFromWatchlist,
            );
          }
        }),
      );

      return groups.where((g) => !g.isEmpty).toList();
    });

