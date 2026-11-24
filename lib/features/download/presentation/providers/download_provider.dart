import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/download_item.dart';
import '../../data/repositories/download_repository.dart';
import '../../data/services/download_file_namer.dart';
import '../../data/services/download_subtitle_pipeline.dart';
import '../../data/services/offline_mp4_builder.dart';
import '../../data/services/video_download_service.dart';
import '../../../player/data/services/subtitle_service.dart';

class _QueuedDownloadTask {
  final DownloadItem item;
  final String? imdbId;
  final String streamUrl;
  final String masterPlaylistUrl;
  final Map<String, String>? headers;
  final SubtitleInfo? selectedSubtitle;
  final bool autoTranslate;
  final String targetTranslateLang;
  final CancelToken cancelToken;
  final int runtimeMinutes;

  const _QueuedDownloadTask({
    required this.item,
    required this.imdbId,
    required this.streamUrl,
    required this.masterPlaylistUrl,
    required this.headers,
    required this.selectedSubtitle,
    required this.autoTranslate,
    required this.targetTranslateLang,
    required this.cancelToken,
    required this.runtimeMinutes,
  });
}

/// State notifier managing all download tasks, persistent storage, smart concurrency queue, and live progress.
class DownloadNotifier extends StateNotifier<List<DownloadItem>> {
  /// Maximum simultaneous video downloads running in parallel background isolates.
  /// Keeping 2 active downloads (each with 16 pipelined workers = 32 connections)
  /// saturates 10+ MB/s ISP links without disk I/O thrashing or bandwidth fragmentation.
  static const int maxConcurrentDownloads = 2;

  final DownloadRepository _repository;
  final DownloadSubtitlePipeline _subtitlePipeline;
  final VideoDownloadService _videoService;
  final Map<String, CancelToken> _cancelTokens = {};
  final Set<String> _activeDownloadIds = <String>{};
  final List<_QueuedDownloadTask> _downloadQueue = <_QueuedDownloadTask>[];

  DownloadNotifier(
    this._repository, {
    DownloadSubtitlePipeline? subtitlePipeline,
    VideoDownloadService? videoService,
  }) : _subtitlePipeline = subtitlePipeline ?? DownloadSubtitlePipeline(),
       _videoService = videoService ?? VideoDownloadService(),
       super([]) {
    _loadAll();
  }

  void _loadAll() {
    state = _repository.getAllDownloads();
  }

  /// Checks if a movie or TV episode is already downloading or completed.
  DownloadItem? findExisting({
    required String mediaType,
    required int tmdbId,
    int? season,
    int? episode,
  }) {
    final id = mediaType == 'movie'
        ? 'movie_$tmdbId'
        : 'tv_${tmdbId}_s${season ?? 1}_e${episode ?? 1}';
    return state.where((item) => item.id == id).firstOrNull;
  }

