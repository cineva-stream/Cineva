import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../../core/network/dio_client.dart';
import '../models/provider_stream_models.dart';

/// Service client for the FlixQuest Multi-Provider Scraper Cluster.
/// Proxies and extracts direct HLS (.m3u8) streams from over 17+ upstream CDNs.
class ScraperApiService {
  static const String defaultScraperUrl = 'https://scraper.flix.quest';
  static const List<String> defaultScraperInstances = [
    'https://scraper.flix.quest',
    'https://flixquest-scraper.onrender.com',
  ];

  final String _baseUrl;
  final Dio _dio;

  ScraperApiService({String? baseUrl, Dio? dio})
      : _baseUrl = _normalizeBaseUrl(
          baseUrl ??
              (dotenv.isInitialized
                  ? (dotenv.env['CINEVA_SCRAPER_API_URL'] ?? defaultScraperUrl)
                  : defaultScraperUrl),
        ),
        _dio = dio ?? DioClient.streamClient;

  static String _normalizeBaseUrl(String url) {
    final trimmed = url.trim().replaceAll(RegExp(r'/+$'), '');
    return trimmed.isEmpty ? defaultScraperUrl : trimmed;
  }

  /// Sends a GET request with automatic fallback between cluster instances.
  Future<Response<String>> _getWithFallback(
    String path, [
    Map<String, String>? queryParams,
    Duration? timeout,
  ]) async {
    final instances = <String>[
      _baseUrl,
      for (final s in defaultScraperInstances)
        if (_normalizeBaseUrl(s) != _baseUrl) _normalizeBaseUrl(s),
    ];

    DioException? lastError;
    for (final base in instances) {
      try {
        final root = base.endsWith('/api/v2') ? base : '$base/api/v2';
        final uri = Uri.parse('$root$path').replace(queryParameters: queryParams);
        return await _dio.get<String>(
          uri.toString(),
          options: Options(receiveTimeout: timeout ?? const Duration(seconds: 15)),
        );
      } on DioException catch (e) {
        lastError = e;
        debugPrint('[ScraperApiService] Instance $base failed for $path ($e), trying fallback instance...');
      } catch (_) {}
    }
    if (lastError != null) throw lastError;
    throw Exception('All scraper instances failed for $path');
  }

  /// Fetches all active, enabled upstream scraper providers.
  Future<List<VideoProvider>> getProviders() async {
    try {
      final response = await _getWithFallback('/providers', null, const Duration(seconds: 6));

      final body = _decodeJson(response.data);
      if (body['success'] != true) {
        return const [];
      }

      final rawList = body['providers'];
      if (rawList is! List) return const [];

      return rawList
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .where((item) => item['enabled'] == true)
          .map(
            (item) => VideoProvider.scraper(
              id: item['id']?.toString() ?? '',
              name: item['name']?.toString() ?? 'Provider',
              alias: item['alias']?.toString(),
              content: item['content']?.toString(),
            ),
          )
          .where((p) => p.apiId != null && p.apiId!.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('[ScraperApiService] Error fetching providers: $e');
      return const [];
    }
  }

  /// Scrapes direct video streams and subtitles for a Movie.
  Future<ProviderLoadResult> loadMovie({
    required String providerId,
    required int movieId,
  }) async {
    return _fetchStream(
      path: '/stream-movie',
      queryParams: {
        'provider': providerId,
        'tmdbId': '$movieId',
      },
      providerName: providerId,
    );
  }

  /// Scrapes direct video streams and subtitles for a TV Show episode.
  Future<ProviderLoadResult> loadTVEpisode({
    required String providerId,
    required int tvId,
    required int seasonNumber,
    required int episodeNumber,
  }) async {
    return _fetchStream(
      path: '/stream-tv',
      queryParams: {
        'provider': providerId,
        'tmdbId': '$tvId',
        'season': '$seasonNumber',
        'episode': '$episodeNumber',
      },
      providerName: providerId,
    );
  }

  Future<ProviderLoadResult> _fetchStream({
    required String path,
    required Map<String, String> queryParams,
    required String providerName,
  }) async {
    try {
      final uri = _endpoint(path, queryParams);
      debugPrint('[ScraperApiService] Fetching stream: $uri');

      final response = await _dio.get<String>(
        uri.toString(),
        options: Options(
          receiveTimeout: const Duration(seconds: 18),
        ),
      );

      final body = _decodeJson(response.data);
      if (body['success'] != true) {
        final errorMsg = body['error']?.toString() ?? body['message']?.toString() ?? 'Stream unavailable';
        return ProviderLoadResult(
          errorMessage: errorMsg,
          providerName: providerName,
        );
      }

      final links = <RegularVideoLinks>[];
      final subtitles = <RegularSubtitleLinks>[];
      final seenSubs = <String>{};

      final rawLinks = body['links'];
      if (rawLinks is List) {
        for (final rawLink in rawLinks.whereType<Map>()) {
          final linkMap = Map<String, dynamic>.from(rawLink);
          final link = RegularVideoLinks.fromJson(linkMap);
          if (link.url != null && link.url!.isNotEmpty) {
            links.add(link);
          }

          // Extract subtitles bundled in link
          final rawSubs = linkMap['subtitles'];
          if (rawSubs is List) {
            for (final rawSub in rawSubs.whereType<Map>()) {
              final sub = RegularSubtitleLinks.fromJson(Map<String, dynamic>.from(rawSub));
              if (sub.url != null && sub.url!.isNotEmpty) {
                final dedupeKey = '${sub.url}:${sub.language}';
                if (seenSubs.add(dedupeKey)) {
                  subtitles.add(sub);
                }
              }
            }
          }
        }
      }

      if (links.isEmpty) {
        return ProviderLoadResult(
          errorMessage: 'No playable video links found for $providerName',
          providerName: providerName,
        );
      }

      return ProviderLoadResult(
        success: true,
        videoLinks: links,
        subtitleLinks: subtitles,
        providerName: providerName,
      );
    } on TimeoutException {
      return ProviderLoadResult(
        errorMessage: 'Request to $providerName timed out',
        providerName: providerName,
      );
    } on DioException catch (dioErr) {
      final timedOut = [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ].contains(dioErr.type);
      return ProviderLoadResult(
        errorMessage: timedOut ? '$providerName timed out' : 'Network error on $providerName',
        providerName: providerName,
      );
    } catch (e) {
      return ProviderLoadResult(
        errorMessage: 'Error loading stream from $providerName: $e',
        providerName: providerName,
      );
    }
  }

  Uri _endpoint(String path, [Map<String, String>? queryParams]) {
    final root = _baseUrl.endsWith('/api/v2') ? _baseUrl : '$_baseUrl/api/v2';
    return Uri.parse('$root$path').replace(queryParameters: queryParams);
  }

  Map<String, dynamic> _decodeJson(String? data) {
    if (data == null || data.isEmpty) return const {};
    try {
      final decoded = jsonDecode(data);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      return const {};
    }
  }
}
