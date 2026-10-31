import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


/// Represents a streaming server configuration in Cineva's Smart Playback Engine.
class SmartStreamServer {
  final String id;
  final String name;
  final String tag;
  final String description;
  final bool isDirectHls;
  final String Function({
    required int tmdbId,
    String? imdbId,
    int? season,
    int? episode,
  }) buildUrl;

  const SmartStreamServer({
    required this.id,
    required this.name,
    required this.tag,
    required this.description,
    this.isDirectHls = false,
    required this.buildUrl,
  });
}

/// Smart Stream Engine that manages multi-server resolution, direct HLS extraction,
/// intelligent stream sniffing, and failover across multiple high-performance CDNs.
class SmartStreamService {
  /// Available streaming servers prioritized by performance, stability, and catalog coverage.
  static final List<SmartStreamServer> servers = [
    // Server 1: Cineva Direct HLS (Native media_kit player)
    SmartStreamServer(
      id: 'cineva_direct',
      name: 'Cineva Direct (FHD)',
      tag: 'Native 1080p',
      description: 'Ekstraksi stream HLS langsung dengan kontrol penuh Cineva',
      isDirectHls: true,
      buildUrl: ({required tmdbId, imdbId, season, episode}) =>
          season != null && episode != null
              ? 'https://vixsrc.to/api/tv/$tmdbId/$season/$episode'
              : 'https://vixsrc.to/api/movie/$tmdbId',
    ),

    // Server 2: VidLink Ultra (Next.js player, ultra fast, great for Anime & TV Series)
    SmartStreamServer(
      id: 'vidlink',
      name: 'VidLink HD',
      tag: 'Fast • Anime/Series',
      description: 'Server cepat untuk serial TV, anime populer & film rilisan baru',
      isDirectHls: false,
      buildUrl: ({required tmdbId, imdbId, season, episode}) =>
          season != null && episode != null
              ? 'https://vidlink.pro/tv/$tmdbId/$season/$episode?autoplay=true&primaryColor=f59e0b'
              : 'https://vidlink.pro/movie/$tmdbId?autoplay=true&primaryColor=f59e0b',
    ),

    // Server 3: MultiEmbed VIP (Massive global catalog, anime, and movies)
    SmartStreamServer(
      id: 'multiembed',
      name: 'MultiEmbed VIP',
      tag: 'Global Catalog',
      description: 'Katalog super lengkap: Anime, K-Drama, dan film luar negeri',
      isDirectHls: false,
      buildUrl: ({required tmdbId, imdbId, season, episode}) {
        if (season != null && episode != null) {
          final param = imdbId != null && imdbId.isNotEmpty
              ? 'video_id=$imdbId'
              : 'video_id=$tmdbId&tmdb=1';
          return 'https://multiembed.mov/?$param&s=$season&e=$episode';
        } else {
          final param = imdbId != null && imdbId.isNotEmpty
              ? 'video_id=$imdbId'
              : 'video_id=$tmdbId&tmdb=1';
          return 'https://multiembed.mov/?$param';
        }
      },
    ),

    // Server 4: VidSrc Ultra
    SmartStreamServer(
      id: 'vidsrc_xyz',
      name: 'VidSrc Ultra',
      tag: 'Cluster Mirror',
      description: 'Mirror cadangan berkecepatan tinggi',
      isDirectHls: false,
      buildUrl: ({required tmdbId, imdbId, season, episode}) {
        final cleanImdb = imdbId != null && imdbId.isNotEmpty
            ? (imdbId.startsWith('tt') ? imdbId : 'tt$imdbId')
            : '';
        if (season != null && episode != null) {
          return cleanImdb.isNotEmpty
              ? 'https://vidsrc.me/embed/tv?imdb=$cleanImdb&season=$season&episode=$episode'
              : 'https://vidsrc.xyz/embed/tv?tmdb=$tmdbId&season=$season&episode=$episode';
        } else {
          return cleanImdb.isNotEmpty
              ? 'https://vidsrc.me/embed/movie?imdb=$cleanImdb'
              : 'https://vidsrc.xyz/embed/movie?tmdb=$tmdbId';
        }
      },
    ),

    // Server 5: 2Embed VIP
    SmartStreamServer(
      id: 'two_embed',
      name: '2Embed Prime',
      tag: 'VIP Server',
      description: 'Server alternatif global untuk anime dan serial',
      isDirectHls: false,
      buildUrl: ({required tmdbId, imdbId, season, episode}) =>
          season != null && episode != null
              ? 'https://www.2embed.cc/embedtv/$tmdbId&s=$season&e=$episode'
              : 'https://www.2embed.cc/embed/$tmdbId',
    ),

    // Server 6: SmashyStream
    SmartStreamServer(
      id: 'smashystream',
      name: 'SmashyStream',
      tag: 'Multi-Source',
      description: 'Server agregator cadangan dengan multi-source player',
      isDirectHls: false,
      buildUrl: ({required tmdbId, imdbId, season, episode}) =>
          season != null && episode != null
              ? 'https://embed.smashystream.com/playere.php?tmdb=$tmdbId&season=$season&episode=$episode'
              : 'https://embed.smashystream.com/playere.php?tmdb=$tmdbId',
    ),
  ];