  /// Starts downloading a movie or TV episode.
  Future<void> startDownload({
    required int tmdbId,
    required String mediaType,
    required String title,
    String releaseYear = '',
    int? season,
    int? episode,
    String? episodeTitle,
    String? posterPath,
    String? episodeStillPath,
    String? backdropPath,
    String? imdbId,
    required String resolution,
    required String streamUrl,
    String masterPlaylistUrl = '',
    Map<String, String>? headers,
    required int estimatedSizeBytes,
    String preferredSubtitleLang = 'id',
    SubtitleInfo? selectedSubtitle,
    bool autoTranslate = true,
    String targetTranslateLang = 'id',
    int runtimeMinutes = 100,
  }) async {
    final id = mediaType == 'movie'
        ? 'movie_$tmdbId'
        : 'tv_${tmdbId}_s${season ?? 1}_e${episode ?? 1}';

    // Format file names strictly according to user rules:
    // Movie: "{Movie Name} - {Release Year}.mp4"
    // TV: "{TV Series Name} - S{Season} E{Episode}.mp4"
    final videoFileName = mediaType == 'movie'
        ? DownloadFileNamer.formatMovieFileName(title, releaseYear)
        : DownloadFileNamer.formatTvFileName(title, season ?? 1, episode ?? 1);
    final subtitleFileName = DownloadFileNamer.formatSubtitleFileName(
      videoFileName,
    );

    final dir = await VideoDownloadService.getDownloadDirectory();
    final itemDir = Directory('${dir.path}/$id');
    if (!await itemDir.exists()) await itemDir.create(recursive: true);

    final videoPath = '${itemDir.path}/master.m3u8';
    final subtitlePath = '${itemDir.path}/$subtitleFileName';

    final cancelToken = CancelToken();
    _cancelTokens[id] = cancelToken;
    _downloadQueue.removeWhere((t) => t.item.id == id);

    final shouldQueue =
        !_activeDownloadIds.contains(id) &&
        _activeDownloadIds.length >= maxConcurrentDownloads;

    var item = DownloadItem(
      id: id,
      tmdbId: tmdbId,
      title: title,
      mediaType: mediaType,
      releaseYear: releaseYear,
      seasonNumber: season,
      episodeNumber: episode,
      episodeTitle: episodeTitle,
      posterPath: posterPath,
      episodeStillPath: episodeStillPath,
      backdropPath: backdropPath,
      resolution: resolution,
      estimatedSizeBytes: estimatedSizeBytes,
      downloadedBytes: 0,
      totalBytes: estimatedSizeBytes,
      status: shouldQueue
          ? DownloadStatus.resolving
          : DownloadStatus.downloading,
      progress: 0.0,
      speed: shouldQueue ? 'Dalam antrean...' : '0 KB/s',
      videoFileName: videoFileName,
      subtitleFileName: subtitleFileName,
      videoPath: videoPath,
      subtitlePath: subtitlePath,
      selectedSubtitleLang: preferredSubtitleLang,
      subtitleStatus: 'none',
      createdAt: DateTime.now(),
    );

    // Save and update state
    await _repository.saveDownload(item);
    _loadAll();

    final queuedTask = _QueuedDownloadTask(
      item: item,
      imdbId: imdbId,
      streamUrl: streamUrl,
      masterPlaylistUrl: masterPlaylistUrl,
      headers: headers,
      selectedSubtitle: selectedSubtitle,
      autoTranslate: autoTranslate,
      targetTranslateLang: targetTranslateLang,
      cancelToken: cancelToken,
      runtimeMinutes: runtimeMinutes,
    );

    if (shouldQueue) {
      _downloadQueue.add(queuedTask);
      return;
    }

    _activeDownloadIds.add(id);
    // Asynchronously execute download task in background isolate without blocking UI
    unawaited(
      _executeDownloadTask(
        item: item,
        imdbId: imdbId,
        streamUrl: streamUrl,
        masterPlaylistUrl: masterPlaylistUrl,
        headers: headers,
        selectedSubtitle: selectedSubtitle,
        autoTranslate: autoTranslate,
        targetTranslateLang: targetTranslateLang,
        cancelToken: cancelToken,
        runtimeMinutes: runtimeMinutes,
      ),
    );
  }

  void _pumpQueue() {
    while (_activeDownloadIds.length < maxConcurrentDownloads &&
        _downloadQueue.isNotEmpty) {
      final next = _downloadQueue.removeAt(0);
      if (next.cancelToken.isCancelled) continue;
      final latest = _repository.getDownloadById(next.item.id) ?? next.item;
      if (latest.status == DownloadStatus.paused ||
          latest.status == DownloadStatus.completed ||
          latest.status == DownloadStatus.cancelled) {
        continue;
      }
      _activeDownloadIds.add(next.item.id);
      unawaited(
        _executeDownloadTask(
          item: latest,
          imdbId: next.imdbId,
          streamUrl: next.streamUrl,
          masterPlaylistUrl: next.masterPlaylistUrl,
          headers: next.headers,
          selectedSubtitle: next.selectedSubtitle,
          autoTranslate: next.autoTranslate,
          targetTranslateLang: next.targetTranslateLang,
          cancelToken: next.cancelToken,
          runtimeMinutes: next.runtimeMinutes,
        ),
      );
    }
  }

