import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:path_provider/path_provider.dart';

import '../../../player/data/services/vixsrc_stream_service.dart';

class ResolutionOption {
  final String label; // '1080p', '720p', '480p', '360p'
  final String title; // 'Full HD (1080p)'
  final String description; // 'Kualitas terbaik & jernih'
  final int estimatedSizeBytes;
  final String formattedSize; // '~1.8 GB'
  final String streamUrl;

  const ResolutionOption({
    required this.label,
    required this.title,
    required this.description,
    required this.estimatedSizeBytes,
    required this.formattedSize,
    required this.streamUrl,
  });
}

/// Service that handles high-speed multi-connection downloading of video streams to local storage.
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

    // Standard video bitrates (bps):
    // 1080p: ~2.5 Mbps -> (2500000 / 8) * duration
    // 720p:  ~1.3 Mbps -> (1300000 / 8) * duration
    // 480p:  ~650 kbps -> (650000 / 8) * duration
    // 360p:  ~350 kbps -> (350000 / 8) * duration
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
      ),
      ResolutionOption(
        label: '720p',
        title: '720p HD',
        description: 'Rekomendasi terbaik, seimbang tajam & hemat memori',
        estimatedSizeBytes: size720,
        formattedSize: formatBytes(size720),
        streamUrl: qualityUrls['720p'] ?? masterUrl,
      ),
      ResolutionOption(
        label: '480p',
        title: '480p SD',
        description: 'Super hemat kuota & ruang penyimpanan',
        estimatedSizeBytes: size480,
        formattedSize: formatBytes(size480),
        streamUrl: qualityUrls['480p'] ?? masterUrl,
      ),
      ResolutionOption(
        label: '360p',
        title: '360p Hemat',
        description: 'Paling hemat kuota dan proses unduh tercepat',
        estimatedSizeBytes: size360,
        formattedSize: formatBytes(size360),
        streamUrl: qualityUrls['360p'] ?? masterUrl,
      ),
    ];
  }

  /// Downloads an HLS stream or direct MP4 URL to the destination file.
  Future<void> downloadStream({
    required String streamUrl,
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
    await targetFile.parent.create(recursive: true);

    // 1. If direct MP4 file
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

    // 2. HLS M3U8 Stream: Download segments and concatenate seamlessly into .mp4
    final playlistRes = await _dio.get<String>(
      streamUrl,
      options: Options(responseType: ResponseType.plain),
      cancelToken: cancelToken,
    );

    final playlistText = playlistRes.data ?? '';
    final lines = playlistText.split('\n');

    // Check if it's a variant master playlist with child playlist
    String targetPlaylistUrl = streamUrl;
    final childM3u8Line = lines.firstWhere(
      (l) => l.trim().endsWith('.m3u8') && !l.trim().startsWith('#'),
      orElse: () => '',
    );
    if (childM3u8Line.isNotEmpty) {
      targetPlaylistUrl = childM3u8Line.startsWith('http')
          ? childM3u8Line
          : Uri.parse(streamUrl).resolve(childM3u8Line.trim()).toString();

      final childRes = await _dio.get<String>(
        targetPlaylistUrl,
        options: Options(responseType: ResponseType.plain),
        cancelToken: cancelToken,
      );
      lines.clear();
      lines.addAll((childRes.data ?? '').split('\n'));
    }

    // Extract all media segments (.ts or .mp4)
    final segmentUrls = <String>[];
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isNotEmpty && !line.startsWith('#')) {
        final fullSegmentUrl = line.startsWith('http')
            ? line
            : Uri.parse(targetPlaylistUrl).resolve(line).toString();
        segmentUrls.add(fullSegmentUrl);
      }
    }

    if (segmentUrls.isEmpty) {
      throw Exception('Tidak ada segmen video yang ditemukan dalam stream.');
    }

    // Multi-connection parallel chunk downloading for maximum network saturation
    final totalSegments = segmentUrls.length;
    final sink = targetFile.openWrite(mode: FileMode.writeOnlyAppend);

    int downloadedBytes = 0;
    int lastBytes = 0;
    int lastTime = DateTime.now().millisecondsSinceEpoch;
    String currentSpeed = '0 KB/s';

    const int concurrency = 6; // 6 parallel connection workers
    final Map<int, List<int>> chunkBuffer = {};
    int nextWriteIndex = 0;
    int nextClaimIndex = 0;
    bool hasError = false;
    Object? errorObj;

    void flushAvailableChunks() {
      while (chunkBuffer.containsKey(nextWriteIndex)) {
        final data = chunkBuffer.remove(nextWriteIndex)!;
        sink.add(data);
        nextWriteIndex++;
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

        // Flow control: Prevent excessive memory usage by limiting in-flight buffer
        if (chunkBuffer.length >= 16) {
          await Future.delayed(const Duration(milliseconds: 40));
          continue;
        }

        int myIndex;
        if (nextClaimIndex >= totalSegments) {
          break; // All segments claimed
        }
        myIndex = nextClaimIndex++;

        final segUrl = segmentUrls[myIndex];
        List<int>? bytes;
        int retries = 0;

        while (retries < 3 && bytes == null) {
          if (cancelToken?.isCancelled ?? false) break;
          try {
            final response = await _dio.get<List<int>>(
              segUrl,
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
            await Future.delayed(Duration(milliseconds: 200 * retries));
          }
        }

        if (bytes != null && bytes.isNotEmpty) {
          chunkBuffer[myIndex] = bytes;
          downloadedBytes += bytes.length;
          flushAvailableChunks();
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

        final progress = (nextWriteIndex / totalSegments).clamp(0.0, 1.0);
        final estimatedTotal = nextWriteIndex > 0
            ? (downloadedBytes / nextWriteIndex * totalSegments).round()
            : estimatedSizeBytes;

        onProgress?.call(
          downloadedBytes: downloadedBytes,
          totalBytes: estimatedTotal > 0 ? estimatedTotal : estimatedSizeBytes,
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

      flushAvailableChunks();

      if (hasError && errorObj != null) {
        throw errorObj!;
      }
    } finally {
      await sink.flush();
      await sink.close();
    }
  }
}
