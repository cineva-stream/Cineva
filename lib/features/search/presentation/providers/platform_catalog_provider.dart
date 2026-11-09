import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/domain/entities/movie.dart';
import '../../../home/domain/entities/tv_series.dart';
import '../../../home/domain/repositories/movie_repository.dart';
import '../../../home/presentation/providers/home_providers.dart';

/// State for paginated catalog loading (infinite scrolling).
class PaginatedPlatformState<T> {
  final List<T> items;
  final int page;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  const PaginatedPlatformState({
    this.items = const [],
    this.page = 1,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  PaginatedPlatformState<T> copyWith({
    List<T>? items,
    int? page,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
  }) {
    return PaginatedPlatformState<T>(
      items: items ?? this.items,
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

/// Paginated notifier for streaming platform movies.
class PlatformMoviesNotifier extends StateNotifier<PaginatedPlatformState<Movie>> {
  final MovieRepository? _repo;
  final String _providerQuery;

  PlatformMoviesNotifier(MovieRepository repo, this._providerQuery)
      : _repo = repo,
        super(const PaginatedPlatformState(isLoading: true)) {
    _loadInitial();
  }

  PlatformMoviesNotifier.withInitial(List<Movie> initialItems)
      : _repo = null,
        _providerQuery = '',
        super(PaginatedPlatformState(
          items: initialItems,
          isLoading: false,
          hasMore: false,
        ));

  Future<void> _loadInitial() async {
    if (_repo == null) return;
    try {
      final initial = await _repo.getMoviesByWatchProvider(
        providerId: _providerQuery,
        page: 1,
      );
      state = PaginatedPlatformState(
        items: initial,
        page: 1,
        isLoading: false,
        hasMore: initial.isNotEmpty,
      );
    } catch (e) {
      state = PaginatedPlatformState(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (_repo == null || state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.page + 1;
      final nextItems = await _repo.getMoviesByWatchProvider(
        providerId: _providerQuery,
        page: nextPage,
      );
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
    state = const PaginatedPlatformState(isLoading: true);
    await _loadInitial();
  }
}

/// Paginated notifier for streaming platform TV series.
class PlatformTvNotifier extends StateNotifier<PaginatedPlatformState<TvSeries>> {
  final MovieRepository? _repo;
  final String _providerQuery;

  PlatformTvNotifier(MovieRepository repo, this._providerQuery)
      : _repo = repo,
        super(const PaginatedPlatformState(isLoading: true)) {
    _loadInitial();
  }

  PlatformTvNotifier.withInitial(List<TvSeries> initialItems)
      : _repo = null,
        _providerQuery = '',
        super(PaginatedPlatformState(
          items: initialItems,
          isLoading: false,
          hasMore: false,
        ));

  Future<void> _loadInitial() async {
    if (_repo == null) return;
    try {
      final initial = await _repo.getTvByWatchProvider(
        providerId: _providerQuery,
        page: 1,
      );
      state = PaginatedPlatformState(
        items: initial,
        page: 1,
        isLoading: false,
        hasMore: initial.isNotEmpty,
      );
    } catch (e) {
      state = PaginatedPlatformState(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (_repo == null || state.isLoading || state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.page + 1;
      final nextItems = await _repo.getTvByWatchProvider(
        providerId: _providerQuery,
        page: nextPage,
      );
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
    state = const PaginatedPlatformState(isLoading: true);
    await _loadInitial();
  }
}

/// Paginated provider family for platform movies.
final paginatedPlatformMoviesProvider = StateNotifierProvider.autoDispose
    .family<PlatformMoviesNotifier, PaginatedPlatformState<Movie>, String>((ref, providerQuery) {
  final repo = ref.watch(movieRepositoryProvider);
  return PlatformMoviesNotifier(repo, providerQuery);
});

/// Paginated provider family for platform TV series.
final paginatedPlatformTvProvider = StateNotifierProvider.autoDispose
    .family<PlatformTvNotifier, PaginatedPlatformState<TvSeries>, String>((ref, providerQuery) {
  final repo = ref.watch(movieRepositoryProvider);
  return PlatformTvNotifier(repo, providerQuery);
});

/// Legacy compatibility providers (first page fetch).
final platformMoviesProvider =
    FutureProvider.family<List<Movie>, int>((ref, providerId) async {
  final repo = ref.watch(movieRepositoryProvider);
  return repo.getMoviesByWatchProvider(providerId: providerId);
});

final platformTvProvider =
    FutureProvider.family<List<TvSeries>, int>((ref, providerId) async {
  final repo = ref.watch(movieRepositoryProvider);
  return repo.getTvByWatchProvider(providerId: providerId);
});

/// Filter tab for platform catalog screen: 0 = All, 1 = Movies, 2 = TV Shows.
final platformTabProvider = StateProvider.autoDispose<int>((ref) => 0);