  Future<void> _executeDownloadTask({
    required DownloadItem item,
    String? imdbId,
    required String streamUrl,
    String masterPlaylistUrl = '',
    Map<String, String>? headers,
    SubtitleInfo? selectedSubtitle,
    bool autoTranslate = true,
    String targetTranslateLang = 'id',
    required CancelToken cancelToken,
    required int runtimeMinutes,
  }) async {
    final id = item.id;
    _activeDownloadIds.add(id);

    try {
      var currentItem = item.status == DownloadStatus.resolving
          ? item.copyWith(status: DownloadStatus.downloading, speed: '0 KB/s')
          : item;
      if (item.status == DownloadStatus.resolving && mounted) {
        await _repository.saveDownload(currentItem);
        _updateItemInState(currentItem);
      }
      var targetStreamUrl = streamUrl;
      var targetMasterUrl = masterPlaylistUrl;
      var targetHeaders = headers;

      // Dynamically resolve download streams on resume if streamUrl was blank
      if (targetStreamUrl.isEmpty) {
        try {
          final options = await _videoService.resolveResolutionOptions(
            tmdbId: item.tmdbId,
            imdbId: imdbId,
            season: item.seasonNumber,
            episode: item.episodeNumber,
            runtimeMinutes: runtimeMinutes,
          );
          if (options.isNotEmpty) {
            final matched = options.firstWhere(
              (o) => o.label == item.resolution,
              orElse: () => options.first,
            );
            targetStreamUrl = matched.streamUrl;
            targetMasterUrl = matched.masterPlaylistUrl;
            targetHeaders = matched.headers;
          }
        } catch (e) {
          debugPrint(
            '[DownloadNotifier] Dynamic stream re-resolution failed: $e',
          );
        }
      }

      // Start Subtitle pipeline concurrently in the background (slightly deferred so initial
      // video playlist & encryption keys take 100% network priority).
      bool videoCompleted = false;
      final subtitleFuture = Future<void>(() async {
        if (item.selectedSubtitleLang != 'none') {
          try {
            await Future<void>.delayed(const Duration(milliseconds: 600));
            if (cancelToken.isCancelled) return;
            final subResult = await _subtitlePipeline.processSubtitle(
              targetFilePath: item.subtitlePath!,
              title: item.title,
              imdbId: imdbId,
              tmdbId: item.tmdbId,
              season: item.seasonNumber,
              episode: item.episodeNumber,
              preferredLang: item.selectedSubtitleLang,
              selectedSubtitle: selectedSubtitle,
              autoTranslate: autoTranslate,
              targetTranslateLang: targetTranslateLang,
              masterPlaylistUrl: targetMasterUrl,
            );
            currentItem = currentItem.copyWith(
              subtitleStatus: subResult.status,
              subtitlePath: subResult.subtitlePath,
            );
            // If video already completed while subtitle was translating, persist the updated subtitle immediately
            if (videoCompleted && mounted) {
              await _repository.saveDownload(currentItem);
              _updateItemInState(currentItem);
            }
          } catch (e) {
            debugPrint('[DownloadNotifier] Subtitle pipeline error: $e');
          }
        }
      });

      int lastHiveSaveMs = 0;

      // Video download runs inside a dedicated background isolate at full multi-connection speed
      await _videoService.downloadStream(
        streamUrl: targetStreamUrl,
        masterPlaylistUrl: targetMasterUrl,
        headers: targetHeaders,
        targetFilePath: item.videoPath,
        estimatedSizeBytes: item.estimatedSizeBytes,
        preferredQuality: item.resolution,
        tmdbId: item.tmdbId,
        imdbId: imdbId,
        season: item.seasonNumber,
        episode: item.episodeNumber,
        cancelToken: cancelToken,
        onProgress:
            ({
              required int downloadedBytes,
              required int totalBytes,
              required double progress,
              required String speed,
            }) {
              if (!mounted) return;
              currentItem = currentItem.copyWith(
                downloadedBytes: downloadedBytes,
                totalBytes: totalBytes,
                progress: progress,
                speed: speed,
              );
              _updateItemInState(currentItem);

              // Throttle Hive disk persistence to once every 4.5 seconds during active download
              // so the UI thread never stutters on frequent JSON/Hive serialization.
              final now = DateTime.now().millisecondsSinceEpoch;
              if (now - lastHiveSaveMs >= 4500) {
                lastHiveSaveMs = now;
                unawaited(_repository.saveDownload(currentItem));
              }
            },
      );

      // Step 3: Build unified offline media container immediately when video segments finish
      // (runs in parallel with any ongoing subtitle translation).
      final parentDir = Directory(File(item.videoPath).parent.path);
      bool mp4Built = false;
      try {
        if (await parentDir.exists()) {
          debugPrint(
            '[DownloadNotifier] Building offline media package in: ${parentDir.path}',
          );
          final expectedDurUs =
              await OfflineMp4Builder.expectedDurationUsFromPlaylist(
                File('${parentDir.path}/video.m3u8'),
              );

          if (mounted) {
            currentItem = currentItem.copyWith(
              status: DownloadStatus.finalizing,
              progress: 0.0,
              speed: 'Menyiapkan berkas offline...',
            );
            await _repository.saveDownload(currentItem);
            _updateItemInState(currentItem);
          }

          mp4Built = await OfflineMp4Builder.build(
            dir: parentDir,
            expectedDurationUs: expectedDurUs,
            deleteSegmentsOnSuccess: true,
            deleteSegmentsInBackground: true,
            onProgress:
                ({required double progress, required String statusMessage}) {
                  if (!mounted) return;
                  currentItem = currentItem.copyWith(
                    status: DownloadStatus.finalizing,
                    progress: progress.clamp(0.0, 1.0),
                    speed: statusMessage,
                  );
                  // Update UI state in-memory without writing to Hive on every progress tick
                  _updateItemInState(currentItem);
                },
          );
        }
      } catch (e) {
        debugPrint('[DownloadNotifier] OfflineMp4Builder build note: $e');
      }

      // If no valid MP4 could be produced, the raw HLS bundle is the only thing left to
      // play. Make sure it is genuine media; otherwise report a failure now instead of
      // marking the item "completed" and letting it open as a black screen at 00:00.
      if (!mp4Built && !await OfflineMp4Builder.verifyHlsBundle(parentDir)) {
        // Drop the suspicious segments so a retry downloads everything fresh.
        try {
          final junk = RegExp(
            r'^(?:[va]_\d+\.(?:ts|m4s)|init_[va]\.mp4|\.dl_state)$',
          );
          await for (final f in parentDir.list()) {
            if (f is! File) continue;
            final name = f.path.split(RegExp(r'[\\/]')).last;
            if (junk.hasMatch(name)) {
              try {
                await f.delete();
              } catch (_) {}
            }
          }
        } catch (_) {}
        throw Exception(
          'File hasil unduhan tidak valid atau rusak (bukan data video). '
          'Hapus lalu unduh ulang.',
        );
      }

      // Step 4: Resolve the best validated playable file and compute actual size
      // When mp4Built is true, the unified container (`video.mp4` or `video.ts`) is already validated
      // and old .ts segments are deleting asynchronously in the background, so read the unified file(s)
      // directly without scanning 1,500 deleting segment files.
      final File? playableFile =
          await OfflineMp4Builder.findPlayableOfflineFile(parentDir);
      int actualTotalBytes = 0;
      if (mp4Built && playableFile != null) {
        try {
          actualTotalBytes = await playableFile.length();
          final secondaryAudio = await OfflineMp4Builder.getSecondaryAudioFile(
            parentDir,
          );
          if (secondaryAudio != null) {
            actualTotalBytes += await secondaryAudio.length();
          }
        } catch (_) {}
      } else {
        try {
          if (await parentDir.exists()) {
            await for (final f in parentDir.list(recursive: true)) {
              if (f is File) actualTotalBytes += await f.length();
            }
          }
        } catch (_) {}
      }

      final masterM3u8 = File('${parentDir.path}/master.m3u8');
      final masterCineva = File('${parentDir.path}/master.cineva');
      final fallbackPath = (await masterM3u8.exists())
          ? masterM3u8.path
          : ((await masterCineva.exists())
                ? masterCineva.path
                : currentItem.videoPath);

      final actualVideoPath = playableFile?.path ?? fallbackPath;

      currentItem = currentItem.copyWith(
        status: DownloadStatus.completed,
        videoPath: actualVideoPath,
        downloadedBytes: actualTotalBytes > 0
            ? actualTotalBytes
            : currentItem.downloadedBytes,
        totalBytes: actualTotalBytes > 0
            ? actualTotalBytes
            : currentItem.totalBytes,
        progress: 1.0,
        speed: 'Selesai',
        completedAt: DateTime.now(),
      );
      videoCompleted = true;
      await _repository.saveDownload(currentItem);
      _updateItemInState(currentItem);

      // Allow any ongoing background subtitle translation to finish and update the completed record
      unawaited(subtitleFuture);
    } catch (e) {
      if (cancelToken.isCancelled) {
        debugPrint('[DownloadNotifier] Download cancelled: $id');
        final pausedItem = item.copyWith(
          status: DownloadStatus.paused,
          speed: 'Dijeda',
        );
        await _repository.saveDownload(pausedItem);
        _updateItemInState(pausedItem);
      } else {
        debugPrint('[DownloadNotifier] Download failed: $e');
        final failedItem = item.copyWith(
          status: DownloadStatus.failed,
          speed: 'Gagal',
          errorMessage: e.toString(),
        );
        await _repository.saveDownload(failedItem);
        _updateItemInState(failedItem);
      }
    } finally {
      _cancelTokens.remove(id);
      _activeDownloadIds.remove(id);
      _pumpQueue();
    }
  }

