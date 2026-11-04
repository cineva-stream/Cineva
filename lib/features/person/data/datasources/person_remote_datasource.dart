import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/person_detail_model.dart';

class PersonRemoteDataSource {
  final Dio _dio;

  PersonRemoteDataSource({Dio? dio}) : _dio = dio ?? DioClient.createTmdbClient();

  /// Fetches comprehensive person details, combined credits, and external IDs.
  Future<PersonDetailModel> getPersonDetail(
    int personId, {
    String language = 'en-US',
  }) async {
    final response = await _dio.get(
      '/person/$personId',
      queryParameters: {
        'append_to_response': 'combined_credits,external_ids',
        'language': language,
      },
    );

    final data = Map<String, dynamic>.from(response.data as Map);
    final biography = (data['biography'] as String? ?? '').trim();

    // Fallback to English biography if primary language (e.g. id-ID) has no bio
    if (biography.isEmpty && language != 'en-US') {
      try {
        final fbResponse = await _dio.get(
          '/person/$personId',
          queryParameters: {
            'language': 'en-US',
          },
        );
        final fbBio = (fbResponse.data['biography'] as String? ?? '').trim();
        if (fbBio.isNotEmpty) {
          data['biography'] = fbBio;
        }
      } catch (_) {}
    }

    return PersonDetailModel.fromJson(data);
  }
}