  /// Resolves both TMDB ID and IMDb ID so all servers have complete metadata.
  static Future<({int tmdbId, String? imdbId})> resolveIds({
    int? tmdbId,
    String? imdbId,
    bool isTv = false,
  }) async {
    int resolvedTmdb = tmdbId ?? 0;
    String? resolvedImdb = imdbId;

    final apiKey = dotenv.env['TMDB_API_KEY'] ?? 'a219d8d995720253534ff876696baf3b';

    // 1. If TMDB ID is missing but IMDb ID is present, find TMDB ID
    if (resolvedTmdb == 0 && resolvedImdb != null && resolvedImdb.isNotEmpty) {
      try {
        final cleanId = resolvedImdb.startsWith('tt') ? resolvedImdb : 'tt$resolvedImdb';
        final url =
            'https://api.themoviedb.org/3/find/$cleanId?external_source=imdb_id&api_key=$apiKey';
        final res = await _httpGetJson(url);
        if (res != null) {
          final list = isTv ? (res['tv_results'] as List?) : (res['movie_results'] as List?);
          if (list != null && list.isNotEmpty) {
            resolvedTmdb = list.first['id'] as int? ?? 0;
          }
        }
      } catch (e) {
        debugPrint('[SmartStreamService] TMDB find error: $e');
      }
    }

    // 2. If IMDb ID is missing but TMDB ID is present, fetch external_ids
    if ((resolvedImdb == null || resolvedImdb.isEmpty) && resolvedTmdb > 0) {
      try {
        final type = isTv ? 'tv' : 'movie';
        final url = 'https://api.themoviedb.org/3/$type/$resolvedTmdb/external_ids?api_key=$apiKey';
        final res = await _httpGetJson(url);
        if (res != null) {
          final imdb = res['imdb_id'] as String?;
          if (imdb != null && imdb.isNotEmpty) {
            resolvedImdb = imdb;
          }
        }
      } catch (e) {
        debugPrint('[SmartStreamService] TMDB external_ids error: $e');
      }
    }

    return (tmdbId: resolvedTmdb, imdbId: resolvedImdb);
  }

