import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../../core/constants/content_preference.dart';
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
  return TmdbRemoteDatasource(ref.watch(tmdbDioProvider));
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
