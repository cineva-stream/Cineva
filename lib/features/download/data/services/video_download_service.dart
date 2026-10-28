import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';

import 'package:dio/io.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../../player/data/services/smart_stream_service.dart';
import '../../../player/data/services/vixsrc_stream_service.dart';
import 'ts_segment_utils.dart';


class ResolutionOption {
  final String label; // '1080p', '720p', '480p', '360p'
  final String title; // 'Full HD (1080p)'
  final String description; // 'Kualitas terbaik & jernih'
  final int estimatedSizeBytes;
  final String formattedSize; // '~1.8 GB'
  final String streamUrl;
  final String masterPlaylistUrl;

  const ResolutionOption({
    required this.label,
    required this.title,
    required this.description,
    required this.estimatedSizeBytes,
    required this.formattedSize,
    required this.streamUrl,
    this.masterPlaylistUrl = '',
  });
}

class _HlsSegmentTask {
  final int index;
  final bool isAudio;
  final String url;
  final double duration;
  final String fileName;

  _HlsSegmentTask({
    required this.index,
    required this.isAudio,
    required this.url,
    required this.duration,
    required this.fileName,
  });
}

/// Service that handles high-speed multi-connection downloading of video streams to local storage.
/// Supports seamless decryption of AES-128 HLS streams with dual video & audio tracks.
class VideoDownloadService {
  final Dio _dio;

