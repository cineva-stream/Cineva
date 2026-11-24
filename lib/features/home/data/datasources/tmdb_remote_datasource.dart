import 'package:dio/dio.dart';

import '../../../../core/constants/content_preference.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/movie_model.dart';
import '../models/tv_series_model.dart';

/// Remote data source for fetching movie/TV catalog data from TMDB API.
class TmdbRemoteDatasource {
  final Dio _dio;
  final String languageCode;

  TmdbRemoteDatasource(this._dio, {this.languageCode = 'id-ID'});

  /// Fetch trending movies (day, or discover if preference set).
  Future<List<MovieModel>> getTrendingMovies({
    int page = 1,
    ContentPreference preference = ContentPreference.all,
  }) async {
    try {
      if (preference == ContentPreference.all) {
        final response = await _dio.get(
          '/trending/movie/day',
          queryParameters: {'page': page, 'language': languageCode},
        );
        return _parseMovieList(response.data);
      } else {
        final response = await _dio.get(
          '/discover/movie',
          queryParameters: _buildDiscoverMovieParams(
            preference,
            page: page,
            sortBy: 'popularity.desc',
          ),
        );
        return _parseMovieList(response.data);
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.statusMessage ?? 'Failed to fetch trending movies',
        e.response?.statusCode,
      );
    }
  }

  /// Fetch popular movies.
  Future<List<MovieModel>> getPopularMovies({
    int page = 1,
    ContentPreference preference = ContentPreference.all,
  }) async {
    try {
      if (preference == ContentPreference.all) {
        final response = await _dio.get(
          '/movie/popular',
          queryParameters: {'page': page, 'language': languageCode},
        );
        return _parseMovieList(response.data);
      } else {
        final response = await _dio.get(
          '/discover/movie',
          queryParameters: _buildDiscoverMovieParams(
            preference,
            page: page,
            sortBy: 'popularity.desc',
          ),
        );
        return _parseMovieList(response.data);
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.statusMessage ?? 'Failed to fetch popular movies',
        e.response?.statusCode,
      );
    }
  }

  /// Fetch top-rated movies.
  Future<List<MovieModel>> getTopRatedMovies({
    int page = 1,
    ContentPreference preference = ContentPreference.all,
  }) async {
    try {
      if (preference == ContentPreference.all) {
        final response = await _dio.get(
          '/movie/top_rated',
          queryParameters: {'page': page, 'language': languageCode},
        );
        return _parseMovieList(response.data);
      } else {
        final response = await _dio.get(
          '/discover/movie',
          queryParameters: _buildDiscoverMovieParams(
            preference,
            page: page,
            sortBy: 'vote_average.desc',
          ),
        );
        return _parseMovieList(response.data);
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.statusMessage ?? 'Failed to fetch top rated movies',
        e.response?.statusCode,
      );
    }
  }

  /// Fetch upcoming movies.
  Future<List<MovieModel>> getUpcomingMovies({
    int page = 1,
    ContentPreference preference = ContentPreference.all,
  }) async {
    try {
      if (preference == ContentPreference.all) {
        final response = await _dio.get(
          '/movie/upcoming',
          queryParameters: {'page': page, 'language': languageCode},
        );
        return _parseMovieList(response.data);
      } else {
        final response = await _dio.get(
          '/discover/movie',
          queryParameters: _buildDiscoverMovieParams(
            preference,
            page: page,
            sortBy: 'primary_release_date.desc',
          ),
        );
        return _parseMovieList(response.data);
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.statusMessage ?? 'Failed to fetch upcoming movies',
        e.response?.statusCode,
      );
    }
  }

  /// Fetch popular TV series.
  Future<List<TvSeriesModel>> getPopularTvSeries({
    int page = 1,
    ContentPreference preference = ContentPreference.all,
  }) async {
    try {
      if (preference == ContentPreference.all) {
        final response = await _dio.get(
          '/tv/popular',
          queryParameters: {'page': page, 'language': languageCode},
        );
        return _parseTvList(response.data);
      } else {
        final response = await _dio.get(
          '/discover/tv',
          queryParameters: _buildDiscoverTvParams(
            preference,
            page: page,
            sortBy: 'popularity.desc',
          ),
        );
        return _parseTvList(response.data);
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.statusMessage ?? 'Failed to fetch popular TV series',
        e.response?.statusCode,
      );
    }
  }

  /// Fetch top-rated TV series.
  Future<List<TvSeriesModel>> getTopRatedTvSeries({
    int page = 1,
    ContentPreference preference = ContentPreference.all,
  }) async {
    try {
      if (preference == ContentPreference.all) {
        final response = await _dio.get(
          '/tv/top_rated',
          queryParameters: {'page': page, 'language': languageCode},
        );
        return _parseTvList(response.data);
      } else {
        final response = await _dio.get(
          '/discover/tv',
          queryParameters: _buildDiscoverTvParams(
            preference,
            page: page,
            sortBy: 'vote_average.desc',
          ),
        );
        return _parseTvList(response.data);
      }
    } on DioException catch (e) {
      throw ServerException(
        e.response?.statusMessage ?? 'Failed to fetch top rated TV series',
        e.response?.statusCode,
      );
    }
  }

