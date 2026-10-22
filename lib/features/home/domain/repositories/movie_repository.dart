import '../../../../core/constants/content_preference.dart';
import '../../domain/entities/movie.dart';
import '../../domain/entities/tv_series.dart';

/// Abstract repository defining the contract for movie/TV data operations.
abstract class MovieRepository {
  Future<List<Movie>> getTrendingMovies({
    int page = 1,
    ContentPreference preference = ContentPreference.all,
  });
  Future<List<Movie>> getPopularMovies({
    int page = 1,
    ContentPreference preference = ContentPreference.all,
  });
  Future<List<Movie>> getTopRatedMovies({
    int page = 1,
    ContentPreference preference = ContentPreference.all,
  });
  Future<List<Movie>> getUpcomingMovies({
    int page = 1,
    ContentPreference preference = ContentPreference.all,
  });
  Future<List<TvSeries>> getPopularTvSeries({
    int page = 1,
    ContentPreference preference = ContentPreference.all,
  });
  Future<List<TvSeries>> getTopRatedTvSeries({
    int page = 1,
    ContentPreference preference = ContentPreference.all,
  });
  Future<List<Movie>> searchMovies(String query, {int page = 1});
  Future<List<TvSeries>> searchTvSeries(String query, {int page = 1});
}
