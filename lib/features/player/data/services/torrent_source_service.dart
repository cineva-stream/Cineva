import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';

/// Represents a torrent source found for a movie/TV show.
class TorrentSource {
  final String title;
  final String quality;
  final String type; // 'bluray', 'web', etc.
  final int sizeBytes;
  final String magnetLink;
  final String hash;
  final int seeds;
  final int peers;
  final String provider;

  TorrentSource({
    required this.title,
    required this.quality,
    required this.type,
    required this.sizeBytes,
    required this.magnetLink,
    required this.hash,
    required this.seeds,
    required this.peers,
    this.provider = 'P2P',
  });

  String get sizeFormatted {
    if (sizeBytes > 1073741824) {
      return '${(sizeBytes / 1073741824).toStringAsFixed(2)} GB';
    } else if (sizeBytes > 1048576) {
      return '${(sizeBytes / 1048576).toStringAsFixed(1)} MB';
    } else if (sizeBytes > 0) {
      return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    }
    return 'Ukuran bervariasi';
  }

  factory TorrentSource.fromYtsJson(Map<String, dynamic> json, String movieTitle) {
    final hash = json['hash'] as String? ?? '';
    final encodedTitle = Uri.encodeComponent(movieTitle);
    final trackerParams = ApiConstants.publicTrackers
        .map((t) => '&tr=${Uri.encodeComponent(t)}')
        .join();
    final magnet = 'magnet:?xt=urn:btih:$hash&dn=$encodedTitle$trackerParams';

    return TorrentSource(
      title: movieTitle,
      quality: json['quality'] as String? ?? 'Unknown',
      type: json['type'] as String? ?? 'unknown',
      sizeBytes: json['size_bytes'] as int? ?? 0,
      magnetLink: magnet,
      hash: hash,
      seeds: json['seeds'] as int? ?? 0,
      peers: json['peers'] as int? ?? 0,
      provider: 'YTS',
    );
  }

  factory TorrentSource.fromTorrentioJson(Map<String, dynamic> json, String defaultTitle) {
    final infoHash = (json['infoHash'] as String? ?? '').toLowerCase();
    final name = json['name'] as String? ?? '';
    final title = json['title'] as String? ?? '';

    // Extract release title (first line of title or behaviorHints filename)
    final behaviorHints = json['behaviorHints'] as Map<String, dynamic>?;
    final hintFilename = behaviorHints?['filename'] as String?;
    final firstLine = title.split('\n').first.trim();
    final releaseTitle = hintFilename != null && hintFilename.isNotEmpty
        ? hintFilename
        : (firstLine.isNotEmpty ? firstLine : defaultTitle);

    // Extract Quality
    final combined = '$name $title'.toLowerCase();
    String quality = 'HD';
    if (combined.contains('4k') || combined.contains('2160p')) {
      quality = '2160p';
    } else if (combined.contains('1080p')) {
      quality = '1080p';
    } else if (combined.contains('720p')) {
      quality = '720p';
    } else if (combined.contains('480p')) {
      quality = '480p';
    } else if (combined.contains('cam') || combined.contains('telesync') || combined.contains('hdts')) {
      quality = 'CAM';
    }

    // Extract Type / Format
    String type = 'WEB-DL';
    if (combined.contains('bluray') || combined.contains('bdrip') || combined.contains('brrip')) {
      type = 'BluRay';
    } else if (combined.contains('web-dl') || combined.contains('webrip') || combined.contains('web')) {
      type = 'WEB-DL';
    } else if (combined.contains('hdtv')) {
      type = 'HDTV';
    } else if (combined.contains('dvd')) {
      type = 'DVD';
    }

    // Extract Seeds: 👤 1695
    int seeds = 0;
    final seedsMatch = RegExp(r'👤\s*(\d+)').firstMatch(title);
    if (seedsMatch != null) {
      seeds = int.tryParse(seedsMatch.group(1) ?? '0') ?? 0;
    }

    // Extract Size: 💾 26.28 GB
    int sizeBytes = 0;
    final sizeMatch = RegExp(r'💾\s*([\d\.]+)\s*(GB|MB|KB)', caseSensitive: false).firstMatch(title);
    if (sizeMatch != null) {
      final val = double.tryParse(sizeMatch.group(1) ?? '0') ?? 0.0;
      final unit = (sizeMatch.group(2) ?? 'GB').toUpperCase();
      if (unit == 'GB') {
        sizeBytes = (val * 1073741824).round();
      } else if (unit == 'MB') {
        sizeBytes = (val * 1048576).round();
      } else if (unit == 'KB') {
        sizeBytes = (val * 1024).round();
      }
    }

    // Extract Provider: ⚙️ ThePirateBay
    String provider = 'P2P';
    final provMatch = RegExp(r'⚙️\s*([^\n\r]+)').firstMatch(title);
    if (provMatch != null) {
      provider = provMatch.group(1)?.trim() ?? 'P2P';
    }

    final encodedTitle = Uri.encodeComponent(releaseTitle);
    final trackerParams = ApiConstants.publicTrackers
        .map((t) => '&tr=${Uri.encodeComponent(t)}')
        .join();
    final magnet = 'magnet:?xt=urn:btih:$infoHash&dn=$encodedTitle$trackerParams';

    return TorrentSource(
      title: releaseTitle,
      quality: quality,
      type: type,
      sizeBytes: sizeBytes,
      magnetLink: magnet,
      hash: infoHash,
      seeds: seeds,
      peers: 0,
      provider: provider,
    );
  }
}

