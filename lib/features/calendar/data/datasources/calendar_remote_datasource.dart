import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/airing_show_model.dart';

class CalendarRemoteDataSource {
  final Dio _dio;

  CalendarRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient.createTmdbClient();

  /// Fetches airing TV shows and anime for a specific [date] and [category].
  ///
  /// Categories supported:
  /// - 'all': All shows airing on that day
  /// - 'anime': Japanese animated shows (with_original_language=ja, with_genres=16)
  /// - 'kdrama': Korean series (with_original_language=ko)
  /// - 'western': English series (with_original_language=en)
  /// - 'indonesian': Indonesian series (with_original_language=id)
  Future<List<AiringShowModel>> getAiringShowsForDate({
    required DateTime date,
    String category = 'all',
    String language = 'en-US',
    int page = 1,
  }) async {
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final queryParams = <String, dynamic>{
      'air_date.gte': dateStr,
      'air_date.lte': dateStr,
      'sort_by': 'popularity.desc',
      'page': page,
      'language': language,
      'include_null_first_air_dates': false,
    };

    switch (category) {
      case 'anime':
        queryParams['with_original_language'] = 'ja';
        queryParams['with_genres'] = '16';
        break;
      case 'kdrama':
        queryParams['with_original_language'] = 'ko';
        break;
      case 'western':
        queryParams['with_original_language'] = 'en';
        break;
      case 'indonesian':
        queryParams['with_original_language'] = 'id';
        break;
      case 'all':
      default:
        break;
    }

    try {
      final response = await _dio.get(
        '/discover/tv',
        queryParameters: queryParams,
      );

      final results = (response.data['results'] as List<dynamic>?) ?? [];
      return results
          .map((item) => AiringShowModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } on DioException {
      // If primary language fails, fallback to en-US
      if (language != 'en-US') {
        queryParams['language'] = 'en-US';
        final response = await _dio.get(
          '/discover/tv',
          queryParameters: queryParams,
        );
        final results = (response.data['results'] as List<dynamic>?) ?? [];
        return results
            .map((item) => AiringShowModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      rethrow;
    }
  }
}

