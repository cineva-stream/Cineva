import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_env.dart';

import '../../../../core/network/dio_client.dart';
import '../models/provider_stream_models.dart';

/// Service client for the FlixQuest Multi-Provider Scraper Cluster.
/// Proxies and extracts direct HLS (.m3u8) streams from over 17+ upstream CDNs.
///
/// Cluster endpoints are injected via `--dart-define-from-file=.env` or
/// `android/key.properties` / `android/local.properties` (`CINEVA_SCRAPER_API_URL`
/// and `CINEVA_SCRAPER_FALLBACK_URL`) with zero hardcoded URLs in source code.
class ScraperApiService {
  static String get defaultScraperUrl {
    return AppEnv.cinevaScraperApiUrl.trim();
  }

  static List<String> get defaultScraperInstances {
    final primary = _normalizeBaseUrl(AppEnv.cinevaScraperApiUrl);
    final fallback = _normalizeBaseUrl(AppEnv.cinevaScraperFallbackUrl);
    return [
      if (primary.isNotEmpty) primary,
      if (fallback.isNotEmpty && fallback != primary) fallback,
    ];
  }

  final String _baseUrl;
  final Dio _dio;

  ScraperApiService({String? baseUrl, Dio? dio})
      : _baseUrl = _normalizeBaseUrl(
          baseUrl ?? AppEnv.cinevaScraperApiUrl,
        ),
        _dio = dio ?? DioClient.streamClient;

  static String _normalizeBaseUrl(String url) {
    final trimmed = url.trim().replaceAll(RegExp(r'/+$'), '');
    return trimmed;
  }

  /// Sends a GET request with automatic fallback between cluster instances.
  Future<Response<String>> _getWithFallback(
    String path, [
    Map<String, String>? queryParams,
    Duration? timeout,
  ]) async {
    final instances = <String>[
      if (_baseUrl.isNotEmpty) _baseUrl,
      for (final s in defaultScraperInstances)
        if (s.isNotEmpty && s != _baseUrl) s,
    ];

    if (instances.isEmpty) {
      throw Exception(
        'Scraper API URL is not configured. Set CINEVA_SCRAPER_API_URL in .env / key.properties / local.properties.',
      );
    }

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
      debugPrint('[ScraperApiService] Fetching stream: $path ($queryParams)');

      final response = await _getWithFallback(
        path,
        queryParams,
        const Duration(seconds: 15),
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

  /// Estimates stream byte size using a Scraper API v2 `sizeToken`.
  /// Ported from `ScraperApi.estimateStreamSize` in `flixquest-add-language`.
  Future<int?> estimateStreamSize(String token) async {
    final normalized = token.trim();
    if (normalized.isEmpty) return null;

    final instances = <String>[
      _baseUrl,
      for (final s in defaultScraperInstances)
        if (_normalizeBaseUrl(s) != _baseUrl) _normalizeBaseUrl(s),
    ];

    for (final base in instances) {
      try {
        final root = base.endsWith('/api/v2') ? base : '$base/api/v2';
        final uri = Uri.parse('$root/stream-size');
        final response = await _dio.post<String>(
          uri.toString(),
          data: jsonEncode({'token': normalized}),
          options: Options(
            headers: const {'Content-Type': 'application/json'},
            sendTimeout: const Duration(seconds: 12),
            receiveTimeout: const Duration(seconds: 25),
          ),
        );
        final body = _decodeJson(response.data);
        if (body['success'] == true) {
          final bytes = body['estimatedBytes'];
          if (bytes is num && bytes > 0) return bytes.round();
          if (bytes is String) {
            final parsed = int.tryParse(bytes);
            if (parsed != null && parsed > 0) return parsed;
          }
        }
      } catch (e) {
        debugPrint('[ScraperApiService] estimateStreamSize failed on $base: $e');
      }
    }
    return null;
  }

  /// Infers required HTTP headers (`Origin`, `Referer`, `User-Agent`) for known
  /// upstream CDNs (e.g. `vixsrc.to`, `secretanchor`, `boats`, `vixcloud`).
  /// Ported from `VideoUtils.inferVideoHeaders` in `flixquest-add-language`.
  static Map<String, String>? inferVideoHeaders(
    String? url, [
    Map<String, String>? explicitHeaders,
  ]) {
    if (explicitHeaders != null && explicitHeaders.isNotEmpty) {
      return Map<String, String>.from(explicitHeaders);
    }
    if (url == null || url.isEmpty) return null;

    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    if (host.contains('vixsrc.to') ||
        host.contains('secretanchor') ||
        host.contains('boats') ||
        host.contains('vixcloud')) {
      return const {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://vixsrc.to/',
        'Origin': 'https://vixsrc.to',
      };
    }

    if (url.toLowerCase().contains('vixsrc')) {
      return const {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://vixsrc.to/',
        'Origin': 'https://vixsrc.to',
      };
    }

    return null;
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
