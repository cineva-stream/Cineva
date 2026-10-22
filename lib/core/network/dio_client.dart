import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';

/// Centralized Dio HTTP client factory.
///
/// Produces pre-configured [Dio] instances for TMDB and
/// OpenSubtitles APIs with appropriate headers and timeouts.
class DioClient {
  DioClient._();

  /// Dio instance configured for TMDB API calls.
  static Dio createTmdbClient() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.tmdbBaseUrl,
        connectTimeout: AppConstants.connectionTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${dotenv.env['TMDB_ACCESS_TOKEN'] ?? ''}',
        },
      ),
    );

    dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (obj) => debugPrint('[TMDB] $obj'),
      ),
    );

    return dio;
  }

  /// Dio instance configured for OpenSubtitles API calls.
  static Dio createOpenSubtitlesClient() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.openSubtitlesBaseUrl,
        connectTimeout: AppConstants.connectionTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Api-Key': dotenv.env['OPENSUBTITLES_API_KEY'] ?? '',
          'User-Agent': 'Cineva v${AppConstants.appVersion}',
        },
      ),
    );

    dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (obj) => debugPrint('[OpenSub] $obj'),
      ),
    );

    return dio;
  }
}
