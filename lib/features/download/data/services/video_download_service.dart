import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../../player/data/services/vixsrc_stream_service.dart';

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
          client.maxConnectionsPerHost = 16;
          client.idleTimeout = const Duration(seconds: 45);
          client.connectionTimeout = const Duration(seconds: 12);
          return client;
        };
      }
    } catch (_) {}
  }

  /// Gets the standard download directory on the device:
  /// Primary: /storage/emulated/0/Download/Cineva
  /// Fallback: External Storage Documents / Cineva
  static Future<Directory> getDownloadDirectory() async {
    if (Platform.isAndroid) {
      try {
        final publicDownload = Directory('/storage/emulated/0/Download/Cineva');
        if (!await publicDownload.exists()) {
          await publicDownload.create(recursive: true);
        }
        // Test write ability
        final testFile = File('${publicDownload.path}/.test_write');
        await testFile.writeAsString('ok');
        await testFile.delete();
        return publicDownload;
      } catch (_) {
        // Scoped storage fallback
      }

      try {
        final extDirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
        if (extDirs != null && extDirs.isNotEmpty) {
          final dir = Directory('${extDirs.first.path}/Cineva');
          if (!await dir.exists()) await dir.create(recursive: true);
          return dir;
        }
      } catch (_) {}

      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        final dir = Directory('${extDir.path}/Cineva');
        if (!await dir.exists()) await dir.create(recursive: true);
        return dir;
      }
    }

    final docDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${docDir.path}/Cineva');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
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

    final vixResult = await VixSrcStreamService.resolveStream(
      tmdbId: tmdbId,
      imdbId: imdbId,
      season: season,
      episode: episode,
    );

    final masterUrl = vixResult?.playlistUrl ?? '';
    final qualityUrls = vixResult?.qualityUrls ?? {};

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

    // Write .nomedia so system media scanners do not index segment files
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
            if (bps >= 1048576) {
              speed = '${(bps / 1048576).toStringAsFixed(1)} MB/s';
            } else {
              speed = '${(bps / 1024).toStringAsFixed(0)} KB/s';
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

    // 2. HLS M3U8 Stream: Download and decrypt video & audio streams into a local HLS bundle
    final effectiveMasterUrl = masterPlaylistUrl.isNotEmpty ? masterPlaylistUrl : streamUrl;
    String masterContent = '';
    try {
      final masterRes = await _dio.get<String>(
        effectiveMasterUrl,
        options: Options(responseType: ResponseType.plain),
        cancelToken: cancelToken,
      );
      masterContent = masterRes.data ?? '';
    } catch (e) {
      debugPrint('[VideoDownloadService] Master playlist fetch note: $e');
    }

    // Identify audio playlist URI from master playlist (prefer DEFAULT=YES or English)
    String? audioPlaylistUrl;
    if (masterContent.isNotEmpty) {
      final masterLines = masterContent.split('\n');
      for (final line in masterLines) {
        if (line.startsWith('#EXT-X-MEDIA:TYPE=AUDIO')) {
          final uriMatch = RegExp(r'URI="([^"]+)"').firstMatch(line);
          if (uriMatch != null) {
            final uriRaw = uriMatch.group(1)!;
            final fullUri = uriRaw.startsWith('http')
                ? uriRaw
                : Uri.parse(effectiveMasterUrl).resolve(uriRaw).toString();
            if (line.contains('DEFAULT=YES') || line.contains('LANGUAGE="eng"') || audioPlaylistUrl == null) {
              audioPlaylistUrl = fullUri;
            }
          }
        }
      }
    }

    // Determine target video playlist
    String targetVideoPlaylistUrl = streamUrl;
    final videoRes = await _dio.get<String>(
      targetVideoPlaylistUrl,
      options: Options(responseType: ResponseType.plain),
      cancelToken: cancelToken,
    );
    String videoContent = videoRes.data ?? '';
    var videoLines = videoContent.split('\n');

    // If streamUrl was a master playlist containing child m3u8 line
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
    int videoTargetDuration = 7;
    final videoTasks = <_HlsSegmentTask>[];

    for (int i = 0; i < videoLines.length; i++) {
      final line = videoLines[i].trim();
      if (line.startsWith('#EXT-X-TARGETDURATION:')) {
        videoTargetDuration = int.tryParse(line.split(':').last.trim()) ?? 7;
      } else if (line.startsWith('#EXT-X-KEY:') && line.contains('AES-128')) {
        final uriMatch = RegExp(r'URI="([^"]+)"').firstMatch(line);
        final ivMatch = RegExp(r'IV=0x([0-9a-fA-F]+)').firstMatch(line);
        if (uriMatch != null) {
          final uriRaw = uriMatch.group(1)!;
          videoKeyUrl = uriRaw.startsWith('http')
              ? uriRaw
              : Uri.parse(targetVideoPlaylistUrl).resolve(uriRaw).toString();
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

    // Parse Audio segments & encryption details (if separate audio stream exists)
    String? audioKeyUrl;
    String? audioIvHex;
    int audioTargetDuration = 7;
    final audioTasks = <_HlsSegmentTask>[];

    if (audioPlaylistUrl != null) {
      try {
        final audioRes = await _dio.get<String>(
          audioPlaylistUrl,
          options: Options(responseType: ResponseType.plain),
          cancelToken: cancelToken,
        );
        final audioContent = audioRes.data ?? '';
        final audioLines = audioContent.split('\n');

        for (int i = 0; i < audioLines.length; i++) {
          final line = audioLines[i].trim();
          if (line.startsWith('#EXT-X-TARGETDURATION:')) {
            audioTargetDuration = int.tryParse(line.split(':').last.trim()) ?? 7;
          } else if (line.startsWith('#EXT-X-KEY:') && line.contains('AES-128')) {
            final uriMatch = RegExp(r'URI="([^"]+)"').firstMatch(line);
            final ivMatch = RegExp(r'IV=0x([0-9a-fA-F]+)').firstMatch(line);
            if (uriMatch != null) {
              final uriRaw = uriMatch.group(1)!;
              audioKeyUrl = uriRaw.startsWith('http')
                  ? uriRaw
                  : Uri.parse(audioPlaylistUrl).resolve(uriRaw).toString();
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
                    : Uri.parse(audioPlaylistUrl).resolve(nextLine).toString();
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
        debugPrint('[VideoDownloadService] Audio playlist fetch error: $e');
      }
    }

    if (videoTasks.isEmpty) {
      throw Exception('Tidak ada segmen video yang ditemukan dalam stream.');
    }

    // Download AES-128 Keys if encrypted
    Uint8List? videoKeyBytes;
    Uint8List? audioKeyBytes;

    if (videoKeyUrl != null) {
      final keyRes = await _dio.get<List<int>>(
        videoKeyUrl,
        options: Options(responseType: ResponseType.bytes),
        cancelToken: cancelToken,
      );
      if (keyRes.data != null && keyRes.data!.isNotEmpty) {
        videoKeyBytes = Uint8List.fromList(keyRes.data!);
      }
    }

    if (audioKeyUrl != null) {
      if (audioKeyUrl == videoKeyUrl && videoKeyBytes != null) {
        audioKeyBytes = videoKeyBytes;
      } else {
        final keyRes = await _dio.get<List<int>>(
          audioKeyUrl,
          options: Options(responseType: ResponseType.bytes),
          cancelToken: cancelToken,
        );
        if (keyRes.data != null && keyRes.data!.isNotEmpty) {
          audioKeyBytes = Uint8List.fromList(keyRes.data!);
        }
      }
    }

    // Combine all segment tasks
    final allTasks = <_HlsSegmentTask>[...videoTasks, ...audioTasks];
    final totalSegments = allTasks.length;

    int downloadedBytes = 0;
    int lastBytes = 0;
    int lastTime = DateTime.now().millisecondsSinceEpoch;
    String currentSpeed = '0 KB/s';

    const int concurrency = 8; // High speed 8 parallel connection workers
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

    List<int> decryptSegment(List<int> cipherBytes, Uint8List keyBytes, Uint8List ivBytes) {
      final alignedLength = (cipherBytes.length ~/ 16) * 16;
      if (alignedLength == 0) return cipherBytes;
      final alignedCipher = cipherBytes.length == alignedLength
          ? (cipherBytes is Uint8List ? cipherBytes : Uint8List.fromList(cipherBytes))
          : Uint8List.fromList(cipherBytes.sublist(0, alignedLength));

      try {
        final encrypter = enc.Encrypter(enc.AES(enc.Key(keyBytes), mode: enc.AESMode.cbc, padding: 'PKCS7'));
        return encrypter.decryptBytes(enc.Encrypted(alignedCipher), iv: enc.IV(ivBytes));
      } catch (_) {
        final encrypter = enc.Encrypter(enc.AES(enc.Key(keyBytes), mode: enc.AESMode.cbc, padding: null));
        return encrypter.decryptBytes(enc.Encrypted(alignedCipher), iv: enc.IV(ivBytes));
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
        final file = File('${targetDir.path}/${task.fileName}');

        // Resume support: skip if segment already downloaded and valid
        if (await file.exists() && await file.length() > 1000) {
          completedSegments++;
          downloadedBytes += await file.length();
          continue;
        }

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
            await Future.delayed(Duration(milliseconds: 250 * retries));
          }
        }

        if (bytes != null && bytes.isNotEmpty) {
          List<int> outputBytes = bytes;

          // Decrypt if stream is encrypted
          final keyBytes = task.isAudio ? audioKeyBytes : videoKeyBytes;
          if (keyBytes != null) {
            final ivHex = task.isAudio ? audioIvHex : videoIvHex;
            final iv = parseIv(ivHex, task.index);
            outputBytes = decryptSegment(bytes, keyBytes, iv);
          }

          await file.writeAsBytes(outputBytes, flush: true);
          downloadedBytes += outputBytes.length;
          completedSegments++;
        }

        final now = DateTime.now().millisecondsSinceEpoch;
        final timeDiff = (now - lastTime) / 1000.0;
        if (timeDiff >= 0.5) {
          final byteDiff = downloadedBytes - lastBytes;
          final bps = (byteDiff / timeDiff).round();
          if (bps >= 1048576) {
            currentSpeed = '${(bps / 1048576).toStringAsFixed(1)} MB/s';
          } else {
            currentSpeed = '${(bps / 1024).toStringAsFixed(0)} KB/s';
          }
          lastBytes = downloadedBytes;
          lastTime = now;
        }

        final progress = (completedSegments / totalSegments).clamp(0.0, 1.0);
        final estimatedTotal = completedSegments > 0
            ? (downloadedBytes / completedSegments * totalSegments).round()
            : estimatedSizeBytes;

        onProgress?.call(
          downloadedBytes: downloadedBytes,
          totalBytes: estimatedTotal > 0 ? estimatedTotal : estimatedSizeBytes,
          progress: progress,
          speed: currentSpeed,
        );
      }
    }

    final workers = <Future>[];
    final effectiveConcurrency = totalSegments < concurrency ? totalSegments : concurrency;
    for (int w = 0; w < effectiveConcurrency; w++) {
      workers.add(runWorker());
    }
    await Future.wait(workers);

    if (hasError && errorObj != null) {
      throw errorObj!;
    }

    // 3. Assemble clean unencrypted HLS Playlists
    // Generate clean video.m3u8
    final videoM3u8Buffer = StringBuffer();
    videoM3u8Buffer.writeln('#EXTM3U');
    videoM3u8Buffer.writeln('#EXT-X-VERSION:3');
    videoM3u8Buffer.writeln('#EXT-X-TARGETDURATION:$videoTargetDuration');
    videoM3u8Buffer.writeln('#EXT-X-PLAYLIST-TYPE:VOD');
    for (final task in videoTasks) {
      videoM3u8Buffer.writeln('#EXTINF:${task.duration.toStringAsFixed(3)},');
      videoM3u8Buffer.writeln(task.fileName);
    }
    videoM3u8Buffer.writeln('#EXT-X-ENDLIST');
    await File('${targetDir.path}/video.m3u8').writeAsString(videoM3u8Buffer.toString());

    // Generate clean audio.m3u8 if audio track exists
    final hasAudioTrack = audioTasks.isNotEmpty;
    if (hasAudioTrack) {
      final audioM3u8Buffer = StringBuffer();
      audioM3u8Buffer.writeln('#EXTM3U');
      audioM3u8Buffer.writeln('#EXT-X-VERSION:3');
      audioM3u8Buffer.writeln('#EXT-X-TARGETDURATION:$audioTargetDuration');
      audioM3u8Buffer.writeln('#EXT-X-PLAYLIST-TYPE:VOD');
      for (final task in audioTasks) {
        audioM3u8Buffer.writeln('#EXTINF:${task.duration.toStringAsFixed(3)},');
        audioM3u8Buffer.writeln(task.fileName);
      }
      audioM3u8Buffer.writeln('#EXT-X-ENDLIST');
      await File('${targetDir.path}/audio.m3u8').writeAsString(audioM3u8Buffer.toString());
    }

    // Generate master.m3u8 (the main entry point for video player)
    final masterM3u8Buffer = StringBuffer();
    masterM3u8Buffer.writeln('#EXTM3U');
    masterM3u8Buffer.writeln('#EXT-X-VERSION:3');
    if (hasAudioTrack) {
      masterM3u8Buffer.writeln(
        '#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio",NAME="English",DEFAULT=YES,AUTOSELECT=YES,FORCED=NO,LANGUAGE="eng",URI="audio.m3u8"',
      );
      masterM3u8Buffer.writeln(
        '#EXT-X-STREAM-INF:BANDWIDTH=2500000,CODECS="avc1.640028,mp4a.40.2",AUDIO="audio"',
      );
      masterM3u8Buffer.writeln('video.m3u8');
    } else {
      masterM3u8Buffer.writeln(
        '#EXT-X-STREAM-INF:BANDWIDTH=2500000,CODECS="avc1.640028,mp4a.40.2"',
      );
      masterM3u8Buffer.writeln('video.m3u8');
    }

    await targetFile.writeAsString(masterM3u8Buffer.toString());
    debugPrint('[VideoDownloadService] Successfully completed offline HLS bundle at: $targetFilePath');
  }
}