  void _updateItemInState(DownloadItem item) {
    state = [
      for (final existing in state)
        if (existing.id == item.id) item else existing,
    ];
  }

  /// Pauses an active or queued download.
  void pauseDownload(String id) {
    _downloadQueue.removeWhere((t) => t.item.id == id);
    _activeDownloadIds.remove(id);
    final token = _cancelTokens[id];
    if (token != null && !token.isCancelled) {
      token.cancel('User paused download');
    }
    final item = _repository.getDownloadById(id);
    if (item != null) {
      final paused = item.copyWith(
        status: DownloadStatus.paused,
        speed: 'Dijeda',
      );
      _repository.saveDownload(paused);
      _updateItemInState(paused);
    }
    _pumpQueue();
  }

  /// Resumes a paused or failed download.
  Future<void> resumeDownload(String id) async {
    final item = _repository.getDownloadById(id);
    if (item == null) return;

    final token = CancelToken();
    _cancelTokens[id] = token;
    _downloadQueue.removeWhere((t) => t.item.id == id);

    final shouldQueue =
        !_activeDownloadIds.contains(id) &&
        _activeDownloadIds.length >= maxConcurrentDownloads;

    final updated = item.copyWith(
      status: shouldQueue
          ? DownloadStatus.resolving
          : DownloadStatus.downloading,
      speed: shouldQueue ? 'Dalam antrean...' : 'Melanjutkan...',
      errorMessage: null,
    );
    await _repository.saveDownload(updated);
    _updateItemInState(updated);

    if (shouldQueue) {
      _downloadQueue.add(
        _QueuedDownloadTask(
          item: updated,
          imdbId: null,
          streamUrl: '',
          masterPlaylistUrl: '',
          headers: null,
          selectedSubtitle: null,
          autoTranslate: true,
          targetTranslateLang: updated.selectedSubtitleLang,
          cancelToken: token,
          runtimeMinutes: 100,
        ),
      );
      return;
    }

    _activeDownloadIds.add(id);
    unawaited(
      _executeDownloadTask(
        item: updated,
        streamUrl: '', // Will be resolved dynamically
        cancelToken: token,
        runtimeMinutes: 100,
      ),
    );
  }

