import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/upcoming_media_model.dart';

class UpcomingRemoteDataSource {
  final Dio _dio;

  UpcomingRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient.createTmdbClient();

  /// Fetches upcoming movies and/or TV series sorted by release date.
  ///
  /// [category]: 'all', 'movie', or 'tv'
  Future<List<UpcomingMediaModel>> getUpcomingMedia({
    String category = 'all',
    String language = 'en-US',
  }) async {
    final now = DateTime.now();
    final todayStr =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final List<UpcomingMediaModel> results = [];

    // 1. Fetch upcoming movies
    if (category == 'all' || category == 'movie') {
      try {
        final response = await _dio.get(
          '/discover/movie',
          queryParameters: {
            'primary_release_date.gte': todayStr,
            'sort_by': 'primary_release_date.asc',
            'language': language,
            'page': 1,
            'include_video': false,
            'vote_count.gte': 0,
          },
        );
        final list = (response.data['results'] as List<dynamic>?) ?? [];
        for (final item in list) {
          final m = UpcomingMediaModel.fromJson(
            Map<String, dynamic>.from(item as Map),
            mediaType: 'movie',
          );
          if (m.releaseDate.isNotEmpty && m.posterPath != null) {
            results.add(m);
          }
        }
      } catch (_) {}
    }

    // 2. Fetch upcoming TV series
    if (category == 'all' || category == 'tv') {
      try {
        final response = await _dio.get(
          '/discover/tv',
          queryParameters: {
            'first_air_date.gte': todayStr,
            'sort_by': 'first_air_date.asc',
            'language': language,
            'page': 1,
            'include_null_first_air_dates': false,
          },
        );
        final list = (response.data['results'] as List<dynamic>?) ?? [];
        for (final item in list) {
          final t = UpcomingMediaModel.fromJson(
            Map<String, dynamic>.from(item as Map),
            mediaType: 'tv',
          );
          if (t.releaseDate.isNotEmpty && t.posterPath != null) {
            results.add(t);
          }
        }
      } catch (_) {}
    }

    // Sort chronologically by releaseDate ascending (soonest to release first)
    results.sort((a, b) => a.releaseDate.compareTo(b.releaseDate));

    return results;
  }
}