  String _todayIsoDate() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Fetch curated regional/genre movies that are already released and available to watch,
  /// prioritizing the latest releases or filtering by a specific [releaseYear] and [sortBy].
  Future<List<MovieModel>> getCuratedSectionMovies({
    required ContentPreference category,
    int page = 1,
    int? releaseYear,
    String sortBy = 'popularity.desc',
  }) async {
    try {
      final params = _buildDiscoverMovieParams(
        category,
        page: page,
        sortBy: sortBy,
      );
      params['primary_release_date.lte'] = _todayIsoDate();
      if (releaseYear != null && releaseYear > 1900) {
        params['primary_release_year'] = releaseYear;
      } else if (sortBy == 'popularity.desc') {
        // Default "Latest & Available": focus on modern recent releases so old random titles do not dominate
        final minYear = DateTime.now().year - 2;
        params['primary_release_date.gte'] = '$minYear-01-01';
      }
      if (sortBy == 'primary_release_date.desc') {
        params['vote_count.gte'] = category == ContentPreference.indonesia
            ? 2
            : 5;
      }
      final response = await _dio.get(
        '/discover/movie',
        queryParameters: params,
      );
      return _parseMovieList(response.data);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.statusMessage ?? 'Failed to fetch curated movies',
        e.response?.statusCode,
      );
    }
  }

  /// Fetch curated regional/genre TV series that are already released and available to watch,
  /// prioritizing the latest releases or filtering by a specific [releaseYear] and [sortBy].
  Future<List<TvSeriesModel>> getCuratedSectionTvSeries({
    required ContentPreference category,
    int page = 1,
    int? releaseYear,
    String sortBy = 'popularity.desc',
  }) async {
    try {
      final params = _buildDiscoverTvParams(
        category,
        page: page,
        sortBy: sortBy,
      );
      params['first_air_date.lte'] = _todayIsoDate();
      if (releaseYear != null && releaseYear > 1900) {
        params['first_air_date_year'] = releaseYear;
      } else if (sortBy == 'popularity.desc') {
        final minYear = DateTime.now().year - 2;
        params['first_air_date.gte'] = '$minYear-01-01';
      }
      if (sortBy == 'first_air_date.desc') {
        params['vote_count.gte'] = category == ContentPreference.indonesia
            ? 1
            : 3;
      }
      final response = await _dio.get('/discover/tv', queryParameters: params);
      return _parseTvList(response.data);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.statusMessage ?? 'Failed to fetch curated TV series',
        e.response?.statusCode,
      );
    }
  }

  Map<String, dynamic> _buildDiscoverMovieParams(
    ContentPreference preference, {
    int page = 1,
    String sortBy = 'popularity.desc',
  }) {
    final params = <String, dynamic>{
      'page': page,
      'language': languageCode,
      'sort_by': sortBy,
    };

    switch (preference) {
      case ContentPreference.indonesia:
        params['with_original_language'] = 'id';
        break;
      case ContentPreference.anime:
        params['with_genres'] = '16';
        params['with_original_language'] = 'ja';
        break;
      case ContentPreference.hollywood:
        params['with_original_language'] = 'en';
        params['region'] = 'US';
        break;
      case ContentPreference.korea:
        params['with_original_language'] = 'ko';
        break;
      case ContentPreference.japan:
        params['with_original_language'] = 'ja';
        break;
      case ContentPreference.bollywood:
        params['with_original_language'] = 'hi';
        break;
      case ContentPreference.all:
        break;
    }

    if (sortBy.contains('vote_average')) {
      params['vote_count.gte'] = preference == ContentPreference.anime
          ? 50
          : (preference == ContentPreference.indonesia ? 5 : 20);
    }

    return params;
  }

  Map<String, dynamic> _buildDiscoverTvParams(
    ContentPreference preference, {
    int page = 1,
    String sortBy = 'popularity.desc',
  }) {
    final params = <String, dynamic>{
      'page': page,
      'language': languageCode,
      'sort_by': sortBy,
    };

    switch (preference) {
      case ContentPreference.indonesia:
        params['with_original_language'] = 'id';
        break;
      case ContentPreference.anime:
        params['with_genres'] = '16';
        params['with_original_language'] = 'ja';
        break;
      case ContentPreference.hollywood:
        params['with_original_language'] = 'en';
        params['with_origin_country'] = 'US';
        break;
      case ContentPreference.korea:
        params['with_original_language'] = 'ko';
        break;
      case ContentPreference.japan:
        params['with_original_language'] = 'ja';
        break;
      case ContentPreference.bollywood:
        params['with_original_language'] = 'hi';
        break;
      case ContentPreference.all:
        break;
    }

    if (sortBy.contains('vote_average')) {
      params['vote_count.gte'] = preference == ContentPreference.anime
          ? 50
          : (preference == ContentPreference.indonesia ? 5 : 20);
    }

    return params;
  }

  /// Search multi (movies + TV shows).
  Future<List<MovieModel>> searchMovies(
    String query, {
    int page = 1,
    int? year,
  }) async {
    try {
      final response = await _dio.get(
        '/search/movie',
        queryParameters: {
          'query': query,
          'page': page,
          'language': languageCode,
          if (year != null && year > 1900) 'primary_release_year': year,
        },
      );
      return _parseMovieList(response.data);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.statusMessage ?? 'Search failed',
        e.response?.statusCode,
      );
    }
  }

  /// Search TV series.
  Future<List<TvSeriesModel>> searchTvSeries(
    String query, {
    int page = 1,
    int? year,
  }) async {
    try {
      final response = await _dio.get(
        '/search/tv',
        queryParameters: {
          'query': query,
          'page': page,
          'language': languageCode,
          if (year != null && year > 1900) 'first_air_date_year': year,
        },
      );
      return _parseTvList(response.data);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.statusMessage ?? 'Search failed',
        e.response?.statusCode,
      );
    }
  }

  /// Discover movies available on a specific streaming provider (e.g. Netflix = 8, Prime = 9, Disney+ = 337).
  Future<List<MovieModel>> getMoviesByWatchProvider({
    required dynamic providerId,
    int page = 1,
    String watchRegion = 'US',
  }) async {
    try {
      final response = await _dio.get(
        '/discover/movie',
        queryParameters: {
          'page': page,
          'language': languageCode,
          'sort_by': 'popularity.desc',
          'with_watch_providers': providerId.toString(),
          'watch_region': watchRegion,
        },
      );
      return _parseMovieList(response.data);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.statusMessage ?? 'Failed to fetch provider movies',
        e.response?.statusCode,
      );
    }
  }

  /// Discover TV series available on a specific streaming provider.
  Future<List<TvSeriesModel>> getTvByWatchProvider({
    required dynamic providerId,
    int page = 1,
    String watchRegion = 'US',
  }) async {
    try {
      final response = await _dio.get(
        '/discover/tv',
        queryParameters: {
          'page': page,
          'language': languageCode,
          'sort_by': 'popularity.desc',
          'with_watch_providers': providerId.toString(),
          'watch_region': watchRegion,
        },
      );
      return _parseTvList(response.data);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.statusMessage ?? 'Failed to fetch provider TV series',
        e.response?.statusCode,
      );
    }
  }

  /// Fetch personalized movie recommendations based on a movie ID.
  /// Automatically falls back to `/movie/{id}/similar` if `/recommendations` is empty.
  Future<List<MovieModel>> getMovieRecommendations(
    int movieId, {
    int page = 1,
  }) async {
    try {
      final response = await _dio.get(
        '/movie/$movieId/recommendations',
        queryParameters: {'page': page, 'language': languageCode},
      );
      final recList = _parseMovieList(response.data);
      if (recList.isNotEmpty) return recList;

      final similarResponse = await _dio.get(
        '/movie/$movieId/similar',
        queryParameters: {'page': page, 'language': languageCode},
      );
      return _parseMovieList(similarResponse.data);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.statusMessage ?? 'Failed to fetch movie recommendations',
        e.response?.statusCode,
      );
    }
  }

  /// Fetch personalized TV series recommendations based on a TV series ID.
  /// Automatically falls back to `/tv/{id}/similar` if `/recommendations` is empty.
  Future<List<TvSeriesModel>> getTvRecommendations(
    int tvId, {
    int page = 1,
  }) async {
    try {
      final response = await _dio.get(
        '/tv/$tvId/recommendations',
        queryParameters: {'page': page, 'language': languageCode},
      );
      final recList = _parseTvList(response.data);
      if (recList.isNotEmpty) return recList;

      final similarResponse = await _dio.get(
        '/tv/$tvId/similar',
        queryParameters: {'page': page, 'language': languageCode},
      );
      return _parseTvList(similarResponse.data);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.statusMessage ?? 'Failed to fetch TV recommendations',
        e.response?.statusCode,
      );
    }
  }

  List<MovieModel> _parseMovieList(dynamic data) {
    final results = data['results'] as List<dynamic>? ?? [];
    return results.map((json) => MovieModel.fromJson(json)).toList();
  }

  List<TvSeriesModel> _parseTvList(dynamic data) {
    final results = data['results'] as List<dynamic>? ?? [];
    return results.map((json) => TvSeriesModel.fromJson(json)).toList();
  }
}
