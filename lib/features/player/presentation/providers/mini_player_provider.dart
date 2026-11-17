import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../history/data/models/watch_history_item.dart';
import '../../../history/data/repositories/watch_history_repository.dart';
import '../../data/models/subtitle_cue.dart';
import '../../data/services/smart_stream_service.dart';
import '../../data/services/subtitle_service.dart';
import 'player_providers.dart';

/// Holds the live, uninterrupted media_kit [Player] and [VideoController]
/// along with full stream metadata when minimized to the In-App Mini-Player.
class MiniPlayerSession {
  final Player player;
  final VideoController videoController;
  final String magnetLink;
  final String title;
  final String? imdbId;
  final int? tmdbId;
  final String? mediaType;
  final int? season;
  final int? episode;
  final String? episodeTitle;
  final String? posterPath;
  final String? backdropPath;
  final String? localVideoPath;
  final String? localSubtitlePath;
  final String? overview;

  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final bool isBuffering;
  final double volume;
  final double playbackSpeed;
  final String currentQuality;
  final String resolutionLabel;
  final SmartStreamServer currentServer;
  final List<SmartStreamServer> availableServers;
  final List<SubtitleInfo> availableSubtitles;
  final List<SubtitleInfo> streamSubtitles;
  final SubtitleInfo? selectedSubtitle;
  final bool isSubtitleTranslated;
  final Map<String, List<SubtitleCue>> customSubtitleCues;
  final List<SubtitleCue> activeCues;
  final bool isExpandingToFullPlayer;

  const MiniPlayerSession({
    required this.player,
    required this.videoController,
    required this.magnetLink,
    required this.title,
    this.imdbId,
    this.tmdbId,
    this.mediaType,
    this.season,
    this.episode,
    this.episodeTitle,
    this.posterPath,
    this.backdropPath,
    this.localVideoPath,
    this.localSubtitlePath,
    this.overview,
    required this.position,
    required this.duration,
    required this.isPlaying,
    this.isBuffering = false,
    required this.volume,
    required this.playbackSpeed,
    required this.currentQuality,
    required this.resolutionLabel,
    required this.currentServer,
    required this.availableServers,
    required this.availableSubtitles,
    required this.streamSubtitles,
    this.selectedSubtitle,
    required this.isSubtitleTranslated,
    required this.customSubtitleCues,
    required this.activeCues,
    this.isExpandingToFullPlayer = false,
  });

  bool matchesMedia({
    required int? tmdbId,
    required String? mediaType,
    required int? season,
    required int? episode,
    required String title,
  }) {
    final normalizedThisType =
        (this.season != null || this.episode != null) ? 'tv' : (this.mediaType ?? 'movie');
    final normalizedOtherType =
        (season != null || episode != null) ? 'tv' : (mediaType ?? 'movie');

    if (this.tmdbId != null && tmdbId != null && this.tmdbId! > 0 && tmdbId > 0) {
      if (this.tmdbId != tmdbId) return false;
      if (normalizedThisType != normalizedOtherType) return false;
      if (normalizedThisType == 'tv') {
        return this.season == season && this.episode == episode;
      }
      return true;
    }
    return this.title == title && this.season == season && this.episode == episode;
  }

  Map<String, dynamic> toRouteExtra() {
    return {
      'magnetLink': magnetLink,
      'title': title,
      'imdbId': imdbId,
      'season': season,
      'episode': episode,
      'tmdbId': tmdbId,
      'mediaType': mediaType,
      'posterPath': posterPath,
      'backdropPath': backdropPath,
      'episodeTitle': episodeTitle,
      'initialPositionMs': position.inMilliseconds,
      'localVideoPath': localVideoPath,
      'localSubtitlePath': localSubtitlePath,
      'overview': overview,
    };
  }

  MiniPlayerSession copyWith({
    Duration? position,
    Duration? duration,
    bool? isPlaying,
    bool? isBuffering,
    double? volume,
    double? playbackSpeed,
    bool? isExpandingToFullPlayer,
  }) {
    return MiniPlayerSession(
      player: player,
      videoController: videoController,
      magnetLink: magnetLink,
      title: title,
      imdbId: imdbId,
      tmdbId: tmdbId,
      mediaType: mediaType,
      season: season,
      episode: episode,
      episodeTitle: episodeTitle,
      posterPath: posterPath,
      backdropPath: backdropPath,
      localVideoPath: localVideoPath,
      localSubtitlePath: localSubtitlePath,
      overview: overview,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      volume: volume ?? this.volume,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      currentQuality: currentQuality,
      resolutionLabel: resolutionLabel,
      currentServer: currentServer,
      availableServers: availableServers,
      availableSubtitles: availableSubtitles,
      streamSubtitles: streamSubtitles,
      selectedSubtitle: selectedSubtitle,
      isSubtitleTranslated: isSubtitleTranslated,
      customSubtitleCues: customSubtitleCues,
      activeCues: activeCues,
      isExpandingToFullPlayer:
          isExpandingToFullPlayer ?? this.isExpandingToFullPlayer,
    );
  }
}

class MiniPlayerNotifier extends StateNotifier<MiniPlayerSession?> {
  final Ref _ref;
  final ValueNotifier<Duration> positionNotifier =
      ValueNotifier<Duration>(Duration.zero);

  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<bool>? _bufferingSub;
  DateTime _lastHistorySaveTime = DateTime.now();

