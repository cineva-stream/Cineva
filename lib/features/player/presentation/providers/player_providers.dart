import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/torrent_source_service.dart';
import '../../data/services/torrent_stream_service.dart';
import '../../data/services/subtitle_service.dart';
import '../../data/services/subtitle_translator_service.dart';
import '../../data/services/network_quality_service.dart';
import '../../data/models/subtitle_cue.dart';
import '../../data/models/subtitle_style_settings.dart';

/// Singleton torrent source service provider.
final torrentSourceServiceProvider = Provider<TorrentSourceService>((ref) {
  final service = TorrentSourceService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Singleton torrent streaming engine provider.
final torrentStreamServiceProvider = Provider<TorrentStreamService>((ref) {
  final service = TorrentStreamService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Singleton subtitle service provider.
final subtitleServiceProvider = Provider<SubtitleService>((ref) {
  final service = SubtitleService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Singleton subtitle translator service provider.
final subtitleTranslatorServiceProvider = Provider<SubtitleTranslatorService>((ref) {
  final service = SubtitleTranslatorService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Singleton network quality & auto source selector service provider.
final networkQualityServiceProvider = Provider<NetworkQualityService>((ref) {
  return NetworkQualityService();
});

/// Fetches available torrent sources for a given IMDb ID.
final torrentSourcesProvider = FutureProvider.family<List<TorrentSource>, String>((ref, imdbId) async {
  final service = ref.watch(torrentSourceServiceProvider);
  return service.searchByImdbId(imdbId);
});

/// Fetches stream/torrent sources for a movie or TV episode.
final streamSourcesProvider = FutureProvider.family<List<TorrentSource>, ({String imdbId, int? season, int? episode})>((ref, params) async {
  final service = ref.watch(torrentSourceServiceProvider);
  return service.searchByImdbId(
    params.imdbId,
    season: params.season,
    episode: params.episode,
  );
});

/// Fetches subtitles for a given IMDb ID with optional language, season, and episode.
final subtitlesProvider = FutureProvider.family<List<SubtitleInfo>, ({String imdbId, String? language, int? season, int? episode})>((ref, params) async {
  final service = ref.watch(subtitleServiceProvider);
  return service.searchByImdbId(
    params.imdbId,
    language: params.language,
    seasonNumber: params.season,
    episodeNumber: params.episode,
  );
});

/// State notifier for subtitle styling, positioning, and timing synchronization.
class SubtitleStyleNotifier extends StateNotifier<SubtitleStyleSettings> {
  SubtitleStyleNotifier() : super(const SubtitleStyleSettings());

  void updateStrokeWidth(double width) {
    state = state.copyWith(strokeWidth: width);
  }

  void updateFontSize(double size) {
    state = state.copyWith(fontSize: size);
  }

  void updateTextColor(dynamic color) {
    state = state.copyWith(textColor: color);
  }

  void updateBottomOffset(double offset) {
    state = state.copyWith(bottomOffset: offset);
  }

  void updateBackgroundOpacity(double opacity) {
    state = state.copyWith(backgroundOpacity: opacity);
  }

  void adjustSyncOffset(int deltaMs) {
    state = state.copyWith(syncOffsetMs: state.syncOffsetMs + deltaMs);
  }

  void resetSyncOffset() {
    state = state.copyWith(syncOffsetMs: 0);
  }
}

final subtitleStyleProvider = StateNotifierProvider<SubtitleStyleNotifier, SubtitleStyleSettings>((ref) {
  return SubtitleStyleNotifier();
});

/// Currently active subtitle cues list loaded in the player.
final activeSubtitleCuesProvider = StateProvider<List<SubtitleCue>>((ref) => []);
