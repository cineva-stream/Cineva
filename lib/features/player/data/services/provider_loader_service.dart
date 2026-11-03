import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/provider_stream_models.dart';
import 'scraper_api_service.dart';
import 'vixsrc_stream_service.dart';

class ProviderSelection {
  final VideoProvider provider;
  final ProviderLoadResult result;

  const ProviderSelection({
    required this.provider,
    required this.result,
  });
}

typedef ProviderProgressCallback = void Function(
  VideoProvider provider,
  bool isSuccess,
  String? errorMessage,
);

/// Multi-provider stream loader with sequential failover and direct HLS extraction.
/// Eliminates dead streams and maximizes playback success across movies & series.
class ProviderLoaderService {
  final ScraperApiService _scraperApi;
  List<VideoProvider>? _cachedProviders;

  ProviderLoaderService({ScraperApiService? scraperApi})
      : _scraperApi = scraperApi ?? ScraperApiService();

  /// Fallback static providers list to ensure full scraper coverage even if
  /// the remote cluster index endpoint is sleeping or temporarily unreachable.
  static const List<VideoProvider> fallbackScraperProviders = [
    VideoProvider(
      fullName: 'ShowBox (Adwa CDN)',
      alias: 'ShowBox',
      codeName: 'scraper:showbox',
      type: VideoProviderType.scraperApi,
      apiId: 'showbox',
    ),
    VideoProvider(
      fullName: 'StreamFlix (Harar)',
      alias: 'StreamFlix',
      codeName: 'scraper:streamflix',
      type: VideoProviderType.scraperApi,
      apiId: 'streamflix',
    ),
    VideoProvider(
      fullName: 'AsiaFlix (Anime & Asia)',
      alias: 'AsiaFlix',
      codeName: 'scraper:asiaflix',
      type: VideoProviderType.scraperApi,
      apiId: 'asiaflix',
    ),
    VideoProvider(
      fullName: 'Cinejoy',
      alias: 'Cinejoy',
      codeName: 'scraper:cinejoy',
      type: VideoProviderType.scraperApi,
      apiId: 'cinejoy',
    ),
    VideoProvider(
      fullName: 'Movy Stream',
      alias: 'Movy',
      codeName: 'scraper:movy',
      type: VideoProviderType.scraperApi,
      apiId: 'movy',
    ),
    VideoProvider(
      fullName: 'Aether Cloud',
      alias: 'Aether',
      codeName: 'scraper:aether',
      type: VideoProviderType.scraperApi,
      apiId: 'aether',
    ),
    VideoProvider(
      fullName: 'ZStream',
      alias: 'ZStream',
      codeName: 'scraper:zstream',
      type: VideoProviderType.scraperApi,
      apiId: 'zstream',
    ),
    VideoProvider(
      fullName: 'YoTurkish',
      alias: 'YoTurkish',
      codeName: 'scraper:yoturkish',
      type: VideoProviderType.scraperApi,
      apiId: 'yoturkish',
    ),
  ];

  /// Retrieves the ordered list of streaming providers (Direct VixSrc + Scraper Cluster).
  Future<List<VideoProvider>> getAvailableProviders({bool forceRefresh = false}) async {
    if (_cachedProviders != null && !forceRefresh) {
      return _cachedProviders!;
    }

    final list = <VideoProvider>[
      VideoProvider.directVixSrc,
    ];

    try {
      final rawScrapers = await _scraperApi.getProviders();
      final scraperProviders = List<VideoProvider>.from(rawScrapers);

      if (scraperProviders.isEmpty) {
        list.addAll(fallbackScraperProviders);
      } else {
        // Prioritize high-performance known scrapers
        final prioritizedIds = [
          'showbox',
          'streamflix',
          'asiaflix',
          'cinejoy',
          'movy',
          'aether',
          'zstream',
          'yoturkish',
        ];

        scraperProviders.sort((a, b) {
          final idxA = prioritizedIds.indexOf(a.apiId ?? '');
          final idxB = prioritizedIds.indexOf(b.apiId ?? '');
          final rankA = idxA >= 0 ? idxA : 999;
          final rankB = idxB >= 0 ? idxB : 999;
          return rankA.compareTo(rankB);
        });

        list.addAll(scraperProviders);
      }
    } catch (e) {
      debugPrint('[ProviderLoaderService] Remote scraper discovery error ($e). Using resilient fallback providers.');
      list.addAll(fallbackScraperProviders);
    }

    _cachedProviders = list;
    return list;
  }

  /// Tries each provider in order until one returns playable HLS/MP4 streams.
  Future<ProviderSelection?> loadFirstSuccessful({
    required int tmdbId,
    int? season,
    int? episode,
    ProviderProgressCallback? onProgress,
  }) async {
    final providers = await getAvailableProviders();

    for (final provider in providers) {
      debugPrint('[ProviderLoaderService] Trying provider: ${provider.displayName} (${provider.codeName})');
      ProviderLoadResult result;

      try {
        result = await loadFromProvider(
          provider: provider,
          tmdbId: tmdbId,
          season: season,
          episode: episode,
        );
      } catch (err) {
        result = ProviderLoadResult(
          errorMessage: err.toString(),
          providerName: provider.displayName,
        );
      }

      final success = result.hasPlayableStreams;
      onProgress?.call(provider, success, result.errorMessage);

      if (success) {
        debugPrint('[ProviderLoaderService] Stream found on ${provider.displayName}! Playable links: ${result.videoLinks?.length}');
        return ProviderSelection(provider: provider, result: result);
      }
    }

    debugPrint('[ProviderLoaderService] All direct providers failed for tmdbId=$tmdbId');
    return null;
  }

  /// Loads stream specifically from a selected provider (e.g. from user manual server switch).
  Future<ProviderLoadResult> loadFromProvider({
    required VideoProvider provider,
    required int tmdbId,
    int? season,
    int? episode,
  }) async {
    switch (provider.type) {
      case VideoProviderType.directVixSrc:
        return VixSrcStreamService.loadProviderResult(
          tmdbId: tmdbId,
          season: season,
          episode: episode,
        );

      case VideoProviderType.scraperApi:
        final apiId = provider.apiId;
        if (apiId == null || apiId.isEmpty) {
          return const ProviderLoadResult(errorMessage: 'Provider API ID is missing');
        }

        final isTv = season != null && episode != null;
        if (isTv) {
          return _scraperApi.loadTVEpisode(
            providerId: apiId,
            tvId: tmdbId,
            seasonNumber: season,
            episodeNumber: episode,
          );
        } else {
          return _scraperApi.loadMovie(
            providerId: apiId,
            movieId: tmdbId,
          );
        }
    }
  }
}

