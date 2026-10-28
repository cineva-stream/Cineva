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
          queryParameters: _buildDiscoverMovieParams(preference, page: page, sortBy: 'popularity.desc'),
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
          queryParameters: _buildDiscoverMovieParams(preference, page: page, sortBy: 'popularity.desc'),
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
          queryParameters: _buildDiscoverMovieParams(preference, page: page, sortBy: 'vote_average.desc'),
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
          queryParameters: _buildDiscoverMovieParams(preference, page: page, sortBy: 'primary_release_date.desc'),
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
          queryParameters: _buildDiscoverTvParams(preference, page: page, sortBy: 'popularity.desc'),
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
          queryParameters: _buildDiscoverTvParams(preference, page: page, sortBy: 'vote_average.desc'),
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
  Future<List<MovieModel>> searchMovies(String query, {int page = 1}) async {
    try {
      final response = await _dio.get(
        '/search/movie',
        queryParameters: {
          'query': query,
          'page': page,
          'language': languageCode,
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
  Future<List<TvSeriesModel>> searchTvSeries(String query, {int page = 1}) async {
    try {
      final response = await _dio.get(
        '/search/tv',
        queryParameters: {
          'query': query,
          'page': page,
          'language': languageCode,
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
    required int providerId,
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
          'with_watch_providers': providerId,
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
    required int providerId,
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
          'with_watch_providers': providerId,
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

  List<MovieModel> _parseMovieList(dynamic data) {
    final results = data['results'] as List<dynamic>? ?? [];
    return results.map((json) => MovieModel.fromJson(json)).toList();
  }

  List<TvSeriesModel> _parseTvList(dynamic data) {
    final results = data['results'] as List<dynamic>? ?? [];
    return results.map((json) => TvSeriesModel.fromJson(json)).toList();
  }
}
