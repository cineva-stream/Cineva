import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import 'interceptors/header_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'interceptors/single_flight_interceptor.dart';

/// Centralized Dio HTTP client factory.
///
/// Produces pre-configured [Dio] instances for TMDB,
/// OpenSubtitles APIs, and Scraper/Stream services with appropriate headers,
/// retries, and deduplication.
class DioClient {
  DioClient._();

  static Dio? _streamDio;

  /// Resilient Dio instance configured for Scraper API and Streaming services.
  /// Features exponential backoff retry on transient errors and single-flight deduplication.
  static Dio get streamClient => _streamDio ??= createStreamHttpClient();

  static Dio createStreamHttpClient({
    Duration connectTimeout = const Duration(seconds: 12),
    Duration receiveTimeout = const Duration(seconds: 25),
  }) {
    final dio = Dio(
      BaseOptions(
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        responseType: ResponseType.plain,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    dio.interceptors.add(HeaderInterceptor());
    dio.interceptors.add(SingleFlightInterceptor(dio));
    dio.interceptors.add(RetryInterceptor(dio, retries: 2));

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: false,
          responseBody: false,
          logPrint: (obj) => debugPrint('[StreamDio] $obj'),
        ),
      );
    }

    return dio;
  }

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