  VideoDownloadService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 25),
              headers: {
                ...VixSrcStreamService.headers,
                'accept-encoding': 'gzip, deflate, br',
              },
            )) {
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
  /// Renames any .cdat chunks to .ts and fixes playlist references so existing
  /// downloads immediately become playable without needing a re-download!
  static Future<void> repairOfflineDirectoryIfNeeded(Directory dir) async {
    try {
      if (!await dir.exists()) return;

      // 1. Check if there are any .cdat files
      final cdatFiles = <File>[];
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.toLowerCase().endsWith('.cdat')) {
          cdatFiles.add(entity);
        }
      }

      // 2. Rename .cdat to .ts
      if (cdatFiles.isNotEmpty) {
        debugPrint('[VideoDownloadService] Auto-repairing ${cdatFiles.length} .cdat segments in ${dir.path}...');
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
      final masterM3u8 = File('${dir.path}/master.m3u8');
      final videoM3u8 = File('${dir.path}/video.m3u8');
      final audioM3u8 = File('${dir.path}/audio.m3u8');

      if (await videoM3u8.exists() && !await masterM3u8.exists()) {
        final hasAudio = await audioM3u8.exists();
        final sb = StringBuffer()
          ..writeln('#EXTM3U')
          ..writeln('#EXT-X-VERSION:3')
          ..writeln('#EXT-X-INDEPENDENT-SEGMENTS');
        if (hasAudio) {
          sb.writeln('#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio",NAME="Audio",DEFAULT=YES,AUTOSELECT=YES,URI="audio.m3u8"');
          sb.writeln('#EXT-X-STREAM-INF:BANDWIDTH=3000000,AUDIO="audio"');
        } else {
          sb.writeln('#EXT-X-STREAM-INF:BANDWIDTH=3000000');
        }
        sb.writeln('video.m3u8');
        await masterM3u8.writeAsString(sb.toString());
      }

      // 5. Ensure .nomedia exists to protect private sandbox
      final noMedia = File('${dir.path}/.nomedia');
      if (!await noMedia.exists()) {
        await noMedia.writeAsString('');
      }
    } catch (e) {
      debugPrint('[VideoDownloadService] repairOfflineDirectory error: $e');
    }
  }

  /// Resolves stream and computes available resolutions and estimated file sizes.
  Future<List<ResolutionOption>> resolveResolutionOptions({
    int? tmdbId,
    String? imdbId,
    int? season,
    int? episode,
    int runtimeMinutes = 100,
  }) async {
    final effectiveRuntime = runtimeMinutes > 15 ? runtimeMinutes : 90;
    final durationSeconds = effectiveRuntime * 60;

    int? resolvedTmdb = tmdbId;
    String? resolvedImdb = imdbId;
    if ((resolvedTmdb == null || resolvedTmdb == 0) && resolvedImdb != null && resolvedImdb.isNotEmpty) {
      try {
        final ids = await SmartStreamService.resolveIds(imdbId: resolvedImdb, isTv: season != null);
        if (ids.tmdbId > 0) resolvedTmdb = ids.tmdbId;
      } catch (_) {}
    }

    final vixResult = await VixSrcStreamService.resolveStream(
      tmdbId: resolvedTmdb,
      imdbId: resolvedImdb,
      season: season,
      episode: episode,
    );

    final masterUrl = vixResult?.playlistUrl ?? '';
    final qualityUrls = Map<String, String>.from(vixResult?.qualityUrls ?? {});

    int calcSize(int bitrateBps) => ((bitrateBps / 8) * durationSeconds).round();

    String formatBytes(int bytes) {
      if (bytes >= 1073741824) {
        return '~${(bytes / 1073741824).toStringAsFixed(1)} GB';
      }
      return '~${(bytes / 1048576).toStringAsFixed(0)} MB';
    }

    final size1080 = calcSize(2600000);
    final size720 = calcSize(1300000);
    final size480 = calcSize(650000);
    final size360 = calcSize(380000);

    return [
      ResolutionOption(
        label: '1080p',
        title: '1080p Full HD',
        description: 'Kualitas terbaik, gambar sangat jernih & tajam',
        estimatedSizeBytes: size1080,
        formattedSize: formatBytes(size1080),
        streamUrl: qualityUrls['1080p'] ?? masterUrl,
        masterPlaylistUrl: masterUrl,
      ),
      ResolutionOption(
        label: '720p',
        title: '720p HD',
        description: 'Rekomendasi terbaik, seimbang tajam & hemat memori',
        estimatedSizeBytes: size720,
        formattedSize: formatBytes(size720),
        streamUrl: qualityUrls['720p'] ?? masterUrl,
        masterPlaylistUrl: masterUrl,
      ),
      ResolutionOption(
        label: '480p',
        title: '480p SD',
        description: 'Super hemat kuota & ruang penyimpanan',
        estimatedSizeBytes: size480,
        formattedSize: formatBytes(size480),
        streamUrl: qualityUrls['480p'] ?? masterUrl,
        masterPlaylistUrl: masterUrl,
      ),
      ResolutionOption(
        label: '360p',
        title: '360p Hemat',
        description: 'Paling hemat kuota dan proses unduh tercepat',
        estimatedSizeBytes: size360,
        formattedSize: formatBytes(size360),
        streamUrl: qualityUrls['360p'] ?? masterUrl,
        masterPlaylistUrl: masterUrl,
      ),
    ];
  }

  /// Downloads an HLS stream (video + audio with AES-128 decryption) or direct MP4 URL.
  Future<void> downloadStream({
    required String streamUrl,
    String masterPlaylistUrl = '',
    required String targetFilePath,
    required int estimatedSizeBytes,
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

    // Ensure .nomedia file in download folder so media is strictly private to Cineva and never scanned by gallery
    try {
      final noMedia = File('${targetDir.path}/.nomedia');
      if (!await noMedia.exists()) {
        await noMedia.writeAsString('');
      }
    } catch (_) {}

    // 1. Direct MP4 file download
    if (streamUrl.contains('.mp4') && !streamUrl.contains('.m3u8')) {
      int lastBytes = 0;
      int lastTime = DateTime.now().millisecondsSinceEpoch;

      await _dio.download(
        streamUrl,
        targetFilePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          final now = DateTime.now().millisecondsSinceEpoch;
          final timeDiff = (now - lastTime) / 1000.0;
          String speed = '0 KB/s';

          if (timeDiff >= 0.5) {
            final byteDiff = received - lastBytes;
            final bps = (byteDiff / timeDiff).round();
            final mbps = (bps * 8) / 1000000.0;
            if (bps >= 1048576) {
              speed = '${(bps / 1048576).toStringAsFixed(1)} MB/s (${mbps.toStringAsFixed(1)} Mbps)';
            } else {
              speed = '${(bps / 1024).toStringAsFixed(0)} KB/s (${mbps.toStringAsFixed(1)} Mbps)';
            }
            lastBytes = received;
            lastTime = now;
          }

          final effectiveTotal = total > 0 ? total : estimatedSizeBytes;
          final prog = effectiveTotal > 0 ? (received / effectiveTotal).clamp(0.0, 1.0) : 0.0;

          onProgress?.call(
            downloadedBytes: received,
            totalBytes: effectiveTotal,
            progress: prog,
            speed: speed,
          );
        },
      );
      return;
    }

    // 2. HLS M3U8 Stream: Download and decrypt video & audio streams into a local offline HLS bundle
    String targetVideoPlaylistUrl = streamUrl;
    String? targetAudioPlaylistUrl;

    // Check master playlist for audio track and video child playlists
    final masterUrlToInspect = masterPlaylistUrl.isNotEmpty ? masterPlaylistUrl : streamUrl;
    try {
      final masterRes = await _dio.get<String>(
        masterUrlToInspect,
        options: Options(responseType: ResponseType.plain),
        cancelToken: cancelToken,
      );
      final masterContent = masterRes.data ?? '';
      final masterLines = masterContent.split('\n');

      for (int i = 0; i < masterLines.length; i++) {
        final line = masterLines[i].trim();
        // Extract audio playlist URI (prefer English or DEFAULT=YES)
        if (line.startsWith('#EXT-X-MEDIA:TYPE=AUDIO')) {
          final uriMatch = RegExp(r'URI="([^"]+)"').firstMatch(line);
          if (uriMatch != null) {
            final rawUri = uriMatch.group(1)!;
            final fullUri = rawUri.startsWith('http')
                ? rawUri
                : Uri.parse(masterUrlToInspect).resolve(rawUri).toString();
            if (line.contains('DEFAULT=YES') ||
                line.contains('LANGUAGE="eng"') ||
                targetAudioPlaylistUrl == null) {
              targetAudioPlaylistUrl = fullUri;
            }
          }
        }
        // If streamUrl was a master playlist, find child video m3u8
        if (targetVideoPlaylistUrl == masterUrlToInspect &&
            line.startsWith('#EXT-X-STREAM-INF') &&
            i + 1 < masterLines.length) {
          final nextLine = masterLines[i + 1].trim();
          if (nextLine.isNotEmpty && !nextLine.startsWith('#')) {
            targetVideoPlaylistUrl = nextLine.startsWith('http')
                ? nextLine
                : Uri.parse(masterUrlToInspect).resolve(nextLine).toString();
          }
        }
      }
    } catch (e) {
      debugPrint('[VideoDownloadService] Master inspection note: $e');
    }

    // Fetch and parse Video Playlist
    final videoRes = await _dio.get<String>(
      targetVideoPlaylistUrl,
      options: Options(responseType: ResponseType.plain),
      cancelToken: cancelToken,
    );
    String videoContent = videoRes.data ?? '';
    var videoLines = videoContent.split('\n');

    // If targetVideoPlaylistUrl was also pointing to a nested m3u8 line
    final childM3u8Line = videoLines.firstWhere(
      (l) => l.trim().endsWith('.m3u8') && !l.trim().startsWith('#'),
      orElse: () => '',
    );
    if (childM3u8Line.isNotEmpty) {
      targetVideoPlaylistUrl = childM3u8Line.startsWith('http')
          ? childM3u8Line
          : Uri.parse(targetVideoPlaylistUrl).resolve(childM3u8Line.trim()).toString();

      final childRes = await _dio.get<String>(
        targetVideoPlaylistUrl,
        options: Options(responseType: ResponseType.plain),
        cancelToken: cancelToken,
      );
      videoContent = childRes.data ?? '';
      videoLines = videoContent.split('\n');
    }

    // Parse Video segments & encryption details
    String? videoKeyUrl;
    String? videoIvHex;
    final videoTasks = <_HlsSegmentTask>[];

    for (int i = 0; i < videoLines.length; i++) {
      final line = videoLines[i].trim();
      if (line.startsWith('#EXT-X-KEY:') && line.contains('AES-128')) {
        final uriMatch = RegExp(r'URI="([^"]+)"').firstMatch(line);
        final ivMatch = RegExp(r'IV=0x([0-9a-fA-F]+)').firstMatch(line);
        if (uriMatch != null) {
          videoKeyUrl = _resolveKeyUrl(uriMatch.group(1)!, targetVideoPlaylistUrl, masterUrlToInspect);
        }
        if (ivMatch != null) videoIvHex = ivMatch.group(1);
      } else if (line.startsWith('#EXTINF:')) {
        final durMatch = RegExp(r'#EXTINF:([0-9.]+)').firstMatch(line);
        final dur = durMatch != null ? double.tryParse(durMatch.group(1)!) ?? 4.0 : 4.0;
        if (i + 1 < videoLines.length) {
          final nextLine = videoLines[i + 1].trim();
          if (nextLine.isNotEmpty && !nextLine.startsWith('#')) {
            final segUrl = nextLine.startsWith('http')
                ? nextLine
                : Uri.parse(targetVideoPlaylistUrl).resolve(nextLine).toString();
            final taskIndex = videoTasks.length;
            videoTasks.add(_HlsSegmentTask(
              index: taskIndex,
              isAudio: false,
              url: segUrl,
              duration: dur,
              fileName: 'v_${taskIndex.toString().padLeft(4, '0')}.ts',
            ));
          }
        }
      }
    }

    if (videoTasks.isEmpty) {
      throw Exception('Tidak ada segmen video yang ditemukan dalam stream.');
    }

    // Parse Audio segments & encryption details (if separate audio stream exists)
    String? audioKeyUrl;
    String? audioIvHex;
    final audioTasks = <_HlsSegmentTask>[];

    if (targetAudioPlaylistUrl != null && targetAudioPlaylistUrl.isNotEmpty) {
      try {
        final audioRes = await _dio.get<String>(
          targetAudioPlaylistUrl,
          options: Options(responseType: ResponseType.plain),
          cancelToken: cancelToken,
        );
        String audioContent = audioRes.data ?? '';
        var audioLines = audioContent.split('\n');

        final audioChildM3u8 = audioLines.firstWhere(
          (l) => l.trim().endsWith('.m3u8') && !l.trim().startsWith('#'),
          orElse: () => '',
        );
        if (audioChildM3u8.isNotEmpty) {
          targetAudioPlaylistUrl = audioChildM3u8.startsWith('http')
              ? audioChildM3u8
              : Uri.parse(targetAudioPlaylistUrl).resolve(audioChildM3u8.trim()).toString();

          final aChildRes = await _dio.get<String>(
            targetAudioPlaylistUrl,
            options: Options(responseType: ResponseType.plain),
            cancelToken: cancelToken,
          );
          audioContent = aChildRes.data ?? '';
          audioLines = audioContent.split('\n');
        }

        for (int i = 0; i < audioLines.length; i++) {
          final line = audioLines[i].trim();
          if (line.startsWith('#EXT-X-KEY:') && line.contains('AES-128')) {
            final uriMatch = RegExp(r'URI="([^"]+)"').firstMatch(line);
            final ivMatch = RegExp(r'IV=0x([0-9a-fA-F]+)').firstMatch(line);
            if (uriMatch != null) {
              audioKeyUrl = _resolveKeyUrl(uriMatch.group(1)!, targetAudioPlaylistUrl, masterUrlToInspect);
            }
            if (ivMatch != null) audioIvHex = ivMatch.group(1);
          } else if (line.startsWith('#EXTINF:')) {
            final durMatch = RegExp(r'#EXTINF:([0-9.]+)').firstMatch(line);
            final dur = durMatch != null ? double.tryParse(durMatch.group(1)!) ?? 4.0 : 4.0;
            if (i + 1 < audioLines.length) {
              final nextLine = audioLines[i + 1].trim();
              if (nextLine.isNotEmpty && !nextLine.startsWith('#')) {
                final segUrl = nextLine.startsWith('http')
                    ? nextLine
                    : Uri.parse(targetAudioPlaylistUrl).resolve(nextLine).toString();
                final taskIndex = audioTasks.length;
                audioTasks.add(_HlsSegmentTask(
                  index: taskIndex,
                  isAudio: true,
                  url: segUrl,
                  duration: dur,
                  fileName: 'a_${taskIndex.toString().padLeft(4, '0')}.ts',
                ));
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[VideoDownloadService] Audio playlist fetch note: $e');
      }
    }

    // Download and validate AES-128 Keys if encrypted
    Uint8List? videoKeyBytes;
    if (videoKeyUrl != null) {
      videoKeyBytes = await _downloadKeyBytes(videoKeyUrl, cancelToken);
    }

    Uint8List? audioKeyBytes;
    if (audioKeyUrl != null) {
      if (audioKeyUrl == videoKeyUrl && videoKeyBytes != null) {
        audioKeyBytes = videoKeyBytes;
      } else {
        audioKeyBytes = await _downloadKeyBytes(audioKeyUrl, cancelToken);
      }
    }

    // Pre-instantiate AES-128 encrypters with padding: null (MPEG-TS chunks are raw aligned blocks)
    final enc.Encrypter? videoEncrypter = videoKeyBytes != null
        ? enc.Encrypter(enc.AES(enc.Key(videoKeyBytes), mode: enc.AESMode.cbc, padding: null))
        : null;

    final enc.Encrypter? audioEncrypter = audioKeyBytes != null
        ? (audioKeyBytes == videoKeyBytes
            ? videoEncrypter
            : enc.Encrypter(enc.AES(enc.Key(audioKeyBytes), mode: enc.AESMode.cbc, padding: null)))
        : null;

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

    Uint8List parseIv(String? ivHex, int sequenceNumber) {
      if (ivHex != null && ivHex.isNotEmpty) {
        String cleanHex = ivHex.startsWith('0x') ? ivHex.substring(2) : ivHex;
        cleanHex = cleanHex.padLeft(32, '0');
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

    List<int> decryptSegment(
      List<int> cipherBytes,
      enc.Encrypter? encrypter,
      Uint8List ivBytes,
    ) {
      if (encrypter == null) return cipherBytes;
      final alignedLength = (cipherBytes.length ~/ 16) * 16;
      if (alignedLength == 0) return cipherBytes;
      final alignedCipher = cipherBytes.length == alignedLength
          ? (cipherBytes is Uint8List ? cipherBytes : Uint8List.fromList(cipherBytes))
          : Uint8List.fromList(cipherBytes.sublist(0, alignedLength));

      final encrypted = enc.Encrypted(alignedCipher);
      final iv = enc.IV(ivBytes);

      // Decryption uses padding: null (raw blocks), so strip the PKCS7 padding here and keep
      // the segment aligned to 188-byte TS packets. Otherwise concatenated segments lose TS sync.
      // Never fall back to storing ciphertext: that yields an unplayable file.
      try {
        final decrypted = encrypter.decryptBytes(encrypted, iv: iv);
        return TsSegmentUtils.stripPaddingAndAlign(decrypted);
      } catch (e) {
        throw Exception('Gagal mendekripsi segmen video: $e');
      }
    }

    Future<void> runWorker() async {
      while (true) {
        if (cancelToken?.isCancelled ?? false) {
          hasError = true;
          errorObj = DioException(
            requestOptions: RequestOptions(path: streamUrl),
            type: DioExceptionType.cancel,
          );
          break;
        }
        if (hasError) break;

        int myIndex;
        if (nextClaimIndex >= totalSegments) break;
        myIndex = nextClaimIndex++;

        final task = allTasks[myIndex];

        List<int>? bytes;
        int retries = 0;

        while (retries < 3 && bytes == null) {
          if (cancelToken?.isCancelled ?? false) break;
          try {
            final response = await _dio.get<List<int>>(
              task.url,
              options: Options(responseType: ResponseType.bytes),
              cancelToken: cancelToken,
            );
            bytes = response.data;
          } catch (e) {
            retries++;
            if (retries >= 3) {
              if (!hasError) {
                hasError = true;
                errorObj = e;
              }
              return;
            }
            await Future.delayed(Duration(milliseconds: 150 * retries));
          }
        }

        if (bytes != null && bytes.isNotEmpty) {
          List<int> outputBytes = bytes;

          final encrypter = task.isAudio ? audioEncrypter : videoEncrypter;
          if (encrypter != null) {
            final ivHex = task.isAudio ? audioIvHex : videoIvHex;
            final iv = parseIv(ivHex, task.index);
            try {
              outputBytes = decryptSegment(bytes, encrypter, iv);
            } catch (e) {
              if (!hasError) {
                hasError = true;
                errorObj = e;
              }
              return;
            }
          }

          // Save decrypted segment directly to offline directory
          final chunkFile = File('${targetDir.path}/${task.fileName}');
          await chunkFile.writeAsBytes(outputBytes);

          downloadedBytes += outputBytes.length;
          completedSegments++;
        }

        final now = DateTime.now().millisecondsSinceEpoch;
        final timeDiff = (now - lastTime) / 1000.0;
        if (timeDiff >= 0.5) {
          final byteDiff = downloadedBytes - lastBytes;
          final bps = (byteDiff / timeDiff).round();
          final mbps = (bps * 8) / 1000000.0;
          if (bps >= 1048576) {
            currentSpeed = '${(bps / 1048576).toStringAsFixed(1)} MB/s (${mbps.toStringAsFixed(1)} Mbps)';
          } else {
            currentSpeed = '${(bps / 1024).toStringAsFixed(0)} KB/s (${mbps.toStringAsFixed(1)} Mbps)';
          }
          lastBytes = downloadedBytes;
          lastTime = now;
        }

        final progress = (completedSegments / totalSegments).clamp(0.0, 1.0);

        onProgress?.call(
          downloadedBytes: downloadedBytes,
          totalBytes: estimatedSizeBytes > 0 ? estimatedSizeBytes : totalSegments * 1048576,
          progress: progress,
          speed: currentSpeed,
        );
      }
    }

    try {
      final workers = <Future>[];
      final effectiveConcurrency = totalSegments < concurrency ? totalSegments : concurrency;
      for (int w = 0; w < effectiveConcurrency; w++) {
        workers.add(runWorker());
      }
      await Future.wait(workers);

      if (hasError && errorObj != null) {
        throw errorObj!;
      }

      onProgress?.call(
        downloadedBytes: downloadedBytes,
        totalBytes: estimatedSizeBytes > 0 ? estimatedSizeBytes : totalSegments * 1048576,
        progress: 1.0,
        speed: 'Menyelesaikan unduhan...',
      );

      // Create .nomedia inside targetDir to prevent OS media scanning
      try {
        final noMedia = File('${targetDir.path}/.nomedia');
        if (!await noMedia.exists()) {
          await noMedia.writeAsString('');
        }
      } catch (_) {}

      // 1. Write video.m3u8 (and video.cineva alias)
      final videoM3u8 = StringBuffer()
        ..writeln('#EXTM3U')
        ..writeln('#EXT-X-VERSION:3')
        ..writeln('#EXT-X-TARGETDURATION:7')
        ..writeln('#EXT-X-MEDIA-SEQUENCE:0');
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
          ..writeln('#EXT-X-VERSION:3')
          ..writeln('#EXT-X-TARGETDURATION:7')
          ..writeln('#EXT-X-MEDIA-SEQUENCE:0');
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
        masterM3u8.writeln('#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio",NAME="Audio",DEFAULT=YES,AUTOSELECT=YES,URI="audio.m3u8"');
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
        await metaFile.writeAsString('{"version":1,"package":"cineva_offline_bundle","createdAt":"${DateTime.now().toIso8601String()}"}');
      } catch (_) {}

      debugPrint('[VideoDownloadService] Offline Cineva media package successfully prepared in: ${targetDir.path}');
    } catch (_) {
      rethrow;
    }
  }


  /// Resolves an AES key URI correctly against origin or master playlist
  String _resolveKeyUrl(String uriRaw, String playlistUrl, String masterUrl) {
    if (uriRaw.startsWith('http')) return uriRaw;
    if (uriRaw.startsWith('/')) {
      final masterUri = Uri.tryParse(masterUrl);
      if (masterUri != null && masterUri.hasScheme) {
        return '${masterUri.scheme}://${masterUri.host}$uriRaw';
      }
      return 'https://vixsrc.to$uriRaw';
    }
    return Uri.parse(playlistUrl).resolve(uriRaw).toString();
  }

  /// Downloads AES-128 16-byte decryption key with automatic fallback to primary origin
  Future<Uint8List> _downloadKeyBytes(String primaryUrl, CancelToken? cancelToken) async {
    final candidateUrls = <String>[
      primaryUrl,
      if (primaryUrl.contains('/storage/enc.key') && !primaryUrl.startsWith('https://vixsrc.to'))
        'https://vixsrc.to/storage/enc.key',
    ];

    for (final url in candidateUrls) {
      try {
        final res = await _dio.get<List<int>>(
          url,
          options: Options(
            responseType: ResponseType.bytes,
            headers: {
              'origin': 'https://vixsrc.to',
              'referer': 'https://vixsrc.to/',
            },
          ),
          cancelToken: cancelToken,
        );
        if (res.data != null && res.data!.length == 16) {
          return Uint8List.fromList(res.data!);
        }
      } catch (e) {
        debugPrint('[VideoDownloadService] Key fetch attempt note for $url: $e');
      }
    }
    throw Exception('Gagal mengunduh kunci dekripsi AES-128 ($primaryUrl).');
  }
}

