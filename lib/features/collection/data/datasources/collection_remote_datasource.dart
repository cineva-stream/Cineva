import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/movie_collection_model.dart';

class CollectionRemoteDataSource {
  final Dio _dio;

  CollectionRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient.createTmdbClient();

  /// Fetches franchise collection details and its movie parts.
  Future<MovieCollectionModel> getCollectionDetail(
    int collectionId, {
    String language = 'en-US',
  }) async {
    final response = await _dio.get(
      '/collection/$collectionId',
      queryParameters: {
        'language': language,
      },
    );

    final data = Map<String, dynamic>.from(response.data as Map);
    final overview = (data['overview'] as String? ?? '').trim();

    // Fallback to English overview if localized overview is empty
    if (overview.isEmpty && language != 'en-US') {
      try {
        final fbResponse = await _dio.get(
          '/collection/$collectionId',
          queryParameters: {
            'language': 'en-US',
          },
        );
        final fbOverview = (fbResponse.data['overview'] as String? ?? '').trim();
        if (fbOverview.isNotEmpty) {
          data['overview'] = fbOverview;
        }
      } catch (_) {}
    }

    return MovieCollectionModel.fromJson(data);
  }
}

