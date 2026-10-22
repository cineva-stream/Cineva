import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'subtitle_service.dart';

class VixSrcStreamResult {
  final String playlistUrl;
  final Map<String, String> qualityUrls;
  final List<String> availableQualities;
  final List<SubtitleInfo> subtitles;

  const VixSrcStreamResult({
    required this.playlistUrl,
    this.qualityUrls = const {},
    this.availableQualities = const ['Auto', '1080p', '720p', '480p'],
    this.subtitles = const [],
  });
}

/// Service that extracts direct HLS M3U8 video streams from VixSrc (like FlixQuest).
/// Eliminates WebView anti-devtool locks, popups, and conflicting controls.
class VixSrcStreamService {
  static const String baseUrl = 'https://vixsrc.to';

  static const Map<String, String> headers = {
    'accept': '*/*',
    'origin': 'https://vixsrc.to',
    'referer': 'https://vixsrc.to/',
    'user-agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
  };

  /// Resolves the stream for either Movie or TV Episode.
  static Future<VixSrcStreamResult?> resolveStream({
    int? tmdbId,
    String? imdbId,
    int? season,
    int? episode,
  }) async {
    try {
      int? resolvedTmdbId = tmdbId;

      // 1. If only IMDb ID is available, resolve TMDB ID using TMDB API
      if (resolvedTmdbId == null && imdbId != null && imdbId.isNotEmpty) {
        resolvedTmdbId = await _findTmdbIdByImdb(imdbId);
      }

      if (resolvedTmdbId == null) {
        debugPrint('[VixSrcStreamService] Could not resolve TMDB ID');
        return null;
      }

      // 2. Fetch API endpoint from VixSrc
      final isTv = season != null && episode != null;
      final apiUrl = isTv
          ? '$baseUrl/api/tv/$resolvedTmdbId/$season/$episode'
          : '$baseUrl/api/movie/$resolvedTmdbId';

      debugPrint('[VixSrcStreamService] Requesting: $apiUrl');
      final apiResponse = await _httpGet(apiUrl);
      if (apiResponse == null) return null;

      final data = jsonDecode(apiResponse);
      final src = data['src'] as String?;
      if (src == null || src.isEmpty) {
        debugPrint('[VixSrcStreamService] No src field in response');
        return null;
      }

      // 3. Fetch embed HTML page
      final embedUrl = src.startsWith('http') ? src : '$baseUrl$src';
      final embedHtml = await _httpGet(embedUrl);
      if (embedHtml == null || embedHtml.isEmpty) return null;

      // 4. Extract playlist and token from embed HTML
      final urlMatch = RegExp(
            r"""window\.masterPlaylist\s*=\s*\{[\s\S]*?url:\s*['"]([^'"]+)['"]""",
          ).firstMatch(embedHtml) ??
          RegExp(
            r"""window\.streams\s*=\s*\[\{[\s\S]*?['"]url['"]:\s*['"]([^'"]+)['"]""",
          ).firstMatch(embedHtml) ??
          RegExp(r"""['"]url['"]:\s*['"]([^'"]+)['"]""").firstMatch(embedHtml);

      final tokenMatch =
          RegExp(r"""['"]token['"]\s*:\s*['"]([^'"]+)['"]""").firstMatch(embedHtml);
      final expiresMatch = RegExp(
        r"""['"]expires['"]\s*:\s*['"]([^'"]+)['"]""",
      ).firstMatch(embedHtml);

      if (urlMatch == null || tokenMatch == null || expiresMatch == null) {
        debugPrint('[VixSrcStreamService] Failed to regex playlist metadata');
        return null;
      }

      final rawUrl = urlMatch.group(1)!.replaceAll(r'\/', '/');
      final uri = Uri.parse(rawUrl.startsWith('http') ? rawUrl : '$baseUrl$rawUrl');

      final masterPlaylistUrl = uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          'token': tokenMatch.group(1)!,
          'expires': expiresMatch.group(1)!,
          'h': '1',
          'lang': 'en',
        },
      ).toString();

      debugPrint('[VixSrcStreamService] Master Playlist: $masterPlaylistUrl');

      // 5. Parse quality renditions & stream subtitle tracks from master playlist
      final qualityMap = <String, String>{
        'Auto': masterPlaylistUrl,
      };
      final streamSubtitles = <SubtitleInfo>[];