/// Service to resolve movie/TV IMDb IDs into torrent magnet links.
///
/// Uses Torrentio multi-source aggregator as primary provider (scrapes ThePirateBay,
/// TorrentGalaxy, 1337x, Rutracker, etc.) and falls back to YTS API.
class TorrentSourceService {
  final Dio _dio;

  TorrentSourceService()
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 12),
          headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'},
        ));

  /// Search for torrent sources for a movie or TV show by IMDb ID.
  Future<List<TorrentSource>> searchByImdbId(
    String imdbId, {
    String? title,
    int? season,
    int? episode,
  }) async {
    final sources = <TorrentSource>[];

    // 1. Primary: Torrentio multi-source aggregator
    try {
      final torrentioSources = await _searchTorrentio(
        imdbId,
        title: title,
        season: season,
        episode: episode,
      );
      sources.addAll(torrentioSources);
    } catch (_) {
      // Torrentio temporarily unavailable, continue to fallbacks
    }

    // 2. Fallback: YTS API (for movies only)
    if (sources.isEmpty && season == null) {
      try {
        final ytsSources = await _searchYts(imdbId, title: title);
        sources.addAll(ytsSources);
      } catch (_) {
        // YTS unavailable, continue
      }
    }

    // Sort by quality (2160p > 1080p > 720p > HD > 480p > CAM) then seeds
    sources.sort((a, b) {
      final qualityOrder = {
        '2160p': 5,
        '1080p': 4,
        '720p': 3,
        'HD': 2,
        '480p': 1,
        'CAM': 0,
      };
      final aQ = qualityOrder[a.quality] ?? 2;
      final bQ = qualityOrder[b.quality] ?? 2;
      if (aQ != bQ) return bQ.compareTo(aQ);
      return b.seeds.compareTo(a.seeds);
    });

    // Return top 30 best sources to keep UI snappy
    return sources.take(30).toList();
  }

  /// Search Torrentio multi-source aggregator.
  Future<List<TorrentSource>> _searchTorrentio(
    String imdbId, {
    String? title,
    int? season,
    int? episode,
  }) async {
    final path = (season != null && episode != null)
        ? 'https://torrentio.strem.fun/stream/series/$imdbId:$season:$episode.json'
        : 'https://torrentio.strem.fun/stream/movie/$imdbId.json';

    final response = await _dio.get(path);
    final data = response.data;
    if (data == null) return [];

    final streams = data['streams'] as List<dynamic>?;
    if (streams == null || streams.isEmpty) return [];

    final fallbackTitle = title ?? imdbId;
    return streams
        .where((s) => s is Map<String, dynamic> && (s['infoHash'] as String? ?? '').isNotEmpty)
        .map((s) => TorrentSource.fromTorrentioJson(s as Map<String, dynamic>, fallbackTitle))
        .toList();
  }

  /// Search YTS (yts.mx) API for movie torrents.
  Future<List<TorrentSource>> _searchYts(String imdbId, {String? title}) async {
    final response = await _dio.get(
      'https://yts.mx/api/v2/list_movies.json',
      queryParameters: {
        'query_term': imdbId,
        'limit': 1,
      },
    );

    final data = response.data;
    if (data == null || data['status'] != 'ok') return [];

    final movies = data['data']?['movies'] as List<dynamic>?;
    if (movies == null || movies.isEmpty) return [];

    final movie = movies.first;
    final movieTitle = title ?? movie['title'] as String? ?? '';
    final torrents = movie['torrents'] as List<dynamic>? ?? [];

    return torrents.map((t) {
      return TorrentSource.fromYtsJson(t as Map<String, dynamic>, movieTitle);
    }).toList();
  }

  /// Search for TV series torrent sources.
  Future<List<TorrentSource>> searchTvByQuery(
    String query, {
    String? imdbId,
    int season = 1,
    int episode = 1,
  }) async {
    if (imdbId != null && imdbId.isNotEmpty) {
      return searchByImdbId(imdbId, title: query, season: season, episode: episode);
    }
    return [];
  }

  void dispose() {
    _dio.close();
  }
}
