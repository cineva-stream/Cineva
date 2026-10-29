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

/// State notifier managing all download tasks, persistent storage, and live progress.
class DownloadNotifier extends StateNotifier<List<DownloadItem>> {
  final DownloadRepository _repository;
  final DownloadSubtitlePipeline _subtitlePipeline;
  final VideoDownloadService _videoService;
  final Map<String, CancelToken> _cancelTokens = {};

  DownloadNotifier(
    this._repository, {
    DownloadSubtitlePipeline? subtitlePipeline,
    VideoDownloadService? videoService,
  })  : _subtitlePipeline = subtitlePipeline ?? DownloadSubtitlePipeline(),
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
    String? backdropPath,
    String? imdbId,
    required String resolution,
    required String streamUrl,
    String masterPlaylistUrl = '',
    required int estimatedSizeBytes,
    String preferredSubtitleLang = 'id',
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
    final subtitleFileName = DownloadFileNamer.formatSubtitleFileName(videoFileName);

    final dir = await VideoDownloadService.getDownloadDirectory();
    final itemDir = Directory('${dir.path}/$id');
    if (!await itemDir.exists()) await itemDir.create(recursive: true);

    final videoPath = '${itemDir.path}/master.m3u8';
    final subtitlePath = '${itemDir.path}/$subtitleFileName';


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
      backdropPath: backdropPath,
      resolution: resolution,
      estimatedSizeBytes: estimatedSizeBytes,
      downloadedBytes: 0,
      totalBytes: estimatedSizeBytes,
      status: DownloadStatus.downloading,
      progress: 0.0,
      speed: '0 KB/s',
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

    final cancelToken = CancelToken();
    _cancelTokens[id] = cancelToken;