      try {
        final playlistContent = await _httpGet(masterPlaylistUrl);
        if (playlistContent != null && playlistContent.isNotEmpty) {
          final lines = playlistContent.split('\n');
          for (int i = 0; i < lines.length; i++) {
            final line = lines[i].trim();
            // Video rendition qualities
            if (line.startsWith('#EXT-X-STREAM-INF:')) {
              String label = 'Auto';
              if (line.contains('1920x1080') || line.contains('rendition=1080p')) {
                label = '1080p';
              } else if (line.contains('1280x720') || line.contains('rendition=720p')) {
                label = '720p';
              } else if (line.contains('854x480') || line.contains('rendition=480p')) {
                label = '480p';
              } else if (line.contains('640x360') || line.contains('rendition=360p')) {
                label = '360p';
              }
              if (i + 1 < lines.length) {
                final nextLine = lines[i + 1].trim();
                if (nextLine.isNotEmpty && !nextLine.startsWith('#')) {
                  final resolvedQualityUrl = nextLine.startsWith('http')
                      ? nextLine
                      : Uri.parse(masterPlaylistUrl).resolve(nextLine).toString();
                  qualityMap[label] = resolvedQualityUrl;
                }
              }
            }

            // Subtitle tracks inside the HLS stream
            if (line.startsWith('#EXT-X-MEDIA:TYPE=SUBTITLES')) {
              final subUriMatch = RegExp(r'URI="([^"]+)"').firstMatch(line);
              final nameMatch = RegExp(r'NAME="([^"]+)"').firstMatch(line);
              final langMatch = RegExp(r'LANGUAGE="([^"]+)"').firstMatch(line);
              if (subUriMatch != null) {
                final subUriRaw = subUriMatch.group(1)!;
                final subUri = subUriRaw.startsWith('http')
                    ? subUriRaw
                    : Uri.parse(masterPlaylistUrl).resolve(subUriRaw).toString();
                final name = nameMatch?.group(1) ?? 'Subtitle';
                final lang = (langMatch?.group(1) ?? 'en').toLowerCase();
                String normLang = lang;
                if (normLang == 'eng' || normLang == 'en' || normLang.startsWith('en-')) {
                  normLang = 'en';
                } else if (normLang == 'ind' || normLang == 'id' || normLang == 'in' || normLang.contains('indonesia')) {
                  normLang = 'id';
                } else if (normLang == 'ita' || normLang == 'it') {
                  normLang = 'it';
                } else if (normLang == 'spa' || normLang == 'es') {
                  normLang = 'es';
                } else if (normLang == 'fra' || normLang == 'fre' || normLang == 'fr') {
                  normLang = 'fr';
                } else if (normLang == 'deu' || normLang == 'ger' || normLang == 'de') {
                  normLang = 'de';
                } else if (normLang.length > 2) {
                  normLang = normLang.substring(0, 2);
                }

                streamSubtitles.add(SubtitleInfo(
                  id: subUri, // direct sub playlist URI
                  language: normLang,
                  languageName: '$name (Stream)',
                  fileName: name,
                  downloadCount: 9999,
                  downloadUrl: subUri,
                ));
              }
            }
          }
        }
      } catch (pe) {
        debugPrint('[VixSrcStreamService] Error parsing master playlist metadata: $pe');
      }

      final qualities = qualityMap.keys.toList();

      return VixSrcStreamResult(
        playlistUrl: masterPlaylistUrl,
        qualityUrls: qualityMap,
        availableQualities: qualities.isNotEmpty ? qualities : ['Auto', '1080p', '720p', '480p'],
        subtitles: streamSubtitles,
      );
    } catch (e, st) {
      debugPrint('[VixSrcStreamService] Error resolving stream: $e\n$st');
      return null;
    }
  }

  /// Downloads raw WebVTT content from a stream subtitle URI or child chunk.
  static Future<String?> downloadSubtitleContent(String uri) async {
    try {
      final res = await _httpGet(uri);
      if (res == null || res.isEmpty) return null;
      if (res.contains('WEBVTT') || res.contains('-->')) {
        return res;
      }
      // If it's an M3U8 pointing to the .vtt chunk:
      final lines = res.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.startsWith('#') || trimmed.isEmpty) continue;
        final vttUrl = trimmed.startsWith('http')
            ? trimmed
            : Uri.parse(uri).resolve(trimmed).toString();
        final vttContent = await _httpGet(vttUrl);
        if (vttContent != null && (vttContent.contains('WEBVTT') || vttContent.contains('-->'))) {
          return vttContent;
        }
      }
    } catch (e) {
      debugPrint('[VixSrcStreamService] downloadSubtitleContent error: $e');
    }
    return null;
  }

  static Future<int?> _findTmdbIdByImdb(String imdbId) async {
    try {
      final cleanId = imdbId.startsWith('tt') ? imdbId : 'tt$imdbId';
      final apiKey = dotenv.env['TMDB_API_KEY'] ?? 'a219d8d995720253534ff876696baf3b';
      final url =
          'https://api.themoviedb.org/3/find/$cleanId?external_source=imdb_id&api_key=$apiKey';

      final res = await _httpGet(url, customHeaders: {'accept': 'application/json'});
      if (res == null) return null;

      final data = jsonDecode(res) as Map<String, dynamic>;
      final movieResults = data['movie_results'] as List?;
      if (movieResults != null && movieResults.isNotEmpty) {
        return movieResults.first['id'] as int?;
      }
      final tvResults = data['tv_results'] as List?;
      if (tvResults != null && tvResults.isNotEmpty) {
        return tvResults.first['id'] as int?;
      }
    } catch (e) {
      debugPrint('[VixSrcStreamService] TMDB find error: $e');
    }
    return null;
  }

  static Future<String?> _httpGet(
    String url, {
    Map<String, String>? customHeaders,
  }) async {
    HttpClient? client;
    try {
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      final req = await client.getUrl(Uri.parse(url));

      final h = customHeaders ?? headers;
      h.forEach((k, v) {
        req.headers.set(k, v);
      });

      final res = await req.close();
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return await res.transform(utf8.decoder).join();
      }
      return null;
    } catch (e) {
      debugPrint('[VixSrcStreamService] httpGet error on $url: $e');
      return null;
    } finally {
      client?.close();
    }
  }
}
