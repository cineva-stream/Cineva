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

  /// Retrieves the ordered list of streaming providers (Direct VixSrc + Scraper Cluster).
  Future<List<VideoProvider>> getAvailableProviders({bool forceRefresh = false}) async {
    if (_cachedProviders != null && !forceRefresh) {
      return _cachedProviders!;
    }

    final list = <VideoProvider>[
      VideoProvider.directVixSrc,
    ];

    try {
      final scraperProviders = await _scraperApi.getProviders();
      // Prioritize high-performance known scrapers
      final prioritizedIds = ['showbox', 'streamflix', 'cinejoy', 'movy', 'asiaflix', 'aether', 'zstream', 'yoturkish'];

      scraperProviders.sort((a, b) {
        final idxA = prioritizedIds.indexOf(a.apiId ?? '');
        final idxB = prioritizedIds.indexOf(b.apiId ?? '');
        final rankA = idxA >= 0 ? idxA : 999;
        final rankB = idxB >= 0 ? idxB : 999;
        return rankA.compareTo(rankB);
      });

      list.addAll(scraperProviders);
    } catch (e) {
      debugPrint('[ProviderLoaderService] Error fetching scraper providers: $e');
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

