import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../../player/data/models/provider_stream_models.dart';
import '../../../player/data/services/provider_loader_service.dart';
import '../../../player/data/services/scraper_api_service.dart';
import '../../../player/data/services/smart_stream_service.dart';
import '../../../player/data/services/subtitle_service.dart';
import '../../../player/data/services/vixsrc_stream_service.dart';
import 'hls_url_resolver.dart';
import 'offline_mp4_builder.dart';
import 'ts_segment_utils.dart';

class ResolutionOption {
  final String label; // '1080p', '720p', '480p', '360p'
  final String title; // 'Full HD (1080p)'
  final String description; // 'Kualitas terbaik & jernih'
  final int estimatedSizeBytes;
  final String formattedSize; // '~1.8 GB'
  final String streamUrl;
  final String masterPlaylistUrl;
  final Map<String, String>? headers;
  final List<SubtitleInfo> streamSubtitles;

  const ResolutionOption({
    required this.label,
    required this.title,
    required this.description,
    required this.estimatedSizeBytes,
    required this.formattedSize,
    required this.streamUrl,
    this.masterPlaylistUrl = '',
    this.headers,
    this.streamSubtitles = const [],
  });
}

class _HlsVariantInfo {
  final String url;
  final int? width;
  final int? height;
  final int? bandwidth;
  final String? audioGroupId;

  const _HlsVariantInfo({
    required this.url,
    this.width,
    this.height,
    this.bandwidth,
    this.audioGroupId,
  });
}

class _HlsAudioRendition {
  final String groupId;
  final String name;
  final String? language;
  final bool isDefault;
  final String url;

  const _HlsAudioRendition({
    required this.groupId,
    required this.name,
    this.language,
    required this.isDefault,
    required this.url,
  });
}

class _HlsMasterPlaylist {
  final String baseUrl;
  final List<_HlsVariantInfo> variants;
  final List<_HlsAudioRendition> audioRenditions;

  const _HlsMasterPlaylist({
    required this.baseUrl,
    required this.variants,
    required this.audioRenditions,
  });

  bool get isMaster => variants.isNotEmpty;

  static _HlsMasterPlaylist parse(String content, String masterUrl) {
    final lines = content.split(RegExp(r'\r?\n'));
    final variants = <_HlsVariantInfo>[];
    final audioRenditions = <_HlsAudioRendition>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#EXT-X-MEDIA:') && line.contains('TYPE=AUDIO')) {
        final uriMatch = RegExp(r'URI="([^"]+)"').firstMatch(line);
        if (uriMatch == null) continue;
        final rawUri = uriMatch.group(1)!.trim();
        if (rawUri.isEmpty) continue;

        final groupMatch = RegExp(r'GROUP-ID="([^"]+)"').firstMatch(line);
        final nameMatch = RegExp(r'NAME="([^"]+)"').firstMatch(line);
        final langMatch = RegExp(r'LANGUAGE="([^"]+)"').firstMatch(line);
        final isDefault = line.contains('DEFAULT=YES');

        audioRenditions.add(
          _HlsAudioRendition(
            groupId: groupMatch?.group(1) ?? 'audio',
            name: nameMatch?.group(1) ?? 'Audio',
            language: langMatch?.group(1),
            isDefault: isDefault,
            url: HlsUrlResolver.resolve(rawUri, masterUrl),
          ),
        );
      } else if (line.startsWith('#EXT-X-STREAM-INF:')) {
        int? width;
        int? height;
        final resMatch = RegExp(r'RESOLUTION=(\d+)x(\d+)').firstMatch(line);
        if (resMatch != null) {
          width = int.tryParse(resMatch.group(1)!);
          height = int.tryParse(resMatch.group(2)!);
        } else {
          final nameHeightMatch = RegExp(
            r'(?:NAME|VIDEO)="?(\d{3,4})p?"?',
            caseSensitive: false,
          ).firstMatch(line);
          if (nameHeightMatch != null) {
            height = int.tryParse(nameHeightMatch.group(1)!);
          }
        }

        final avgBwMatch = RegExp(r'AVERAGE-BANDWIDTH=(\d+)').firstMatch(line);
        final maxBwMatch = RegExp(r'(?:^|,)BANDWIDTH=(\d+)').firstMatch(line);
        final bandwidth = avgBwMatch != null
            ? int.tryParse(avgBwMatch.group(1)!)
            : (maxBwMatch != null ? int.tryParse(maxBwMatch.group(1)!) : null);

        final audioMatch = RegExp(r'AUDIO="([^"]+)"').firstMatch(line);
        final audioGroupId = audioMatch?.group(1);

        // Find the next non-empty, non-comment URI line
        String? variantUri;
        for (int j = i + 1; j < lines.length; j++) {
          final candidate = lines[j].trim();
          if (candidate.isEmpty) continue;
          if (candidate.startsWith('#')) {
            if (candidate.startsWith('#EXT-X-STREAM-INF:')) break;
            continue;
          }
          variantUri = candidate;
          i = j;
          break;
        }

        if (variantUri != null && variantUri.isNotEmpty) {
          variants.add(
            _HlsVariantInfo(
              url: HlsUrlResolver.resolve(variantUri, masterUrl),
              width: width,
              height: height,
              bandwidth: bandwidth,
              audioGroupId: audioGroupId,
            ),
          );
        }
      }
    }

    return _HlsMasterPlaylist(
      baseUrl: masterUrl,
      variants: variants,
      audioRenditions: audioRenditions,
    );
  }

  /// Selects the variant that best matches [qualityLabel] (e.g. '1080p', '720p', '480p', '360p').
  /// Ported from `VideoUtils.preferredVideoSource` & `DownloadSourceResolver.kt` in FlixQuest.
  _HlsVariantInfo? selectVariantForQuality(String? qualityLabel) {
    if (variants.isEmpty) return null;
    if (variants.length == 1) return variants.first;

    final targetHeight = _parseQualityHeight(qualityLabel);

    // Sort variants from highest quality to lowest
    final sorted = List<_HlsVariantInfo>.from(variants)
      ..sort((a, b) {
        final hCmp = (b.height ?? 0).compareTo(a.height ?? 0);
        if (hCmp != 0) return hCmp;
        return (b.bandwidth ?? 0).compareTo(a.bandwidth ?? 0);
      });

    if (targetHeight == null) {
      return sorted.first;
    }

    final withHeight = sorted.where((v) => (v.height ?? 0) > 0).toList();
    if (withHeight.isNotEmpty) {
      // 1. Exact height match
      for (final v in withHeight) {
        if (v.height == targetHeight) return v;
      }
      // 2. Highest variant whose height is <= targetHeight
      for (final v in withHeight) {
        if (v.height! <= targetHeight) return v;
      }
      // 3. Closest height overall (e.g., if user picked 360p and lowest is 480p)
      _HlsVariantInfo closest = withHeight.last;
      int bestDiff = (closest.height! - targetHeight).abs();
      for (final v in withHeight) {
        final diff = (v.height! - targetHeight).abs();
        if (diff < bestDiff) {
          bestDiff = diff;
          closest = v;
        }
      }
      return closest;
    }

    // Fallback when variants only declare BANDWIDTH without RESOLUTION
    switch (targetHeight) {
      case 1080:
        return sorted.first;
      case 720:
        return sorted[(sorted.length * 0.35).floor().clamp(0, sorted.length - 1)];
      case 480:
        return sorted[(sorted.length * 0.65).floor().clamp(0, sorted.length - 1)];
      case 360:
        return sorted.last;
      default:
        return sorted.first;
    }
  }

  _HlsAudioRendition? selectAudioForVariant(_HlsVariantInfo? variant) {
    if (audioRenditions.isEmpty) return null;
    final group = variant?.audioGroupId;
    final candidates = (group != null && group.isNotEmpty)
        ? audioRenditions.where((a) => a.groupId == group).toList()
        : audioRenditions;
    final pool = candidates.isNotEmpty ? candidates : audioRenditions;

    for (final a in pool) {
      if (a.isDefault) return a;
    }
    for (final a in pool) {
      final lang = (a.language ?? '').toLowerCase();
      if (lang.startsWith('en') || lang.startsWith('id')) return a;
    }
    return pool.first;
  }

  static int? _parseQualityHeight(String? label) {
    if (label == null || label.isEmpty) return null;
    final match = RegExp(r'(\d{3,4})').firstMatch(label);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }
}

