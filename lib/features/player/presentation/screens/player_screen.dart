import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/models/subtitle_cue.dart';
import '../../data/services/subtitle_service.dart';
import '../../data/services/subtitle_translator_service.dart';
import '../../data/services/vixsrc_stream_service.dart';
import '../../data/services/smart_stream_service.dart';
import '../../data/services/provider_loader_service.dart';
import '../../data/models/provider_stream_models.dart';
import '../../../settings/data/settings_service.dart';
import '../../../settings/data/subtitle_languages.dart';
import '../../../history/data/models/watch_history_item.dart';
import '../../../history/data/repositories/watch_history_repository.dart';
import '../../../download/domain/models/download_item.dart';
import '../../../download/data/services/local_stream_server.dart';
import '../../../download/data/services/offline_mp4_builder.dart';
import '../../../download/data/services/video_download_service.dart';
import '../../../download/presentation/providers/download_provider.dart';
import '../providers/player_providers.dart';
import '../widgets/custom_subtitle_overlay.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/app_language_provider.dart';

enum _PlayerLoadingStep {
  searching,
  connecting,
  preparingBuffer,
  preparingBackup,
  preparingOffline,
  preparingMp4,
  preparingEpisode,
}

enum _PlayerMiniPopup {
  none,
  quality,
  subtitle,
  subtitleSettings,
  volume,
  server,
}

enum _SidePanelPage {
  main,
  quality,
  audio,
  subtitleTrack,
  subtitleSettings,
  server,
  speed,
  info,
}

/// Full-featured Cinema Player Screen with edge-to-edge notch rendering,
/// audio amplification (up to 150%), customizable subtitle background,
/// and transparent mini popups.
class PlayerScreen extends ConsumerStatefulWidget {
  final String magnetLink;
  final String title;
  final String? imdbId;
  final int? season;
  final int? episode;
  final int? tmdbId;
  final String? mediaType;
  final String? posterPath;
  final String? backdropPath;
  final String? episodeTitle;
  final int? initialPositionMs;
  final String? localVideoPath;
  final String? localSubtitlePath;
  final String? overview;

