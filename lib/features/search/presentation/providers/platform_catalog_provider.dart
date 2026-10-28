import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/domain/entities/movie.dart';
import '../../../home/domain/entities/tv_series.dart';
import '../../../home/presentation/providers/home_providers.dart';

/// Fetches popular movies for a specific watch provider ID (e.g. Netflix = 8).
final platformMoviesProvider =
    FutureProvider.family<List<Movie>, int>((ref, providerId) async {
  final repo = ref.watch(movieRepositoryProvider);
  return repo.getMoviesByWatchProvider(providerId: providerId);
});

/// Fetches popular TV series for a specific watch provider ID.
final platformTvProvider =
    FutureProvider.family<List<TvSeries>, int>((ref, providerId) async {
  final repo = ref.watch(movieRepositoryProvider);
  return repo.getTvByWatchProvider(providerId: providerId);
});

/// Filter tab for platform catalog screen: 0 = All, 1 = Movies, 2 = TV Shows.
final platformTabProvider = StateProvider.autoDispose<int>((ref) => 0);
