import '../../../../core/constants/content_preference.dart';
import '../../domain/entities/movie.dart';
import '../../domain/entities/tv_series.dart';
import '../../domain/repositories/movie_repository.dart';
import '../datasources/tmdb_remote_datasource.dart';

/// Concrete implementation of [MovieRepository] backed by TMDB API.
class MovieRepositoryImpl implements MovieRepository {
  final TmdbRemoteDatasource _remoteDatasource;

  MovieRepositoryImpl(this._remoteDatasource);

  @override
  Future<List<Movie>> getTrendingMovies({
    int page = 1,
    ContentPreference preference = ContentPreference.all,
  }) {
    return _remoteDatasource.getTrendingMovies(page: page, preference: preference);
  }

  @override
  Future<List<Movie>> getPopularMovies({
    int page = 1,
    ContentPreference preference = ContentPreference.all,
  }) {
    return _remoteDatasource.getPopularMovies(page: page, preference: preference);
  }

  @override
  Future<List<Movie>> getTopRatedMovies({
    int page = 1,
    ContentPreference preference = ContentPreference.all,
  }) {
    return _remoteDatasource.getTopRatedMovies(page: page, preference: preference);
  }

  @override
  Future<List<Movie>> getUpcomingMovies({
    int page = 1,
    ContentPreference preference = ContentPreference.all,
  }) {
    return _remoteDatasource.getUpcomingMovies(page: page, preference: preference);
  }

  @override
  Future<List<TvSeries>> getPopularTvSeries({
    int page = 1,
    ContentPreference preference = ContentPreference.all,
  }) {
    return _remoteDatasource.getPopularTvSeries(page: page, preference: preference);
  }

  @override
  Future<List<TvSeries>> getTopRatedTvSeries({
    int page = 1,
    ContentPreference preference = ContentPreference.all,
  }) {
    return _remoteDatasource.getTopRatedTvSeries(page: page, preference: preference);
  }

  @override
  Future<List<Movie>> searchMovies(String query, {int page = 1}) {
    return _remoteDatasource.searchMovies(query, page: page);
  }

  @override
  Future<List<TvSeries>> searchTvSeries(String query, {int page = 1}) {
    return _remoteDatasource.searchTvSeries(query, page: page);
  }

  @override
  Future<List<Movie>> getMoviesByWatchProvider({required int providerId, int page = 1}) {
    return _remoteDatasource.getMoviesByWatchProvider(providerId: providerId, page: page);
  }

  @override
  Future<List<TvSeries>> getTvByWatchProvider({required int providerId, int page = 1}) {
    return _remoteDatasource.getTvByWatchProvider(providerId: providerId, page: page);
  }
}