  const PlayerScreen({
    super.key,
    required this.magnetLink,
    required this.title,
    this.imdbId,
    this.season,
    this.episode,
    this.tmdbId,
    this.mediaType,
    this.posterPath,
    this.backdropPath,
    this.episodeTitle,
    this.initialPositionMs,
    this.localVideoPath,
    this.localSubtitlePath,
    this.overview,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  // ── Native Video Player (media_kit / mpv) ──
  late final Player _player;
  late final VideoController _videoController;
  bool _useNativePlayer = true;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _playingSub;
  StreamSubscription? _bufferingSub;
  StreamSubscription? _trackSub;
  StreamSubscription? _tracksSub;

  // ── Fallback WebView Controller ──
  WebViewController? _webViewController;

  // ── Smart Stream Multi-Server & Direct Engine ──
  SmartStreamServer _currentServer = SmartStreamService.servers[0];
  List<SmartStreamServer> _availableServers = SmartStreamService.servers;
  int? _currentTmdbId;
  String? _currentImdbId;
  bool _isWebPlaying = false;

  // ── Playback State ──
  bool _isLoading = true;
  bool _isBuffering = false;
  _PlayerLoadingStep _loadingStep = _PlayerLoadingStep.searching;
  String? _customLoadingStatus;

  static String _formatResolutionLabel(String quality) {
    if (quality == 'Auto') {
      return 'Auto (1080p)';
    } else if (quality == '1080p') {
      return '1080p FHD';
    } else if (quality == '720p') {
      return '720p HD';
    } else if (quality == '480p' || quality == '360p') {
      return '$quality SD';
    } else {
      return '$quality HD';
    }
  }

  late String _currentQuality = SettingsService.getDefaultQuality();
  late String _resolutionLabel = _formatResolutionLabel(_currentQuality);
  bool _hasAppliedDefaultQuality = false;
  bool _isSwitchingQuality = false;
  Duration? _qualityRestorePos;
  bool _streamNotFound = false;

  String _getLoadingStatusText(AppStrings s) {
    if (_customLoadingStatus != null) return _customLoadingStatus!;
    switch (_loadingStep) {
      case _PlayerLoadingStep.searching:
        return s.playerSearchingStream;
      case _PlayerLoadingStep.connecting:
        return s.playerConnectingStream;
      case _PlayerLoadingStep.preparingBuffer:
        return s.playerPreparingFastBuffer;
      case _PlayerLoadingStep.preparingBackup:
        return s.playerPreparingBackup;
      case _PlayerLoadingStep.preparingOffline:
        return s.playerPreparingOffline;
      case _PlayerLoadingStep.preparingMp4:
        return s.playerPreparingMp4;
      case _PlayerLoadingStep.preparingEpisode:
        return s.playerPreparingEpisode(_currentEpisode ?? 1);
    }
  }

  String _getTargetTranslateLang() {
    final prefLang = SettingsService.getDefaultSubtitleLang();
    if (prefLang != 'off') {
      return prefLang.toLowerCase();
    }
    final appLang = ref.read(appLanguageProvider);
    return appLang == AppLanguage.en ? 'en' : 'id';
  }

  Duration _position = Duration.zero;
  final ValueNotifier<Duration> _positionNotifier = ValueNotifier<Duration>(
    Duration.zero,
  );
  Duration _duration = Duration.zero;
  bool _isPlaying = true;
  BoxFit _fitMode =
      BoxFit.cover; // Default cover to expand through camera cutout!

  // ── Audio Volume & Boost State ──
  double _volume = 100.0; // 0 to 150% (boosted)
  bool _showVolumeIndicator = false;
  Timer? _volumeIndicatorTimer;

  // ── Screen Brightness State ──
  static const MethodChannel _brightnessChannel = MethodChannel(
    'com.primadev.cineva/brightness',
  );
  double _brightness = 0.5; // 0.05 to 1.0 (5% to 100%)
  bool _showBrightnessIndicator = false;
  Timer? _brightnessIndicatorTimer;

  // ── Controls & Mini Popups State ──
  bool _showControls = false;
  Timer? _controlsTimer;
  _PlayerMiniPopup _activePopup = _PlayerMiniPopup.none;
  int _subtitleSettingsTab = 0; // 0: Waktu (Sync), 1: Tampilan
  bool _isShowingSubtitleSettingsInPopup = false;

  // ── Right Side Panel State (YouTube-style Collapsible Drawer) ──
  bool _isSidePanelOpen = false;
  _SidePanelPage _sidePanelPage = _SidePanelPage.main;
  double _playbackSpeed = 1.0;

  // ── Subtitles State ──
  List<SubtitleInfo> _availableSubtitles = [];
  List<SubtitleInfo> _streamSubtitles = [];
  SubtitleInfo? _selectedSubtitle;
  bool _isAutoTranslating = false;
  double _translationProgress = 0.0;
  bool _isSubtitleTranslated = false;

  DateTime _lastHistorySaveTime = DateTime.now();
  bool _hasRestoredPosition = false;
  bool _hasAutoPlayedNext = false;
  bool _nextEpisodeButtonVisible = false;
  bool _isSwitchingEpisode = false;

  // ── TV Series Episode & Media State (Allows seamless in-place episode skipping) ──
  late final int? _currentSeason = widget.season;
  late int? _currentEpisode = widget.episode;
  late String? _currentEpisodeTitle =
      widget.episodeTitle ??
      (widget.episode != null ? 'Episode ${widget.episode}' : null);
  late String? _currentLocalVideoPath = widget.localVideoPath;
  late String? _currentLocalSubtitlePath = widget.localSubtitlePath;
  late int? _initialPositionMs = widget.initialPositionMs;
  late String? _currentOverview = widget.overview;
  late String? _currentBackdropPath = widget.backdropPath;
  late String? _currentPosterPath = widget.posterPath;

  @override
  void initState() {
    super.initState();
    _fetchOverviewIfNeeded();
    // Immersive landscape cinema mode covering status bar and notch area
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );

    // Initialize media_kit Player with 32 MB initial demuxer footprint (dynamically caches up to 128 MB)
    _player = Player(
      configuration: const PlayerConfiguration(bufferSize: 32 * 1024 * 1024),
    );
    _videoController = VideoController(
      _player,
      configuration: const VideoControllerConfiguration(
        enableHardwareAcceleration:
            true, // Hardware MediaCodec decoding on Android GPU
      ),
    );

    // Ensure subtitle styling is freshly synchronized from user preferences
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(subtitleStyleProvider.notifier).reloadFromSettings();
      }
    });

    _listenToPlayerStreams();
    _player.setVolume(_volume); // Explicitly ensure 100% base audio volume
    if ((_currentLocalVideoPath != null &&
            _currentLocalVideoPath!.isNotEmpty) ||
        (widget.localVideoPath != null && widget.localVideoPath!.isNotEmpty)) {
      _setupMpvOfflineOptions();
    } else {
      _setupMpvFastBufferOptions();
    }
    _initializeStreaming();
    _resetControlsTimer();
  }

  /// Sets up smooth, zero-latency offline playback options for mpv.
  Future<void> _setupMpvOfflineOptions() async {
    try {
      final mpv = (_player.platform as dynamic);
      await mpv?.command(['set', 'cache', 'yes']);
      await mpv?.command(['set', 'cache-pause', 'no']);
      await mpv?.command(['set', 'cache-pause-initial', 'no']);
      await mpv?.command(['set', 'cache-secs', '60']);
      await mpv?.command(['set', 'demuxer-readahead-secs', '60']);
      await mpv?.command(['set', 'demuxer-max-bytes', '67108864']); // 64 MB
      await mpv?.command(['set', 'hr-seek', 'yes']);
      await mpv?.command(['set', 'network-timeout', '10']);
    } catch (e) {
      debugPrint('[PlayerScreen] mpv offline options setup error: $e');
    }
  }

  /// Sets up low-latency fast-start probing and progressive 3-minute background caching in mpv
  Future<void> _setupMpvFastBufferOptions() async {
    try {
      final mpv = (_player.platform as dynamic);
      // Fast start: initial buffer within ~3-7 seconds
      // Avoid setting demuxer-lavf-probesize to a small value (256KB) because HLS master playlists
      // and variant MPEG-TS chunks need adequate probe size to discover video codecs and streams.
      await mpv?.command([
        'set',
        'demuxer-lavf-analyzeduration',
        '2.0',
      ]); // 2s analyze duration
      await mpv?.command([
        'set',
        'cache-pause-initial',
        'no',
      ]); // Start playing immediately without waiting
      await mpv?.command([
        'set',
        'cache-pause-wait',
        '3',
      ]); // Low 3s re-buffer threshold on stalls

      // Progressive 3-minute background cache:
      await mpv?.command(['set', 'cache', 'yes']);
      await mpv?.command([
        'set',
        'demuxer-readahead-secs',
        '180',
      ]); // Buffer up to 180s (3 minutes) ahead while watching!
      await mpv?.command([
        'set',
        'cache-secs',
        '180',
      ]); // 180s forward cache in memory
      await mpv?.command([
        'set',
        'demuxer-max-bytes',
        '134217728',
      ]); // 128 MB RAM max
      await mpv?.command([
        'set',
        'demuxer-max-back-bytes',
        '33554432',
      ]); // 32 MB backward buffer for instant rewind
      await mpv?.command([
        'set',
        'stream-buffer-size',
        '524288',
      ]); // 512 KB chunk reads
      await mpv?.command(['set', 'network-timeout', '30']);
    } catch (e) {
      debugPrint('[PlayerScreen] mpv buffer setup error: $e');
    }
  }

  bool _isExiting = false;

  /// Shows a minimalist modal popup when exiting a movie near completion (<= 12 min remaining)
  Future<bool?> _showFinishedWatchingDialog() async {
    final s = ref.read(appStringsProvider);
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF141418),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.7),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  s.playerFinishedPromptTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  s.playerFinishedPromptDesc(widget.title),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    // Option 1: Belum / Not Yet -> Continue Watching
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.of(ctx).pop(false),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            s.playerFinishedOptionNo,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Option 2: Sudah / Done -> Completed
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.of(ctx).pop(true),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            s.playerFinishedOptionYes,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleExit() async {
    if (_isExiting) return;

    final isTv =
        widget.mediaType == 'tv' ||
        (_currentSeason != null && _currentEpisode != null);
    final durSecs = _duration.inSeconds;
    final posSecs = _position.inSeconds;
    final remainingSecs = durSecs - posSecs;

    bool? markCompletedOnExit;
    // Show confirmation modal for movies when remaining time <= 12 minutes (720 seconds)
    if (!isTv &&
        durSecs > 180 &&
        remainingSecs <= (12 * 60) &&
        remainingSecs >= -30) {
      try {
        _player.pause();
      } catch (_) {}

      final result = await _showFinishedWatchingDialog();
      // If user dismissed dialog by tapping outside, resume playback and do not exit
      if (result == null) {
        try {
          _player.play();
        } catch (_) {}
        return;
      }
      markCompletedOnExit = result;
    }

    _isExiting = true;

    // 1. Instantly mute and stop native player audio to kill sound immediately
    try {
      await _player.setVolume(0.0);
      await _player.pause();
      await _player.stop();
    } catch (e) {
      debugPrint('[PlayerScreen] Error stopping native player on exit: $e');
    }

    // 2. Kill WebView playback & audio if web player fallback was active
    try {
      await _webViewController?.runJavaScript(
        'var v = document.querySelector("video"); if (v) { v.pause(); v.src = ""; v.load(); }',
      );
      await _webViewController?.loadRequest(Uri.parse('about:blank'));
    } catch (e) {
      debugPrint('[PlayerScreen] Error clearing webview on exit: $e');
    }

    // 3. Immediately restore portrait orientation BEFORE popping
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );

    // 4. Force save watch history before popping
    _saveWatchHistory(force: true, markCompleted: markCompletedOnExit);

    // 5. Restore default system brightness
    _resetBrightness();

    // 6. Pop player route safely
    if (mounted) {
      context.pop();
    }
  }

  @override
  void dispose() {
    if (!_isExiting) {
      _saveWatchHistory(force: true);
    }
    _resetBrightness();
    _controlsTimer?.cancel();
    _volumeIndicatorTimer?.cancel();
    _brightnessIndicatorTimer?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _playingSub?.cancel();
    _bufferingSub?.cancel();
    _trackSub?.cancel();
    _tracksSub?.cancel();
    _positionNotifier.dispose();

    try {
      _player.setVolume(0.0);
      _player.pause();
      _player.stop();
    } catch (_) {}

    try {
      _webViewController?.runJavaScript(
        'var v = document.querySelector("video"); if (v) { v.pause(); v.src = ""; v.load(); }',
      );
      _webViewController?.loadRequest(Uri.parse('about:blank'));
    } catch (_) {}

    _player.dispose();

    // Re-assert portrait mode as safety net
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _fetchOverviewIfNeeded() async {
    if (_currentOverview != null && _currentOverview!.trim().isNotEmpty) return;
    final tmdbId = widget.tmdbId ?? _currentTmdbId;
    if (tmdbId == null || tmdbId == 0) return;

    try {
      final lang = ref.read(appLanguageProvider);
      final tmdbLang = lang == AppLanguage.en ? 'en-US' : 'id-ID';
      final dio = DioClient.createTmdbClient();

      final isTv = _currentSeason != null || _currentEpisode != null;
      if (isTv && _currentSeason != null && _currentEpisode != null) {
        final res = await dio.get(
          '/tv/$tmdbId/season/$_currentSeason/episode/$_currentEpisode',
          queryParameters: {'language': tmdbLang},
        );
        if (res.statusCode == 200 && res.data is Map) {
          final data = res.data as Map<String, dynamic>;
          final epOverview = (data['overview'] as String? ?? '').trim();
          final epName = data['name'] as String?;
          final epStill = data['still_path'] as String?;
          if (mounted) {
            setState(() {
              if (epOverview.isNotEmpty) _currentOverview = epOverview;
              if (epName != null && epName.isNotEmpty) {
                _currentEpisodeTitle =
                    'S$_currentSeason:E$_currentEpisode $epName';
              }
              if (epStill != null && epStill.isNotEmpty) {
                _currentBackdropPath = epStill;
              }
            });
          }
        }
      } else {
        final endpoint = isTv ? '/tv/$tmdbId' : '/movie/$tmdbId';
        final res = await dio.get(
          endpoint,
          queryParameters: {'language': tmdbLang},
        );
        if (res.statusCode == 200 && res.data is Map) {
          final data = res.data as Map<String, dynamic>;
          final ov = (data['overview'] as String? ?? '').trim();
          final backdrop = data['backdrop_path'] as String?;
          final poster = data['poster_path'] as String?;
          if (mounted) {
            setState(() {
              if (ov.isNotEmpty) _currentOverview = ov;
              if (backdrop != null && backdrop.isNotEmpty) {
                _currentBackdropPath = backdrop;
              }
              if (poster != null && poster.isNotEmpty) {
                _currentPosterPath = poster;
              }
            });
          }
        }
      }
    } catch (_) {}
  }

  int? _getSavedPositionMs() {
    if (widget.tmdbId == null) return null;
    final mediaType =
        widget.mediaType ?? (_currentSeason != null ? 'tv' : 'movie');
    final repo = ref.read(watchHistoryRepositoryProvider);
    final item = repo.getItem(
      mediaType,
      widget.tmdbId!,
      season: _currentSeason,
      episode: _currentEpisode,
    );
    if (item != null && !item.isCompleted && item.positionMs > 5000) {
      if (mediaType == 'tv') {
        if (item.season == _currentSeason && item.episode == _currentEpisode) {
          return item.positionMs;
        }
      } else {
        return item.positionMs;
      }
    }
    return null;
  }

  void _saveWatchHistory({bool force = false, bool? markCompleted}) {
    if (_isSwitchingEpisode && markCompleted != true) return;
    if (_isSwitchingQuality && markCompleted != true) return;
    if (_isExiting && markCompleted == null && !force) return;

    final tmdbId = widget.tmdbId;
    if (tmdbId == null || tmdbId == 0) return;

    var posMs = _position.inMilliseconds;
    final durMs = _duration.inMilliseconds;
    if (durMs <= 0 || (posMs < 3000 && markCompleted != true)) return;

    final mediaType = (_currentSeason != null || _currentEpisode != null)
        ? 'tv'
        : (widget.mediaType ?? 'movie');
    final isTv = mediaType == 'tv';

    bool isCompleted;
    if (markCompleted != null) {
      isCompleted = markCompleted;
      if (isCompleted) {
        posMs = durMs > 0
            ? durMs
            : posMs; // 100% completion ensures isInProgress is false
      } else if ((posMs / durMs) >= 0.95) {
        // If user explicitly says not yet completed ("Belum") for movie, clamp to ~94% so it remains in Continue Watching
        posMs = (durMs * 0.94).toInt();
      }
    } else if (isTv) {
      final remainingSecs = (_duration - _position).inSeconds;
      isCompleted =
          (posMs / durMs) >= 0.92 ||
          (_duration.inSeconds > 30 && remainingSecs <= 60);
    } else {
      isCompleted = (posMs / durMs) >= 0.95;
    }

    final item = WatchHistoryItem(
      id: tmdbId,
      mediaType: mediaType,
      title: widget.title,
      episodeTitle: _currentEpisodeTitle ?? widget.episodeTitle,
      season: _currentSeason,
      episode: _currentEpisode,
      imdbId: widget.imdbId,
      posterPath: widget.posterPath,
      backdropPath: widget.backdropPath,
      positionMs: posMs,
      durationMs: durMs,
      lastWatchedAt: DateTime.now(),
      isCompleted: isCompleted,
    );

    _lastHistorySaveTime = DateTime.now();
    ref.read(watchHistoryProvider.notifier).saveProgress(item);
  }

  void _listenToPlayerStreams() {
    _posSub = _player.stream.position.listen((pos) {
      // While switching quality, ignore momentary 0s updates to prevent seekbar flickering
      if (_isSwitchingQuality && _qualityRestorePos != null) {
        if (pos.inSeconds < 1 && _qualityRestorePos!.inSeconds > 2) {
          return;
        }
      }

      _position = pos;
      _positionNotifier.value = pos;

      // Immediately dismiss initial loading spinner as soon as first video frames play
      if ((_isLoading || _isBuffering) && pos.inMilliseconds > 0) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isBuffering = false;
          });
        }
      }

      // Restore position once video duration is known and playback starts
      if (!_hasRestoredPosition &&
          _duration.inMilliseconds > 0 &&
          pos.inMilliseconds > 0) {
        _hasRestoredPosition = true;
        final resumeMs = _initialPositionMs ?? _getSavedPositionMs();
        if (resumeMs != null &&
            resumeMs > 5000 &&
            resumeMs < _duration.inMilliseconds - 10000) {
          debugPrint('[PlayerScreen] Resuming playback at ${resumeMs}ms');
          _player.seek(Duration(milliseconds: resumeMs));
        }
      }

      // ── TV Series Next Episode (Auto when <= 5s, Manual button when <= 60s) ──
      final isTv = _currentSeason != null && _currentEpisode != null;
      if (isTv && _duration.inSeconds > 30) {
        final remainingSecs = (_duration - pos).inSeconds;

        // Auto next episode when 5 seconds or less remain
        if (remainingSecs <= 5 &&
            remainingSecs >= 0 &&
            !_hasAutoPlayedNext &&
            !_isSwitchingEpisode) {
          _hasAutoPlayedNext = true;
          if (_nextEpisodeButtonVisible && mounted) {
            setState(() => _nextEpisodeButtonVisible = false);
          }
          _playNextEpisode();
        } else if (remainingSecs > 10 && _hasAutoPlayedNext) {
          _hasAutoPlayedNext = false; // Reset on rewind
        }

        // Show manual button when <= 60 seconds (under 1 minute) and > 5 seconds
        final inNextEpisodeWindow = remainingSecs <= 60 && remainingSecs > 5;
        if (inNextEpisodeWindow && !_isSwitchingEpisode) {
          if (!_nextEpisodeButtonVisible && mounted) {
            setState(() => _nextEpisodeButtonVisible = true);
          }
        } else {
          if (_nextEpisodeButtonVisible && mounted) {
            setState(() => _nextEpisodeButtonVisible = false);
          }
        }
      }

      // Save watch history periodically every 5 seconds
      if (!_isSwitchingEpisode && !_isExiting) {
        final now = DateTime.now();
        if (now.difference(_lastHistorySaveTime).inSeconds >= 5) {
          _lastHistorySaveTime = now;
          _saveWatchHistory();
        }
      }
    });
    _durSub = _player.stream.duration.listen((dur) {
      if (mounted && _duration != dur) setState(() => _duration = dur);
    });
    _playingSub = _player.stream.playing.listen((playing) {
      if (mounted && _isPlaying != playing) {
        setState(() {
          _isPlaying = playing;
          if (playing && _isLoading) _isLoading = false;
          if (playing && _isBuffering) _isBuffering = false;
        });
      }
    });
    _bufferingSub = _player.stream.buffering.listen((buffering) {
      final isOffline =
          (_currentLocalVideoPath != null &&
              _currentLocalVideoPath!.isNotEmpty) ||
          (widget.localVideoPath != null && widget.localVideoPath!.isNotEmpty);
      if (isOffline) {
        // Offline playback: never show full-screen buffering spinner unless player is completely stopped/not playing
        final shouldBuffer = buffering && !_isPlaying;
        if (mounted && _isBuffering != shouldBuffer) {
          setState(() => _isBuffering = shouldBuffer);
        }
        return;
      }
      if (mounted && _isBuffering != buffering) {
        setState(() => _isBuffering = buffering);
      }
    });
    _trackSub = _player.stream.track.listen((track) {
      // libmpv auto-detects internal stream subtitles and selects one by default.
      // We force internal mpv subtitles to be disabled at all times so that only
      // Cineva's CustomSubtitleOverlay renders on top with custom opacity, sync, and translation.
      if (track.subtitle != SubtitleTrack.no()) {
        _player.setSubtitleTrack(SubtitleTrack.no());
      }
      // Ensure video track remains active and does not drop to 'no'
      if (track.video == VideoTrack.no() &&
          _player.state.tracks.video.isNotEmpty) {
        debugPrint(
          '[PlayerScreen] Video track was none, restoring auto video track',
        );
        _player.setVideoTrack(VideoTrack.auto());
      }
    });
    _tracksSub = _player.stream.tracks.listen((tracks) {
      if (tracks.video.isNotEmpty) {
        if (!_hasAppliedDefaultQuality) {
          _hasAppliedDefaultQuality = true;
          final targetQuality =
              _currentQuality.isNotEmpty && _currentQuality != 'Offline'
              ? _currentQuality
              : SettingsService.getDefaultQuality();
          if (targetQuality != 'Auto') {
            _selectQualityTrack(targetQuality);
          } else if (_player.state.track.video == VideoTrack.no()) {
            _player.setVideoTrack(VideoTrack.auto());
          }
        } else if (_player.state.track.video == VideoTrack.no()) {
          _player.setVideoTrack(VideoTrack.auto());
        }
      }
    });
  }

  Future<void> _loadSubtitles() async {
    final prefLang =
        SettingsService.getDefaultSubtitleLang(); // 'id', 'en', 'off'
    if (prefLang == 'off') {
      debugPrint('[PlayerScreen] Subtitle preference is OFF');
      ref.read(activeSubtitleCuesProvider.notifier).state = [];
      await _player.setSubtitleTrack(SubtitleTrack.no());
      return;
    }

    try {
      final allSubs = <SubtitleInfo>[];

      // 1. Add stream subtitles from VixSrc (exact sync, hosted on CDN, 100% reliable)
      if (_streamSubtitles.isNotEmpty) {
        allSubs.addAll(_streamSubtitles);
      }

      // 2. Add external subtitles from OpenSubtitles if IMDb ID available
      if (widget.imdbId != null && widget.imdbId!.isNotEmpty) {
        final subService = ref.read(subtitleServiceProvider);
        final queryLang = prefLang == 'en' ? 'en' : '$prefLang,en,id';
        final subs = await subService.searchByImdbId(
          widget.imdbId!,
          language: queryLang,
          seasonNumber: _currentSeason,
          episodeNumber: _currentEpisode,
        );
        allSubs.addAll(subs);
      }

      if (!mounted) return;
      setState(() => _availableSubtitles = allSubs);

      if (allSubs.isEmpty) {
        debugPrint('[PlayerScreen] No subtitles found anywhere');
        return;
      }

      // Priority 1: Check if native subtitle in preferred language is found
      final nativeSub = allSubs
          .where((s) => s.language.toLowerCase() == prefLang.toLowerCase())
          .firstOrNull;
      if (nativeSub != null) {
        debugPrint(
          '[PlayerScreen] Native ${nativeSub.languageName} subtitle found: ${nativeSub.fileName}',
        );
        final success = await _applySubtitle(nativeSub);
        if (success) {
          final s = ref.read(appStringsProvider);
          _showToastSubtitle(s.playerSubActiveToast(nativeSub.languageName));
          return;
        }
        debugPrint(
          '[PlayerScreen] Native subtitle download failed, falling back to auto-translation...',
        );
      }

      // Priority 2: Fallback to English / available track + Auto-translate
      final autoTranslate = SettingsService.getAutoTranslate();
      final fallbackSub =
          _streamSubtitles
              .where((s) => s.language.toLowerCase() == 'en')
              .firstOrNull ??
          allSubs.where((s) => s.language.toLowerCase() == 'en').firstOrNull ??
          allSubs.first;
      debugPrint(
        '[PlayerScreen] Fallback to ${fallbackSub.languageName} (Target: $prefLang, Auto-translate: $autoTranslate)',
      );

      final s = ref.read(appStringsProvider);
      if (autoTranslate &&
          prefLang.toLowerCase() != fallbackSub.language.toLowerCase()) {
        final target = _getTargetTranslateLang();
        final translated = await _applyAndAutoTranslateSubtitle(
          fallbackSub,
          targetLang: target,
        );
        if (!translated) {
          await _applySubtitle(fallbackSub);
          _showToastSubtitle(s.playerSubActiveToast(fallbackSub.languageName));
        }
      } else {
        await _applySubtitle(fallbackSub);
        _showToastSubtitle(s.playerSubActiveToast(fallbackSub.languageName));
      }
    } catch (e) {
      debugPrint('[PlayerScreen] Subtitle load error: $e');
    }
  }

  Future<bool> _applySubtitle(SubtitleInfo sub) async {
    setState(() {
      _selectedSubtitle = sub;
      _isSubtitleTranslated = false;
    });
    try {
      // Ensure media_kit internal subtitle renderer is completely disabled!
      await _player.setSubtitleTrack(SubtitleTrack.no());

      final subService = ref.read(subtitleServiceProvider);
      final downloadUrl =
          (sub.downloadUrl != null && sub.downloadUrl!.isNotEmpty)
          ? sub.downloadUrl
          : await subService.getDownloadUrl(sub.id);
      if (downloadUrl != null) {
        final content = await subService.downloadSubtitleContent(downloadUrl);
        if (content != null && mounted) {
          final cues = SubtitleCue.parseSrt(content);
          if (cues.isNotEmpty) {
            final refinedCues = cues
                .map(
                  (c) => SubtitleCue(
                    start: c.start,
                    end: c.end,
                    text: sub.language.toLowerCase() == 'id'
                        ? SubtitleTranslatorService.balanceSubtitleLines(
                            SubtitleTranslatorService.smartFormatIndonesianSubtitle(
                              SubtitleTranslatorService.refineIndonesianPronouns(
                                c.text,
                              ),
                            ),
                          )
                        : SubtitleTranslatorService.balanceSubtitleLines(
                            c.text,
                          ),
                  ),
                )
                .toList();
            ref.read(activeSubtitleCuesProvider.notifier).state = refinedCues;
            return true;
          }
        }
      }
    } catch (e) {
      debugPrint('[PlayerScreen] Failed to apply subtitle: $e');
    }
    return false;
  }

  Future<bool> _applyAndAutoTranslateSubtitle(
    SubtitleInfo sub, {
    String? targetLang,
  }) async {
    setState(() {
      _selectedSubtitle = sub;
      _isAutoTranslating = true;
      _translationProgress = 0.0;
    });

    final s = ref.read(appStringsProvider);
    try {
      // Ensure media_kit internal subtitle renderer is completely disabled!
      await _player.setSubtitleTrack(SubtitleTrack.no());

      final subService = ref.read(subtitleServiceProvider);
      final downloadUrl =
          (sub.downloadUrl != null && sub.downloadUrl!.isNotEmpty)
          ? sub.downloadUrl
          : await subService.getDownloadUrl(sub.id);
      if (downloadUrl != null) {
        final content = await subService.downloadSubtitleContent(downloadUrl);
        if (content != null && mounted) {
          final originalCues = SubtitleCue.parseSrt(content);
          if (originalCues.isNotEmpty) {
            // Immediately show original cues with line balancing while background translating
            final balancedOriginalCues = originalCues
                .map(
                  (c) => SubtitleCue(
                    start: c.start,
                    end: c.end,
                    text: SubtitleTranslatorService.balanceSubtitleLines(
                      c.text,
                    ),
                  ),
                )
                .toList();
            ref.read(activeSubtitleCuesProvider.notifier).state =
                balancedOriginalCues;

            final targetLanguage = (targetLang ?? _getTargetTranslateLang())
                .toLowerCase();
            final translator = ref.read(subtitleTranslatorServiceProvider);
            final cacheKey =
                'sub_${widget.imdbId ?? widget.tmdbId}_auto_${targetLanguage}_${sub.id.hashCode}_s${_currentSeason ?? 0}_e${_currentEpisode ?? 0}';

            final translatedCues = await translator.translateCues(
              cues: originalCues,
              cacheKey: cacheKey,
              targetLang: targetLanguage,
              onProgress: (p) {
                if (mounted && _activePopup == _PlayerMiniPopup.subtitle) {
                  setState(() => _translationProgress = p);
                }
              },
            );

            if (mounted && translatedCues.isNotEmpty) {
              ref.read(activeSubtitleCuesProvider.notifier).state =
                  translatedCues;
              setState(() {
                _isAutoTranslating = false;
                _isSubtitleTranslated = true;
              });
              final langObj = SubtitleLanguageCatalog.findByCode(
                targetLanguage,
              );
              _showToastSubtitle(s.playerSubAutoTranslatedToast(langObj.name));
              return true;
            }
            return true;
          }
        }
      }
    } catch (e) {
      debugPrint('[PlayerScreen] Failed to auto-translate subtitle: $e');
    } finally {
      if (mounted) setState(() => _isAutoTranslating = false);
    }
    return false;
  }

  void _showToastSubtitle(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Iconsax.subtitle, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 2500),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceVariant.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      ),
    );
  }

  Future<void> _initializeStreaming() async {
    _hasAutoPlayedNext = false;
    _nextEpisodeButtonVisible = false;

    // 0. OFFLINE LOCAL FILE PLAYBACK (Completely isolated from online streaming)
    if ((_currentLocalVideoPath != null &&
            _currentLocalVideoPath!.isNotEmpty) ||
        (widget.localVideoPath != null && widget.localVideoPath!.isNotEmpty)) {
      await _initOfflinePlayback();
      return;
    }

    // Auto-detect if title is already completed in offline downloads (offline playback without internet)
    if (widget.tmdbId != null && widget.tmdbId! > 0) {
      try {
        final existing = ref
            .read(downloadManagerProvider.notifier)
            .findExisting(
              mediaType: widget.mediaType ?? 'movie',
              tmdbId: widget.tmdbId!,
              season: widget.season,
              episode: widget.episode,
            );
        if (existing != null &&
            existing.isCompleted &&
            existing.videoPath.isNotEmpty) {
          final f = File(existing.videoPath);
          if (await f.exists() || await f.parent.exists()) {
            debugPrint(
              '[PlayerScreen] Auto-switching to offline download: ${existing.videoPath}',
            );
            _currentLocalVideoPath = existing.videoPath;
            _currentLocalSubtitlePath = existing.subtitlePath;
            await _initOfflinePlayback();
            return;
          }
        }
      } catch (e) {
        debugPrint('[PlayerScreen] Existing offline check note: $e');
      }
    }

    // 1. ONLINE STREAMING FLOW
    await _initOnlineStreaming();
  }

  /// Dedicated offline video player handler.
  /// Plays offline videos directly or via local loopback streaming with zero internet requirement.
  Future<void> _initOfflinePlayback() async {
    setState(() {
      _isLoading = true;
      _loadingStep = _PlayerLoadingStep.preparingOffline;
      _customLoadingStatus = null;
    });

    try {
      final s = ref.read(appStringsProvider);
      final rawPath = _currentLocalVideoPath ?? widget.localVideoPath!;
      final localFile = File(rawPath);
      debugPrint(
        '[PlayerScreen] Initializing offline playback: ${localFile.path}',
      );

      final mediaDir = localFile.parent;
      if (!await mediaDir.exists()) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(s.playerDownloadNotFound),
              backgroundColor: Colors.redAccent,
            ),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      // 1. Auto-repair any legacy .cdat segments and playlists in mediaDir
      await VideoDownloadService.repairOfflineDirectoryIfNeeded(mediaDir);

      // 2. Discover the best offline playable file (MP4 -> HLS playlist -> TS fallback)
      final playable =
          await OfflineMp4Builder.findPlayableOfflineFile(mediaDir) ??
          localFile;

      _useNativePlayer = true;
      await _setupMpvOfflineOptions();

      final path = playable.path;
      final ext = path.split('.').last.toLowerCase();
      debugPrint('[PlayerScreen] Resolved offline playable: $path (ext: $ext)');

      if (ext == 'mp4' || ext == 'mkv') {
        // Direct standalone hardware container
        await _player.open(Media(path));
      } else {
        // Check if master.m3u8, master.cineva, or video.m3u8 exists in mediaDir to use LocalStreamServer
        final masterFile = File('${mediaDir.path}/master.m3u8');
        final masterCineva = File('${mediaDir.path}/master.cineva');
        final videoM3u8File = File('${mediaDir.path}/video.m3u8');
        final hlsFile = (await masterFile.exists())
            ? masterFile
            : ((await masterCineva.exists())
                  ? masterCineva
                  : ((await videoM3u8File.exists()) ? videoM3u8File : null));

        if (hlsFile != null) {
          final port = await LocalStreamServer.instance.start();
          if (port > 0) {
            final fileName = hlsFile.path
                .split(RegExp(r'[\\/]'))
                .where((s) => s.isNotEmpty)
                .last;
            final cleanId = 'cineva_${mediaDir.path.hashCode.abs()}';
            final streamUrl = LocalStreamServer.instance.getStreamUrl(
              dirPath: mediaDir.path,
              fileName: fileName,
              id: cleanId,
            );
            debugPrint('[PlayerScreen] Opening local loopback HLS: $streamUrl');
            await _player.open(Media(streamUrl));
          } else {
            await _player.open(Media(path));
          }
        } else {
          // Fallback: direct media file (e.g. video.ts without playlist)
          await _player.open(Media(path));
          final secondaryAudio = await OfflineMp4Builder.getSecondaryAudioFile(
            mediaDir,
          );
          if (secondaryAudio != null && await secondaryAudio.exists()) {
            try {
              final mpv = (_player.platform as dynamic);
              await mpv?.command([
                'audio-add',
                secondaryAudio.path,
                'auto',
                'Audio',
              ]);
            } catch (_) {}
          }
        }
      }

      await _player.setAudioTrack(AudioTrack.auto());
      await _player.setSubtitleTrack(SubtitleTrack.no());
      await _player.setVolume(_volume);
      await _player.play();

      // Load offline subtitle if available
      var subPath = _currentLocalSubtitlePath ?? widget.localSubtitlePath;
      if (subPath == null || subPath.isEmpty) {
        try {
          final subFiles = mediaDir.listSync().whereType<File>().where(
            (f) => f.path.endsWith('.srt') || f.path.endsWith('.vtt'),
          );
          if (subFiles.isNotEmpty) {
            subPath = subFiles.first.path;
            _currentLocalSubtitlePath = subPath;
          }
        } catch (_) {}
      }

      if (subPath != null && subPath.isNotEmpty) {
        try {
          final subFile = File(subPath);
          if (await subFile.exists()) {
            final content = await subFile.readAsString();
            final cues = SubtitleCue.parseSrt(content);
            ref.read(activeSubtitleCuesProvider.notifier).state = cues;
            debugPrint(
              '[PlayerScreen] Loaded offline subtitle: ${cues.length} cues',
            );
            if (mounted) {
              setState(() {
                _streamSubtitles = [
                  SubtitleInfo(
                    id: 'offline_sub',
                    language: 'id',
                    languageName: 'Bahasa Indonesia (Offline)',
                    fileName: subPath!.split(RegExp(r'[\\/]')).last,
                    downloadCount: 1,
                    downloadUrl: subPath,
                  ),
                ];
                _selectedSubtitle = _streamSubtitles.first;
              });
            }
          }
        } catch (e) {
          debugPrint('[PlayerScreen] Failed to load offline subtitle: $e');
        }
      }

      if (mounted) {
        final isId = ref.read(appStringsProvider).isIndonesian;
        setState(() {
          _isLoading = false;
          _isBuffering = false;
          _currentQuality = 'Offline';
          _resolutionLabel = path.toLowerCase().endsWith('.mp4')
              ? (isId ? 'Lokal MP4' : 'Local MP4')
              : 'Cineva Offline';
        });
      }
    } catch (e) {
      debugPrint('[PlayerScreen] Offline playback failed: $e');
      if (mounted) {
        final s = ref.read(appStringsProvider);
        setState(() => _isLoading = false);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              s.playerOfflineFailedTitle,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              '${s.playerOfflineFailedDesc}\n\n$e',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/downloads');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                ),
                child: Text(s.playerBackToDownloads),
              ),
            ],
          ),
        );
      }
    }
  }

  /// Online video streaming handler with Smart Stream multi-server engine.
  Future<void> _initOnlineStreaming() async {
    setState(() {
      _isLoading = true;
      _streamNotFound = false;
      _loadingStep = _PlayerLoadingStep.connecting;
      _customLoadingStatus = null;
    });

    _currentTmdbId ??= widget.tmdbId;
    _currentImdbId ??= widget.imdbId;
    final isTv = _currentSeason != null && _currentEpisode != null;

    // 0. Resolve both TMDB and IMDb IDs from TMDB database so no media is blocked by missing IDs
    try {
      final resolved = await SmartStreamService.resolveIds(
        tmdbId: _currentTmdbId,
        imdbId: _currentImdbId,
        isTv: isTv,
      );
      if (resolved.tmdbId > 0) {
        _currentTmdbId = resolved.tmdbId;
      }
      if (resolved.imdbId != null && resolved.imdbId!.isNotEmpty) {
        _currentImdbId = resolved.imdbId;
      }
    } catch (e) {
      debugPrint('[PlayerScreen] resolveIds exception: $e');
    }

    if (_currentTmdbId == null || _currentTmdbId == 0) {
      debugPrint('[PlayerScreen] Unable to resolve TMDB ID');
      if (mounted) {
        setState(() {
          _customLoadingStatus = null;
          _isLoading = false;
          _streamNotFound = true;
        });
      }
      return;
    }

    // Refresh dynamic list of servers
    final loader = ref.read(providerLoaderServiceProvider);
    try {
      final providers = await loader.getAvailableProviders();
      if (mounted) {
        setState(() {
          _availableServers = SmartStreamService.buildCombinedServers(
            providers,
          );
        });
      }
    } catch (_) {}

    if (_currentServer.isDirectHls) {
      ProviderSelection? selection;

      // 1. If user specifically picked a single direct provider from server menu
      if (_currentServer.videoProvider != null) {
        try {
          final res = await loader.loadFromProvider(
            provider: _currentServer.videoProvider!,
            tmdbId: _currentTmdbId!,
            season: _currentSeason,
            episode: _currentEpisode,
          );
          if (res.hasPlayableStreams) {
            selection = ProviderSelection(
              provider: _currentServer.videoProvider!,
              result: res,
            );
          }
        } catch (e) {
          debugPrint('[PlayerScreen] Error loading from selected provider: $e');
        }
      }

      // 2. If not specifically picked or selected provider failed, run the failover loader
      selection ??= await loader.loadFirstSuccessful(
        tmdbId: _currentTmdbId!,
        season: _currentSeason,
        episode: _currentEpisode,
        onStartAttempt: (provider) {
          if (mounted) {
            setState(() {
              _customLoadingStatus = 'Mencoba ${provider.displayName}...';
            });
          }
        },
        onProgress: (provider, isSuccess, error) {
          if (mounted && isSuccess) {
            setState(() {
              _customLoadingStatus = null;
            });
          }
        },
      );

      if (selection != null && selection.result.hasPlayableStreams) {
        if (mounted) {
          setState(() {
            _customLoadingStatus = null;
          });
        }
        final links = selection.result.videoLinks!;
        final defaultQuality = SettingsService.getDefaultQuality();
        final targetQuality =
            _currentQuality.isNotEmpty && _currentQuality != 'Offline'
            ? _currentQuality
            : defaultQuality;

        // Select preferred quality link if available (1080p, 720p, etc.)
        RegularVideoLinks bestLink = links.first;
        if (targetQuality != 'Auto' && links.length > 1) {
          final targetH =
              int.tryParse(targetQuality.replaceAll(RegExp(r'[^0-9]'), '')) ??
              1080;
          final match = links.where((l) {
            final q = (l.quality ?? '').toLowerCase();
            return q.contains('${targetH}p') || q.contains('$targetH');
          }).firstOrNull;
          if (match != null && match.url != null && match.url!.isNotEmpty) {
            bestLink = match;
          }
        }

        final streamUrl = bestLink.url!;
        final streamHeaders =
            bestLink.headers ??
            (selection.provider.type == VideoProviderType.directVixSrc
                ? VixSrcStreamService.headers
                : null);

        debugPrint(
          '[PlayerScreen] Playing native Master stream from ${selection.provider.displayName}: $streamUrl',
        );
        _useNativePlayer = true;
        _currentServer = SmartStreamServer.fromVideoProvider(
          selection.provider,
        );

        // Map provider subtitles into Cineva subtitle overlay
        if (selection.result.subtitleLinks != null &&
            selection.result.subtitleLinks!.isNotEmpty) {
          _streamSubtitles = selection.result.subtitleLinks!
              .map((sub) => sub.toSubtitleInfo())
              .toList();
        } else {
          _streamSubtitles = [];
        }

        if (mounted) {
          setState(() {
            _loadingStep = _PlayerLoadingStep.preparingBuffer;
          });
        }

        // Apply fast initial buffer + 3-minute background cache before stream open
        await _setupMpvFastBufferOptions();

        // Opening the stream with headers ensures full CDN & audio rendition is bound
        await _player.open(Media(streamUrl, httpHeaders: streamHeaders));
        // CRITICAL: Disable mpv's internal subtitles so they do not bypass Cineva's settings!
        await _player.setSubtitleTrack(SubtitleTrack.no());
        await _player.setVolume(_volume);

        _hasAppliedDefaultQuality = false;

        if (mounted) {
          setState(() {
            _isLoading = false;
            _currentQuality = targetQuality;
            _resolutionLabel = _formatResolutionLabel(targetQuality);
          });
        }

        if (_player.state.tracks.video.isNotEmpty) {
          _hasAppliedDefaultQuality = true;
          if (targetQuality != 'Auto') {
            unawaited(_selectQualityTrack(targetQuality));
          }
        }

        // Subtitles loaded asynchronously in background so video playback begins immediately!
        unawaited(_loadSubtitles());
        return;
      }

      // If all Direct HLS providers fail, do NOT auto-failover to web server!
      // Unreleased, theatrical, or unavailable movies do not exist on external web servers either,
      // and auto-switching causes ad clips or unrelated fallback movies to be played instead.
      debugPrint(
        '[PlayerScreen] All direct HLS streams unavailable for tmdbId=$_currentTmdbId. Showing Stream Not Available state.',
      );
      if (mounted) {
        setState(() {
          _customLoadingStatus = null;
          _isLoading = false;
          _streamNotFound = true;
        });
      }
      return;
    }

    // Load web streaming server (when user explicitly selected a web fallback server)
    await _loadWebServer(_currentServer);
  }

  Future<void> _loadWebServer(SmartStreamServer server) async {
    _useNativePlayer = false;
    _isWebPlaying = true;
    _isPlaying = true;

    // Mute and stop native player before fallback
    try {
      await _player.setVolume(0.0);
      await _player.pause();
      await _player.stop();
    } catch (_) {}

    final streamUrl = server.buildUrl(
      tmdbId: _currentTmdbId ?? 0,
      imdbId: _currentImdbId,
      season: _currentSeason,
      episode: _currentEpisode,
    );

    debugPrint(
      '[PlayerScreen] Loading web stream from ${server.name}: $streamUrl',
    );

    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      debugPrint('[PlayerScreen] WebView fallback not supported on desktop platform');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Server webview tidak didukung di platform desktop'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final controller = WebViewController();
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel(
        'CinevaStreamBridge',
        onMessageReceived: (JavaScriptMessage message) {
          _handleBridgeMessage(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) {
              setState(() => _loadingStep = _PlayerLoadingStep.preparingBackup);
            }
          },
          onProgress: (progress) async {
            if (progress >= 25) {
              try {
                await controller.runJavaScript(
                  "if (!document.getElementById('cineva-cleaner-style')) {"
                  "  const style = document.createElement('style');"
                  "  style.id = 'cineva-cleaner-style';"
                  "  style.innerHTML = `${SmartStreamService.cinemaCleanerCss.replaceAll('`', r'\`')}`;"
                  "  (document.head || document.documentElement).appendChild(style);"
                  "}",
                );
              } catch (_) {}
            }
          },
          onPageFinished: (url) async {
            try {
              // 1. Inject cinema ad-cleaner CSS to hide external web ads & intrusive overlays
              await controller.runJavaScript(
                "if (!document.getElementById('cineva-cleaner-style')) {"
                "  const style = document.createElement('style');"
                "  style.id = 'cineva-cleaner-style';"
                "  style.innerHTML = `${SmartStreamService.cinemaCleanerCss.replaceAll('`', r'\`')}`;"
                "  (document.head || document.documentElement).appendChild(style);"
                "}",
              );
              // 2. Inject stream sniffer JS to detect .m3u8 / .mp4 video stream URLs
              await controller.runJavaScript(
                SmartStreamService.streamSnifferJs,
              );
            } catch (_) {}
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            final url = request.url.toLowerCase();
            if (url.startsWith('intent://') ||
                url.startsWith('market://') ||
                url.startsWith('vnd.youtube:') ||
                url.contains('play.google.com') ||
                url.contains('shopee') ||
                url.contains('lazada') ||
                url.contains('tokopedia') ||
                url.contains('casino') ||
                url.contains('betting') ||
                url.contains('slot') ||
                url.contains('judi') ||
                url.contains('adclick') ||
                url.contains('popads') ||
                url.contains('adsterra') ||
                url.contains('doubleclick') ||
                url.contains('googleads') ||
                url.contains('onclick') ||
                url.contains('banner')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    await controller.loadRequest(Uri.parse(streamUrl));

    if (mounted) {
      setState(() {
        _webViewController = controller;
        // Keep _isLoading = true until onPageFinished or stream playback begins,
        // preventing double controls from colliding on initial webview load.
      });
      unawaited(_loadSubtitles());
    }

    // Safety fallback: ensure loading overlay does not hang if onPageFinished is delayed
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted && _isLoading && _webViewController == controller) {
        setState(() => _isLoading = false);
      }
    });
  }

  void _handleBridgeMessage(String rawJson) {
    try {
      final data = jsonDecode(rawJson) as Map<String, dynamic>;
      final type = data['type'] as String?;
      if (type == 'STREAM_FOUND') {
        final directUrl = data['url'] as String?;
        if (directUrl != null &&
            directUrl.isNotEmpty &&
            !directUrl.startsWith('blob:') &&
            !SmartStreamService.isAdUrl(directUrl)) {
          _upgradeToNativePlayer(directUrl);
        }
      } else if (type == 'TIME_UPDATE') {
        final timeMs = data['timeMs'] as int?;
        if (timeMs != null && !_useNativePlayer && mounted) {
          final pos = Duration(milliseconds: timeMs);
          _position = pos;
          _positionNotifier.value = pos;
          if (_isLoading && timeMs > 500) {
            setState(() => _isLoading = false);
          }
        }
      } else if (type == 'DURATION_UPDATE') {
        final durationMs = data['durationMs'] as int?;
        if (durationMs != null &&
            durationMs > 0 &&
            !_useNativePlayer &&
            mounted) {
          setState(() {
            _duration = Duration(milliseconds: durationMs);
          });
        }
      } else if (type == 'PLAY_STATE') {
        final playing = data['playing'] as bool?;
        if (playing != null && !_useNativePlayer && mounted) {
          setState(() {
            _isPlaying = playing;
            _isWebPlaying = playing;
            if (playing && _isLoading) {
              _isLoading = false;
            }
          });
        }
      } else if (type == 'BUFFERING_STATE') {
        final buffering = data['buffering'] as bool?;
        if (buffering != null && !_useNativePlayer && mounted) {
          setState(() {
            _isBuffering = buffering;
          });
        }
      }
    } catch (e) {
      debugPrint('[PlayerScreen] Bridge message parse error: $e');
    }
  }

  Future<void> _upgradeToNativePlayer(String directStreamUrl) async {
    if (_useNativePlayer) return;
    if (SmartStreamService.isAdUrl(directStreamUrl)) {
      debugPrint('[PlayerScreen] Ignored ad stream URL: $directStreamUrl');
      return;
    }
    debugPrint(
      '[PlayerScreen] Sniffed direct stream URL! Upgrading to native player: $directStreamUrl',
    );
    try {
      // Pause & clear webview
      await _webViewController?.runJavaScript(
        'var v = document.querySelector("video"); if (v) { v.pause(); v.src = ""; v.load(); }',
      );
      await _setupMpvFastBufferOptions();
      await _player.open(Media(directStreamUrl));
      await _player.setSubtitleTrack(SubtitleTrack.no());
      await _player.setVolume(_volume);

      final defaultQuality = SettingsService.getDefaultQuality();
      final targetQuality =
          _currentQuality.isNotEmpty && _currentQuality != 'Offline'
          ? _currentQuality
          : defaultQuality;
      _hasAppliedDefaultQuality = false;

      if (mounted) {
        setState(() {
          _useNativePlayer = true;
          _isLoading = false;
          _currentQuality = targetQuality;
          _resolutionLabel = _formatResolutionLabel(targetQuality);
        });
      }

      if (_player.state.tracks.video.isNotEmpty) {
        _hasAppliedDefaultQuality = true;
        if (targetQuality != 'Auto') {
          unawaited(_selectQualityTrack(targetQuality));
        }
      }
      unawaited(_loadSubtitles());
    } catch (e) {
      debugPrint('[PlayerScreen] Failed to upgrade sniffed stream: $e');
    }
  }

  Future<void> _switchServer(SmartStreamServer server) async {
    if (_currentServer.id == server.id && !_isLoading) {
      setState(() {
        _activePopup = _PlayerMiniPopup.none;
      });
      return;
    }

    setState(() {
      _currentServer = server;
      _activePopup = _PlayerMiniPopup.none;
      _isLoading = true;
      _streamNotFound = false;
      _loadingStep = _PlayerLoadingStep.connecting;
      _customLoadingStatus = ref
          .read(appStringsProvider)
          .playerServerSwitched(server.name);
      _hasAppliedDefaultQuality = false;
    });

    try {
      await _player.pause();
      await _player.stop();
    } catch (_) {}

    try {
      await _webViewController?.runJavaScript(
        'var v = document.querySelector("video"); if (v) { v.pause(); v.src = ""; v.load(); }',
      );
      await _webViewController?.loadRequest(Uri.parse('about:blank'));
      _webViewController = null;
    } catch (_) {}

    if (server.isDirectHls) {
      await _initOnlineStreaming();
    } else {
      await _loadWebServer(server);
    }
  }

  // ── Quality Switching ──

  Future<void> _selectQualityTrack(String quality) async {
    final videoTracks = _player.state.tracks.video;
    if (videoTracks.length <= 1) return;

    VideoTrack targetTrack;
    if (quality == 'Auto') {
      targetTrack = VideoTrack.auto();
    } else {
      final targetH =
          int.tryParse(quality.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1080;
      VideoTrack? matched = videoTracks
          .where((t) => (t.h ?? 0) == targetH)
          .firstOrNull;
      if (matched == null) {
        final sorted = List<VideoTrack>.from(videoTracks)
          ..sort((a, b) => (a.h ?? 0).compareTo(b.h ?? 0));
        matched =
            sorted.where((t) => (t.h ?? 0) <= targetH).lastOrNull ??
            sorted.first;
      }
      targetTrack = matched;
    }

    if (_player.state.track.video.id != targetTrack.id) {
      final savedPos = _position;
      final wasPlaying = _isPlaying;
      debugPrint(
        '[PlayerScreen] Applying quality track: ${targetTrack.id} ($quality)',
      );
      try {
        await _player.setVideoTrack(targetTrack);
        if (savedPos > const Duration(seconds: 1)) {
          await Future.delayed(const Duration(milliseconds: 150));
          await _player.seek(savedPos);
          if (wasPlaying) {
            await _player.play();
          }
        }
      } catch (e) {
        debugPrint('[PlayerScreen] Failed to apply quality track: $e');
      }
    }
  }

  Future<void> _setQuality(String quality) async {
    if (_currentQuality == quality) {
      setState(() => _activePopup = _PlayerMiniPopup.none);
      return;
    }

    final savedPos = _position;
    final wasPlaying = _isPlaying;

    setState(() {
      _currentQuality = quality;
      _resolutionLabel = _formatResolutionLabel(quality);
      _activePopup = _PlayerMiniPopup.none;
    });

    final videoTracks = _player.state.tracks.video;
    if (videoTracks.length > 1) {
      VideoTrack targetTrack;
      if (quality == 'Auto') {
        targetTrack = VideoTrack.auto();
      } else {
        final targetH =
            int.tryParse(quality.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1080;
        VideoTrack? matched = videoTracks
            .where((t) => (t.h ?? 0) == targetH)
            .firstOrNull;
        if (matched == null) {
          final sorted = List<VideoTrack>.from(videoTracks)
            ..sort((a, b) => (a.h ?? 0).compareTo(b.h ?? 0));
          matched =
              sorted.where((t) => (t.h ?? 0) <= targetH).lastOrNull ??
              sorted.first;
        }
        targetTrack = matched;
      }

      if (_player.state.track.video.id != targetTrack.id) {
        _isSwitchingQuality = true;
        _qualityRestorePos = savedPos;

        try {
          await _player.setVideoTrack(targetTrack);

          if (savedPos > const Duration(seconds: 1)) {
            // Give mpv demuxer a moment to switch variant playlist before seeking
            await Future.delayed(const Duration(milliseconds: 150));
            await _player.seek(savedPos);
            if (wasPlaying) {
              await _player.play();
            }

            // Safety double-check after 250ms to ensure position didn't stick to 0
            await Future.delayed(const Duration(milliseconds: 250));
            if (_player.state.position.inSeconds < 1 &&
                savedPos.inSeconds > 2) {
              await _player.seek(savedPos);
              if (wasPlaying) {
                await _player.play();
              }
            }
          }
        } catch (e) {
          debugPrint('[PlayerScreen] Quality switch error: $e');
        } finally {
          // Release lock after small grace period
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _isSwitchingQuality = false;
              _qualityRestorePos = null;
            }
          });
        }
      }
    }
    _resetControlsTimer();
  }

  // ── Volume & Audio Boost ──

  void _setVolume(double newVolume) {
    final clamped = newVolume.clamp(0.0, 150.0);
    setState(() {
      _volume = clamped;
      _showVolumeIndicator = true;
    });
    _player.setVolume(clamped);

    _volumeIndicatorTimer?.cancel();
    _volumeIndicatorTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _showVolumeIndicator = false);
    });
  }

  // ── Screen Brightness Gesture Control ──

  void _setBrightness(double newBrightness) {
    final clamped = newBrightness.clamp(0.05, 1.0);
    setState(() {
      _brightness = clamped;
      _showBrightnessIndicator = true;
    });

    try {
      _brightnessChannel.invokeMethod('setBrightness', {'brightness': clamped});
    } catch (_) {}

    _brightnessIndicatorTimer?.cancel();
    _brightnessIndicatorTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _showBrightnessIndicator = false);
    });
  }

  void _resetBrightness() {
    try {
      _brightnessChannel.invokeMethod('resetBrightness');
    } catch (_) {}
  }

  // ── Unified Custom Controls ──

  void _togglePlayPause() {
    _resetControlsTimer();
    if (_useNativePlayer) {
      _player.playOrPause();
    } else {
      _webViewController?.runJavaScript(
        'var v = document.querySelector("video"); if (v) { if (v.paused) { v.play(); } else { v.pause(); } }',
      );
      setState(() {
        _isWebPlaying = !_isWebPlaying;
        _isPlaying = _isWebPlaying;
      });
    }
  }

  void _seekRelative(int seconds) {
    _resetControlsTimer();
    final target = _position + Duration(seconds: seconds);
    final clamped = target < Duration.zero ? Duration.zero : target;
    _position = clamped;
    _positionNotifier.value = clamped;
    if (_useNativePlayer) {
      _player.seek(clamped);
    } else {
      _webViewController?.runJavaScript(
        'var v = document.querySelector("video"); if (v) { v.currentTime = Math.max(0, v.currentTime + $seconds); }',
      );
    }
  }

  void _seekTo(double seconds) {
    _resetControlsTimer();
    final target = Duration(milliseconds: (seconds * 1000).toInt());
    _position = target;
    _positionNotifier.value = target;
    if (_useNativePlayer) {
      _player.seek(target);
    } else {
      _webViewController?.runJavaScript(
        'var v = document.querySelector("video"); if (v) { v.currentTime = $seconds; }',
      );
    }
  }

  void _resetControlsTimer() {
    _controlsTimer?.cancel();
    // Auto-hide timer only dismisses player screen controls (top bar, scrubber, buttons)
    // and mini popups. The right side panel NEVER auto-closes (only closed manually by user).
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showControls = false;
          _activePopup = _PlayerMiniPopup.none;
        });
      }
    });
  }

  void _toggleControls() {
    if (_isLoading || _streamNotFound) {
      return; // Do not toggle controls while processing/searching server or when stream not found
    }
    if (_activePopup != _PlayerMiniPopup.none) {
      setState(() => _activePopup = _PlayerMiniPopup.none);
      _resetControlsTimer();
      return;
    }
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _resetControlsTimer();
    } else {
      _controlsTimer?.cancel();
    }
  }

  void _openSidePanel([_SidePanelPage page = _SidePanelPage.main]) {
    _resetControlsTimer();
    setState(() {
      _sidePanelPage = page;
      _isSidePanelOpen = true;
      _showControls = true;
      _activePopup = _PlayerMiniPopup.none;
    });
  }

  void _closeSidePanel() {
    _resetControlsTimer();
    setState(() {
      _isSidePanelOpen = false;
    });
  }

  void _toggleSidePanel([_SidePanelPage page = _SidePanelPage.main]) {
    if (_isSidePanelOpen) {
      _closeSidePanel();
    } else {
      _openSidePanel(page);
    }
  }

  void _navigateToSidePanelPage(_SidePanelPage page) {
    _resetControlsTimer();
    setState(() {
      _sidePanelPage = page;
    });
  }

  void _setPlaybackSpeed(double speed) {
    setState(() => _playbackSpeed = speed);
    if (_useNativePlayer) {
      try {
        _player.setRate(speed);
      } catch (e) {
        debugPrint('[PlayerScreen] Failed to set playback rate: $e');
      }
    } else {
      _webViewController?.runJavaScript(
        'var v = document.querySelector("video"); if (v) { v.playbackRate = $speed; }',
      );
    }
  }

  void _toggleFitMode() {
    _resetControlsTimer();
    setState(() {
      if (_fitMode == BoxFit.cover) {
        _fitMode = BoxFit.contain;
      } else if (_fitMode == BoxFit.contain) {
        _fitMode = BoxFit.fill;
      } else {
        _fitMode = BoxFit.cover;
      }
    });
  }

  // ── TV Series Next Episode ──

  Future<void> _playNextEpisode() async {
    if (_isSwitchingEpisode) return;
    _isSwitchingEpisode = true;

    if (_currentSeason == null || _currentEpisode == null) {
      _isSwitchingEpisode = false;
      return;
    }

    final nextEp = _currentEpisode! + 1;
    // Mark previous episode 100% completed in watch history
    _saveWatchHistory(force: true, markCompleted: true);
    _lastHistorySaveTime = DateTime.now();

    // Advance episode state immediately
    _currentEpisode = nextEp;
    _currentEpisodeTitle = 'Episode $nextEp';
    _currentOverview = null;
    _fetchOverviewIfNeeded();

    if (mounted) {
      setState(() {
        _nextEpisodeButtonVisible = false;
        _showControls = false;
        _isSidePanelOpen = false;
        _activePopup = _PlayerMiniPopup.none;
        _isLoading = true;
        _loadingStep = _PlayerLoadingStep.preparingEpisode;
        _customLoadingStatus = null;
      });
    }

    // 1. COMPLETE SOUND AND STREAM TERMINATION:
    // Mute and stop native player immediately to eliminate any previous audio bleed
    try {
      await _player.setVolume(0.0);
      await _player.pause();
      await _player.stop();
    } catch (e) {
      debugPrint(
        '[PlayerScreen] Error stopping native player on next episode: $e',
      );
    }

    // 2. Kill WebView playback & audio if web player was active
    try {
      await _webViewController?.runJavaScript(
        'var v = document.querySelector("video"); if (v) { v.pause(); v.src = ""; v.load(); }',
      );
      await _webViewController?.loadRequest(Uri.parse('about:blank'));
      _webViewController = null;
    } catch (e) {
      debugPrint('[PlayerScreen] Error clearing webview on next episode: $e');
    }

    // 3. Instantly clear subtitles
    ref.read(activeSubtitleCuesProvider.notifier).state = [];
    _availableSubtitles = [];
    _streamSubtitles = [];
    _selectedSubtitle = null;
    _isSubtitleTranslated = false;

    // 4. Reset playback timeline & state
    _position = Duration.zero;
    _positionNotifier.value = Duration.zero;
    _duration = Duration.zero;
    _hasRestoredPosition = false;
    _hasAutoPlayedNext = false;
    _hasAppliedDefaultQuality = false;
    _initialPositionMs = null;
    _activePopup = _PlayerMiniPopup.none;

    // Check if the next episode was downloaded locally
    String? nextLocalVideo;
    String? nextLocalSub;
    try {
      final downloadItems = ref.read(downloadManagerProvider);
      final nextDownload = downloadItems
          .where(
            (d) =>
                d.tmdbId == widget.tmdbId &&
                d.mediaType == 'tv' &&
                d.seasonNumber == _currentSeason &&
                d.episodeNumber == nextEp &&
                d.status == DownloadStatus.completed,
          )
          .firstOrNull;

      if (nextDownload != null) {
        final f = File(nextDownload.videoPath);
        if (f.existsSync() && f.lengthSync() > 10000) {
          nextLocalVideo = nextDownload.videoPath;
          nextLocalSub = nextDownload.subtitlePath;
          debugPrint(
            '[PlayerScreen] Next episode found in offline downloads: $nextLocalVideo',
          );
        }
      }
    } catch (_) {}

    _currentLocalVideoPath = nextLocalVideo;
    _currentLocalSubtitlePath = nextLocalSub;

    // 6. Restore volume setting for the next episode
    try {
      await _player.setVolume(_volume);
    } catch (_) {}

    if (!mounted) {
      _isSwitchingEpisode = false;
      return;
    }

    // 7. Initialize streaming for next episode in-place
    try {
      if ((_currentLocalVideoPath != null &&
              _currentLocalVideoPath!.isNotEmpty) ||
          (widget.localVideoPath != null &&
              widget.localVideoPath!.isNotEmpty)) {
        await _initOfflinePlayback();
      } else {
        await _initOnlineStreaming();
      }
    } catch (e) {
      debugPrint('[PlayerScreen] Failed to start next episode: $e');
    } finally {
      _isSwitchingEpisode = false;
    }
  }

  Widget _buildSkipPillButton({
    Key? key,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      key: key,
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) return '$hours:$minutes:$seconds';
    return '$minutes:$seconds';
  }

  // ── Semi-Transparent Mini Popups Builders ──

  Widget _buildQualityMiniPopup(AppStrings s) {
    const qualities = ['Auto', '1080p', '720p', '480p', '360p'];

    return _buildMiniPopupContainer(
      width: 250,
      title: s.playerQualityTitle,
      icon: Iconsax.video_play,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              '${s.playerQualityTitle}: $_resolutionLabel',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...qualities.map((q) {
            final isSelected = _currentQuality == q;
            String label = q == 'Auto' ? s.playerQualityAutoAdaptive : '$q HD';
            if (q == '1080p') label = '1080p FHD (${s.playerQualityClear})';
            if (q == '720p') label = '720p HD (${s.playerQualityStandard})';
            if (q == '480p') label = '480p SD (${s.playerQualityDataSaver})';
            if (q == '360p') label = '360p ${s.playerQualityLow} (< 500 Kbps)';

            return InkWell(
              onTap: () => _setQuality(q),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 16,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? AppColors.primary : Colors.white,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildVolumeMiniPopup(AppStrings s) {
    return _buildMiniPopupContainer(
      width: 270,
      title: s.playerVolumeTitle,
      icon: Icons.volume_up_rounded,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _volume > 100.0
                    ? 'Boost: ${_volume.toInt()}%'
                    : 'Level: ${_volume.toInt()}%',
                style: TextStyle(
                  color: _volume > 100.0 ? AppColors.primary : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              if (_volume > 100.0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    s.playerAudioBoost,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              activeTrackColor: _volume > 100.0
                  ? AppColors.primary
                  : Colors.white,
            ),
            child: Slider(
              value: _volume,
              min: 0.0,
              max: 150.0,
              divisions: 30,
              onChanged: _setVolume,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildVolumePresetChip(s.playerVolumeMute, 0.0),
              _buildVolumePresetChip('100%', 100.0),
              _buildVolumePresetChip('125%', 125.0),
              _buildVolumePresetChip('150%', 150.0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVolumePresetChip(String label, double val) {
    final isSelected = (_volume - val).abs() < 1.0;
    return InkWell(
      onTap: () => _setVolume(val),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitleMiniPopup(AppStrings s) {
    return _buildMiniPopupContainer(
      width: 350,
      title: _isShowingSubtitleSettingsInPopup
          ? s.playerSubSettingsTitle
          : s.playerSubtitleTrack,
      icon: _isShowingSubtitleSettingsInPopup
          ? Iconsax.setting_2
          : Iconsax.subtitle,
      leading: _isShowingSubtitleSettingsInPopup
          ? GestureDetector(
              onTap: () =>
                  setState(() => _isShowingSubtitleSettingsInPopup = false),
              child: const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            )
          : null,
      trailing: !_isShowingSubtitleSettingsInPopup
          ? GestureDetector(
              onTap: () =>
                  setState(() => _isShowingSubtitleSettingsInPopup = true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Iconsax.setting_2,
                      size: 12,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      s.playerSubSettings,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          final isSettings = child.key == const ValueKey('sub_settings_view');
          final inTween = Tween<Offset>(
            begin: isSettings
                ? const Offset(0.35, 0.0)
                : const Offset(-0.35, 0.0),
            end: Offset.zero,
          );
          return SlideTransition(
            position: inTween.animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: _isShowingSubtitleSettingsInPopup
            ? _buildSubtitleSettingsContent(
                s,
                key: const ValueKey('sub_settings_view'),
              )
            : _buildSubtitleTracksContent(
                s,
                key: const ValueKey('sub_tracks_view'),
              ),
      ),
    );
  }

  Widget _buildSubtitleSettingsMiniPopup(AppStrings s) {
    return _buildSubtitleMiniPopup(s);
  }

  Widget _buildSubtitleTracksContent(AppStrings s, {Key? key}) {
    final targetLangCode = _getTargetTranslateLang();
    final targetLangObj = SubtitleLanguageCatalog.findByCode(targetLangCode);

    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Option: Matikan Subtitle
        InkWell(
          onTap: () async {
            ref.read(activeSubtitleCuesProvider.notifier).state = [];
            await _player.setSubtitleTrack(SubtitleTrack.no());
            setState(() {
              _selectedSubtitle = null;
              _isSubtitleTranslated = false;
              _activePopup = _PlayerMiniPopup.none;
              _isShowingSubtitleSettingsInPopup = false;
            });
            _resetControlsTimer();
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: _selectedSubtitle == null
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  _selectedSubtitle == null
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: _selectedSubtitle == null
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
                const SizedBox(width: 10),
                Text(
                  s.playerDisableSubtitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Menu "Atur Subtitle" (Ditempatkan di atas agar langsung terlihat & mudah dijangkau di layar HP landscape, tanpa border, dengan chevron right)
        const SizedBox(height: 4),
        InkWell(
          onTap: () => setState(() => _isShowingSubtitleSettingsInPopup = true),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              // TANPA BORDER
            ),
            child: Row(
              children: [
                const Icon(
                  Iconsax.setting_2,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.playerSubSettings,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),

        // Border pembatas yang smooth
        const Divider(color: Colors.white12, height: 16),

        // 3. 1-Tap Auto-Translate Action (TANPA BORDER, border pembatas smooth)
        if (_selectedSubtitle != null &&
            _selectedSubtitle!.language.toLowerCase() !=
                targetLangCode.toLowerCase()) ...[
          if (_isAutoTranslating) ...[
            LinearProgressIndicator(
              value: _translationProgress > 0 ? _translationProgress : null,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceElevated,
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                s.playerTranslatingTo(targetLangObj.name),
                style: const TextStyle(color: AppColors.primary, fontSize: 11),
              ),
            ),
          ] else ...[
            InkWell(
              onTap: () {
                _applyAndAutoTranslateSubtitle(
                  _selectedSubtitle!,
                  targetLang: targetLangCode,
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  // TANPA BORDER!
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Iconsax.magic_star,
                      color: AppColors.primary,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isSubtitleTranslated
                          ? s.playerTranslateActive(
                              targetLangCode.toUpperCase(),
                            )
                          : s.playerTranslateTo(targetLangObj.name),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const Divider(color: Colors.white12, height: 16),
        ],

        // 4. Subtitle tracks list (fluid dan ikut scroll penuh dalam mini popup)
        if (_availableSubtitles.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                s.playerNoSubtitleFound,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
          )
        else
          ..._availableSubtitles.map((sub) {
            final isSelected = _selectedSubtitle?.id == sub.id;
            final isPreferred =
                sub.language.toLowerCase() == targetLangCode.toLowerCase();

            return InkWell(
              onTap: () async {
                final success = await _applySubtitle(sub);
                if (!success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        s.playerFailedDownloadSub(sub.languageName),
                      ),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
                setState(() {
                  _activePopup = _PlayerMiniPopup.none;
                  _isShowingSubtitleSettingsInPopup = false;
                });
                _resetControlsTimer();
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 16,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isPreferred
                            ? AppColors.success.withValues(alpha: 0.25)
                            : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        sub.language.toUpperCase(),
                        style: TextStyle(
                          color: isPreferred
                              ? AppColors.success
                              : Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sub.fileName.isNotEmpty
                            ? sub.fileName
                            : sub.languageName,
                        style: TextStyle(
                          color: isSelected ? AppColors.primary : Colors.white,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildSubtitleSettingsContent(AppStrings s, {Key? key}) {
    final style = ref.watch(subtitleStyleProvider);
    final notifier = ref.read(subtitleStyleProvider.notifier);

    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 1. Live Subtitle Preview Screen ──
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1218),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s.isIndonesian
                        ? 'PRATINJAU LANGSUNG'
                        : 'LIVE PREVIEW',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _subtitleSettingsTab == 0
                          ? (s.isIndonesian ? 'PRATINJAU WAKTU' : 'SYNC PREVIEW')
                          : (s.isIndonesian ? 'PRATINJAU TAMPILAN' : 'STYLE PREVIEW'),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(
                      alpha: style.backgroundOpacity,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (style.strokeWidth > 0)
                        Text(
                          s.isIndonesian
                              ? 'Contoh Teks Subtitle Cineva'
                              : 'Cineva Subtitle Sample Text',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: (style.fontSize * 0.8).clamp(13.0, 20.0),
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = style.strokeWidth
                              ..color = Colors.black,
                          ),
                        ),
                      Text(
                        s.isIndonesian
                            ? 'Contoh Teks Subtitle Cineva'
                            : 'Cineva Subtitle Sample Text',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: style.textColor,
                          fontSize: (style.fontSize * 0.8).clamp(13.0, 20.0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── 2. Segmented Navigation Tabs ──
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12, width: 0.8),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildSubTabButton(
                  label: s.playerTabSync,
                  icon: Icons.timer_outlined,
                  isSelected: _subtitleSettingsTab == 0,
                  onTap: () => setState(() => _subtitleSettingsTab = 0),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildSubTabButton(
                  label: s.playerTabAppearance,
                  icon: Icons.palette_outlined,
                  isSelected: _subtitleSettingsTab == 1,
                  onTap: () => setState(() => _subtitleSettingsTab = 1),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ── 3. Tab Contents ──
        if (_subtitleSettingsTab == 0) ...[
          // ── TAB 0: ATUR WAKTU (TIMING & SYNCHRONIZATION) ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white12, width: 0.8),
              ),
            ),
            child: Column(
              children: [
                // Status badge & Offset display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.isIndonesian
                          ? 'Offset Penyesuaian'
                          : 'Timing Offset',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: style.syncOffsetMs == 0
                            ? AppColors.success.withValues(alpha: 0.2)
                            : (style.syncOffsetMs > 0
                                  ? AppColors.primary.withValues(alpha: 0.2)
                                  : Colors.blueAccent.withValues(alpha: 0.2)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        style.syncOffsetMs == 0
                            ? (s.isIndonesian ? 'Tepat Waktu' : 'On Time')
                            : (style.syncOffsetMs > 0
                                  ? (s.isIndonesian ? 'Terlambat' : 'Delayed')
                                  : (s.isIndonesian ? 'Lebih Awal' : 'Advanced')),
                        style: TextStyle(
                          color: style.syncOffsetMs == 0
                              ? AppColors.success
                              : (style.syncOffsetMs > 0
                                    ? AppColors.primary
                                    : Colors.blueAccent),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  style.syncOffsetMs == 0
                      ? (s.isIndonesian ? '0.00 detik' : '0.00 seconds')
                      : '${style.syncOffsetMs > 0 ? "+" : ""}${(style.syncOffsetMs / 1000.0).toStringAsFixed(2)} ${s.isIndonesian ? "detik" : "seconds"}',
                  style: GoogleFonts.outfit(
                    color: style.syncOffsetMs != 0
                        ? AppColors.primary
                        : Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),

                // Stepper Buttons Row
                Row(
                  children: [
                    _buildTimingStepButton(
                      '-0.5s',
                      () => notifier.adjustSyncOffset(-500),
                    ),
                    const SizedBox(width: 6),
                    _buildTimingStepButton(
                      '-0.1s',
                      () => notifier.adjustSyncOffset(-100),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 3,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: notifier.resetSyncOffset,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: style.syncOffsetMs == 0
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: style.syncOffsetMs == 0
                                    ? Colors.white12
                                    : AppColors.primary,
                                width: 0.8,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Reset (0s)',
                                style: TextStyle(
                                  color: style.syncOffsetMs == 0
                                      ? Colors.white70
                                      : AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildTimingStepButton(
                      '+0.1s',
                      () => notifier.adjustSyncOffset(100),
                    ),
                    const SizedBox(width: 6),
                    _buildTimingStepButton(
                      '+0.5s',
                      () => notifier.adjustSyncOffset(500),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Continuous Slider for smooth timing
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: Colors.white12,
                    thumbColor: AppColors.primary,
                    overlayColor: AppColors.primary.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: (style.syncOffsetMs / 1000.0).clamp(-5.0, 5.0),
                    min: -5.0,
                    max: 5.0,
                    divisions: 100,
                    onChanged: (val) {
                      final ms = (val * 1000).round();
                      notifier.adjustSyncOffset(ms - style.syncOffsetMs);
                    },
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.isIndonesian
                      ? 'Petunjuk: Tekan [-] jika subtitle muncul terlambat dari ucapan aktor, atau [+] jika subtitle muncul mendahului suara.'
                      : 'Tip: Tap [-] if subtitle appears after dialogue, or [+] if subtitle appears before the voice.',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // ── TAB 1: TAMPILAN (APPEARANCE & STYLING) ──

          // 1. Ukuran Font
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white12, width: 0.8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.isIndonesian ? 'Ukuran Font' : 'Font Size',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${style.fontSize.toInt()} pt',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildPresetPill(
                      s.isIndonesian ? 'Kecil (16)' : 'Small (16)',
                      16.0,
                      style.fontSize,
                      (v) => notifier.updateFontSize(v),
                    ),
                    const SizedBox(width: 6),
                    _buildPresetPill(
                      s.isIndonesian ? 'Sedang (20)' : 'Medium (20)',
                      20.0,
                      style.fontSize,
                      (v) => notifier.updateFontSize(v),
                    ),
                    const SizedBox(width: 6),
                    _buildPresetPill(
                      s.isIndonesian ? 'Besar (24)' : 'Large (24)',
                      24.0,
                      style.fontSize,
                      (v) => notifier.updateFontSize(v),
                    ),
                    const SizedBox(width: 6),
                    _buildPresetPill(
                      s.isIndonesian ? 'Ekstra (28)' : 'Extra (28)',
                      28.0,
                      style.fontSize,
                      (v) => notifier.updateFontSize(v),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: Colors.white12,
                    thumbColor: AppColors.primary,
                  ),
                  child: Slider(
                    value: style.fontSize.clamp(14.0, 30.0),
                    min: 14.0,
                    max: 30.0,
                    divisions: 8,
                    onChanged: (v) => notifier.updateFontSize(v),
                  ),
                ),
              ],
            ),
          ),

          // 2. Warna Teks
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white12, width: 0.8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.isIndonesian ? 'Warna Teks' : 'Text Color',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildColorCard(
                      s.isIndonesian ? 'Putih' : 'White',
                      const Color(0xFFFFFFFF),
                      style.textColor,
                      notifier,
                    ),
                    const SizedBox(width: 8),
                    _buildColorCard(
                      s.isIndonesian ? 'Kuning' : 'Yellow',
                      const Color(0xFFFFD700),
                      style.textColor,
                      notifier,
                    ),
                    const SizedBox(width: 8),
                    _buildColorCard(
                      'Cyan',
                      const Color(0xFF00E5FF),
                      style.textColor,
                      notifier,
                    ),
                    const SizedBox(width: 8),
                    _buildColorCard(
                      s.isIndonesian ? 'Hijau' : 'Green',
                      const Color(0xFF00E676),
                      style.textColor,
                      notifier,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. Latar Belakang (Background Opacity)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white12, width: 0.8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.isIndonesian ? 'Latar Belakang Teks' : 'Text Background',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(style.backgroundOpacity * 100).toInt()}%',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildPresetPill(
                      s.isIndonesian ? 'Transparan' : 'Transparent',
                      0.0,
                      style.backgroundOpacity,
                      (v) => notifier.updateBackgroundOpacity(v),
                    ),
                    const SizedBox(width: 6),
                    _buildPresetPill(
                      s.isIndonesian ? 'Tipis (30%)' : 'Thin (30%)',
                      0.3,
                      style.backgroundOpacity,
                      (v) => notifier.updateBackgroundOpacity(v),
                    ),
                    const SizedBox(width: 6),
                    _buildPresetPill(
                      s.isIndonesian ? 'Sedang (65%)' : 'Medium (65%)',
                      0.65,
                      style.backgroundOpacity,
                      (v) => notifier.updateBackgroundOpacity(v),
                    ),
                    const SizedBox(width: 6),
                    _buildPresetPill(
                      s.isIndonesian ? 'Pekat (90%)' : 'Solid (90%)',
                      0.9,
                      style.backgroundOpacity,
                      (v) => notifier.updateBackgroundOpacity(v),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: Colors.white12,
                    thumbColor: AppColors.primary,
                  ),
                  child: Slider(
                    value: style.backgroundOpacity.clamp(0.0, 1.0),
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    onChanged: (v) => notifier.updateBackgroundOpacity(v),
                  ),
                ),
              ],
            ),
          ),

          // 4. Garis Tepi (Stroke / Outline)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white12, width: 0.8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.isIndonesian ? 'Garis Tepi Teks (Outline)' : 'Text Outline (Stroke)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${style.strokeWidth.toStringAsFixed(1)} px',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: Colors.white12,
                    thumbColor: AppColors.primary,
                  ),
                  child: Slider(
                    value: style.strokeWidth.clamp(0.0, 5.0),
                    min: 0.0,
                    max: 5.0,
                    divisions: 10,
                    onChanged: (v) => notifier.updateStrokeWidth(v),
                  ),
                ),
              ],
            ),
          ),

          // 5. Posisi Vertikal Subtitle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white12, width: 0.8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.isIndonesian ? 'Jarak dari Bawah (Posisi)' : 'Bottom Offset (Position)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${style.bottomOffset.toInt()} px',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: Colors.white12,
                    thumbColor: AppColors.primary,
                  ),
                  child: Slider(
                    value: style.bottomOffset.clamp(10.0, 100.0),
                    min: 10.0,
                    max: 100.0,
                    divisions: 18,
                    onChanged: (v) => notifier.updateBottomOffset(v),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubTabButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.black : Colors.white70,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimingStepButton(String label, VoidCallback onTap) {
    return Expanded(
      flex: 2,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12, width: 0.8),
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetPill(
    String label,
    double targetVal,
    double currentVal,
    void Function(double) onSelected,
  ) {
    final isSelected = (currentVal - targetVal).abs() < 1.0;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSelected(targetVal),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.white12,
                width: 0.8,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : Colors.white70,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorCard(
    String name,
    Color color,
    Color currentColor,
    dynamic notifier,
  ) {
    final isSelected = color.toARGB32() == currentColor.toARGB32();
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => notifier.updateTextColor(color),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.white12,
                width: 0.8,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white30, width: 1),
                  ),
                  child: isSelected
                      ? Center(
                          child: Icon(
                            Icons.check,
                            size: 12,
                            color: color == const Color(0xFFFFFFFF)
                                ? Colors.black
                                : Colors.black,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : Colors.white70,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServerMiniPopup(AppStrings s) {
    return _buildMiniPopupContainer(
      width: 300,
      title: s.playerServerTitle,
      icon: Icons.dns_rounded,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              s.playerServerDesc,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
          ..._availableServers.map((srv) {
            final isSelected = _currentServer.id == srv.id;
            return InkWell(
              onTap: () => _switchServer(srv),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected
                      ? Border.all(
                          color: AppColors.primary.withValues(alpha: 0.5),
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 16,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            srv.name,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.white,
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          Text(
                            srv.description,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: srv.isDirectHls
                            ? const Color(0xFF00E676).withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        srv.isDirectHls ? 'DIRECT' : 'HD',
                        style: TextStyle(
                          color: srv.isDirectHls
                              ? const Color(0xFF00E676)
                              : Colors.white70,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMiniPopupContainer({
    required double width,
    required String title,
    required IconData icon,
    required Widget child,
    Widget? leading,
    Widget? trailing,
  }) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxPopupHeight = (screenHeight - 64).clamp(180.0, 520.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: width,
          constraints: BoxConstraints(maxHeight: maxPopupHeight),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header (Pinned)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (leading != null) ...[
                        leading,
                        const SizedBox(width: 6),
                      ],
                      Icon(icon, color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (trailing != null) ...[
                        trailing,
                        const SizedBox(width: 8),
                      ],
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _activePopup = _PlayerMiniPopup.none;
                            _isShowingSubtitleSettingsInPopup = false;
                          });
                          _resetControlsTimer();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white10,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white70,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── YouTube-Style Right Side Panel Implementation ──

  Widget _buildSidePanel(AppStrings s, double drawerWidth, double totalHeight) {
    String title;
    IconData icon;
    switch (_sidePanelPage) {
      case _SidePanelPage.main:
        title = s.isIndonesian ? 'Pengaturan' : 'Settings';
        icon = Iconsax.setting_2;
        break;
      case _SidePanelPage.quality:
        title = s.playerQualityTitle;
        icon = Icons.high_quality_rounded;
        break;
      case _SidePanelPage.audio:
        title = 'Audio & Volume';
        icon = Icons.volume_up_rounded;
        break;
      case _SidePanelPage.subtitleTrack:
        title = s.playerSubtitleTrack;
        icon = Iconsax.subtitle;
        break;
      case _SidePanelPage.subtitleSettings:
        title = s.playerSubSettingsTitle;
        icon = Iconsax.setting_2;
        break;
      case _SidePanelPage.server:
        title = s.playerServerTitle;
        icon = Icons.dns_rounded;
        break;
      case _SidePanelPage.speed:
        title = s.playerSpeed;
        icon = Icons.speed_rounded;
        break;
      case _SidePanelPage.info:
        title = s.playerInfoTitle;
        icon = Iconsax.info_circle;
        break;
    }

    final isSubPage = _sidePanelPage != _SidePanelPage.main &&
        _sidePanelPage != _SidePanelPage.info;

    return Container(
      width: drawerWidth,
      height: totalHeight,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.96),
        border: const Border(
          left: BorderSide(color: Colors.white12, width: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 16,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: SafeArea(
        left: false,
        child: Column(
          children: [
            // ── Panel Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
              child: Row(
                children: [
                  if (isSubPage) ...[
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () =>
                            _navigateToSidePanelPage(_SidePanelPage.main),
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: AppColors.primary, size: 16),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _closeSidePanel,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),

            // ── Slide Transition Body ──
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final isMain = child.key == const ValueKey('panel_main');
                  final beginOffset = isMain
                      ? const Offset(-0.25, 0.0)
                      : const Offset(0.25, 0.0);
                  return SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: beginOffset,
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: _buildSidePanelCurrentView(s),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidePanelCurrentView(AppStrings s) {
    switch (_sidePanelPage) {
      case _SidePanelPage.main:
        return _buildSidePanelMainMenu(s, key: const ValueKey('panel_main'));
      case _SidePanelPage.quality:
        return _buildSidePanelQuality(s, key: const ValueKey('panel_quality'));
      case _SidePanelPage.audio:
        return _buildSidePanelAudio(s, key: const ValueKey('panel_audio'));
      case _SidePanelPage.subtitleTrack:
        return _buildSidePanelSubtitleTrack(
          s,
          key: const ValueKey('panel_sub_track'),
        );
      case _SidePanelPage.subtitleSettings:
        return _buildSidePanelSubtitleSettings(
          s,
          key: const ValueKey('panel_sub_settings'),
        );
      case _SidePanelPage.server:
        return _buildSidePanelServer(s, key: const ValueKey('panel_server'));
      case _SidePanelPage.speed:
        return _buildSidePanelSpeed(s, key: const ValueKey('panel_speed'));
      case _SidePanelPage.info:
        return _buildSidePanelInfo(s, key: const ValueKey('panel_info'));
    }
  }

  Widget _buildSidePanelInfo(AppStrings s, {Key? key}) {
    final isTv = _currentSeason != null || _currentEpisode != null;
    final imagePath = _currentBackdropPath ?? _currentPosterPath;
    final hasImage = imagePath != null && imagePath.isNotEmpty;
    final imageUrl = hasImage
        ? (imagePath.startsWith('http')
            ? imagePath
            : ApiConstants.imageUrl(
                imagePath,
                size: ApiConstants.backdropMedium,
              ))
        : null;

    final hasSynopsis =
        _currentOverview != null && _currentOverview!.trim().isNotEmpty;

    return ListView(
      key: key,
      padding: EdgeInsets.zero,
      children: [
        // ── Top Media Banner with Black Gradient Overlay ──
        SizedBox(
          width: double.infinity,
          height: 155,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image or Solid Obsidian Fallback
              if (imageUrl != null)
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppColors.background,
                    child: const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.background,
                    child: const Center(
                      child: Icon(
                        Iconsax.video,
                        color: AppColors.textMuted,
                        size: 38,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  color: AppColors.background,
                  child: const Center(
                    child: Icon(
                      Iconsax.video,
                      color: AppColors.textMuted,
                      size: 38,
                    ),
                  ),
                ),

              // Smooth Pure Black Gradient Overlay blending with background
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.black.withValues(alpha: 0.15),
                        AppColors.surfaceVariant.withValues(alpha: 0.98),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),

              // Media Type Chip
              Positioned(
                top: 10,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 0.6,
                    ),
                  ),
                  child: Text(
                    isTv ? 'TV Series' : 'Movie',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Details Body: Title, Episode, and Synopsis ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Media Title
              Text(
                widget.title,
                style: GoogleFonts.outfit(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.25,
                ),
              ),

              // Specific Episode Title if available
              if (_currentEpisodeTitle != null &&
                  _currentEpisodeTitle!.isNotEmpty) ...[
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 0.6,
                    ),
                  ),
                  child: Text(
                    _currentEpisodeTitle!,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 14),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 14),

              // Section Header: "Sinopsis" / "Synopsis"
              Row(
                children: [
                  const Icon(
                    Iconsax.document_text,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    s.playerSynopsisTitle,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Synopsis Content or Placeholder
              if (hasSynopsis)
                Text(
                  _currentOverview!,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    height: 1.55,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10, width: 0.8),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Iconsax.info_circle,
                        size: 24,
                        color: AppColors.textMuted.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.playerNoSynopsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          height: 1.45,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidePanelMainMenu(AppStrings s, {Key? key}) {
    return ListView(
      key: key,
      padding: EdgeInsets.zero,
      children: [
        // 1. Kualitas Video
        _buildSidePanelMenuItem(
          icon: Icons.high_quality_rounded,
          title: s.playerQualityTitle,
          subtitle: _resolutionLabel,
          onTap: () => _navigateToSidePanelPage(_SidePanelPage.quality),
        ),

        // 2. Audio & Volume
        _buildSidePanelMenuItem(
          icon: _volume == 0
              ? Icons.volume_off_rounded
              : (_volume > 100.0
                    ? Icons.volume_up_rounded
                    : Icons.volume_down_rounded),
          title: 'Audio & Volume',
          subtitle: _volume == 0
              ? (s.isIndonesian ? 'Bisu (Muted)' : 'Muted')
              : '${_volume.toInt()}%${_volume > 100.0 ? (s.isIndonesian ? ' • Boost Aktif' : ' • Boost Active') : ''}',
          onTap: () => _navigateToSidePanelPage(_SidePanelPage.audio),
        ),

        // 3. Subtitle Track
        _buildSidePanelMenuItem(
          icon: Iconsax.subtitle,
          title: s.playerSubtitleTrack,
          subtitle: _selectedSubtitle != null
              ? '${_selectedSubtitle!.language.toUpperCase()} • ${_selectedSubtitle!.fileName.isNotEmpty ? _selectedSubtitle!.fileName : _selectedSubtitle!.languageName}'
              : s.playerDisableSubtitle,
          onTap: () => _navigateToSidePanelPage(_SidePanelPage.subtitleTrack),
        ),

        // 4. Subtitle Settings
        _buildSidePanelMenuItem(
          icon: Iconsax.setting_2,
          title: s.playerSubSettingsTitle,
          subtitle: '${s.playerTabSync} & ${s.playerTabAppearance}',
          onTap: () =>
              _navigateToSidePanelPage(_SidePanelPage.subtitleSettings),
        ),

        // 5. Server Streaming (Online only)
        if (_currentLocalVideoPath == null && widget.localVideoPath == null)
          _buildSidePanelMenuItem(
            icon: Icons.dns_rounded,
            title: s.playerServerTitle,
            subtitle: _currentServer.name,
            onTap: () => _navigateToSidePanelPage(_SidePanelPage.server),
          ),

        // 6. Playback Speed
        _buildSidePanelMenuItem(
          icon: Icons.speed_rounded,
          title: s.playerSpeed,
          subtitle: _playbackSpeed == 1.0
              ? 'Normal (1.0x)'
              : '${_playbackSpeed}x',
          onTap: () => _navigateToSidePanelPage(_SidePanelPage.speed),
        ),
      ],
    );
  }

  Widget _buildSidePanelMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.primary.withValues(alpha: 0.12),
        highlightColor: Colors.white.withValues(alpha: 0.04),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white12, width: 0.8),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 17),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              trailing ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white38,
                    size: 20,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidePanelQuality(AppStrings s, {Key? key}) {
    final videoTracks = _player.state.tracks.video;
    final List<String> qualities;
    if (videoTracks.length > 1) {
      final Set<String> heights = {};
      for (final track in videoTracks) {
        if (track.h != null && track.h! > 0) {
          heights.add('${track.h}p');
        }
      }
      final sortedHeights = heights.toList()
        ..sort((a, b) {
          final intA = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          final intB = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          return intB.compareTo(intA);
        });
      qualities = ['Auto', ...sortedHeights];
    } else {
      qualities = const ['Auto', '1080p', '720p', '480p', '360p'];
    }

    return ListView(
      key: key,
      padding: EdgeInsets.zero,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white12, width: 0.8),
            ),
          ),
          child: Text(
            '${s.playerQualityTitle}: $_resolutionLabel',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...qualities.map((q) {
          final isSelected = _currentQuality == q;
          String label = q == 'Auto' ? s.playerQualityAutoAdaptive : '$q HD';
          if (q == '1080p') label = '1080p FHD (${s.playerQualityClear})';
          if (q == '720p') label = '720p HD (${s.playerQualityStandard})';
          if (q == '480p') label = '480p SD (${s.playerQualityDataSaver})';
          if (q == '360p') label = '360p ${s.playerQualityLow} (< 500 Kbps)';

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _setQuality(q),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white12, width: 0.8),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 18,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? AppColors.primary : Colors.white,
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          s.isIndonesian ? 'AKTIF' : 'ACTIVE',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSidePanelAudio(AppStrings s, {Key? key}) {
    final audioTracks = _player.state.tracks.audio;

    return ListView(
      key: key,
      padding: EdgeInsets.zero,
      children: [
        // Volume Level & Status
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white12, width: 0.8),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _volume == 0
                            ? Icons.volume_off_rounded
                            : (_volume > 100.0
                                  ? Icons.volume_up_rounded
                                  : Icons.volume_down_rounded),
                        color: _volume > 100.0
                            ? AppColors.primary
                            : Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _volume > 100.0
                            ? 'Volume: ${_volume.toInt()}% (Boost)'
                            : 'Volume: ${_volume.toInt()}%',
                        style: TextStyle(
                          color: _volume > 100.0
                              ? AppColors.primary
                              : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (_volume > 100.0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '+${(_volume - 100).toInt()}% BOOST',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 7,
                  ),
                  activeTrackColor: _volume > 100.0
                      ? AppColors.primary
                      : Colors.white,
                  inactiveTrackColor: Colors.white12,
                  thumbColor: _volume > 100.0
                      ? AppColors.primary
                      : Colors.white,
                  overlayColor: AppColors.primary.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: _volume,
                  min: 0.0,
                  max: 150.0,
                  divisions: 30,
                  onChanged: _setVolume,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildSidePanelVolumeChip('Mute', 0.0),
                  const SizedBox(width: 6),
                  _buildSidePanelVolumeChip('50%', 50.0),
                  const SizedBox(width: 6),
                  _buildSidePanelVolumeChip('100%', 100.0),
                  const SizedBox(width: 6),
                  _buildSidePanelVolumeChip('125%', 125.0),
                  const SizedBox(width: 6),
                  _buildSidePanelVolumeChip('150%', 150.0),
                ],
              ),
            ],
          ),
        ),

        // Audio Tracks (if available)
        if (audioTracks.length > 1) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white12, width: 0.8),
              ),
            ),
            child: Text(
              s.playerAudioTrack,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...audioTracks.map((track) {
            final isSelected = _player.state.track.audio == track;
            final trackTitle =
                track.title ?? track.language ?? (s.isIndonesian ? 'Trek ${track.id}' : 'Track ${track.id}');
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  await _player.setAudioTrack(track);
                  setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.white12, width: 0.8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 18,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          trackTitle,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.white,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            s.isIndonesian ? 'AKTIF' : 'ACTIVE',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildSidePanelVolumeChip(String label, double targetVal) {
    final isSelected = (_volume - targetVal).abs() < 2.0;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _setVolume(targetVal),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.white12,
                width: 0.8,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : Colors.white70,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidePanelSubtitleTrack(AppStrings s, {Key? key}) {
    final targetLangCode = _getTargetTranslateLang();
    final targetLangObj = SubtitleLanguageCatalog.findByCode(targetLangCode);

    return ListView(
      key: key,
      padding: EdgeInsets.zero,
      children: [
        // 1. Matikan Subtitle
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              ref.read(activeSubtitleCuesProvider.notifier).state = [];
              await _player.setSubtitleTrack(SubtitleTrack.no());
              setState(() {
                _selectedSubtitle = null;
                _isSubtitleTranslated = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white12, width: 0.8),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedSubtitle == null
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 18,
                    color: _selectedSubtitle == null
                        ? AppColors.primary
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: 14),
                  Text(
                    s.playerDisableSubtitle,
                    style: TextStyle(
                      color: _selectedSubtitle == null
                          ? AppColors.primary
                          : Colors.white,
                      fontSize: 13,
                      fontWeight: _selectedSubtitle == null
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 2. Action: Atur Subtitle (Slide ke Subtitle Settings)
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () =>
                _navigateToSidePanelPage(_SidePanelPage.subtitleSettings),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white12, width: 0.8),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Iconsax.setting_2,
                    size: 17,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      s.playerSubSettings,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ),

        // 3. 1-Tap Auto-Translate Action
        if (_selectedSubtitle != null &&
            _selectedSubtitle!.language.toLowerCase() !=
                targetLangCode.toLowerCase()) ...[
          if (_isAutoTranslating) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: _translationProgress > 0
                        ? _translationProgress
                        : null,
                    color: AppColors.primary,
                    backgroundColor: AppColors.surfaceElevated,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.playerTranslatingTo(targetLangObj.name),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _applyAndAutoTranslateSubtitle(
                    _selectedSubtitle!,
                    targetLang: targetLangCode,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.white12, width: 0.8),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Iconsax.magic_star,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isSubtitleTranslated
                              ? s.playerTranslateActive(
                                  targetLangCode.toUpperCase(),
                                )
                              : s.playerTranslateTo(targetLangObj.name),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],

        // 4. Subtitle Tracks Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white12, width: 0.8),
            ),
          ),
          child: Text(
            s.isIndonesian ? 'Daftar Subtitle Tersedia' : 'Available Subtitles',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),

        // Subtitle tracks
        if (_availableSubtitles.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                s.playerNoSubtitleFound,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
          )
        else
          ..._availableSubtitles.map((sub) {
            final isSelected = _selectedSubtitle?.id == sub.id;
            final isPreferred =
                sub.language.toLowerCase() == targetLangCode.toLowerCase();

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  final success = await _applySubtitle(sub);
                  if (!success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          s.playerFailedDownloadSub(sub.languageName),
                        ),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.white12, width: 0.8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 16,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isPreferred
                              ? AppColors.success.withValues(alpha: 0.25)
                              : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          sub.language.toUpperCase(),
                          style: TextStyle(
                            color: isPreferred
                                ? AppColors.success
                                : Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          sub.fileName.isNotEmpty
                              ? sub.fileName
                              : sub.languageName,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.white,
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildSidePanelSubtitleSettings(AppStrings s, {Key? key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: _buildSubtitleSettingsContent(s),
    );
  }

  Widget _buildSidePanelServer(AppStrings s, {Key? key}) {
    return ListView(
      key: key,
      padding: EdgeInsets.zero,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white12, width: 0.8),
            ),
          ),
          child: Text(
            s.playerServerDesc,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ),
        ..._availableServers.map((srv) {
          final isSelected = _currentServer.id == srv.id;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _switchServer(srv),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white12, width: 0.8),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 18,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            srv.name,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.white,
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            srv.description,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          s.isIndonesian ? 'AKTIF' : 'ACTIVE',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSidePanelSpeed(AppStrings s, {Key? key}) {
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

    return ListView(
      key: key,
      padding: EdgeInsets.zero,
      children: speeds.map((sp) {
        final isSelected = (_playbackSpeed - sp).abs() < 0.05;
        final label = sp == 1.0 ? '1.0x (Normal)' : '${sp}x';

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _setPlaybackSpeed(sp),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white12, width: 0.8),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 18,
                    color: isSelected ? AppColors.primary : AppColors.textMuted,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? AppColors.primary : Colors.white,
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        s.isIndonesian ? 'AKTIF' : 'ACTIVE',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStreamNotFoundOverlay(AppStrings s) {
    return Container(
      color: Colors.black.withValues(alpha: 0.96),
      child: SafeArea(
        child: Stack(
          children: [
            // Top back button so user can exit immediately
            Positioned(
              top: 8,
              left: 16,
              child: IconButton(
                onPressed: _handleExit,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            // Center content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.videocam_off_rounded,
                          color: AppColors.primary,
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.playerStreamNotFoundTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        s.playerStreamNotFoundMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 12.5,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              final webServer = _availableServers.firstWhere(
                                (srv) => !srv.isDirectHls,
                                orElse: () =>
                                    SmartStreamService.fallbackWebServers.first,
                              );
                              setState(() {
                                _streamNotFound = false;
                              });
                              _switchServer(webServer);
                            },
                            icon: const Icon(Icons.public_rounded, size: 16),
                            label: const Text('Coba Server Web (VidLink)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _openSidePanel(_SidePanelPage.server),
                            icon: const Icon(Icons.dns_rounded, size: 16),
                            label: Text(s.playerStreamNotFoundChooseServer),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _streamNotFound = false;
                              });
                              _initOnlineStreaming();
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: Text(s.playerRetry),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBarIconButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    Color? activeColor,
    Color? inactiveColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary
              : Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            icon,
            size: 19,
            color: isActive
                ? (activeColor ?? Colors.black)
                : (inactiveColor ?? Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(AppStrings s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: _handleExit,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_currentSeason != null && _currentEpisode != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Season $_currentSeason • Episode $_currentEpisode',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (!_useNativePlayer) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _playNextEpisode,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.skip_next_rounded,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  size: 12,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  s.playerNextEpShort(
                                    (_currentEpisode ?? 1) + 1,
                                  ),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),

          // Side Panel Info Hub Toggle
          _buildTopBarIconButton(
            icon: Iconsax.info_circle,
            isActive: _isSidePanelOpen && _sidePanelPage == _SidePanelPage.info,
            onTap: () => _toggleSidePanel(_SidePanelPage.info),
          ),
          const SizedBox(width: 8),

          // Side Panel Settings & Features Hub Toggle
          _buildTopBarIconButton(
            icon: Iconsax.setting_2,
            isActive: _isSidePanelOpen && _sidePanelPage != _SidePanelPage.info,
            onTap: () => _toggleSidePanel(_SidePanelPage.main),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final subtitleStyle = ref.watch(subtitleStyleProvider);
    final activeCues = ref.watch(activeSubtitleCuesProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_isSidePanelOpen) {
          if (_sidePanelPage != _SidePanelPage.main) {
            _navigateToSidePanelPage(_SidePanelPage.main);
          } else {
            _closeSidePanel();
          }
          return;
        }
        await _handleExit();
      },
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            final key = event.logicalKey;
            if (key == LogicalKeyboardKey.select ||
                key == LogicalKeyboardKey.enter ||
                key == LogicalKeyboardKey.space ||
                key == LogicalKeyboardKey.gameButtonA) {
              _togglePlayPause();
              return KeyEventResult.handled;
            } else if (key == LogicalKeyboardKey.arrowLeft) {
              _seekRelative(-10);
              return KeyEventResult.handled;
            } else if (key == LogicalKeyboardKey.arrowRight) {
              _seekRelative(10);
              return KeyEventResult.handled;
            } else if (key == LogicalKeyboardKey.arrowUp) {
              _setVolume((_volume + 10.0).clamp(0.0, 150.0));
              return KeyEventResult.handled;
            } else if (key == LogicalKeyboardKey.arrowDown) {
              _setVolume((_volume - 10.0).clamp(0.0, 150.0));
              return KeyEventResult.handled;
            } else if (key == LogicalKeyboardKey.keyM) {
              _setVolume(_volume > 0 ? 0.0 : 100.0);
              return KeyEventResult.handled;
            } else if (key == LogicalKeyboardKey.escape) {
              if (_isSidePanelOpen) {
                _closeSidePanel();
              } else {
                _handleExit();
              }
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Scaffold(
        backgroundColor: Colors.black,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final totalHeight = constraints.maxHeight;
            final drawerWidth = (totalWidth * 0.36).clamp(310.0, 390.0);
            final videoWidth = _isSidePanelOpen
                ? totalWidth - drawerWidth
                : totalWidth;
            final effectiveFit = _isSidePanelOpen ? BoxFit.contain : _fitMode;

            return SizedBox(
              width: totalWidth,
              height: totalHeight,
              child: Row(
                children: [
                  // ── 1. Video Player & Controls (Left Container with Animated Width) ──
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOutCubic,
                    width: videoWidth,
                    height: totalHeight,
                    child: ClipRect(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // ── 1. Video Layer: Passes all the way through camera cutout / notch ──
                          if (_useNativePlayer)
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _toggleControls,
                              // Vertical swipe gesture on right half of video to adjust volume, left half to adjust brightness
                              onVerticalDragUpdate: (details) {
                                if (details.localPosition.dx > videoWidth / 2) {
                                  // Drag up increases volume, drag down decreases volume
                                  final delta = -details.primaryDelta! * 0.5;
                                  _setVolume(_volume + delta);
                                } else {
                                  // Drag up increases brightness, drag down decreases brightness
                                  final delta = -details.primaryDelta! / 250.0;
                                  _setBrightness(_brightness + delta);
                                }
                              },
                              child: Video(
                                controller: _videoController,
                                controls:
                                    NoVideoControls, // Guarantees NO built-in media_kit controls!
                                subtitleViewConfiguration:
                                    const SubtitleViewConfiguration(
                                      visible:
                                          false, // Ensures media_kit never renders its own internal subtitle
                                    ),
                                fit: effectiveFit,
                              ),
                            )
                          else if (_webViewController != null)
                            Stack(
                              fit: StackFit.expand,
                              children: [
                                WebViewWidget(controller: _webViewController!),
                                // Anti-Ad Transparent Touch Shield: Intercepts taps & gestures to prevent triggering web ads!
                                Positioned.fill(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: _toggleControls,
                                    onVerticalDragUpdate: (details) {
                                      if (details.localPosition.dx >
                                          videoWidth / 2) {
                                        final delta =
                                            -details.primaryDelta! * 0.5;
                                        _setVolume(_volume + delta);
                                      } else {
                                        final delta =
                                            -details.primaryDelta! / 250.0;
                                        _setBrightness(_brightness + delta);
                                      }
                                    },
                                    child: Container(color: Colors.transparent),
                                  ),
                                ),
                              ],
                            )
                          else
                            const SizedBox.shrink(),

                          // ── 2. Synchronized Custom Subtitles Layer (Direct child of Stack!) ──
                          CustomSubtitleOverlay(
                            cues: activeCues,
                            positionListenable: _positionNotifier,
                            settings: subtitleStyle,
                          ),

                          // ── 3. Quick Volume Indicator HUD Pill ──
                          if (_showVolumeIndicator)
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _volume == 0
                                          ? Icons.volume_off_rounded
                                          : _volume > 100.0
                                          ? Icons.volume_up_rounded
                                          : Icons.volume_down_rounded,
                                      color: _volume > 100.0
                                          ? AppColors.primary
                                          : Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _volume > 100.0
                                          ? 'Volume: ${_volume.toInt()}% (Boost)'
                                          : 'Volume: ${_volume.toInt()}%',
                                      style: TextStyle(
                                        color: _volume > 100.0
                                            ? AppColors.primary
                                            : Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // ── 3.1 Quick Brightness Indicator HUD Pill ──
                          if (_showBrightnessIndicator)
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _brightness > 0.6
                                          ? Icons.brightness_high_rounded
                                          : (_brightness > 0.3
                                                ? Icons
                                                      .brightness_medium_rounded
                                                : Icons.brightness_low_rounded),
                                      color: AppColors.primary,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      '${s.playerBrightness}: ${(_brightness * 100).round()}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // ── 4. Loading & Buffering Overlay ──
                          if (_isLoading)
                            Container(
                              color: Colors.black.withValues(alpha: 0.94),
                              child: SafeArea(
                                child: Stack(
                                  children: [
                                    // Top back button so user can always cancel/exit during loading
                                    Positioned(
                                      top: 8,
                                      left: 16,
                                      child: IconButton(
                                        onPressed: _handleExit,
                                        icon: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.1,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.arrow_back,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Center Loading Indicator: pure orange spinner, no background box
                                    Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SizedBox(
                                            width: 50,
                                            height: 50,
                                            child: CircularProgressIndicator(
                                              color: AppColors.primary,
                                              strokeWidth: 3.5,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 40,
                                            ),
                                            child: Text(
                                              widget.title,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _getLoadingStatusText(s),
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Unified center buffering indicator when controls are hidden: pure orange spinner, no background box
                          if (_useNativePlayer &&
                              !_showControls &&
                              _isBuffering &&
                              !_isLoading)
                            const IgnorePointer(
                              child: Center(
                                child: SizedBox(
                                  width: 52,
                                  height: 52,
                                  child: CircularProgressIndicator(
                                    color: AppColors.primary,
                                    strokeWidth: 3.5,
                                  ),
                                ),
                              ),
                            ),

                          // ── 4b. Stream Not Available (404) Overlay ──
                          if (!_isLoading && _streamNotFound)
                            _buildStreamNotFoundOverlay(s),

                          // ── 5. Cineva Custom Cinema Controls (Unified for Both Native & Web Streams) ──
                          if (!_isLoading && !_streamNotFound)
                            AnimatedOpacity(
                              opacity: _showControls ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: IgnorePointer(
                                ignoring: !_showControls,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.85),
                                        Colors.transparent,
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.85),
                                      ],
                                      stops: const [0.0, 0.25, 0.7, 1.0],
                                    ),
                                  ),
                                  child: SafeArea(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // ── Top Navigation & Quality Bar ──
                                        _buildTopBar(s),

                                        // ── Center Controls (Play/Pause, Replay 10, Forward 10) ──
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              onPressed: () =>
                                                  _seekRelative(-10),
                                              icon: const Icon(
                                                Icons.replay_10_rounded,
                                                color: Colors.white,
                                                size: 44,
                                              ),
                                            ),
                                            const SizedBox(width: 36),
                                            GestureDetector(
                                              onTap: _isBuffering
                                                  ? null
                                                  : _togglePlayPause,
                                              behavior: HitTestBehavior.opaque,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8,
                                                    ),
                                                child: _isBuffering
                                                    ? const SizedBox(
                                                        width: 54,
                                                        height: 54,
                                                        child:
                                                            CircularProgressIndicator(
                                                              color: AppColors
                                                                  .primary,
                                                              strokeWidth: 3.5,
                                                            ),
                                                      )
                                                    : Icon(
                                                        _isPlaying
                                                            ? Icons
                                                                  .pause_rounded
                                                            : Icons
                                                                  .play_arrow_rounded,
                                                        color:
                                                            AppColors.primary,
                                                        size: 58,
                                                      ),
                                              ),
                                            ),
                                            const SizedBox(width: 36),
                                            IconButton(
                                              onPressed: () =>
                                                  _seekRelative(10),
                                              icon: const Icon(
                                                Icons.forward_10_rounded,
                                                color: Colors.white,
                                                size: 44,
                                              ),
                                            ),
                                          ],
                                        ),

                                        // ── Bottom Timeline Scrubber ──
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            24,
                                            0,
                                            24,
                                            12,
                                          ),
                                          child: ValueListenableBuilder<Duration>(
                                            valueListenable: _positionNotifier,
                                            builder: (ctx, pos, _) {
                                              return Row(
                                                children: [
                                                  Text(
                                                    _formatDuration(pos),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: SliderTheme(
                                                      data:
                                                          SliderTheme.of(
                                                            context,
                                                          ).copyWith(
                                                            trackHeight: 3.5,
                                                            thumbShape:
                                                                const RoundSliderThumbShape(
                                                                  enabledThumbRadius:
                                                                      6,
                                                                ),
                                                            overlayShape:
                                                                const RoundSliderOverlayShape(
                                                                  overlayRadius:
                                                                      14,
                                                                ),
                                                            activeTrackColor:
                                                                AppColors
                                                                    .primary,
                                                            inactiveTrackColor:
                                                                Colors.white24,
                                                            thumbColor:
                                                                AppColors
                                                                    .primary,
                                                          ),
                                                      child: Slider(
                                                        value:
                                                            _duration
                                                                    .inSeconds >
                                                                0
                                                            ? pos.inSeconds
                                                                  .toDouble()
                                                                  .clamp(
                                                                    0.0,
                                                                    _duration
                                                                        .inSeconds
                                                                        .toDouble(),
                                                                  )
                                                            : 0.0,
                                                        min: 0.0,
                                                        max:
                                                            _duration
                                                                    .inSeconds >
                                                                0
                                                            ? _duration
                                                                  .inSeconds
                                                                  .toDouble()
                                                            : 1.0,
                                                        onChanged: (v) =>
                                                            _seekTo(v),
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    _formatDuration(_duration),
                                                    style: const TextStyle(
                                                      color: AppColors
                                                          .textSecondary,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 14),
                                                  // Fit mode toggle (cover / contain / fill)
                                                  IconButton(
                                                    onPressed: _toggleFitMode,
                                                    tooltip:
                                                        'Aspect Ratio & Notch Mode',
                                                    icon: Icon(
                                                      _fitMode == BoxFit.cover
                                                          ? Icons
                                                                .fullscreen_rounded
                                                          : Icons
                                                                .aspect_ratio_rounded,
                                                      color:
                                                          _fitMode ==
                                                              BoxFit.cover
                                                          ? AppColors.primary
                                                          : Colors.white70,
                                                      size: 22,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // ── 5.5 Floating TV Series Next Episode Action (<= 60s remaining) ──
                          if (!_isLoading &&
                              _nextEpisodeButtonVisible &&
                              (_currentSeason != null &&
                                  _currentEpisode != null))
                            Positioned(
                              bottom: _showControls ? 78 : 28,
                              right: 28,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: _buildSkipPillButton(
                                  key: ValueKey(
                                    'tv_next_episode_$_currentEpisode',
                                  ),
                                  icon: Icons.skip_next_rounded,
                                  label: s.playerNextEpisodePill(
                                    (_currentEpisode ?? 1) + 1,
                                  ),
                                  onTap: _playNextEpisode,
                                ),
                              ),
                            ),

                          // ── 6. Compact Semi-Transparent Mini Popups Layer ──
                          if (!_isLoading &&
                              _activePopup != _PlayerMiniPopup.none) ...[
                            // Outside tap dismisser (transparent, non-blocking)
                            Positioned.fill(
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: () {
                                  setState(() {
                                    _activePopup = _PlayerMiniPopup.none;
                                    _isShowingSubtitleSettingsInPopup = false;
                                  });
                                  _resetControlsTimer();
                                },
                              ),
                            ),

                            // The active Mini Popup Card
                            Positioned(
                              top: 54,
                              right: 16,
                              child: switch (_activePopup) {
                                _PlayerMiniPopup.quality =>
                                  _buildQualityMiniPopup(s),
                                _PlayerMiniPopup.volume =>
                                  _buildVolumeMiniPopup(s),
                                _PlayerMiniPopup.subtitle =>
                                  _buildSubtitleMiniPopup(s),
                                _PlayerMiniPopup.subtitleSettings =>
                                  _buildSubtitleSettingsMiniPopup(s),
                                _PlayerMiniPopup.server =>
                                  _buildServerMiniPopup(s),
                                _PlayerMiniPopup.none =>
                                  const SizedBox.shrink(),
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // ── 2. YouTube-style Right Side Panel ──
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOutCubic,
                    width: _isSidePanelOpen ? drawerWidth : 0.0,
                    height: totalHeight,
                    child: ClipRect(
                      child: OverflowBox(
                        minWidth: drawerWidth,
                        maxWidth: drawerWidth,
                        minHeight: totalHeight,
                        maxHeight: totalHeight,
                        alignment: Alignment.topRight,
                        child: _buildSidePanel(s, drawerWidth, totalHeight),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}
}
