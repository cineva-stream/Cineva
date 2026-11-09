import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../../core/constants/content_preference.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../../core/network/dio_client.dart';
import '../../../settings/data/settings_service.dart';
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
  final tmdbLang = lang == AppLanguage.en ? 'en-US' : 'id-ID';
  return TmdbRemoteDatasource(ref.watch(tmdbDioProvider), languageCode: tmdbLang);
});

final movieRepositoryProvider = Provider<MovieRepository>((ref) {
  return MovieRepositoryImpl(ref.watch(tmdbDatasourceProvider));
});

// ── Content Preference Provider ──

class ContentPreferenceNotifier extends StateNotifier<ContentPreference> {
  ContentPreferenceNotifier()
      : super(ContentPreference.fromCode(SettingsService.getContentPreference()));

  Future<void> setPreference(ContentPreference pref) async {
    state = pref;
    await SettingsService.setContentPreference(pref.code);
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
  return ref.watch(movieRepositoryProvider).getPopularTvSeries(preference: pref);
});

final topRatedTvProvider = FutureProvider<List<TvSeries>>((ref) {
  final pref = ref.watch(contentPreferenceProvider);
  return ref.watch(movieRepositoryProvider).getTopRatedTvSeries(preference: pref);
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

class PaginatedPopularMoviesNotifier extends StateNotifier<PaginatedMediaState<Movie>> {
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
      state = PaginatedMediaState(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.page + 1;
      final nextItems = await _repo.getPopularMovies(page: nextPage, preference: _pref);
      if (nextItems.isEmpty) {
        state = state.copyWith(isLoadingMore: false, hasMore: false);
      } else {
        final existingIds = state.items.map((m) => m.id).toSet();
        final newItems = nextItems.where((m) => !existingIds.contains(m.id)).toList();
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

class PaginatedPopularTvNotifier extends StateNotifier<PaginatedMediaState<TvSeries>> {
  final MovieRepository _repo;
  final ContentPreference _pref;

  PaginatedPopularTvNotifier(this._repo, this._pref)
      : super(const PaginatedMediaState(isLoading: true)) {
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    try {
      final initial = await _repo.getPopularTvSeries(page: 1, preference: _pref);
      state = PaginatedMediaState(
        items: initial,
        page: 1,
        isLoading: false,
        hasMore: initial.isNotEmpty,
      );
    } catch (e) {
      state = PaginatedMediaState(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.page + 1;
      final nextItems = await _repo.getPopularTvSeries(page: nextPage, preference: _pref);
      if (nextItems.isEmpty) {
        state = state.copyWith(isLoadingMore: false, hasMore: false);
      } else {
        final existingIds = state.items.map((t) => t.id).toSet();
        final newItems = nextItems.where((t) => !existingIds.contains(t.id)).toList();
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
    StateNotifierProvider<PaginatedPopularMoviesNotifier, PaginatedMediaState<Movie>>((ref) {
  final repo = ref.watch(movieRepositoryProvider);
  final pref = ref.watch(contentPreferenceProvider);
  return PaginatedPopularMoviesNotifier(repo, pref);
});

final paginatedPopularTvProvider =
    StateNotifierProvider<PaginatedPopularTvNotifier, PaginatedMediaState<TvSeries>>((ref) {
  final repo = ref.watch(movieRepositoryProvider);
  final pref = ref.watch(contentPreferenceProvider);
  return PaginatedPopularTvNotifier(repo, pref);
});
