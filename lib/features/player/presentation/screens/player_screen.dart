import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/subtitle_cue.dart';
import '../../data/services/subtitle_service.dart';
import '../../data/services/subtitle_translator_service.dart';
import '../../data/services/vixsrc_stream_service.dart';
import '../../data/services/smart_stream_service.dart';
import '../../../settings/data/settings_service.dart';
import '../../../settings/data/subtitle_languages.dart';
import '../../../history/data/models/watch_history_item.dart';
import '../../../history/data/repositories/watch_history_repository.dart';
import '../../../download/domain/models/download_item.dart';
import '../../../download/data/services/local_stream_server.dart';
import '../../../download/data/services/native_media_muxer.dart';
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

enum _PlayerMiniPopup { none, quality, subtitle, subtitleSettings, volume, server }

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
  int? _currentTmdbId;
  String? _currentImdbId;
  bool _isWebPlaying = false;

  // ── Playback State ──
  bool _isLoading = true;
  bool _isBuffering = false;
  _PlayerLoadingStep _loadingStep = _PlayerLoadingStep.searching;
  String? _customLoadingStatus;
  String _resolutionLabel = '1080p FHD';
  String _currentQuality = 'Auto';

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
  final ValueNotifier<Duration> _positionNotifier = ValueNotifier<Duration>(Duration.zero);
  Duration _duration = Duration.zero;
  bool _isPlaying = true;
  BoxFit _fitMode = BoxFit.cover; // Default cover to expand through camera cutout!

  // ── Audio Volume & Boost State ──
  double _volume = 100.0; // 0 to 150% (boosted)
  bool _showVolumeIndicator = false;
  Timer? _volumeIndicatorTimer;

  // ── Controls & Mini Popups State ──
  bool _showControls = false;
  Timer? _controlsTimer;
  _PlayerMiniPopup _activePopup = _PlayerMiniPopup.none;
  int _subtitleSettingsTab = 0; // 0: Waktu (Sync), 1: Tampilan
  bool _isShowingSubtitleSettingsInPopup = false;

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
  late String? _currentEpisodeTitle = widget.episodeTitle ?? (widget.episode != null ? 'Episode ${widget.episode}' : null);
  late String? _currentLocalVideoPath = widget.localVideoPath;
  late String? _currentLocalSubtitlePath = widget.localSubtitlePath;
  late int? _initialPositionMs = widget.initialPositionMs;

  @override
  void initState() {
    super.initState();
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
      configuration: const PlayerConfiguration(
        bufferSize: 32 * 1024 * 1024,
      ),
    );
    _videoController = VideoController(
      _player,
      configuration: const VideoControllerConfiguration(
        enableHardwareAcceleration: true, // Hardware MediaCodec decoding on Android GPU
      ),
    );

    _listenToPlayerStreams();
    _player.setVolume(_volume); // Explicitly ensure 100% base audio volume
    if ((_currentLocalVideoPath != null && _currentLocalVideoPath!.isNotEmpty) ||
        (widget.localVideoPath != null && widget.localVideoPath!.isNotEmpty)) {
      _setupMpvOfflineOptions();
    } else {
      _setupMpvFastBufferOptions();
    }
    _initializeStreaming();
    _resetControlsTimer();
  }

  /// Sets up zero-latency instant offline playback options for mpv.
  /// Eliminates network caching delays and prevents loopback buffering freezes.
  Future<void> _setupMpvOfflineOptions() async {
    try {
      final mpv = (_player.platform as dynamic);
      await mpv?.command(['set', 'cache', 'no']); // ZERO network cache: read directly from local storage
      await mpv?.command(['set', 'cache-pause', 'no']); // Never pause on local files
      await mpv?.command(['set', 'cache-pause-initial', 'no']); // Play immediately without waiting
      await mpv?.command(['set', 'demuxer-readahead-secs', '5']); // Minimal 5s readahead
      await mpv?.command(['set', 'demuxer-lavf-o', 'fflags=+genpts,allowed_extensions=ALL']);
      await mpv?.command(['set', 'hr-seek', 'yes']); // Precise seeking
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
      await mpv?.command(['set', 'demuxer-lavf-analyzeduration', '2.0']); // 2s analyze duration
      await mpv?.command(['set', 'cache-pause-initial', 'no']); // Start playing immediately without waiting
      await mpv?.command(['set', 'cache-pause-wait', '3']); // Low 3s re-buffer threshold on stalls

      // Progressive 3-minute background cache:
      await mpv?.command(['set', 'cache', 'yes']);
      await mpv?.command(['set', 'demuxer-readahead-secs', '180']); // Buffer up to 180s (3 minutes) ahead while watching!
      await mpv?.command(['set', 'cache-secs', '180']); // 180s forward cache in memory
      await mpv?.command(['set', 'demuxer-max-bytes', '134217728']); // 128 MB RAM max
      await mpv?.command(['set', 'demuxer-max-back-bytes', '33554432']); // 32 MB backward buffer for instant rewind
      await mpv?.command(['set', 'stream-buffer-size', '524288']); // 512 KB chunk reads
      await mpv?.command(['set', 'network-timeout', '30']);
    } catch (e) {
      debugPrint('[PlayerScreen] mpv buffer setup error: $e');
    }
  }

  bool _isExiting = false;

  Future<void> _handleExit() async {
    if (_isExiting) return;
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
        'var v = document.querySelector("video"); if (v) { v.pause(); v.src = ""; v.load(); }'
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
    _saveWatchHistory(force: true);

    // 5. Pop player route safely
    if (mounted) {
      context.pop();
    }
  }

  @override
  void dispose() {
    _saveWatchHistory(force: true);
    _controlsTimer?.cancel();
    _volumeIndicatorTimer?.cancel();
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
        'var v = document.querySelector("video"); if (v) { v.pause(); v.src = ""; v.load(); }'
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

  int? _getSavedPositionMs() {
    if (widget.tmdbId == null) return null;
    final mediaType = widget.mediaType ?? (_currentSeason != null ? 'tv' : 'movie');
    final repo = ref.read(watchHistoryRepositoryProvider);
    final item = repo.getItem(mediaType, widget.tmdbId!);
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

  void _saveWatchHistory({bool force = false}) {
    final tmdbId = widget.tmdbId;
    if (tmdbId == null || tmdbId == 0) return;

    final posMs = _position.inMilliseconds;
    final durMs = _duration.inMilliseconds;
    if (durMs <= 0 || posMs < 3000) return;

    final isCompleted = (posMs / durMs) >= 0.95;
    final mediaType = widget.mediaType ?? (_currentSeason != null ? 'tv' : 'movie');

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

    ref.read(watchHistoryProvider.notifier).saveProgress(item);
  }

  void _listenToPlayerStreams() {
    _posSub = _player.stream.position.listen((pos) {
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
      if (!_hasRestoredPosition && _duration.inMilliseconds > 0 && pos.inMilliseconds > 0) {
        _hasRestoredPosition = true;
        final resumeMs = _initialPositionMs ?? _getSavedPositionMs();
        if (resumeMs != null && resumeMs > 5000 && resumeMs < _duration.inMilliseconds - 10000) {
          debugPrint('[PlayerScreen] Resuming playback at ${resumeMs}ms');
          _player.seek(Duration(milliseconds: resumeMs));
        }
      }

      // ── TV Series Next Episode (Auto when <= 5s, Manual button when <= 60s) ──
      final isTv = _currentSeason != null && _currentEpisode != null;
      if (isTv && _duration.inSeconds > 30) {
        final remainingSecs = (_duration - pos).inSeconds;

        // Auto next episode when 5 seconds or less remain
        if (remainingSecs <= 5 && remainingSecs >= 0 && !_hasAutoPlayedNext && !_isSwitchingEpisode) {
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
      final now = DateTime.now();
      if (now.difference(_lastHistorySaveTime).inSeconds >= 5) {
        _lastHistorySaveTime = now;
        _saveWatchHistory();
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
      final isOffline = (_currentLocalVideoPath != null && _currentLocalVideoPath!.isNotEmpty) ||
          (widget.localVideoPath != null && widget.localVideoPath!.isNotEmpty);
      if (isOffline) {
        // Offline playback: never show full-screen buffering spinner unless player is completely stopped/not playing
        final shouldBuffer = buffering && !_isPlaying;
        if (mounted && _isBuffering != shouldBuffer) {
          setState(() => _isBuffering = shouldBuffer);
        }
        return;
      }
      if (mounted && _isBuffering != buffering) setState(() => _isBuffering = buffering);
    });
    _trackSub = _player.stream.track.listen((track) {
      // libmpv auto-detects internal stream subtitles and selects one by default.
      // We force internal mpv subtitles to be disabled at all times so that only
      // Cineva's CustomSubtitleOverlay renders on top with custom opacity, sync, and translation.
      if (track.subtitle != SubtitleTrack.no()) {
        _player.setSubtitleTrack(SubtitleTrack.no());
      }
      // Ensure video track remains active and does not drop to 'no'
      if (track.video == VideoTrack.no() && _player.state.tracks.video.isNotEmpty) {
        debugPrint('[PlayerScreen] Video track was none, restoring auto video track');
        _player.setVideoTrack(VideoTrack.auto());
      }
    });
    _tracksSub = _player.stream.tracks.listen((tracks) {
      if (tracks.video.isNotEmpty && _player.state.track.video == VideoTrack.no()) {
        debugPrint('[PlayerScreen] New video tracks detected, setting auto video track');
        _player.setVideoTrack(VideoTrack.auto());
      }
    });
  }

  Future<void> _loadSubtitles() async {
    final prefLang = SettingsService.getDefaultSubtitleLang(); // 'id', 'en', 'off'
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
      final nativeSub = allSubs.where((s) => s.language.toLowerCase() == prefLang.toLowerCase()).firstOrNull;
      if (nativeSub != null) {
        debugPrint('[PlayerScreen] Native ${nativeSub.languageName} subtitle found: ${nativeSub.fileName}');
        final success = await _applySubtitle(nativeSub);
        if (success) {
          final s = ref.read(appStringsProvider);
          _showToastSubtitle(s.playerSubActiveToast(nativeSub.languageName));
          return;
        }
        debugPrint('[PlayerScreen] Native subtitle download failed, falling back to auto-translation...');
      }

      // Priority 2: Fallback to English / available track + Auto-translate
      final autoTranslate = SettingsService.getAutoTranslate();
      final fallbackSub = _streamSubtitles.where((s) => s.language.toLowerCase() == 'en').firstOrNull
          ?? allSubs.where((s) => s.language.toLowerCase() == 'en').firstOrNull
          ?? allSubs.first;
      debugPrint('[PlayerScreen] Fallback to ${fallbackSub.languageName} (Target: $prefLang, Auto-translate: $autoTranslate)');

      final s = ref.read(appStringsProvider);
      if (autoTranslate && prefLang.toLowerCase() != fallbackSub.language.toLowerCase()) {
        final target = _getTargetTranslateLang();
        final translated = await _applyAndAutoTranslateSubtitle(fallbackSub, targetLang: target);
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
      final downloadUrl = await subService.getDownloadUrl(sub.id);
      if (downloadUrl != null) {
        final content = await subService.downloadSubtitleContent(downloadUrl);
        if (content != null && mounted) {
          final cues = SubtitleCue.parseSrt(content);
          if (cues.isNotEmpty) {
            final refinedCues = cues.map((c) => SubtitleCue(
                    start: c.start,
                    end: c.end,
                    text: sub.language.toLowerCase() == 'id'
                        ? SubtitleTranslatorService.balanceSubtitleLines(
                            SubtitleTranslatorService.smartFormatIndonesianSubtitle(
                                SubtitleTranslatorService.refineIndonesianPronouns(c.text)))
                        : SubtitleTranslatorService.balanceSubtitleLines(c.text),
                  )).toList();
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

  Future<bool> _applyAndAutoTranslateSubtitle(SubtitleInfo sub, {String? targetLang}) async {
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
      final downloadUrl = await subService.getDownloadUrl(sub.id);
      if (downloadUrl != null) {
        final content = await subService.downloadSubtitleContent(downloadUrl);
        if (content != null && mounted) {
          final originalCues = SubtitleCue.parseSrt(content);
          if (originalCues.isNotEmpty) {
            // Immediately show original cues with line balancing while background translating
            final balancedOriginalCues = originalCues.map((c) => SubtitleCue(
              start: c.start,
              end: c.end,
              text: SubtitleTranslatorService.balanceSubtitleLines(c.text),
            )).toList();
            ref.read(activeSubtitleCuesProvider.notifier).state = balancedOriginalCues;

            final targetLanguage = (targetLang ?? _getTargetTranslateLang()).toLowerCase();
            final translator = ref.read(subtitleTranslatorServiceProvider);
            final cacheKey = 'sub_${widget.imdbId ?? widget.tmdbId}_auto_${targetLanguage}_${sub.id.hashCode}_s${_currentSeason ?? 0}_e${_currentEpisode ?? 0}';

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
              ref.read(activeSubtitleCuesProvider.notifier).state = translatedCues;
              setState(() {
                _isAutoTranslating = false;
                _isSubtitleTranslated = true;
              });
              final langObj = SubtitleLanguageCatalog.findByCode(targetLanguage);
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
            Expanded(child: Text(message, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
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
    if ((_currentLocalVideoPath != null && _currentLocalVideoPath!.isNotEmpty) ||
        (widget.localVideoPath != null && widget.localVideoPath!.isNotEmpty)) {
      await _initOfflinePlayback();
      return;
    }

    // 1. ONLINE STREAMING FLOW
    await _initOnlineStreaming();
  }

  /// Dedicated offline video player handler.
  /// Plays local MP4 video directly from storage without any network traffic or buffering.
  Future<void> _initOfflinePlayback() async {
    setState(() {
      _isLoading = true;
      _loadingStep = _PlayerLoadingStep.preparingOffline;
      _customLoadingStatus = null;
    });

    try {
      final s = ref.read(appStringsProvider);
      final path = _currentLocalVideoPath ?? widget.localVideoPath!;
      final localFile = File(path);
      debugPrint('[PlayerScreen] Initializing offline playback: ${localFile.path}');
      if (!await localFile.exists()) {
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

      var targetMediaFile = localFile;

      // 1. Check if hardware-muxed video.mp4 exists in the folder
      if (!targetMediaFile.path.toLowerCase().endsWith('.mp4')) {
        final mp4Candidate = File('${targetMediaFile.parent.path}/video.mp4');
        if (await mp4Candidate.exists() && (await mp4Candidate.length()) > 50000) {
          targetMediaFile = mp4Candidate;
        }
      }

      // 2. If not MP4 yet, but offline TS chunks exist on Android, auto-mux to MP4 for instant zero-buffer playback
      if (Platform.isAndroid && !targetMediaFile.path.toLowerCase().endsWith('.mp4')) {
        final parentDir = targetMediaFile.parent;
        final v0 = File('${parentDir.path}/v_0000.ts');
        if (await v0.exists()) {
          try {
            debugPrint('[PlayerScreen] Found offline TS chunks, auto-muxing to MP4 for optimal offline playback...');
            if (mounted) setState(() => _loadingStep = _PlayerLoadingStep.preparingMp4);
            final vTemp = File('${parentDir.path}/temp_video.ts');
            final aTemp = File('${parentDir.path}/temp_audio.ts');
            final outMp4 = File('${parentDir.path}/video.mp4');

            final vSink = vTemp.openWrite();
            final chunks = parentDir.listSync().whereType<File>().toList();
            final vFiles = chunks.where((f) => f.path.split(RegExp(r'[\\/]')).last.startsWith('v_')).toList()
              ..sort((a, b) => a.path.compareTo(b.path));
            for (final f in vFiles) {
              await vSink.addStream(f.openRead());
            }
            await vSink.flush();
            await vSink.close();

            String? aTempPath;
            final aFiles = chunks.where((f) => f.path.split(RegExp(r'[\\/]')).last.startsWith('a_')).toList()
              ..sort((a, b) => a.path.compareTo(b.path));
            if (aFiles.isNotEmpty) {
              final aSink = aTemp.openWrite();
              for (final f in aFiles) {
                await aSink.addStream(f.openRead());
              }
              await aSink.flush();
              await aSink.close();
              if (await aTemp.exists() && (await aTemp.length()) > 1000) {
                aTempPath = aTemp.path;
              }
            }

            final success = await NativeMediaMuxer.muxToMp4(
              videoPath: vTemp.path,
              audioPath: aTempPath,
              outputPath: outMp4.path,
            );

            if (await vTemp.exists()) await vTemp.delete();
            if (await aTemp.exists()) await aTemp.delete();

            if (success && await outMp4.exists() && (await outMp4.length()) > 50000) {
              debugPrint('[PlayerScreen] Auto-muxing succeeded: ${outMp4.path}');
              targetMediaFile = outMp4;
              for (final f in [...vFiles, ...aFiles]) {
                try {
                  await f.delete();
                } catch (_) {}
              }
            }
          } catch (e) {
            debugPrint('[PlayerScreen] Auto-muxing note: $e');
          }
        }
      }

      _useNativePlayer = true;
      await _setupMpvOfflineOptions();

      // 3. Play media file directly without HTTP server if it is a container file (MP4, MKV, TS)
      final isSingleContainer = targetMediaFile.path.toLowerCase().endsWith('.mp4') ||
          targetMediaFile.path.toLowerCase().endsWith('.mkv') ||
          targetMediaFile.path.toLowerCase().endsWith('.ts');

      if (isSingleContainer) {
        debugPrint('[PlayerScreen] Playing offline native media directly from storage: ${targetMediaFile.path}');
        await _player.open(Media(targetMediaFile.path));
      } else {
        // Fallback for HLS manifest: try direct file path first, fallback to loopback HTTP server with cache:no
        try {
          debugPrint('[PlayerScreen] Attempting direct local HLS manifest open: ${targetMediaFile.path}');
          await _player.open(Media(targetMediaFile.path));
        } catch (_) {
          debugPrint('[PlayerScreen] Direct HLS failed, streaming via LocalStreamServer with zero-network cache');
          final port = await LocalStreamServer.instance.start();
          if (port == 0) {
            throw Exception('Gagal mengaktifkan server streaming lokal.');
          }

          final parentDir = targetMediaFile.parent.path;
          final fileName = targetMediaFile.path.split(RegExp(r'[\\/]')).where((s) => s.isNotEmpty).last;

          final streamUrl = LocalStreamServer.instance.getStreamUrl(
            dirPath: parentDir,
            fileName: fileName,
          );

          await _player.open(Media(streamUrl));
        }
      }

      await _player.setAudioTrack(AudioTrack.auto());
      await _player.setSubtitleTrack(SubtitleTrack.no());
      await _player.setVolume(_volume);
      await _player.play();

      final subPath = _currentLocalSubtitlePath ?? widget.localSubtitlePath;
      if (subPath != null && subPath.isNotEmpty) {
        try {
          final subFile = File(subPath);
          if (await subFile.exists()) {
            final content = await subFile.readAsString();
            final cues = SubtitleCue.parseSrt(content);
            ref.read(activeSubtitleCuesProvider.notifier).state = cues;
            debugPrint('[PlayerScreen] Loaded offline subtitle: ${cues.length} cues');
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
          _resolutionLabel = targetMediaFile.path.toLowerCase().endsWith('.mp4')
              ? (isId ? 'Lokal MP4' : 'Local MP4')
              : (isId ? 'Lokal' : 'Local');
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              s.playerOfflineFailedTitle,
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: Text(
              '${s.playerOfflineFailedDesc}\n\n$e',
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
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
    final s = ref.read(appStringsProvider);
    setState(() {
      _isLoading = true;
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
      if (resolved.tmdbId > 0) _currentTmdbId = resolved.tmdbId;
      if (resolved.imdbId != null && resolved.imdbId!.isNotEmpty) _currentImdbId = resolved.imdbId;
    } catch (e) {
      debugPrint('[PlayerScreen] resolveIds exception: $e');
    }

    if (_currentServer.isDirectHls) {
      try {
        // 1. Direct HLS Master Playlist extraction from VixSrc (native media_kit player)
        final vixResult = await VixSrcStreamService.resolveStream(
          tmdbId: _currentTmdbId,
          imdbId: _currentImdbId,
          season: _currentSeason,
          episode: _currentEpisode,
        );

        if (vixResult != null && vixResult.playlistUrl.isNotEmpty) {
          debugPrint('[PlayerScreen] Playing native Master HLS M3U8: ${vixResult.playlistUrl}');
          _useNativePlayer = true;
          _streamSubtitles = vixResult.subtitles;

          if (mounted) {
            setState(() {
              _loadingStep = _PlayerLoadingStep.preparingBuffer;
            });
          }

          // Apply fast initial buffer + 3-minute background cache before stream open
          await _setupMpvFastBufferOptions();

          // Opening the Master Playlist ensures full audio rendition is bound with video
          await _player.open(
            Media(
              vixResult.playlistUrl,
              httpHeaders: VixSrcStreamService.headers,
            ),
          );
          // CRITICAL: Disable mpv's internal subtitles so they do not bypass Cineva's settings!
          await _player.setSubtitleTrack(SubtitleTrack.no());
          await _player.setVolume(_volume);

          if (mounted) {
            setState(() {
              _isLoading = false;
              _currentQuality = 'Auto';
              _resolutionLabel = '1080p FHD';
            });
          }

          // Subtitles loaded asynchronously in background so video playback begins immediately!
          unawaited(_loadSubtitles());
          return;
        }
      } catch (e) {
        debugPrint('[PlayerScreen] VixSrc resolution exception: $e');
      }

      // If Direct HLS fails or returns 404 (e.g. Kimetsu No Yaiba, Naruto, or certain films),
      // intelligently auto-failover to Server 2: VidLink HD!
      debugPrint('[PlayerScreen] Direct HLS not available for this title. Auto-failover to VidLink HD...');
      _currentServer = SmartStreamService.servers[1]; // VidLink HD
      if (mounted) {
        setState(() {
          _customLoadingStatus = s.playerAutoSwitched(_currentServer.name);
        });
      }
    }

    // Load web streaming server with ad cleaner and stream sniffer
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

    debugPrint('[PlayerScreen] Loading web stream from ${server.name}: $streamUrl');

    final controller = WebViewController()
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
            if (mounted) setState(() => _loadingStep = _PlayerLoadingStep.preparingBackup);
          },
          onPageFinished: (url) async {
            try {
              // 1. Inject cinema ad-cleaner CSS to hide external web ads & intrusive overlays
              await _webViewController?.runJavaScript(
                "const style = document.createElement('style');"
                "style.innerHTML = `${SmartStreamService.cinemaCleanerCss.replaceAll('`', r'\`')}`;"
                "document.head.appendChild(style);"
              );
              // 2. Inject stream sniffer JS to detect .m3u8 / .mp4 video stream URLs
              await _webViewController?.runJavaScript(SmartStreamService.streamSnifferJs);
            } catch (_) {}
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            final url = request.url.toLowerCase();
            if (url.startsWith('intent://') ||
                url.startsWith('market://') ||
                url.contains('play.google.com') ||
                url.contains('shopee') ||
                url.contains('lazada') ||
                url.contains('casino') ||
                url.contains('betting') ||
                url.contains('adclick') ||
                url.contains('doubleclick')) {
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
        _isLoading = false;
      });
      unawaited(_loadSubtitles());
    }
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
            !directUrl.contains('doubleclick') &&
            !directUrl.contains('googleads')) {
          _upgradeToNativePlayer(directUrl);
        }
      } else if (type == 'TIME_UPDATE') {
        final timeMs = data['timeMs'] as int?;
        if (timeMs != null && !_useNativePlayer && mounted) {
          _positionNotifier.value = Duration(milliseconds: timeMs);
        }
      }
    } catch (e) {
      debugPrint('[PlayerScreen] Bridge message parse error: $e');
    }
  }

  Future<void> _upgradeToNativePlayer(String directStreamUrl) async {
    if (_useNativePlayer) return;
    debugPrint('[PlayerScreen] Sniffed direct stream URL! Upgrading to native player: $directStreamUrl');
    try {
      // Pause & clear webview
      await _webViewController?.runJavaScript(
        'var v = document.querySelector("video"); if (v) { v.pause(); v.src = ""; v.load(); }'
      );
      await _setupMpvFastBufferOptions();
      await _player.open(Media(directStreamUrl));
      await _player.setSubtitleTrack(SubtitleTrack.no());
      await _player.setVolume(_volume);

      if (mounted) {
        setState(() {
          _useNativePlayer = true;
          _isLoading = false;
          _currentQuality = 'Auto';
          _resolutionLabel = '1080p FHD';
        });
      }
      unawaited(_loadSubtitles());
    } catch (e) {
      debugPrint('[PlayerScreen] Failed to upgrade sniffed stream: $e');
    }
  }

  Future<void> _switchServer(SmartStreamServer server) async {
    if (_currentServer.id == server.id && !_isLoading) {
      setState(() => _activePopup = _PlayerMiniPopup.none);
      return;
    }

    setState(() {
      _currentServer = server;
      _activePopup = _PlayerMiniPopup.none;
      _isLoading = true;
      _loadingStep = _PlayerLoadingStep.connecting;
      _customLoadingStatus = ref.read(appStringsProvider).playerServerSwitched(server.name);
    });

    try {
      await _player.pause();
      await _player.stop();
    } catch (_) {}

    try {
      await _webViewController?.runJavaScript(
        'var v = document.querySelector("video"); if (v) { v.pause(); v.src = ""; v.load(); }'
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

  Future<void> _setQuality(String quality) async {
    setState(() {
      _currentQuality = quality;
      if (quality == 'Auto') {
        _resolutionLabel = 'Auto (1080p)';
      } else if (quality == '360p' || quality == '480p') {
        _resolutionLabel = '$quality SD';
      } else {
        _resolutionLabel = '$quality HD';
      }
      _activePopup = _PlayerMiniPopup.none;
    });

    // In media_kit, video tracks on HLS master playlists can be selected
    final videoTracks = _player.state.tracks.video;
    if (videoTracks.length > 1) {
      if (quality == 'Auto') {
        await _player.setVideoTrack(VideoTrack.auto());
      } else {
        final targetH = int.tryParse(quality.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1080;
        VideoTrack? matchedTrack = videoTracks.where((t) => (t.h ?? 0) == targetH).firstOrNull;
        if (matchedTrack == null) {
          final sorted = List<VideoTrack>.from(videoTracks)
            ..sort((a, b) => (a.h ?? 0).compareTo(b.h ?? 0));
          matchedTrack = sorted.where((t) => (t.h ?? 0) <= targetH).lastOrNull ?? sorted.first;
        }
        await _player.setVideoTrack(matchedTrack);
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

  // ── Unified Custom Controls ──

  void _togglePlayPause() {
    _resetControlsTimer();
    if (_useNativePlayer) {
      _player.playOrPause();
    } else {
      _webViewController?.runJavaScript(
        'var v = document.querySelector("video"); if (v) { if (v.paused) { v.play(); } else { v.pause(); } }'
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
        'var v = document.querySelector("video"); if (v) { v.currentTime = Math.max(0, v.currentTime + $seconds); }'
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
        'var v = document.querySelector("video"); if (v) { v.currentTime = $seconds; }'
      );
    }
  }

  void _resetControlsTimer() {
    _controlsTimer?.cancel();
    if (_activePopup != _PlayerMiniPopup.none) return; // Keep controls active when popup is open
    _controlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _activePopup == _PlayerMiniPopup.none) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    if (_isLoading) return; // Do not toggle controls while processing/searching server
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

  void _togglePopup(_PlayerMiniPopup popup) {
    setState(() {
      if (_activePopup == popup) {
        _activePopup = _PlayerMiniPopup.none;
        _isShowingSubtitleSettingsInPopup = false;
        _resetControlsTimer();
      } else {
        _activePopup = popup;
        if (popup == _PlayerMiniPopup.subtitle) {
          _isShowingSubtitleSettingsInPopup = false;
        }
        _controlsTimer?.cancel();
      }
    });
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
    _saveWatchHistory(force: true);

    if (mounted) {
      setState(() {
        _nextEpisodeButtonVisible = false;
        _showControls = false;
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
      debugPrint('[PlayerScreen] Error stopping native player on next episode: $e');
    }

    // 2. Kill WebView playback & audio if web player was active
    try {
      await _webViewController?.runJavaScript(
        'var v = document.querySelector("video"); if (v) { v.pause(); v.src = ""; v.load(); }'
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
    _initialPositionMs = null;
    _activePopup = _PlayerMiniPopup.none;

    // 5. Advance episode state
    _currentEpisode = nextEp;
    _currentEpisodeTitle = 'Episode $nextEp';

    // Check if the next episode was downloaded locally
    String? nextLocalVideo;
    String? nextLocalSub;
    try {
      final downloadItems = ref.read(downloadManagerProvider);
      final nextDownload = downloadItems.where((d) =>
        d.tmdbId == widget.tmdbId &&
        d.mediaType == 'tv' &&
        d.seasonNumber == _currentSeason &&
        d.episodeNumber == nextEp &&
        d.status == DownloadStatus.completed
      ).firstOrNull;

      if (nextDownload != null) {
        final f = File(nextDownload.videoPath);
        if (f.existsSync() && f.lengthSync() > 10000) {
          nextLocalVideo = nextDownload.videoPath;
          nextLocalSub = nextDownload.subtitlePath;
          debugPrint('[PlayerScreen] Next episode found in offline downloads: $nextLocalVideo');
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
      if ((_currentLocalVideoPath != null && _currentLocalVideoPath!.isNotEmpty) ||
          (widget.localVideoPath != null && widget.localVideoPath!.isNotEmpty)) {
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
            color: Colors.black.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 12,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 6,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
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
              style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.18) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    size: 16,
                    color: isSelected ? AppColors.primary : AppColors.textMuted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? AppColors.primary : Colors.white,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
                _volume > 100.0 ? 'Boost: ${_volume.toInt()}%' : 'Level: ${_volume.toInt()}%',
                style: TextStyle(
                  color: _volume > 100.0 ? AppColors.primary : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              if (_volume > 100.0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(s.playerAudioBoost, style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              activeTrackColor: _volume > 100.0 ? AppColors.primary : Colors.white,
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
      title: _isShowingSubtitleSettingsInPopup ? s.playerSubSettingsTitle : s.playerSubtitleTrack,
      icon: _isShowingSubtitleSettingsInPopup ? Iconsax.setting_2 : Iconsax.subtitle,
      leading: _isShowingSubtitleSettingsInPopup
          ? GestureDetector(
              onTap: () => setState(() => _isShowingSubtitleSettingsInPopup = false),
              child: const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
              ),
            )
          : null,
      trailing: !_isShowingSubtitleSettingsInPopup
          ? GestureDetector(
              onTap: () => setState(() => _isShowingSubtitleSettingsInPopup = true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconsax.setting_2, size: 12, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      s.playerSubSettings,
                      style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
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
            begin: isSettings ? const Offset(0.35, 0.0) : const Offset(-0.35, 0.0),
            end: Offset.zero,
          );
          return SlideTransition(
            position: inTween.animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: _isShowingSubtitleSettingsInPopup
            ? _buildSubtitleSettingsContent(s, key: const ValueKey('sub_settings_view'))
            : _buildSubtitleTracksContent(s, key: const ValueKey('sub_tracks_view')),
      ),
    );
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
              color: _selectedSubtitle == null ? AppColors.primary.withValues(alpha: 0.18) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  _selectedSubtitle == null ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: _selectedSubtitle == null ? AppColors.primary : AppColors.textMuted,
                ),
                const SizedBox(width: 10),
                Text(s.playerDisableSubtitle, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
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
                const Icon(Iconsax.setting_2, size: 16, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.playerSubSettings,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.primary),
              ],
            ),
          ),
        ),

        // Border pembatas yang smooth
        const Divider(color: Colors.white12, height: 16),

        // 3. 1-Tap Auto-Translate Action (TANPA BORDER, border pembatas smooth)
        if (_selectedSubtitle != null && _selectedSubtitle!.language.toLowerCase() != targetLangCode.toLowerCase()) ...[
          if (_isAutoTranslating) ...[
            LinearProgressIndicator(
              value: _translationProgress > 0 ? _translationProgress : null,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceElevated,
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(s.playerTranslatingTo(targetLangObj.name), style: const TextStyle(color: AppColors.primary, fontSize: 11)),
            ),
          ] else ...[
            InkWell(
              onTap: () {
                _applyAndAutoTranslateSubtitle(_selectedSubtitle!, targetLang: targetLangCode);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  // TANPA BORDER!
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Iconsax.magic_star, color: AppColors.primary, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      _isSubtitleTranslated
                          ? s.playerTranslateActive(targetLangCode.toUpperCase())
                          : s.playerTranslateTo(targetLangObj.name),
                      style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
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
              child: Text(s.playerNoSubtitleFound, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ),
          )
        else
          ..._availableSubtitles.map((sub) {
            final isSelected = _selectedSubtitle?.id == sub.id;
            final isPreferred = sub.language.toLowerCase() == targetLangCode.toLowerCase();

            return InkWell(
              onTap: () async {
                final success = await _applySubtitle(sub);
                if (!success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(s.playerFailedDownloadSub(sub.languageName)),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.18) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      size: 16,
                      color: isSelected ? AppColors.primary : AppColors.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPreferred ? AppColors.success.withValues(alpha: 0.25) : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        sub.language.toUpperCase(),
                        style: TextStyle(
                          color: isPreferred ? AppColors.success : Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sub.fileName.isNotEmpty ? sub.fileName : sub.languageName,
                        style: TextStyle(
                          color: isSelected ? AppColors.primary : Colors.white,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sub-tabs: Sync vs Tampilan
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _subtitleSettingsTab = 0),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: _subtitleSettingsTab == 0 ? AppColors.primary : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      s.playerTabSync,
                      style: TextStyle(
                        color: _subtitleSettingsTab == 0 ? Colors.black : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _subtitleSettingsTab = 1),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: _subtitleSettingsTab == 1 ? AppColors.primary : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      s.playerTabAppearance,
                      style: TextStyle(
                        color: _subtitleSettingsTab == 1 ? Colors.black : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Content of selected tab
        if (_subtitleSettingsTab == 0) ...[
          // Sync offset tab
          Center(
            child: Column(
              children: [
                Text(
                  style.syncOffsetMs == 0
                      ? s.playerSyncOnTime
                      : '${style.syncOffsetMs > 0 ? "+" : ""}${(style.syncOffsetMs / 1000.0).toStringAsFixed(2)}s',
                  style: TextStyle(
                    color: style.syncOffsetMs != 0 ? AppColors.primary : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  style.syncOffsetMs == 0
                      ? s.playerSyncDefault
                      : style.syncOffsetMs > 0
                          ? s.playerSyncDelayed
                          : s.playerSyncAdvanced,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSyncChip('-500ms', () => notifier.adjustSyncOffset(-500)),
              const SizedBox(width: 6),
              _buildSyncChip('-100ms', () => notifier.adjustSyncOffset(-100)),
              const SizedBox(width: 6),
              OutlinedButton(
                onPressed: () => notifier.resetSyncOffset(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(48, 30),
                  side: const BorderSide(color: AppColors.surfaceElevated),
                ),
                child: Text(s.playerReset, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ),
              const SizedBox(width: 6),
              _buildSyncChip('+100ms', () => notifier.adjustSyncOffset(100)),
              const SizedBox(width: 6),
              _buildSyncChip('+500ms', () => notifier.adjustSyncOffset(500)),
            ],
          ),
        ] else ...[
          // Style & Background Tab (live sliders)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                  // Background Opacity Controls (Transparan vs Background)
                  Text(s.playerSubBackground, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildBgChip(s.playerBgTransparent, 0.0, style.backgroundOpacity, notifier),
                      const SizedBox(width: 6),
                      _buildBgChip('Semi 40%', 0.4, style.backgroundOpacity, notifier),
                      const SizedBox(width: 6),
                      _buildBgChip('${s.playerBgDark} 75%', 0.75, style.backgroundOpacity, notifier),
                      const SizedBox(width: 6),
                      _buildBgChip('${s.playerBgSolid} 100%', 1.0, style.backgroundOpacity, notifier),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(width: 80, child: Text(s.playerBgOpacity, style: const TextStyle(color: Colors.white70, fontSize: 11))),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
                          child: Slider(
                            value: style.backgroundOpacity,
                            min: 0.0,
                            max: 1.0,
                            divisions: 20,
                            activeColor: AppColors.primary,
                            onChanged: (v) => notifier.updateBackgroundOpacity(v),
                          ),
                        ),
                      ),
                      Text('${(style.backgroundOpacity * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 12),

                  // Font Size Slider
                  Row(
                    children: [
                      SizedBox(width: 80, child: Text(s.playerFontSize, style: const TextStyle(color: Colors.white70, fontSize: 11))),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
                          child: Slider(
                            value: style.fontSize,
                            min: 14.0,
                            max: 30.0,
                            divisions: 8,
                            activeColor: AppColors.primary,
                            onChanged: (v) => notifier.updateFontSize(v),
                          ),
                        ),
                      ),
                      Text('${style.fontSize.toInt()}pt', style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ],
                  ),

                  // Stroke Thickness Slider
                  Row(
                    children: [
                      SizedBox(width: 80, child: Text(s.playerStrokeWidth, style: const TextStyle(color: Colors.white70, fontSize: 11))),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
                          child: Slider(
                            value: style.strokeWidth,
                            min: 0.0,
                            max: 5.0,
                            divisions: 10,
                            activeColor: AppColors.primary,
                            onChanged: (v) => notifier.updateStrokeWidth(v),
                          ),
                        ),
                      ),
                      Text('${style.strokeWidth.toStringAsFixed(1)}px', style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ],
                  ),

                  // Bottom Offset Slider
                  Row(
                    children: [
                      SizedBox(width: 80, child: Text(s.playerSubPosition, style: const TextStyle(color: Colors.white70, fontSize: 11))),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
                          child: Slider(
                            value: style.bottomOffset.clamp(10.0, 120.0),
                            min: 10.0,
                            max: 120.0,
                            divisions: 22,
                            activeColor: AppColors.primary,
                            onChanged: (v) => notifier.updateBottomOffset(v),
                          ),
                        ),
                      ),
                      Text('${style.bottomOffset.toInt()}px', style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ],
                  ),

                  // Color selection chips
                  Row(
                    children: [
                      SizedBox(width: 80, child: Text(s.playerSubColor, style: const TextStyle(color: Colors.white70, fontSize: 11))),
                      _buildColorMiniDot(const Color(0xFFFFFFFF), style.textColor, notifier),
                      const SizedBox(width: 8),
                      _buildColorMiniDot(const Color(0xFFFFD700), style.textColor, notifier),
                      const SizedBox(width: 8),
                      _buildColorMiniDot(const Color(0xFF00E5FF), style.textColor, notifier),
                      const SizedBox(width: 8),
                      _buildColorMiniDot(const Color(0xFF00E676), style.textColor, notifier),
                    ],
                  ),
                ],
              ),
        ],
      ],
    );
  }

  Widget _buildSubtitleSettingsMiniPopup(AppStrings s) {
    _isShowingSubtitleSettingsInPopup = true;
    return _buildSubtitleMiniPopup(s);
  }

  Widget _buildBgChip(String label, double val, double current, dynamic notifier) {
    final isSelected = (current - val).abs() < 0.05;
    return InkWell(
      onTap: () => notifier.updateBackgroundOpacity(val),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSyncChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildColorMiniDot(Color color, Color current, dynamic notifier) {
    final isSelected = color.toARGB32() == current.toARGB32();
    return GestureDetector(
      onTap: () => notifier.updateTextColor(color),
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white24,
            width: isSelected ? 2.5 : 1.0,
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
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ),
          ...SmartStreamService.servers.map((srv) {
            final isSelected = _currentServer.id == srv.id;
            return InkWell(
              onTap: () => _switchServer(srv),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.18) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected ? Border.all(color: AppColors.primary.withValues(alpha: 0.5)) : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      size: 16,
                      color: isSelected ? AppColors.primary : AppColors.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            srv.name,
                            style: TextStyle(
                              color: isSelected ? AppColors.primary : Colors.white,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: srv.isDirectHls
                            ? const Color(0xFF00E676).withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        srv.isDirectHls ? 'DIRECT' : 'HD',
                        style: TextStyle(
                          color: srv.isDirectHls ? const Color(0xFF00E676) : Colors.white70,
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
            border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1.2),
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
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
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
                          child: const Icon(Icons.close, color: Colors.white70, size: 14),
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
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
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
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.skip_next_rounded, color: AppColors.primary, size: 12),
                                const SizedBox(width: 2),
                                Text(
                                  'Next Ep ${(_currentEpisode ?? 1) + 1}',
                                  style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
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

          // Mini Popup Button: Server Switcher (Smart Stream Engine) - Icon only without border
          if (_currentLocalVideoPath == null && widget.localVideoPath == null)
            _buildTopBarIconButton(
              icon: Icons.dns_rounded,
              isActive: _activePopup == _PlayerMiniPopup.server,
              onTap: () => _togglePopup(_PlayerMiniPopup.server),
            ),

          // Mini Popup Button: Resolution & Quality (Native Player only) - Icon only without border
          if (_useNativePlayer)
            _buildTopBarIconButton(
              icon: Icons.high_quality_rounded,
              isActive: _activePopup == _PlayerMiniPopup.quality,
              onTap: () => _togglePopup(_PlayerMiniPopup.quality),
            ),

          // Mini Popup Button: Volume & Audio Boost (Native Player only) - Icon only without border
          if (_useNativePlayer)
            _buildTopBarIconButton(
              icon: _volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              isActive: _activePopup == _PlayerMiniPopup.volume,
              onTap: () => _togglePopup(_PlayerMiniPopup.volume),
            ),

          // Mini Popup Button: Subtitle Selection (Includes Atur Sub) - Icon only without border
          _buildTopBarIconButton(
            icon: Iconsax.subtitle,
            isActive: _activePopup == _PlayerMiniPopup.subtitle,
            inactiveColor: _selectedSubtitle != null ? AppColors.primary : Colors.white,
            onTap: () => _togglePopup(_PlayerMiniPopup.subtitle),
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
        await _handleExit();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Video Layer: Passes all the way through camera cutout / notch ──
          if (_useNativePlayer)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggleControls,
              // Vertical swipe gesture on right half of screen to adjust volume
              onVerticalDragUpdate: (details) {
                final screenWidth = MediaQuery.of(context).size.width;
                if (details.globalPosition.dx > screenWidth / 2) {
                  // Drag up increases volume, drag down decreases volume
                  final delta = -details.primaryDelta! * 0.5;
                  _setVolume(_volume + delta);
                }
              },
              child: Video(
                controller: _videoController,
                controls: NoVideoControls, // Guarantees NO built-in media_kit controls!
                subtitleViewConfiguration: const SubtitleViewConfiguration(
                  visible: false, // Ensures media_kit never renders its own internal subtitle
                ),
                fit: _fitMode,
              ),
            )
          else if (_webViewController != null)
            WebViewWidget(controller: _webViewController!)
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                        color: _volume > 100.0 ? AppColors.primary : Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _volume > 100.0 ? 'Volume: ${_volume.toInt()}% (Boost)' : 'Volume: ${_volume.toInt()}%',
                        style: TextStyle(
                          color: _volume > 100.0 ? AppColors.primary : Colors.white,
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
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
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
                              padding: const EdgeInsets.symmetric(horizontal: 40),
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
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Unified center buffering indicator when controls are hidden: pure orange spinner, no background box
            if (_useNativePlayer && !_showControls && _isBuffering && !_isLoading)
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

                        // ── 5. Native Mode: The ONLY Control Overlay: Cineva Custom Cinema Controls ──
            if (!_isLoading && _useNativePlayer)
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // ── Top Navigation & Quality Bar ──
                          _buildTopBar(s),

                          // ── Center Controls (Native Player Only) ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: () => _seekRelative(-10),
                                icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 44),
                              ),
                              const SizedBox(width: 36),
                              GestureDetector(
                                onTap: _isBuffering ? null : _togglePlayPause,
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: _isBuffering
                                      ? const SizedBox(
                                          width: 54,
                                          height: 54,
                                          child: CircularProgressIndicator(
                                            color: AppColors.primary,
                                            strokeWidth: 3.5,
                                          ),
                                        )
                                      : Icon(
                                          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                          color: AppColors.primary,
                                          size: 58,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 36),
                              IconButton(
                                onPressed: () => _seekRelative(10),
                                icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 44),
                              ),
                            ],
                          ),

                          // ── Bottom Timeline Scrubber (Native Player Only) ──
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
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
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Expanded(
                                      child: SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          trackHeight: 3.5,
                                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                          activeTrackColor: AppColors.primary,
                                          inactiveTrackColor: Colors.white24,
                                          thumbColor: AppColors.primary,
                                        ),
                                        child: Slider(
                                          value: _duration.inSeconds > 0
                                              ? pos.inSeconds
                                                  .toDouble()
                                                  .clamp(0.0, _duration.inSeconds.toDouble())
                                              : 0.0,
                                          min: 0.0,
                                          max: _duration.inSeconds > 0
                                              ? _duration.inSeconds.toDouble()
                                              : 1.0,
                                          onChanged: (v) => _seekTo(v),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(_duration),
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    // Fit mode toggle (cover / contain / fill)
                                    IconButton(
                                      onPressed: _toggleFitMode,
                                      tooltip: 'Aspect Ratio & Notch Mode',
                                      icon: Icon(
                                        _fitMode == BoxFit.cover ? Icons.fullscreen_rounded : Icons.aspect_ratio_rounded,
                                        color: _fitMode == BoxFit.cover ? AppColors.primary : Colors.white70,
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

            // ── 5.1 Web Mode: Top Navigation & Server Switcher Bar ONLY (Zero Double Controls!) ──
            if (!_isLoading && !_useNativePlayer) ...[
              // Top touch area to reveal top bar if hidden
              if (!_showControls)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 48,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      setState(() => _showControls = true);
                      _resetControlsTimer();
                    },
                  ),
                ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
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
                            Colors.black.withValues(alpha: 0.9),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: _buildTopBar(s),
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // ── 5.5 Floating TV Series Next Episode Action (Native Player <= 60s remaining) ──
            if (!_isLoading &&
                _useNativePlayer &&
                _nextEpisodeButtonVisible &&
                (_currentSeason != null && _currentEpisode != null))
              Positioned(
                bottom: _showControls ? 78 : 28,
                right: 28,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildSkipPillButton(
                    key: ValueKey('tv_next_episode_$_currentEpisode'),
                    icon: Icons.skip_next_rounded,
                    label: s.playerNextEpisodePill((_currentEpisode ?? 1) + 1),
                    onTap: _playNextEpisode,
                  ),
                ),
              ),

// ── 6. Compact Semi-Transparent Mini Popups Layer ──
            if (!_isLoading && _activePopup != _PlayerMiniPopup.none) ...[
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
                  _PlayerMiniPopup.quality => _buildQualityMiniPopup(s),
                  _PlayerMiniPopup.volume => _buildVolumeMiniPopup(s),
                  _PlayerMiniPopup.subtitle => _buildSubtitleMiniPopup(s),
                  _PlayerMiniPopup.subtitleSettings => _buildSubtitleSettingsMiniPopup(s),
                  _PlayerMiniPopup.server => _buildServerMiniPopup(s),
                  _PlayerMiniPopup.none => const SizedBox.shrink(),
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