    // Asynchronously execute download task without blocking UI
    unawaited(_executeDownloadTask(
      item: item,
      imdbId: imdbId,
      streamUrl: streamUrl,
      masterPlaylistUrl: masterPlaylistUrl,
      cancelToken: cancelToken,
      runtimeMinutes: runtimeMinutes,
    ));
  }

  Future<void> _executeDownloadTask({
    required DownloadItem item,
    String? imdbId,
    required String streamUrl,
    String masterPlaylistUrl = '',
    required CancelToken cancelToken,
    required int runtimeMinutes,
  }) async {
    final id = item.id;

    try {
      var currentItem = item;

      // Start Subtitle pipeline concurrently in the background so video download begins immediately
      final subtitleFuture = Future<void>(() async {
        if (item.selectedSubtitleLang != 'none') {
          try {
            final subResult = await _subtitlePipeline.processSubtitle(
              targetFilePath: item.subtitlePath!,
              title: item.title,
              imdbId: imdbId,
              tmdbId: item.tmdbId,
              season: item.seasonNumber,
              episode: item.episodeNumber,
              preferredLang: item.selectedSubtitleLang,
              masterPlaylistUrl: masterPlaylistUrl,
            );
            currentItem = currentItem.copyWith(
              subtitleStatus: subResult.status,
              subtitlePath: subResult.subtitlePath,
            );
            await _repository.saveDownload(currentItem);
            _updateItemInState(currentItem);
          } catch (e) {
            debugPrint('[DownloadNotifier] Subtitle pipeline error: $e');
          }
        }
      });

      // Video download starts at full multi-connection speed instantly
      final videoFuture = _videoService.downloadStream(
        streamUrl: streamUrl,
        masterPlaylistUrl: masterPlaylistUrl,
        targetFilePath: item.videoPath,
        estimatedSizeBytes: item.estimatedSizeBytes,
        cancelToken: cancelToken,
        onProgress: ({
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
          _repository.saveDownload(currentItem);
          _updateItemInState(currentItem);
        },
      );

      // Wait for both video and subtitle streams to complete
      await Future.wait([videoFuture, subtitleFuture]);

      // Step 3: Build unified offline media container (video.mp4 with video.ts fallback)
      final parentDir = Directory(File(item.videoPath).parent.path);
      try {
        if (await parentDir.exists()) {
          debugPrint('[DownloadNotifier] Building offline media package in: ${parentDir.path}');
          await OfflineMp4Builder.build(
            dir: parentDir,
            deleteSegmentsOnSuccess: true,
          );
        }
      } catch (e) {
        debugPrint('[DownloadNotifier] OfflineMp4Builder build note: $e');
      }

      // Step 4: Resolve the best validated playable file and compute actual size
      final playableFile = await OfflineMp4Builder.findPlayableOfflineFile(parentDir);

      int actualTotalBytes = 0;
      try {
        if (await parentDir.exists()) {
          await for (final f in parentDir.list(recursive: true)) {
            if (f is File) actualTotalBytes += await f.length();
          }
        }
      } catch (_) {}

      final masterM3u8 = File('${parentDir.path}/master.m3u8');
      final masterCineva = File('${parentDir.path}/master.cineva');
      final fallbackPath = (await masterM3u8.exists())
          ? masterM3u8.path
          : ((await masterCineva.exists()) ? masterCineva.path : currentItem.videoPath);

      final actualVideoPath = playableFile?.path ?? fallbackPath;

      final completedItem = currentItem.copyWith(
        status: DownloadStatus.completed,
        videoPath: actualVideoPath,
        downloadedBytes: actualTotalBytes > 0 ? actualTotalBytes : currentItem.downloadedBytes,
        totalBytes: actualTotalBytes > 0 ? actualTotalBytes : currentItem.totalBytes,
        progress: 1.0,
        speed: 'Selesai',
        completedAt: DateTime.now(),
      );
      await _repository.saveDownload(completedItem);
      _updateItemInState(completedItem);
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
    }
  }

  void _updateItemInState(DownloadItem item) {
    state = [
      for (final existing in state)
        if (existing.id == item.id) item else existing
    ];
  }

  /// Pauses an active download.
  void pauseDownload(String id) {
    final token = _cancelTokens[id];
    if (token != null && !token.isCancelled) {
      token.cancel('User paused download');
    }
    final item = _repository.getDownloadById(id);
    if (item != null) {
      final paused = item.copyWith(status: DownloadStatus.paused, speed: 'Dijeda');
      _repository.saveDownload(paused);
      _updateItemInState(paused);
    }
  }

  /// Resumes a paused or failed download.
  Future<void> resumeDownload(String id) async {
    final item = _repository.getDownloadById(id);
    if (item == null) return;

    final token = CancelToken();
    _cancelTokens[id] = token;

    final updated = item.copyWith(
      status: DownloadStatus.downloading,
      speed: 'Melanjutkan...',
      errorMessage: null,
    );
    await _repository.saveDownload(updated);
    _updateItemInState(updated);

    unawaited(_executeDownloadTask(
      item: updated,
      streamUrl: '', // Will be resolved dynamically
      cancelToken: token,
      runtimeMinutes: 100,
    ));
  }

  /// Cancels and deletes an active or completed download.
  Future<void> deleteDownload(String id) async {
    final token = _cancelTokens[id];
    if (token != null && !token.isCancelled) {
      token.cancel('User deleted download');
      _cancelTokens.remove(id);
    }
    await _repository.deleteDownload(id);
    _loadAll();
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
  final items = ref.watch(downloadManagerProvider);
  return items.where((item) => item.isDownloading).length;
});

final completedDownloadsProvider = Provider<List<DownloadItem>>((ref) {
  final items = ref.watch(downloadManagerProvider);
  return items.where((item) => item.isCompleted).toList();
});

final inProgressDownloadsProvider = Provider<List<DownloadItem>>((ref) {
  final items = ref.watch(downloadManagerProvider);
  return items.where((item) => !item.isCompleted).toList();
});