  /// Cancels and deletes an active, queued, or completed download.
  Future<void> deleteDownload(String id) async {
    _downloadQueue.removeWhere((t) => t.item.id == id);
    _activeDownloadIds.remove(id);
    final token = _cancelTokens[id];
    if (token != null && !token.isCancelled) {
      token.cancel('User deleted download');
      _cancelTokens.remove(id);
    }
    await _repository.deleteDownload(id);
    _loadAll();
    _pumpQueue();
  }

  /// Cancels an active download.
  Future<void> cancelDownload(String id) => deleteDownload(id);
}

// ── Providers ──
final downloadManagerProvider =
    StateNotifierProvider<DownloadNotifier, List<DownloadItem>>((ref) {
      final repo = ref.watch(downloadRepositoryProvider);
      return DownloadNotifier(repo);
    });

final activeDownloadsCountProvider = Provider<int>((ref) {
  return ref.watch(
    downloadManagerProvider.select(
      (items) => items.where((item) => item.isDownloading).length,
    ),
  );
});

final completedDownloadsProvider = Provider<List<DownloadItem>>((ref) {
  final items = ref.watch(downloadManagerProvider);
  return items.where((item) => item.isCompleted).toList();
});

final inProgressDownloadsProvider = Provider<List<DownloadItem>>((ref) {
  final items = ref.watch(downloadManagerProvider);
  return items.where((item) => !item.isCompleted).toList();
});