class _HlsInitMapInfo {
  final String url;
  final String fileName;
  final String? keyUrl;
  final String? ivHex;
  final String? byteRangeHeader;

  const _HlsInitMapInfo({
    required this.url,
    required this.fileName,
    this.keyUrl,
    this.ivHex,
    this.byteRangeHeader,
  });
}

class _HlsSegmentTask {
  final int index;
  final int sequenceNumber;
  final bool isAudio;
  String url;
  final double duration;
  final String fileName;
  String? keyUrl;
  String? ivHex;
  final String? byteRangeHeader;

  _HlsSegmentTask({
    required this.index,
    required this.sequenceNumber,
    required this.isAudio,
    required this.url,
    required this.duration,
    required this.fileName,
    this.keyUrl,
    this.ivHex,
    this.byteRangeHeader,
  });
}

class _ParsedMediaPlaylist {
  final String finalPlaylistUrl;
  final List<_HlsSegmentTask> tasks;
  final _HlsInitMapInfo? initMap;
  final double totalDurationSeconds;

  const _ParsedMediaPlaylist({
    required this.finalPlaylistUrl,
    required this.tasks,
    this.initMap,
    required this.totalDurationSeconds,
  });
}

/// Service that handles high-speed multi-connection downloading of video streams to local storage.
/// Supports seamless decryption of AES-128 HLS streams, disguised segment unwrapping
/// (WebP EXIF, PNG IEND, PNG TIKTIKPX + Gzip, TIKTIKRAW/TIKTIKTSGZ), and dual video & audio tracks.
class VideoDownloadService {
  final Dio _dio;
  final ProviderLoaderService _providerLoader;
  final ScraperApiService _scraperApi;

