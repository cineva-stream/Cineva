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
      fullName: 'Movy (Miami)',
      alias: 'Zeila',
      codeName: 'scraper:movy',
      type: VideoProviderType.scraperApi,
      apiId: 'movy',
      content: 'Hollywood, Indonesia, Asian Movies & Series (1080p FHD)',
    ),
    VideoProvider(
      fullName: 'VidUp',
      alias: 'Gura',
      codeName: 'scraper:vidup',
      type: VideoProviderType.scraperApi,
      apiId: 'vidup',
      content: 'High-Speed Multi-CDN Mirror (1080p/720p/480p)',
    ),
    VideoProvider(
      fullName: 'Reelix',
      alias: 'Entoto',
      codeName: 'scraper:reelix',
      type: VideoProviderType.scraperApi,
      apiId: 'reelix',
      content: 'Global Movies & Drama Series (Adaptive HLS/DASH)',
    ),
    VideoProvider(
      fullName: 'Cinejoy',
      alias: 'Abyssinia',
      codeName: 'scraper:cinejoy',
      type: VideoProviderType.scraperApi,
      apiId: 'cinejoy',
      content: 'Hollywood & Anime (FHD)',
    ),
    VideoProvider(
      fullName: 'Atlantic',
      alias: 'Gundet',
      codeName: 'scraper:atlantic',
      type: VideoProviderType.scraperApi,
      apiId: 'atlantic',
    ),
    VideoProvider(
      fullName: 'Vivarium',
      alias: 'Kaffa',
      codeName: 'scraper:viv',
      type: VideoProviderType.scraperApi,
      apiId: 'viv',
    ),
    VideoProvider(
      fullName: 'AsiaFlix',
      alias: 'Adulis',
      codeName: 'scraper:asiaflix',
      type: VideoProviderType.scraperApi,
      apiId: 'asiaflix',
    ),
    VideoProvider(
      fullName: 'AnimeKai',
      alias: 'Lalibela',
      codeName: 'scraper:animekai',
      type: VideoProviderType.scraperApi,
      apiId: 'animekai',
    ),
    VideoProvider(
      fullName: 'AnimeYY',
      alias: 'Magdala',
      codeName: 'scraper:animeyy',
      type: VideoProviderType.scraperApi,
      apiId: 'animeyy',
    ),
    VideoProvider(
      fullName: 'AnimePahe',
      alias: 'Maychew',
      codeName: 'scraper:animepahe',
      type: VideoProviderType.scraperApi,
      apiId: 'animepahe',
    ),
    VideoProvider(
      fullName: 'AniKoto',
      alias: 'Metemma',
      codeName: 'scraper:anikoto',
      type: VideoProviderType.scraperApi,
      apiId: 'anikoto',
    ),
    VideoProvider(
      fullName: 'KissKH',
      alias: 'Chelenqo',
      codeName: 'scraper:kisskh',
      type: VideoProviderType.scraperApi,
      apiId: 'kisskh',
    ),
    VideoProvider(
      fullName: '4KHDHub',
      alias: 'Gondar',
      codeName: 'scraper:4khdhub',
      type: VideoProviderType.scraperApi,
      apiId: '4khdhub',
    ),
    VideoProvider(
      fullName: 'YoTurkish',
      alias: 'Sebastopol',
      codeName: 'scraper:yoturkish',
      type: VideoProviderType.scraperApi,
      apiId: 'yoturkish',
    ),
    VideoProvider(
      fullName: 'AethoFlix',
      alias: 'Karamara',
      codeName: 'scraper:aethoflix',
      type: VideoProviderType.scraperApi,
      apiId: 'aethoflix',
    ),
    VideoProvider(
      fullName: 'Aether',
      alias: 'Yeha',
      codeName: 'scraper:aether',
      type: VideoProviderType.scraperApi,
      apiId: 'aether',
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
          'movy',
          'vidup',
          'reelix',
          'cinejoy',
          'atlantic',
          'viv',
          'asiaflix',
          'animekai',
          'animepahe',
          'anikoto',
          'animeyy',
          'kisskh',
          '4khdhub',
          'yoturkish',
          'aethoflix',
          'aether',
          'moviepire',
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
    void Function(VideoProvider provider)? onStartAttempt,
  }) async {
    final providers = await getAvailableProviders();

    for (final provider in providers) {
      // Moviepire upstream scraper frequently returns unrelated content (e.g. random anime
      // or short clips) when requested media is missing. Exclude from automatic failover.
      if (provider.apiId == 'moviepire') continue;

      onStartAttempt?.call(provider);
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