  MiniPlayerNotifier(this._ref) : super(null);

  /// Receives ownership of an active [Player] & [VideoController] from [PlayerScreen]
  /// without interrupting playback, buffer, or audio.
  void activateSession(MiniPlayerSession session) {
    // If another session existed, dispose it first
    if (state != null && state!.player != session.player) {
      _disposeInternalPlayer(state!);
    }
    _cancelSubscriptions();

    positionNotifier.value = session.position;
    state = session;

    _posSub = session.player.stream.position.listen((pos) {
      positionNotifier.value = pos;
      if (state != null) {
        state = state!.copyWith(position: pos);
        final now = DateTime.now();
        if (now.difference(_lastHistorySaveTime).inSeconds >= 5) {
          _lastHistorySaveTime = now;
          _saveWatchHistory(state!);
        }
      }
    });

    _durSub = session.player.stream.duration.listen((dur) {
      if (state != null && dur.inMilliseconds > 0 && state!.duration != dur) {
        state = state!.copyWith(duration: dur);
      }
    });

    _playingSub = session.player.stream.playing.listen((playing) {
      if (state != null && state!.isPlaying != playing) {
        state = state!.copyWith(isPlaying: playing);
      }
    });

    _bufferingSub = session.player.stream.buffering.listen((buffering) {
      if (state != null && state!.isBuffering != buffering) {
        state = state!.copyWith(isBuffering: buffering);
      }
    });
  }

  /// Marks that the Mini-Player is about to expand back to [PlayerScreen].
  void prepareForExpand() {
    if (state == null) return;
    _cancelSubscriptions();
    state = state!.copyWith(isExpandingToFullPlayer: true);
  }

  /// Transfers ownership of the [MiniPlayerSession] back to [PlayerScreen]
  /// without stopping or disposing the [Player].
  MiniPlayerSession? takeOverSession() {
    final current = state;
    if (current == null) return null;
    _cancelSubscriptions();
    _ref.read(activeSubtitleCuesProvider.notifier).state = current.activeCues;
    state = null;
    return current;
  }

  void togglePlayPause() {
    final current = state;
    if (current == null) return;
    try {
      current.player.playOrPause();
    } catch (e) {
      debugPrint('[MiniPlayer] togglePlayPause error: $e');
    }
  }

  void seekRelative(int seconds) {
    final current = state;
    if (current == null) return;
    final target = current.position + Duration(seconds: seconds);
    final clamped = target < Duration.zero
        ? Duration.zero
        : (current.duration > Duration.zero && target > current.duration
            ? current.duration
            : target);
    positionNotifier.value = clamped;
    state = current.copyWith(position: clamped);
    try {
      current.player.seek(clamped);
    } catch (e) {
      debugPrint('[MiniPlayer] seekRelative error: $e');
    }
  }

  /// Completely stops and disposes the active Mini-Player session.
  Future<void> closeAndDispose() async {
    final current = state;
    if (current == null) return;
    _saveWatchHistory(current);
    _cancelSubscriptions();
    state = null;
    await _disposeInternalPlayer(current);
  }

  Future<void> _disposeInternalPlayer(MiniPlayerSession session) async {
    try {
      await session.player.setVolume(0.0);
      await session.player.pause();
      await session.player.stop();
      await session.player.dispose();
    } catch (e) {
      debugPrint('[MiniPlayer] Error disposing player: $e');
    }
  }

  void _saveWatchHistory(MiniPlayerSession session) {
    final tmdbId = session.tmdbId;
    if (tmdbId == null || tmdbId == 0) return;

    final posMs = session.position.inMilliseconds;
    final durMs = session.duration.inMilliseconds;
    if (durMs <= 0 || posMs < 3000) return;

    final mediaType = (session.season != null || session.episode != null)
        ? 'tv'
        : (session.mediaType ?? 'movie');
    final isTv = mediaType == 'tv';
    final remainingSecs = (session.duration - session.position).inSeconds;
    final isCompleted = isTv
        ? ((posMs / durMs) >= 0.92 ||
            (session.duration.inSeconds > 30 && remainingSecs <= 60))
        : ((posMs / durMs) >= 0.95);

    final item = WatchHistoryItem(
      id: tmdbId,
      mediaType: mediaType,
      title: session.title,
      episodeTitle: session.episodeTitle,
      season: session.season,
      episode: session.episode,
      imdbId: session.imdbId,
      posterPath: session.posterPath,
      backdropPath: session.backdropPath,
      positionMs: posMs,
      durationMs: durMs,
      lastWatchedAt: DateTime.now(),
      isCompleted: isCompleted,
    );

    _ref.read(watchHistoryProvider.notifier).saveProgress(item);
  }

  void _cancelSubscriptions() {
    _posSub?.cancel();
    _posSub = null;
    _durSub?.cancel();
    _durSub = null;
    _playingSub?.cancel();
    _playingSub = null;
    _bufferingSub?.cancel();
    _bufferingSub = null;
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    positionNotifier.dispose();
    super.dispose();
  }
}

final miniPlayerProvider =
    StateNotifierProvider<MiniPlayerNotifier, MiniPlayerSession?>((ref) {
  return MiniPlayerNotifier(ref);
});

