import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/torrent_source_service.dart';
import '../../data/services/torrent_stream_service.dart';
import '../../data/services/subtitle_service.dart';
import '../../data/services/subtitle_translator_service.dart';
import '../../data/services/network_quality_service.dart';
import '../../data/models/subtitle_cue.dart';
import '../../data/models/subtitle_style_settings.dart';
import '../../../settings/data/settings_service.dart';

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
  SubtitleStyleNotifier() : super(SubtitleStyleSettings.fromSettings());

  void reloadFromSettings() {
    state = state.copyWith(
      fontSize: SettingsService.getSubtitleFontSizePoints(),
      backgroundOpacity: SettingsService.getSubtitleBackgroundOpacity(),
    );
  }

  void updateStrokeWidth(double width) {
    state = state.copyWith(strokeWidth: width);
  }

  void updateFontSize(double size) {
    state = state.copyWith(fontSize: size);
    try {
      if (size <= 17.0) {
        SettingsService.setSubtitleFontSize('Kecil');
      } else if (size >= 23.0) {
        SettingsService.setSubtitleFontSize('Besar');
      } else {
        SettingsService.setSubtitleFontSize('Sedang');
      }
    } catch (_) {}
  }

  void updateTextColor(dynamic color) {
    state = state.copyWith(textColor: color);
  }

  void updateBottomOffset(double offset) {
    state = state.copyWith(bottomOffset: offset);
  }

  void updateBackgroundOpacity(double opacity) {
    state = state.copyWith(backgroundOpacity: opacity);
    try {
      if (opacity <= 0.15) {
        SettingsService.setSubtitleBackground('Transparan');
      } else if (opacity >= 0.8) {
        SettingsService.setSubtitleBackground('Hitam Pekat');
      } else {
        SettingsService.setSubtitleBackground('Semi-Transparan');
      }
    } catch (_) {}
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