  VideoDownloadService({
    Dio? dio,
    ProviderLoaderService? providerLoader,
    ScraperApiService? scraperApi,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 25),
                headers: {
                  'User-Agent':
                      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
                  'accept': '*/*',
                  'accept-encoding': 'gzip, deflate, br',
                },
              ),
            ),
        _providerLoader = providerLoader ?? ProviderLoaderService(),
        _scraperApi = scraperApi ?? ScraperApiService() {
    try {
      final adapter = _dio.httpClientAdapter;
      if (adapter is IOHttpClientAdapter) {
        adapter.createHttpClient = () {
          final client = HttpClient();
          client.maxConnectionsPerHost = 32;
          client.idleTimeout = const Duration(seconds: 45);
          client.connectionTimeout = const Duration(seconds: 12);
          return client;
        };
      }
    } catch (_) {}
  }

  /// Gets the standard download directory on the device:
  /// Sandboxed app-internal offline download directory:
  /// {ApplicationDocumentsDirectory}/offline_media (YouTube/Netflix style)
  static Future<Directory> getDownloadDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final offlineDir = Directory('${docs.path}/offline_media');
    if (!await offlineDir.exists()) {
      await offlineDir.create(recursive: true);
    }
    final noMedia = File('${offlineDir.path}/.nomedia');
    if (!await noMedia.exists()) {
      await noMedia.writeAsString('');
    }
    return offlineDir;
  }

  /// Seamlessly migrates/repairs legacy or corrupted offline bundles in [dir].
  /// Renames any .cdat chunks to .ts, heals direct MP4s saved as master.m3u8,
  /// and fixes playlist references so existing downloads immediately become playable.
  static Future<void> repairOfflineDirectoryIfNeeded(Directory dir) async {
    try {
      if (!await dir.exists()) return;

      // 0. Check if a direct MP4 was previously saved under master.m3u8 by mistake
      final masterM3u8 = File('${dir.path}/master.m3u8');
      final mp4File = File('${dir.path}/${OfflineMp4Builder.mp4Name}');
      if (await masterM3u8.exists() && !await mp4File.exists()) {
        final len = await masterM3u8.length();
        if (len > 512 * 1024) {
          try {
            final headerBytes = await masterM3u8.openRead(0, 16).first;
            if (TsSegmentUtils.isFmp4Segment(headerBytes)) {
              debugPrint(
                '[VideoDownloadService] Healing direct MP4 saved as master.m3u8 in ${dir.path}',
              );
              await masterM3u8.rename(mp4File.path);
              return;
            }
          } catch (_) {}
        }
      }

      // 1. Check if there are any .cdat files
      final cdatFiles = <File>[];
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.toLowerCase().endsWith('.cdat')) {
          cdatFiles.add(entity);
        }
      }

      // 2. Rename .cdat to .ts
      if (cdatFiles.isNotEmpty) {
        debugPrint(
          '[VideoDownloadService] Auto-repairing ${cdatFiles.length} .cdat segments in ${dir.path}...',
        );
        for (final file in cdatFiles) {
          final newPath = '${file.path.substring(0, file.path.length - 5)}.ts';
          try {
            await file.rename(newPath);
          } catch (_) {
            try {
              await file.copy(newPath);
              await file.delete();
            } catch (_) {}
          }
        }
      }

      // 3. Ensure playlists reference .ts instead of .cdat and .cineva, and create .m3u8 versions
      final pairs = [
        ['video.cineva', 'video.m3u8'],
        ['audio.cineva', 'audio.m3u8'],
        ['master.cineva', 'master.m3u8'],
      ];
      for (final pair in pairs) {
        final cinevaFile = File('${dir.path}/${pair[0]}');
        final m3u8File = File('${dir.path}/${pair[1]}');

        String? content;
        if (await m3u8File.exists()) {
          content = await m3u8File.readAsString();
        } else if (await cinevaFile.exists()) {
          content = await cinevaFile.readAsString();
        }

        if (content != null) {
          final fixed = content
              .replaceAll('.cdat', '.ts')
              .replaceAll('video.cineva', 'video.m3u8')
              .replaceAll('audio.cineva', 'audio.m3u8');
          await m3u8File.writeAsString(fixed);
          if (await cinevaFile.exists()) {
            await cinevaFile.writeAsString(fixed);
          }
        }
      }

      // 4. Ensure master.m3u8 exists if video.m3u8 exists
      final videoM3u8 = File('${dir.path}/video.m3u8');
      final audioM3u8 = File('${dir.path}/audio.m3u8');

      if (await videoM3u8.exists() && !await masterM3u8.exists()) {
        final hasAudio = await audioM3u8.exists();
        final sb = StringBuffer()
          ..writeln('#EXTM3U')
          ..writeln('#EXT-X-VERSION:3')
          ..writeln('#EXT-X-INDEPENDENT-SEGMENTS');
        if (hasAudio) {
          sb.writeln(
            '#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio",NAME="Audio",DEFAULT=YES,AUTOSELECT=YES,URI="audio.m3u8"',
          );
          sb.writeln('#EXT-X-STREAM-INF:BANDWIDTH=3000000,AUDIO="audio"');
        } else {
          sb.writeln('#EXT-X-STREAM-INF:BANDWIDTH=3000000');
        }
        sb.writeln('video.m3u8');
        await masterM3u8.writeAsString(sb.toString());
      }

      // 5. If raw segments are gone but video.ts exists, construct synthetic m3u8 manifests
      final videoTs = File('${dir.path}/video.ts');
      final audioTs = File('${dir.path}/audio.ts');
      if (await videoTs.exists() && (await videoTs.length()) > 50000) {
        final segments = await OfflineMp4Builder.listSegments(dir, 'v_');
        if (segments.isEmpty) {
          debugPrint(
            '[VideoDownloadService] Synthesizing HLS manifests for unified TS files in ${dir.path}...',
          );
          final hasAudio =
              await audioTs.exists() && (await audioTs.length()) > 1000;
          await videoM3u8.writeAsString(
            '#EXTM3U\n#EXT-X-VERSION:3\n#EXT-X-TARGETDURATION:7200\n#EXTINF:7200.0,\nvideo.ts\n#EXT-X-ENDLIST\n',
          );
          if (hasAudio) {
            await audioM3u8.writeAsString(
              '#EXTM3U\n#EXT-X-VERSION:3\n#EXT-X-TARGETDURATION:7200\n#EXTINF:7200.0,\naudio.ts\n#EXT-X-ENDLIST\n',
            );
          }
          final sb = StringBuffer()
            ..writeln('#EXTM3U')
            ..writeln('#EXT-X-VERSION:3')
            ..writeln('#EXT-X-INDEPENDENT-SEGMENTS');
          if (hasAudio) {
            sb.writeln(
              '#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio",NAME="Audio",DEFAULT=YES,AUTOSELECT=YES,URI="audio.m3u8"',
            );
            sb.writeln('#EXT-X-STREAM-INF:BANDWIDTH=3000000,AUDIO="audio"');
          } else {
            sb.writeln('#EXT-X-STREAM-INF:BANDWIDTH=3000000');
          }
          sb.writeln('video.m3u8');
          await masterM3u8.writeAsString(sb.toString());
        } else if (segments.length > 5) {
          try {
            await videoTs.delete();
          } catch (_) {}
          try {
            if (await audioTs.exists()) await audioTs.delete();
          } catch (_) {}
        }
      }

      // 6. Ensure .nomedia exists to protect private sandbox
      final noMedia = File('${dir.path}/.nomedia');
      if (!await noMedia.exists()) {
        await noMedia.writeAsString('');
      }
    } catch (e) {
      debugPrint('[VideoDownloadService] repairOfflineDirectory error: $e');
    }
  }

  /// Resolves stream and computes available resolutions and accurate estimated file sizes.
  Future<List<ResolutionOption>> resolveResolutionOptions({
    int? tmdbId,
    String? imdbId,
    int? season,
    int? episode,
    int runtimeMinutes = 100,
  }) async {
    final effectiveRuntime = runtimeMinutes > 15 ? runtimeMinutes : 90;
    double durationSeconds = (effectiveRuntime * 60).toDouble();

    int? resolvedTmdb = tmdbId;
    String? resolvedImdb = imdbId;
    if ((resolvedTmdb == null || resolvedTmdb == 0) &&
        resolvedImdb != null &&
        resolvedImdb.isNotEmpty) {
      try {
        final ids = await SmartStreamService.resolveIds(
          imdbId: resolvedImdb,
          isTv: season != null,
        );
        if (ids.tmdbId > 0) resolvedTmdb = ids.tmdbId;
      } catch (_) {}
    }

    String masterUrl = '';
    final qualityUrls = <String, String>{};
    final qualitySizes = <String, int>{};
    final qualitySizeTokens = <String, String>{};
    final discoveredSubtitles = <SubtitleInfo>[];
    Map<String, String>? streamHeaders;

    // 1. Try Direct VixSrc stream first and verify the playlist is reachable
    final vixResult = await VixSrcStreamService.resolveStream(
      tmdbId: resolvedTmdb,
      imdbId: resolvedImdb,
      season: season,
      episode: episode,
    );

    if (vixResult != null && vixResult.playlistUrl.isNotEmpty) {
      final candidateHeaders = ScraperApiService.inferVideoHeaders(
        vixResult.playlistUrl,
        VixSrcStreamService.headers,
      );
      final verified = await _inspectMasterPlaylistAndSizes(
        playlistUrl: vixResult.playlistUrl,
        headers: candidateHeaders,
        fallbackDurationSeconds: durationSeconds,
      );
      if (verified != null) {
        masterUrl = verified.finalUrl;
        streamHeaders = candidateHeaders;
        qualityUrls.addAll(vixResult.qualityUrls);
        qualityUrls.addAll(verified.qualityUrls);
        qualitySizes.addAll(verified.qualitySizes);
        discoveredSubtitles.addAll(vixResult.subtitles);
        if (verified.actualDurationSeconds != null &&
            verified.actualDurationSeconds! > 60) {
          durationSeconds = verified.actualDurationSeconds!;
        }
      }
    }

    // 2. Multi-provider fallback if VixSrc has no reachable playlist
    if (masterUrl.isEmpty && resolvedTmdb != null && resolvedTmdb > 0) {
      try {
        debugPrint(
          '[VideoDownloadService] Falling back to multi-provider cluster for tmdbId=$resolvedTmdb...',
        );
        final selection = await _providerLoader.loadFirstSuccessful(
          tmdbId: resolvedTmdb,
          season: season,
          episode: episode,
        );
        if (selection != null && selection.result.hasPlayableStreams) {
          final links = selection.result.videoLinks!;
          final first = links.first;
          masterUrl = first.url ?? '';
          streamHeaders = ScraperApiService.inferVideoHeaders(
            masterUrl,
            first.headers ??
                (selection.provider.type == VideoProviderType.directVixSrc
                    ? VixSrcStreamService.headers
                    : null),
          );
          if (selection.result.subtitleLinks != null) {
            for (final sub in selection.result.subtitleLinks!) {
              discoveredSubtitles.add(sub.toSubtitleInfo());
            }
          }

          for (final RegularVideoLinks link in links) {
            final url = link.url;
            if (url == null || url.isEmpty) continue;
            final q = (link.quality ?? '').toLowerCase();
            String? key;
            if (q.contains('1080')) {
              key = '1080p';
            } else if (q.contains('720')) {
              key = '720p';
            } else if (q.contains('480')) {
              key = '480p';
            } else if (q.contains('360')) {
              key = '360p';
            }
            if (key != null) {
              qualityUrls[key] = url;
              if (link.sizeToken != null && link.sizeToken!.isNotEmpty) {
                qualitySizeTokens[key] = link.sizeToken!;
              }
            } else if (link.sizeToken != null &&
                link.sizeToken!.isNotEmpty &&
                !qualitySizeTokens.containsKey('Auto')) {
              qualitySizeTokens['Auto'] = link.sizeToken!;
            }
          }

          // Inspect master playlist if the provider returned an M3U8
          if (masterUrl.isNotEmpty) {
            final inspected = await _inspectMasterPlaylistAndSizes(
              playlistUrl: masterUrl,
              headers: streamHeaders,
              fallbackDurationSeconds: durationSeconds,
            );
            if (inspected != null) {
              masterUrl = inspected.finalUrl;
              for (final entry in inspected.qualityUrls.entries) {
                qualityUrls.putIfAbsent(entry.key, () => entry.value);
              }
              qualitySizes.addAll(inspected.qualitySizes);
            }
          }

          // Resolve any sizeTokens from Scraper API v2 (/api/v2/stream-size)
          if (qualitySizeTokens.isNotEmpty) {
            await Future.wait(
              qualitySizeTokens.entries.map((entry) async {
                final est = await _scraperApi
                    .estimateStreamSize(entry.value)
                    .timeout(const Duration(seconds: 6), onTimeout: () => null);
                if (est != null && est > 0) {
                  if (entry.key == 'Auto') {
                    qualitySizes.putIfAbsent('1080p', () => est);
                    qualitySizes.putIfAbsent('720p', () => (est * 0.55).round());
                    qualitySizes.putIfAbsent('480p', () => (est * 0.30).round());
                    qualitySizes.putIfAbsent('360p', () => (est * 0.18).round());
                  } else {
                    qualitySizes[entry.key] = est;
                  }
                }
              }),
            );
          }

          debugPrint(
            '[VideoDownloadService] Resolved download from provider: ${selection.provider.displayName} (${links.length} sources)',
          );
        }
      } catch (e) {
        debugPrint('[VideoDownloadService] Multi-provider fallback error: $e');
      }
    }

    if (masterUrl.isEmpty && qualityUrls.isEmpty) {
      return [];
    }

    int calcSize(int bitrateBps) =>
        ((bitrateBps / 8) * durationSeconds).round();

    String formatBytes(int bytes) {
      if (bytes >= 1073741824) {
        return '~${(bytes / 1073741824).toStringAsFixed(1)} GB';
      }
      return '~${(bytes / 1048576).toStringAsFixed(0)} MB';
    }

    final size1080 = qualitySizes['1080p'] ?? calcSize(2600000);
    final size720 = qualitySizes['720p'] ?? calcSize(1300000);
    final size480 = qualitySizes['480p'] ?? calcSize(650000);
    final size360 = qualitySizes['360p'] ?? calcSize(380000);

    return [
      ResolutionOption(
        label: '1080p',
        title: '1080p Full HD',
        description: 'Kualitas terbaik, gambar sangat jernih & tajam',
        estimatedSizeBytes: size1080,
        formattedSize: formatBytes(size1080),
        streamUrl: qualityUrls['1080p'] ?? masterUrl,
        masterPlaylistUrl: masterUrl,
        headers: streamHeaders,
        streamSubtitles: discoveredSubtitles,
      ),
      ResolutionOption(
        label: '720p',
        title: '720p HD',
        description: 'Rekomendasi terbaik, seimbang tajam & hemat memori',
        estimatedSizeBytes: size720,
        formattedSize: formatBytes(size720),
        streamUrl: qualityUrls['720p'] ?? masterUrl,
        masterPlaylistUrl: masterUrl,
        headers: streamHeaders,
        streamSubtitles: discoveredSubtitles,
      ),
      ResolutionOption(
        label: '480p',
        title: '480p SD',
        description: 'Super hemat kuota & ruang penyimpanan',
        estimatedSizeBytes: size480,
        formattedSize: formatBytes(size480),
        streamUrl: qualityUrls['480p'] ?? masterUrl,
        masterPlaylistUrl: masterUrl,
        headers: streamHeaders,
        streamSubtitles: discoveredSubtitles,
      ),
      ResolutionOption(
        label: '360p',
        title: '360p Hemat',
        description: 'Paling hemat kuota dan proses unduh tercepat',
        estimatedSizeBytes: size360,
        formattedSize: formatBytes(size360),
        streamUrl: qualityUrls['360p'] ?? masterUrl,
        masterPlaylistUrl: masterUrl,
        headers: streamHeaders,
        streamSubtitles: discoveredSubtitles,
      ),
    ];
  }

  /// Inspects an HLS playlist URL (or direct MP4) to extract per-resolution
  /// variant URLs and bandwidth-based size estimates.
  Future<
      ({
        String finalUrl,
        Map<String, String> qualityUrls,
        Map<String, int> qualitySizes,
        double? actualDurationSeconds,
      })?> _inspectMasterPlaylistAndSizes({
    required String playlistUrl,
    Map<String, String>? headers,
    required double fallbackDurationSeconds,
  }) async {
    try {
      final effectiveHeaders = ScraperApiService.inferVideoHeaders(
        playlistUrl,
        headers,
      );
      final lowerUrl = playlistUrl.toLowerCase();
      final isLikelyPlaylist =
          lowerUrl.contains('.m3u8') || lowerUrl.contains('/playlist/');
      final res = await _dio.get<List<int>>(
        playlistUrl,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            ...?effectiveHeaders,
            if (!isLikelyPlaylist) 'Range': 'bytes=0-262143',
          },
          receiveTimeout: const Duration(seconds: 10),
          validateStatus: (status) => status != null && status >= 200 && status < 400,
        ),
      );

      final bytes = res.data;
      if (bytes == null || bytes.isEmpty) return null;
      final finalUrl = res.realUri.toString().isNotEmpty
          ? res.realUri.toString()
          : playlistUrl;

      // Check if it is a direct binary MP4 instead of an M3U8 text playlist
      if (TsSegmentUtils.isFmp4Segment(bytes)) {
        int? totalLen;
        final contentRange = res.headers.value('content-range');
        if (contentRange != null && contentRange.contains('/')) {
          totalLen = int.tryParse(contentRange.split('/').last.trim());
        }
        totalLen ??= int.tryParse(res.headers.value('content-length') ?? '');
        final sizes = <String, int>{};
        if (totalLen != null && totalLen > 1024 * 1024) {
          sizes['1080p'] = totalLen;
          sizes['720p'] = totalLen;
          sizes['480p'] = totalLen;
          sizes['360p'] = totalLen;
        }
        return (
          finalUrl: finalUrl,
          qualityUrls: <String, String>{},
          qualitySizes: sizes,
          actualDurationSeconds: null,
        );
      }

      final text = utf8.decode(bytes, allowMalformed: true);
      if (!text.contains('#EXTM3U')) return null;

      final qualityUrls = <String, String>{};
      final qualitySizes = <String, int>{};
      double durationSec = fallbackDurationSeconds;

      if (text.contains('#EXT-X-STREAM-INF')) {
        final master = _HlsMasterPlaylist.parse(text, finalUrl);
        for (final label in const ['1080p', '720p', '480p', '360p']) {
          final variant = master.selectVariantForQuality(label);
          if (variant != null) {
            qualityUrls[label] = variant.url;
            if (variant.bandwidth != null && variant.bandwidth! > 0) {
              qualitySizes[label] =
                  ((variant.bandwidth! / 8.0) * durationSec).round();
            }
          }
        }
      } else if (text.contains('#EXTINF:')) {
        double sumDur = 0;
        for (final line in text.split(RegExp(r'\r?\n'))) {
          final m = RegExp(r'^#EXTINF:([0-9.]+)').firstMatch(line.trim());
          if (m != null) {
            sumDur += double.tryParse(m.group(1)!) ?? 0;
          }
        }
        if (sumDur > 60) durationSec = sumDur;
      }

      return (
        finalUrl: finalUrl,
        qualityUrls: qualityUrls,
        qualitySizes: qualitySizes,
        actualDurationSeconds: durationSec,
      );
    } catch (e) {
      debugPrint('[VideoDownloadService] _inspectMasterPlaylistAndSizes note: $e');
      return null;
    }
  }

  /// Downloads an HLS stream (video + audio with AES-128 decryption & disguised segment unwrapping)
  /// or direct MP4 URL.
  Future<void> downloadStream({
    required String streamUrl,
    String masterPlaylistUrl = '',
    Map<String, String>? headers,
    required String targetFilePath,
    required int estimatedSizeBytes,
    String? preferredQuality,
    int? tmdbId,
    String? imdbId,
    int? season,
    int? episode,
    CancelToken? cancelToken,
    void Function({
      required int downloadedBytes,
      required int totalBytes,
      required double progress,
      required String speed,
    })? onProgress,
  }) async {
    final targetFile = File(targetFilePath);
    final targetDir = targetFile.parent;
    await targetDir.create(recursive: true);

    var currentStreamUrl = streamUrl;
    var currentMasterUrl = masterPlaylistUrl;
    var effectiveHeaders = <String, String>{
      ...?ScraperApiService.inferVideoHeaders(
        currentStreamUrl.isNotEmpty ? currentStreamUrl : currentMasterUrl,
        headers,
      ),
    };

    // Ensure .nomedia file in download folder so media is strictly private to Cineva
    try {
      final noMedia = File('${targetDir.path}/.nomedia');
      if (!await noMedia.exists()) {
        await noMedia.writeAsString('');
      }
    } catch (_) {}

    // Helper to dynamically refresh expired stream URLs using TMDB/IMDb metadata
    Future<bool> refreshExpiredSource() async {
      if (tmdbId == null || tmdbId <= 0) return false;
      try {
        debugPrint(
          '[VideoDownloadService] Refreshing expired stream URL for tmdbId=$tmdbId ($preferredQuality)...',
        );
        final options = await resolveResolutionOptions(
          tmdbId: tmdbId,
          imdbId: imdbId,
          season: season,
          episode: episode,
        );
        if (options.isEmpty) return false;
        final matched = preferredQuality != null
            ? options.firstWhere(
                (o) => o.label == preferredQuality,
                orElse: () => options.first,
              )
            : options.first;
        currentStreamUrl = matched.streamUrl;
        currentMasterUrl = matched.masterPlaylistUrl;
        effectiveHeaders = <String, String>{
          ...?ScraperApiService.inferVideoHeaders(
            currentStreamUrl,
            matched.headers,
          ),
        };
        return currentStreamUrl.isNotEmpty;
      } catch (e) {
        debugPrint('[VideoDownloadService] refreshExpiredSource error: $e');
        return false;
      }
    }

    if (currentStreamUrl.isEmpty) {
      await refreshExpiredSource();
    }
    if (currentStreamUrl.isEmpty) {
      throw Exception('URL stream tidak tersedia untuk diunduh.');
    }

    // 1. Check if streamUrl is a direct MP4/MKV file (by URL or by probing initial response)
    final cleanPath = Uri.tryParse(currentStreamUrl)?.path.toLowerCase() ??
        currentStreamUrl.toLowerCase();
    final looksLikeDirectMp4Url =
        (cleanPath.endsWith('.mp4') || cleanPath.endsWith('.mkv')) &&
        !cleanPath.endsWith('.m3u8');

    if (looksLikeDirectMp4Url) {
      await _downloadDirectMp4File(
        url: currentStreamUrl,
        targetDir: targetDir,
        headers: effectiveHeaders,
        estimatedSizeBytes: estimatedSizeBytes,
        cancelToken: cancelToken,
        onProgress: onProgress,
      );
      return;
    }

    // 2. Fetch and inspect initial playlist (or detect binary direct MP4 without .mp4 extension)
    final masterUrlToInspect =
        currentMasterUrl.isNotEmpty ? currentMasterUrl : currentStreamUrl;

    ({String text, String finalUrl, bool isDirectBinary})? initialFetch =
        await _fetchPlaylistOrDetectBinary(
          masterUrlToInspect,
          effectiveHeaders,
          cancelToken,
        );

    if (initialFetch == null && tmdbId != null && tmdbId > 0) {
      if (await refreshExpiredSource()) {
        final refreshedUrl =
            currentMasterUrl.isNotEmpty ? currentMasterUrl : currentStreamUrl;
        initialFetch = await _fetchPlaylistOrDetectBinary(
          refreshedUrl,
          effectiveHeaders,
          cancelToken,
        );
      }
    }

    if (initialFetch == null) {
      throw Exception('Gagal mengambil manifest stream untuk diunduh.');
    }

    if (initialFetch.isDirectBinary) {
      await _downloadDirectMp4File(
        url: currentStreamUrl,
        targetDir: targetDir,
        headers: effectiveHeaders,
        estimatedSizeBytes: estimatedSizeBytes,
        cancelToken: cancelToken,
        onProgress: onProgress,
      );
      return;
    }

    // 3. Resolve Video & Audio Media Playlists from Master or Media Playlist
    var resolvedPlaylists = await _resolveVideoAndAudioPlaylists(
      initialText: initialFetch.text,
      initialFinalUrl: initialFetch.finalUrl,
      requestedStreamUrl: currentStreamUrl,
      preferredQuality: preferredQuality,
      headers: effectiveHeaders,
      cancelToken: cancelToken,
    );

    final videoMedia = resolvedPlaylists.video;
    final audioMedia = resolvedPlaylists.audio;

    if (videoMedia.tasks.isEmpty) {
      throw Exception('Tidak ada segmen video yang ditemukan dalam stream.');
    }

    // Update effectiveHeaders if redirected to a known CDN (e.g. secretanchor / boats / vixcloud)
    final redirectedHeaders = ScraperApiService.inferVideoHeaders(
      videoMedia.finalPlaylistUrl,
      effectiveHeaders,
    );
    if (redirectedHeaders != null) {
      effectiveHeaders = redirectedHeaders;
    }

    // 4. Cache for AES-128 keys (supports key rotation & separate video/audio keys)
    final keyCache = <String, enc.Encrypter>{};
    Future<enc.Encrypter> getEncrypterForKeyUrl(String keyUrl) async {
      final existing = keyCache[keyUrl];
      if (existing != null) return existing;
      final keyBytes = await _downloadKeyBytes(
        keyUrl,
        cancelToken,
        effectiveHeaders,
      );
      final encrypter = enc.Encrypter(
        enc.AES(enc.Key(keyBytes), mode: enc.AESMode.cbc, padding: null),
      );
      keyCache[keyUrl] = encrypter;
      return encrypter;
    }

    Uint8List parseIv(String? ivHex, int sequenceNumber) {
      if (ivHex != null && ivHex.isNotEmpty) {
        String cleanHex = ivHex.startsWith('0x') || ivHex.startsWith('0X')
            ? ivHex.substring(2)
            : ivHex;
        cleanHex = cleanHex.padLeft(32, '0');
        if (cleanHex.length > 32) {
          cleanHex = cleanHex.substring(cleanHex.length - 32);
        }
        final iv = Uint8List(16);
        for (int i = 0; i < 16; i++) {
          iv[i] = int.parse(cleanHex.substring(i * 2, i * 2 + 2), radix: 16);
        }
        return iv;
      }
      final iv = Uint8List(16);
      final byteData = ByteData.view(iv.buffer);
      byteData.setUint64(8, sequenceNumber, Endian.big);
      return iv;
    }

    List<int> decryptSegmentBytes(
      List<int> cipherBytes,
      enc.Encrypter encrypter,
      Uint8List ivBytes,
    ) {
      final alignedLength = (cipherBytes.length ~/ 16) * 16;
      if (alignedLength == 0) return cipherBytes;
      final alignedCipher = cipherBytes.length == alignedLength
          ? (cipherBytes is Uint8List
              ? cipherBytes
              : Uint8List.fromList(cipherBytes))
          : Uint8List.fromList(cipherBytes.sublist(0, alignedLength));

      final encrypted = enc.Encrypted(alignedCipher);
      final iv = enc.IV(ivBytes);
      try {
        final decrypted = encrypter.decryptBytes(encrypted, iv: iv);
        return TsSegmentUtils.stripPaddingAndAlign(
          decrypted,
          isEncrypted: true,
        );
      } catch (e) {
        throw Exception('Gagal mendekripsi segmen video: $e');
      }
    }

    // 5. Download fMP4 Initialization Segments (#EXT-X-MAP) if present
    for (final initInfo in [videoMedia.initMap, audioMedia?.initMap]) {
      if (initInfo == null) continue;
      final initFile = File('${targetDir.path}/${initInfo.fileName}');
      if (await initFile.exists() && await initFile.length() > 128) continue;

      final res = await _dio.get<List<int>>(
        initInfo.url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            ...effectiveHeaders,
            if (initInfo.byteRangeHeader != null)
              'Range': initInfo.byteRangeHeader!,
          },
        ),
        cancelToken: cancelToken,
      );
      var initBytes = res.data ?? const <int>[];
      if (initBytes.isEmpty) {
        throw Exception('Gagal mengunduh segmen inisialisasi fMP4.');
      }
      if (initInfo.keyUrl != null && initInfo.keyUrl!.isNotEmpty) {
        final encrypter = await getEncrypterForKeyUrl(initInfo.keyUrl!);
        final iv = parseIv(initInfo.ivHex, 0);
        initBytes = decryptSegmentBytes(initBytes, encrypter, iv);
      } else {
        initBytes = TsSegmentUtils.unwrapDisguisedSegment(initBytes);
      }
      await initFile.writeAsBytes(initBytes);
    }

    // Pre-fetch primary encryption keys before spawning parallel workers
    final initialKeyUrls = <String>{
      for (final t in videoMedia.tasks)
        if (t.keyUrl != null && t.keyUrl!.isNotEmpty) t.keyUrl!,
      if (audioMedia != null)
        for (final t in audioMedia.tasks)
          if (t.keyUrl != null && t.keyUrl!.isNotEmpty) t.keyUrl!,
    };
    for (final kUrl in initialKeyUrls) {
      await getEncrypterForKeyUrl(kUrl);
    }

    final videoTasks = videoMedia.tasks;
    final audioTasks = audioMedia?.tasks ?? <_HlsSegmentTask>[];
    final hasAudioTrack = audioTasks.isNotEmpty;
    final allTasks = <_HlsSegmentTask>[...videoTasks, ...audioTasks];
    final totalSegments = allTasks.length;

    int downloadedBytes = 0;
    int lastBytes = 0;
    int lastTime = DateTime.now().millisecondsSinceEpoch;
    String currentSpeed = '0 KB/s (0.0 Mbps)';

    const int concurrency = 12; // High-speed 12 parallel connection workers
    int nextClaimIndex = 0;
    int completedSegments = 0;
    bool hasError = false;
    Object? errorObj;
    Completer<bool>? refreshCompleter;
    bool hasAttemptedRefresh = false;

    // Synchronized mid-download URL refresh if signed segment URLs expire (401/403/410)
    Future<bool> triggerMidDownloadUrlRefresh() async {
      if (refreshCompleter != null) {
        return refreshCompleter!.future;
      }
      if (hasAttemptedRefresh || tmdbId == null || tmdbId <= 0) {
        return false;
      }
      hasAttemptedRefresh = true;
      refreshCompleter = Completer<bool>();
      try {
        final ok = await refreshExpiredSource();
        if (!ok) {
          refreshCompleter!.complete(false);
          return false;
        }
        final refreshedUrl =
            currentMasterUrl.isNotEmpty ? currentMasterUrl : currentStreamUrl;
        final fetched = await _fetchPlaylistOrDetectBinary(
          refreshedUrl,
          effectiveHeaders,
          cancelToken,
        );
        if (fetched == null || fetched.isDirectBinary) {
          refreshCompleter!.complete(false);
          return false;
        }
        final refreshedPlaylists = await _resolveVideoAndAudioPlaylists(
          initialText: fetched.text,
          initialFinalUrl: fetched.finalUrl,
          requestedStreamUrl: currentStreamUrl,
          preferredQuality: preferredQuality,
          headers: effectiveHeaders,
          cancelToken: cancelToken,
        );
        if (refreshedPlaylists.video.tasks.length == videoTasks.length) {
          for (int i = 0; i < videoTasks.length; i++) {
            videoTasks[i].url = refreshedPlaylists.video.tasks[i].url;
            videoTasks[i].keyUrl = refreshedPlaylists.video.tasks[i].keyUrl;
            videoTasks[i].ivHex = refreshedPlaylists.video.tasks[i].ivHex;
          }
        }
        if (refreshedPlaylists.audio != null &&
            refreshedPlaylists.audio!.tasks.length == audioTasks.length) {
          for (int i = 0; i < audioTasks.length; i++) {
            audioTasks[i].url = refreshedPlaylists.audio!.tasks[i].url;
            audioTasks[i].keyUrl = refreshedPlaylists.audio!.tasks[i].keyUrl;
            audioTasks[i].ivHex = refreshedPlaylists.audio!.tasks[i].ivHex;
          }
        }
        refreshCompleter!.complete(true);
        return true;
      } catch (_) {
        refreshCompleter!.complete(false);
        return false;
      }
    }

    Future<void> runWorker() async {
      while (true) {
        if (cancelToken?.isCancelled ?? false) {
          hasError = true;
          errorObj = DioException(
            requestOptions: RequestOptions(path: currentStreamUrl),
            type: DioExceptionType.cancel,
          );
          break;
        }
        if (hasError) break;

        if (nextClaimIndex >= totalSegments) break;
        final myIndex = nextClaimIndex++;
        final task = allTasks[myIndex];
        final chunkFile = File('${targetDir.path}/${task.fileName}');

        // Resume support: skip already-downloaded valid segments on disk!
        if (await chunkFile.exists()) {
          final existingLen = await chunkFile.length();
          if (existingLen > 512) {
            downloadedBytes += existingLen;
            completedSegments++;
            final progress = (completedSegments / totalSegments).clamp(0.0, 1.0);
            onProgress?.call(
              downloadedBytes: downloadedBytes,
              totalBytes: estimatedSizeBytes > 0
                  ? estimatedSizeBytes
                  : totalSegments * 524288,
              progress: progress,
              speed: currentSpeed,
            );
            continue;
          }
        }

        List<int>? outputBytes;
        int retries = 0;

        while (retries < 5 && outputBytes == null) {
          if (cancelToken?.isCancelled ?? false) break;
          try {
            final segHeaders = <String, String>{
              ...effectiveHeaders,
              if (task.byteRangeHeader != null) 'Range': task.byteRangeHeader!,
            };
            final response = await _dio.get<List<int>>(
              task.url,
              options: Options(
                responseType: ResponseType.bytes,
                headers: segHeaders.isNotEmpty ? segHeaders : null,
              ),
              cancelToken: cancelToken,
            );
            final data = response.data;
            if (data == null || data.isEmpty) {
              throw Exception('Segmen kosong (${task.fileName})');
            }
            if (TsSegmentUtils.looksLikeErrorDocument(data)) {
              throw Exception(
                'Server mengembalikan halaman error pada segmen ${task.fileName}',
              );
            }

            List<int> processed = data;
            if (task.keyUrl != null && task.keyUrl!.isNotEmpty) {
              final encrypter = await getEncrypterForKeyUrl(task.keyUrl!);
              final iv = parseIv(task.ivHex, task.sequenceNumber);
              processed = decryptSegmentBytes(data, encrypter, iv);
            } else {
              processed = TsSegmentUtils.stripPaddingAndAlign(
                processed,
                isEncrypted: false,
              );
            }

            if (processed.isEmpty ||
                TsSegmentUtils.looksLikeErrorDocument(processed)) {
              throw Exception(
                'Segmen terdekripsi tidak valid (${task.fileName})',
              );
            }
            outputBytes = processed;
          } catch (e) {
            if (e is DioException) {
              final status = e.response?.statusCode;
              if (status == 401 || status == 403 || status == 410) {
                await triggerMidDownloadUrlRefresh();
              }
            }
            retries++;
            if (retries >= 5) {
              if (!hasError) {
                hasError = true;
                errorObj = e;
              }
              return;
            }
            await Future.delayed(Duration(milliseconds: 250 * (1 << retries)));
          }
        }

        if (outputBytes != null && outputBytes.isNotEmpty) {
          await chunkFile.writeAsBytes(outputBytes);

          downloadedBytes += outputBytes.length;
          completedSegments++;
        }

        final now = DateTime.now().millisecondsSinceEpoch;
        final timeDiff = (now - lastTime) / 1000.0;
        if (timeDiff >= 0.5) {
          final byteDiff = downloadedBytes - lastBytes;
          final bps = (byteDiff >= 0 ? byteDiff / timeDiff : 0).round();
          final mbps = (bps * 8) / 1000000.0;
          if (bps >= 1048576) {
            currentSpeed =
                '${(bps / 1048576).toStringAsFixed(1)} MB/s (${mbps.toStringAsFixed(1)} Mbps)';
          } else {
            currentSpeed =
                '${(bps / 1024).toStringAsFixed(0)} KB/s (${mbps.toStringAsFixed(1)} Mbps)';
          }
          lastBytes = downloadedBytes;
          lastTime = now;
        }

        final progress = (completedSegments / totalSegments).clamp(0.0, 1.0);

        onProgress?.call(
          downloadedBytes: downloadedBytes,
          totalBytes: estimatedSizeBytes > 0
              ? estimatedSizeBytes
              : totalSegments * 524288,
          progress: progress,
          speed: currentSpeed,
        );
      }
    }

    try {
      final workers = <Future>[];
      final effectiveConcurrency =
          totalSegments < concurrency ? totalSegments : concurrency;
      for (int w = 0; w < effectiveConcurrency; w++) {
        workers.add(runWorker());
      }
      await Future.wait(workers);

      if (hasError && errorObj != null) {
        throw errorObj!;
      }

      onProgress?.call(
        downloadedBytes: downloadedBytes,
        totalBytes: downloadedBytes > 0 ? downloadedBytes : estimatedSizeBytes,
        progress: 1.0,
        speed: 'Menyelesaikan unduhan...',
      );

      // 1. Write video.m3u8 (and video.cineva alias)
      final videoM3u8 = StringBuffer()
        ..writeln('#EXTM3U')
        ..writeln('#EXT-X-VERSION:${videoMedia.initMap != null ? 6 : 3}')
        ..writeln('#EXT-X-TARGETDURATION:7')
        ..writeln('#EXT-X-MEDIA-SEQUENCE:0');
      if (videoMedia.initMap != null) {
        videoM3u8.writeln('#EXT-X-MAP:URI="${videoMedia.initMap!.fileName}"');
      }
      for (final t in videoTasks) {
        videoM3u8.writeln('#EXTINF:${t.duration.toStringAsFixed(3)},');
        videoM3u8.writeln(t.fileName);
      }
      videoM3u8.writeln('#EXT-X-ENDLIST');
      final videoContent = videoM3u8.toString();
      await File('${targetDir.path}/video.m3u8').writeAsString(videoContent);
      await File('${targetDir.path}/video.cineva').writeAsString(videoContent);

      // 2. Write audio.m3u8 (and audio.cineva alias) if separate audio stream exists
      if (hasAudioTrack) {
        final audioM3u8 = StringBuffer()
          ..writeln('#EXTM3U')
          ..writeln('#EXT-X-VERSION:${audioMedia?.initMap != null ? 6 : 3}')
          ..writeln('#EXT-X-TARGETDURATION:7')
          ..writeln('#EXT-X-MEDIA-SEQUENCE:0');
        if (audioMedia?.initMap != null) {
          audioM3u8.writeln('#EXT-X-MAP:URI="${audioMedia!.initMap!.fileName}"');
        }
        for (final t in audioTasks) {
          audioM3u8.writeln('#EXTINF:${t.duration.toStringAsFixed(3)},');
          audioM3u8.writeln(t.fileName);
        }
        audioM3u8.writeln('#EXT-X-ENDLIST');
        final audioContent = audioM3u8.toString();
        await File('${targetDir.path}/audio.m3u8').writeAsString(audioContent);
        await File('${targetDir.path}/audio.cineva').writeAsString(audioContent);
      }

      // 3. Write master.m3u8 (standard offline HLS playlist)
      final masterM3u8 = StringBuffer()
        ..writeln('#EXTM3U')
        ..writeln('#EXT-X-VERSION:3')
        ..writeln('#EXT-X-INDEPENDENT-SEGMENTS');
      if (hasAudioTrack) {
        masterM3u8.writeln(
          '#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio",NAME="Audio",DEFAULT=YES,AUTOSELECT=YES,URI="audio.m3u8"',
        );
        masterM3u8.writeln('#EXT-X-STREAM-INF:BANDWIDTH=3000000,AUDIO="audio"');
      } else {
        masterM3u8.writeln('#EXT-X-STREAM-INF:BANDWIDTH=3000000');
      }
      masterM3u8.writeln('video.m3u8');
      final masterContent = masterM3u8.toString();
      await File('${targetDir.path}/master.m3u8').writeAsString(masterContent);
      await File('${targetDir.path}/master.cineva').writeAsString(masterContent);

      // 4. Write proprietary Cineva package metadata
      try {
        final metaFile = File('${targetDir.path}/cineva_package.json');
        await metaFile.writeAsString(
          '{"version":2,"package":"cineva_offline_bundle","createdAt":"${DateTime.now().toIso8601String()}"}',
        );
      } catch (_) {}

      debugPrint(
        '[VideoDownloadService] Offline Cineva media package successfully prepared in: ${targetDir.path}',
      );
    } catch (_) {
      rethrow;
    }
  }

  /// Downloads a direct binary MP4/MKV file to `video.mp4` inside [targetDir],
  /// never overwriting `master.m3u8` with binary bytes.
  Future<void> _downloadDirectMp4File({
    required String url,
    required Directory targetDir,
    required Map<String, String> headers,
    required int estimatedSizeBytes,
    CancelToken? cancelToken,
    void Function({
      required int downloadedBytes,
      required int totalBytes,
      required double progress,
      required String speed,
    })? onProgress,
  }) async {
    final mp4File = File('${targetDir.path}/${OfflineMp4Builder.mp4Name}');
    int lastBytes = 0;
    int lastTime = DateTime.now().millisecondsSinceEpoch;
    String currentSpeed = '0 KB/s';

    await _dio.download(
      url,
      mp4File.path,
      options: headers.isNotEmpty ? Options(headers: headers) : null,
      cancelToken: cancelToken,
      onReceiveProgress: (received, total) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final timeDiff = (now - lastTime) / 1000.0;

        if (timeDiff >= 0.5) {
          final byteDiff = received - lastBytes;
          final bps = (byteDiff >= 0 ? byteDiff / timeDiff : 0).round();
          final mbps = (bps * 8) / 1000000.0;
          if (bps >= 1048576) {
            currentSpeed =
                '${(bps / 1048576).toStringAsFixed(1)} MB/s (${mbps.toStringAsFixed(1)} Mbps)';
          } else {
            currentSpeed =
                '${(bps / 1024).toStringAsFixed(0)} KB/s (${mbps.toStringAsFixed(1)} Mbps)';
          }
          lastBytes = received;
          lastTime = now;
        }

        final effectiveTotal = total > 0 ? total : estimatedSizeBytes;
        final prog = effectiveTotal > 0
            ? (received / effectiveTotal).clamp(0.0, 1.0)
            : 0.0;

        onProgress?.call(
          downloadedBytes: received,
          totalBytes: effectiveTotal,
          progress: prog,
          speed: currentSpeed,
        );
      },
    );
  }

  /// Fetches a playlist URL and detects whether it is an `#EXTM3U` text manifest
  /// or a direct binary media stream (MP4/fMP4).
  Future<({String text, String finalUrl, bool isDirectBinary})?>
      _fetchPlaylistOrDetectBinary(
    String url,
    Map<String, String> headers,
    CancelToken? cancelToken,
  ) async {
    try {
      final res = await _dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: headers.isNotEmpty ? headers : null,
        ),
        cancelToken: cancelToken,
      );
      final bytes = res.data;
      if (bytes == null || bytes.isEmpty) return null;

      final finalUrl =
          res.realUri.toString().isNotEmpty ? res.realUri.toString() : url;
      final ct = (res.headers.value('content-type') ?? '').toLowerCase();

      if (TsSegmentUtils.isFmp4Segment(bytes) ||
          ct.contains('video/mp4') ||
          ct.contains('video/x-matroska')) {
        return (text: '', finalUrl: finalUrl, isDirectBinary: true);
      }

      final text = utf8.decode(bytes, allowMalformed: true);
      if (!text.contains('#EXTM3U')) {
        return null;
      }
      return (text: text, finalUrl: finalUrl, isDirectBinary: false);
    } catch (e) {
      debugPrint('[VideoDownloadService] _fetchPlaylistOrDetectBinary error: $e');
      return null;
    }
  }

  /// Resolves both video and audio media playlists starting from either a Master
  /// Playlist or a Media Playlist, selecting the variant matching [preferredQuality].
  Future<({
    _ParsedMediaPlaylist video,
    _ParsedMediaPlaylist? audio,
  })> _resolveVideoAndAudioPlaylists({
    required String initialText,
    required String initialFinalUrl,
    required String requestedStreamUrl,
    required String? preferredQuality,
    required Map<String, String> headers,
    CancelToken? cancelToken,
  }) async {
    String targetVideoUrl = requestedStreamUrl.isNotEmpty
        ? requestedStreamUrl
        : initialFinalUrl;
    String? targetAudioUrl;
    String? preFetchedVideoText;
    String? preFetchedVideoFinalUrl;

    if (initialText.contains('#EXT-X-STREAM-INF')) {
      final master = _HlsMasterPlaylist.parse(initialText, initialFinalUrl);
      final selectedVariant = master.selectVariantForQuality(preferredQuality);
      final selectedAudio = master.selectAudioForVariant(selectedVariant);

      if (selectedAudio != null && selectedAudio.url.isNotEmpty) {
        targetAudioUrl = selectedAudio.url;
      }

      if (selectedVariant != null && selectedVariant.url.isNotEmpty) {
        targetVideoUrl = selectedVariant.url;
      }
    } else if (initialText.contains('#EXTINF:')) {
      preFetchedVideoText = initialText;
      preFetchedVideoFinalUrl = initialFinalUrl;
    }

    final videoPlaylist = await _fetchAndParseMediaPlaylist(
      playlistUrl: targetVideoUrl,
      masterBaseUrl: initialFinalUrl,
      isAudio: false,
      preferredQuality: preferredQuality,
      headers: headers,
      cancelToken: cancelToken,
      preFetchedText: preFetchedVideoText,
      preFetchedFinalUrl: preFetchedVideoFinalUrl,
    );

    _ParsedMediaPlaylist? audioPlaylist;
    if (targetAudioUrl != null && targetAudioUrl.isNotEmpty) {
      try {
        audioPlaylist = await _fetchAndParseMediaPlaylist(
          playlistUrl: targetAudioUrl,
          masterBaseUrl: initialFinalUrl,
          isAudio: true,
          preferredQuality: preferredQuality,
          headers: headers,
          cancelToken: cancelToken,
        );
      } catch (e) {
        debugPrint('[VideoDownloadService] Audio playlist parse note: $e');
      }
    }

    return (video: videoPlaylist, audio: audioPlaylist);
  }

  /// Fetches a media playlist (following up to 3 nested playlist hops if needed)
  /// and parses all `#EXTINF` segments, `#EXT-X-MEDIA-SEQUENCE`, `#EXT-X-KEY`
  /// rotations, `#EXT-X-MAP` fMP4 init segments, and `#EXT-X-BYTERANGE`.
  Future<_ParsedMediaPlaylist> _fetchAndParseMediaPlaylist({
    required String playlistUrl,
    required String masterBaseUrl,
    required bool isAudio,
    required String? preferredQuality,
    required Map<String, String> headers,
    CancelToken? cancelToken,
    String? preFetchedText,
    String? preFetchedFinalUrl,
  }) async {
    String currentUrl = preFetchedFinalUrl ?? playlistUrl;
    String content = preFetchedText ?? '';

    for (int hop = 0; hop < 3; hop++) {
      if (content.isEmpty) {
        final effectiveHeaders =
            ScraperApiService.inferVideoHeaders(currentUrl, headers) ?? headers;
        final res = await _dio.get<String>(
          currentUrl,
          options: Options(
            responseType: ResponseType.plain,
            headers: effectiveHeaders.isNotEmpty ? effectiveHeaders : null,
          ),
          cancelToken: cancelToken,
        );
        content = res.data ?? '';
        if (res.realUri.toString().isNotEmpty) {
          currentUrl = res.realUri.toString();
        }
      }

      if (content.contains('#EXT-X-STREAM-INF')) {
        final nestedMaster = _HlsMasterPlaylist.parse(content, currentUrl);
        final variant = nestedMaster.selectVariantForQuality(preferredQuality);
        if (variant != null && variant.url.isNotEmpty) {
          currentUrl = variant.url;
          content = '';
          continue;
        }
      }

      if (content.contains('#EXTINF:')) {
        break;
      }

      // Check if it's a single-URI wrapper playlist without #EXTINF
      final lines = content.split(RegExp(r'\r?\n'));
      final childUri = lines
          .map((l) => l.trim())
          .firstWhere(
            (l) => l.isNotEmpty && !l.startsWith('#'),
            orElse: () => '',
          );
      if (childUri.isNotEmpty) {
        currentUrl = HlsUrlResolver.resolve(childUri, currentUrl);
        content = '';
        continue;
      }
      break;
    }

    final lines = content.split(RegExp(r'\r?\n'));
    int mediaSequence = 0;
    String? activeKeyUrl;
    String? activeIvHex;
    String? pendingByteRange;
    int byteRangeAutoOffset = 0;
    _HlsInitMapInfo? initMap;
    final tasks = <_HlsSegmentTask>[];
    double totalDuration = 0;

    final prefix = isAudio ? 'a_' : 'v_';

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#EXT-X-MEDIA-SEQUENCE:')) {
        final seqStr = line.substring('#EXT-X-MEDIA-SEQUENCE:'.length).trim();
        mediaSequence = int.tryParse(seqStr) ?? 0;
      } else if (line.startsWith('#EXT-X-KEY:')) {
        if (line.contains('METHOD=NONE')) {
          activeKeyUrl = null;
          activeIvHex = null;
        } else if (line.contains('AES-128')) {
          final uriMatch = RegExp(r'URI="([^"]+)"').firstMatch(line);
          final ivMatch = RegExp(r'IV=0x([0-9a-fA-F]+)').firstMatch(line);
          if (uriMatch != null) {
            activeKeyUrl = _resolveKeyUrl(
              uriMatch.group(1)!,
              currentUrl,
              masterBaseUrl,
            );
          }
          activeIvHex = ivMatch?.group(1);
        }
      } else if (line.startsWith('#EXT-X-MAP:')) {
        final uriMatch = RegExp(r'URI="([^"]+)"').firstMatch(line);
        if (uriMatch != null) {
          final mapUrl = HlsUrlResolver.resolve(uriMatch.group(1)!, currentUrl);
          String? mapRangeHeader;
          final brMatch = RegExp(r'BYTERANGE="(\d+)(?:@(\d+))?"').firstMatch(line);
          if (brMatch != null) {
            final len = int.parse(brMatch.group(1)!);
            final start = int.tryParse(brMatch.group(2) ?? '0') ?? 0;
            mapRangeHeader = 'bytes=$start-${start + len - 1}';
          }
          initMap = _HlsInitMapInfo(
            url: mapUrl,
            fileName: isAudio ? 'init_a.mp4' : 'init_v.mp4',
            keyUrl: activeKeyUrl,
            ivHex: activeIvHex,
            byteRangeHeader: mapRangeHeader,
          );
        }
      } else if (line.startsWith('#EXT-X-BYTERANGE:')) {
        final brSpec = line.substring('#EXT-X-BYTERANGE:'.length).trim();
        final parts = brSpec.split('@');
        final len = int.tryParse(parts[0]) ?? 0;
        if (len > 0) {
          final start = parts.length > 1
              ? (int.tryParse(parts[1]) ?? byteRangeAutoOffset)
              : byteRangeAutoOffset;
          final end = start + len - 1;
          pendingByteRange = 'bytes=$start-$end';
          byteRangeAutoOffset = end + 1;
        }
      } else if (line.startsWith('#EXTINF:')) {
        final durMatch = RegExp(r'#EXTINF:([0-9.]+)').firstMatch(line);
        final dur = durMatch != null
            ? (double.tryParse(durMatch.group(1)!) ?? 4.0)
            : 4.0;

        // Find the next non-empty, non-comment URI line (allowing intermediate tags like #EXT-X-BYTERANGE)
        String? segUri;
        for (int j = i + 1; j < lines.length; j++) {
          final nextLine = lines[j].trim();
          if (nextLine.isEmpty) continue;
          if (nextLine.startsWith('#EXT-X-BYTERANGE:')) {
            final brSpec = nextLine.substring('#EXT-X-BYTERANGE:'.length).trim();
            final parts = brSpec.split('@');
            final len = int.tryParse(parts[0]) ?? 0;
            if (len > 0) {
              final start = parts.length > 1
                  ? (int.tryParse(parts[1]) ?? byteRangeAutoOffset)
                  : byteRangeAutoOffset;
              final end = start + len - 1;
              pendingByteRange = 'bytes=$start-$end';
              byteRangeAutoOffset = end + 1;
            }
            continue;
          }
          if (nextLine.startsWith('#')) {
            if (nextLine.startsWith('#EXTINF:')) break;
            continue;
          }
          segUri = nextLine;
          i = j;
          break;
        }

        if (segUri != null && segUri.isNotEmpty) {
          final segUrl = HlsUrlResolver.resolve(segUri, currentUrl);
          final taskIndex = tasks.length;
          final segExt = initMap != null ? 'm4s' : 'ts';
          totalDuration += dur;
          tasks.add(
            _HlsSegmentTask(
              index: taskIndex,
              sequenceNumber: mediaSequence + taskIndex,
              isAudio: isAudio,
              url: segUrl,
              duration: dur,
              fileName: '$prefix${taskIndex.toString().padLeft(4, '0')}.$segExt',
              keyUrl: activeKeyUrl,
              ivHex: activeIvHex,
              byteRangeHeader: pendingByteRange,
            ),
          );
          pendingByteRange = null;
        }
      }
    }

    return _ParsedMediaPlaylist(
      finalPlaylistUrl: currentUrl,
      tasks: tasks,
      initMap: initMap,
      totalDurationSeconds: totalDuration,
    );
  }

  /// Resolves an AES key URI correctly against media playlist or master playlist
  String _resolveKeyUrl(String uriRaw, String playlistUrl, String masterUrl) {
    final base = playlistUrl.isNotEmpty ? playlistUrl : masterUrl;
    return HlsUrlResolver.resolve(uriRaw, base);
  }

  /// Downloads AES-128 16-byte decryption key with automatic fallback to primary origin
  Future<Uint8List> _downloadKeyBytes(
    String primaryUrl,
    CancelToken? cancelToken, [
    Map<String, String>? headers,
  ]) async {
    final candidateUrls = <String>[
      primaryUrl,
      if (primaryUrl.contains('/storage/enc.key') &&
          !primaryUrl.startsWith('https://vixsrc.to'))
        'https://vixsrc.to/storage/enc.key',
      if (primaryUrl.contains('?')) primaryUrl.split('?').first,
    ];

    for (final url in candidateUrls) {
      try {
        final effectiveHeaders =
            ScraperApiService.inferVideoHeaders(url, headers) ?? headers;
        final res = await _dio.get<List<int>>(
          url,
          options: Options(
            responseType: ResponseType.bytes,
            headers: effectiveHeaders,
          ),
          cancelToken: cancelToken,
        );
        if (res.data != null && res.data!.length == 16) {
          return Uint8List.fromList(res.data!);
        }
      } catch (e) {
        debugPrint(
          '[VideoDownloadService] Key fetch attempt note for $url: $e',
        );
      }
    }
    throw Exception('Gagal mengunduh kunci dekripsi AES-128 ($primaryUrl).');
  }
}