  /// JavaScript payload injected into the webview to sniff direct HLS (.m3u8) / MP4 streams,
  /// neutralize intrusive ad popups, and synchronize video playback state with Cineva's Custom UI.
  static const String streamSnifferJs = '''
(function() {
  if (window.__cinevaSnifferInstalled) return;
  window.__cinevaSnifferInstalled = true;

  // Neutralize popups and unwanted alert redirects
  try {
    window.open = function() { return null; };
    window.alert = function() { return null; };
  } catch(e) {}

  function notifyStream(url) {
    if (!url || typeof url !== 'string') return;
    const clean = url.trim();
    if (clean.includes('.m3u8') || clean.includes('.mp4') || clean.includes('/hls/') || clean.includes('master.m3u8') || clean.includes('playlist.m3u8')) {
      if (window.CinevaStreamBridge) {
        window.CinevaStreamBridge.postMessage(JSON.stringify({
          type: 'STREAM_FOUND',
          url: clean
        }));
      }
    }
  }

  // 1. Hook window.fetch
  try {
    const originalFetch = window.fetch;
    window.fetch = async function(...args) {
      try {
        const url = typeof args[0] === 'string' ? args[0] : (args[0] && args[0].url ? args[0].url : '');
        notifyStream(url);
      } catch(e) {}
      return originalFetch.apply(this, args);
    };
  } catch(e) {}

  // 2. Hook XMLHttpRequest
  try {
    const originalOpen = XMLHttpRequest.prototype.open;
    XMLHttpRequest.prototype.open = function(method, url) {
      try {
        notifyStream(url);
      } catch(e) {}
      return originalOpen.apply(this, arguments);
    };
  } catch(e) {}

  // 3. Hook HTMLMediaElement (video.src and video.currentSrc)
  try {
    const originalSrc = Object.getOwnPropertyDescriptor(HTMLMediaElement.prototype, 'src');
    if (originalSrc && originalSrc.set) {
      Object.defineProperty(HTMLMediaElement.prototype, 'src', {
        set: function(val) {
          notifyStream(val);
          return originalSrc.set.call(this, val);
        },
        get: originalSrc.get
      });
    }
  } catch(e) {}

  // 4. Periodic scan and full synchronization for video elements
  setInterval(function() {
    try {
      const videos = document.querySelectorAll('video');
      for (let i = 0; i < videos.length; i++) {
        const v = videos[i];
        if (v.src) notifyStream(v.src);
        if (v.currentSrc) notifyStream(v.currentSrc);
        const sources = v.querySelectorAll('source');
        for (let j = 0; j < sources.length; j++) {
          if (sources[j].src) notifyStream(sources[j].src);
        }

        // Full event synchronization with Cineva's Custom Cinema UI
        if (!v.__cinevaEventsHooked) {
          v.__cinevaEventsHooked = true;

          // Auto-unmute if muted and attempt playback
          v.muted = false;

          function sendDuration() {
            if (window.CinevaStreamBridge && !isNaN(v.duration) && v.duration > 0) {
              window.CinevaStreamBridge.postMessage(JSON.stringify({
                type: 'DURATION_UPDATE',
                durationMs: Math.round(v.duration * 1000)
              }));
            }
          }

          sendDuration();
          v.addEventListener('durationchange', sendDuration);
          v.addEventListener('loadedmetadata', sendDuration);

          v.addEventListener('timeupdate', function() {
            if (window.CinevaStreamBridge && !isNaN(v.currentTime)) {
              window.CinevaStreamBridge.postMessage(JSON.stringify({
                type: 'TIME_UPDATE',
                timeMs: Math.round(v.currentTime * 1000)
              }));
            }
          });

          v.addEventListener('play', function() {
            if (window.CinevaStreamBridge) {
              window.CinevaStreamBridge.postMessage(JSON.stringify({
                type: 'PLAY_STATE',
                playing: true
              }));
            }
          });

          v.addEventListener('pause', function() {
            if (window.CinevaStreamBridge) {
              window.CinevaStreamBridge.postMessage(JSON.stringify({
                type: 'PLAY_STATE',
                playing: false
              }));
            }
          });

          v.addEventListener('waiting', function() {
            if (window.CinevaStreamBridge) {
              window.CinevaStreamBridge.postMessage(JSON.stringify({
                type: 'BUFFERING_STATE',
                buffering: true
              }));
            }
          });

          v.addEventListener('playing', function() {
            if (window.CinevaStreamBridge) {
              window.CinevaStreamBridge.postMessage(JSON.stringify({
                type: 'BUFFERING_STATE',
                buffering: false
              }));
            }
          });
        }
      }
    } catch(e) {}
  }, 600);
})();
''';

  /// CSS injected into web streams to clean up ads, popups, disable duplicate web controls,
  /// and maximize cinema viewport.
  static const String cinemaCleanerCss = '''
/* Hide common ad containers, popups, and watermarks */
iframe[src*="ad"], iframe[id*="ad"], div[id*="ad"], div[class*="ad-"], div[class*="banner"],
.modal-backdrop, #pop-ad, .adsterra-banner, .anti-adblock, .jw-watermark,
div[style*="z-index: 2147483647"], div[id*="overlay"] {
  display: none !important;
  opacity: 0 !important;
  pointer-events: none !important;
  visibility: hidden !important;
}

/* Hide built-in web player controls to prevent duplicate controls with Cineva's Custom UI */
video::-webkit-media-controls { display: none !important; }
video::-webkit-media-controls-enclosure { display: none !important; }
.jw-controls, .jw-controlbar, .vjs-control-bar, .plyr__controls, .control-bar, .player-controls {
  display: none !important;
  opacity: 0 !important;
  pointer-events: none !important;
  visibility: hidden !important;
}

/* Ensure true full viewport with zero overflow */
html, body {
  background-color: #000000 !important;
  margin: 0 !important;
  padding: 0 !important;
  width: 100vw !important;
  height: 100vh !important;
  overflow: hidden !important;
}

video {
  width: 100% !important;
  height: 100% !important;
  object-fit: contain !important;
}
''';

  static Future<Map<String, dynamic>?> _httpGetJson(String url) async {
    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      final req = await client.getUrl(Uri.parse(url));
      req.headers.set('accept', 'application/json');
      final res = await req.close();
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = await res.transform(utf8.decoder).join();
        return jsonDecode(body) as Map<String, dynamic>;
      }
    } catch (_) {
    } finally {
      client?.close();
    }
    return null;
  }
}
