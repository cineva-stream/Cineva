import 'dart:async';
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
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/subtitle_cue.dart';
import '../../data/services/subtitle_service.dart';
import '../../data/services/subtitle_translator_service.dart';
import '../../data/services/vixsrc_stream_service.dart';
import '../../../settings/data/settings_service.dart';
import '../../../history/data/models/watch_history_item.dart';
import '../../../history/data/repositories/watch_history_repository.dart';
import '../providers/player_providers.dart';
import '../widgets/custom_subtitle_overlay.dart';

enum _PlayerMiniPopup { none, quality, subtitle, subtitleSettings, volume }

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

  // ── Playback State ──
  bool _isLoading = true;
  bool _isBuffering = false;
  String _loadingStatus = 'Mencari stream berkecepatan tinggi...';
  String _resolutionLabel = '1080p FHD';
  String _currentQuality = 'Auto';
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
  bool _showControls = true;
  Timer? _controlsTimer;
  _PlayerMiniPopup _activePopup = _PlayerMiniPopup.none;
  int _subtitleSettingsTab = 0; // 0: Waktu (Sync), 1: Tampilan

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
    _setupMpvFastBufferOptions();
    _initializeStreaming();
    _resetControlsTimer();
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
      _player.stop();
    } catch (_) {}

    try {
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
    final mediaType = widget.mediaType ?? (widget.season != null ? 'tv' : 'movie');
    final repo = ref.read(watchHistoryRepositoryProvider);
    final item = repo.getItem(mediaType, widget.tmdbId!);
    if (item != null && !item.isCompleted && item.positionMs > 5000) {
      if (mediaType == 'tv') {
        if (item.season == widget.season && item.episode == widget.episode) {
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
    final mediaType = widget.mediaType ?? (widget.season != null ? 'tv' : 'movie');

    final item = WatchHistoryItem(
      id: tmdbId,
      mediaType: mediaType,
      title: widget.title,
      episodeTitle: widget.episodeTitle,
      season: widget.season,
      episode: widget.episode,
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
      if (_isLoading && pos.inMilliseconds > 0) {
        if (mounted) setState(() => _isLoading = false);
      }

      // Restore position once video duration is known and playback starts
      if (!_hasRestoredPosition && _duration.inMilliseconds > 0 && pos.inMilliseconds > 0) {
        _hasRestoredPosition = true;
        final resumeMs = widget.initialPositionMs ?? _getSavedPositionMs();
        if (resumeMs != null && resumeMs > 5000 && resumeMs < _duration.inMilliseconds - 10000) {
          debugPrint('[PlayerScreen] Resuming playback at ${resumeMs}ms');
          _player.seek(Duration(milliseconds: resumeMs));
        }
      }

      // ── TV Series Next Episode (Auto when <= 5s, Manual button when <= 60s) ──
      final isTv = widget.season != null && widget.episode != null;
      if (isTv && _duration.inSeconds > 30) {
        final remainingSecs = (_duration - pos).inSeconds;

        // Auto next episode when 5 seconds or less remain
        if (remainingSecs <= 5 && remainingSecs >= 0 && !_hasAutoPlayedNext) {
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
        if (inNextEpisodeWindow) {
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
        });
      }
    });
    _bufferingSub = _player.stream.buffering.listen((buffering) {
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
        final subs = await subService.searchByImdbId(
          widget.imdbId!,
          language: 'id,en',
          seasonNumber: widget.season,
          episodeNumber: widget.episode,
        );
        allSubs.addAll(subs);
      }

      if (!mounted) return;
      setState(() => _availableSubtitles = allSubs);

      if (allSubs.isEmpty) {
        debugPrint('[PlayerScreen] No subtitles found anywhere');
        return;
      }

      if (prefLang == 'id') {
        // Priority 1: Native Indonesian subtitle (either from stream or OpenSubtitles)
        final idSub = allSubs.where((s) => s.language.toLowerCase() == 'id').firstOrNull;
        if (idSub != null) {
          debugPrint('[PlayerScreen] Native Indonesian subtitle found: ${idSub.fileName}');
          final success = await _applySubtitle(idSub);
          if (success) {
            _showToastSubtitle('Subtitle Bahasa Indonesia aktif');
            return;
          }
          debugPrint('[PlayerScreen] Native Indonesian subtitle download failed, falling back to auto-translation...');
        }

        // Priority 2: Fallback to English / available track + Auto-translate
        final autoTranslate = SettingsService.getAutoTranslate();
        // Prefer English from _streamSubtitles because it never 503s and is on CDN
        final fallbackSub = _streamSubtitles.where((s) => s.language.toLowerCase() == 'en').firstOrNull
            ?? allSubs.where((s) => s.language.toLowerCase() == 'en').firstOrNull
            ?? allSubs.first;
        debugPrint('[PlayerScreen] Fallback to ${fallbackSub.languageName} (Auto-translate: $autoTranslate)');

        if (autoTranslate) {
          final translated = await _applyAndAutoTranslateSubtitle(fallbackSub);
          if (!translated) {
            await _applySubtitle(fallbackSub);
            _showToastSubtitle('Subtitle ${fallbackSub.languageName} aktif');
          }
        } else {
          await _applySubtitle(fallbackSub);
          _showToastSubtitle('Subtitle ${fallbackSub.languageName} aktif');
        }
      } else if (prefLang == 'en') {
        final enSub = _streamSubtitles.where((s) => s.language.toLowerCase() == 'en').firstOrNull
            ?? allSubs.where((s) => s.language.toLowerCase() == 'en').firstOrNull
            ?? allSubs.first;
        await _applySubtitle(enSub);
        _showToastSubtitle('Subtitle ${enSub.languageName} aktif');
      } else {
        await _applySubtitle(allSubs.first);
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
                            SubtitleTranslatorService.refineIndonesianPronouns(c.text))
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

  Future<bool> _applyAndAutoTranslateSubtitle(SubtitleInfo sub) async {
    setState(() {
      _selectedSubtitle = sub;
      _isAutoTranslating = true;
      _translationProgress = 0.0;
    });

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

            final translator = ref.read(subtitleTranslatorServiceProvider);
            final cacheKey = 'sub_${widget.imdbId ?? widget.tmdbId}_auto_id_${sub.id.hashCode}_s${widget.season ?? 0}_e${widget.episode ?? 0}';

            final translatedCues = await translator.translateCuesToIndonesian(
              cues: originalCues,
              cacheKey: cacheKey,
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
              _showToastSubtitle('Subtitle otomatis diterjemahkan ke Bahasa Indonesia');
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

    setState(() {
      _isLoading = true;
      _loadingStatus = 'Menghubungkan stream video & audio...';
    });

    try {
      // 0. Offline Local File Playback (Downloaded Videos)
      if (widget.localVideoPath != null && widget.localVideoPath!.isNotEmpty) {
        debugPrint('[PlayerScreen] Playing local offline file: ${widget.localVideoPath}');
        final localFile = File(widget.localVideoPath!);
        if (!await localFile.exists()) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File unduhan tidak ditemukan atau rusak. Silakan unduh ulang.'),
                backgroundColor: Colors.redAccent,
              ),
            );
            Navigator.of(context).pop();
          }
          return;
        }

        _useNativePlayer = true;
        try {
          final mpv = (_player.platform as dynamic);
          await mpv?.command(['set', 'demuxer-lavf-analyzeduration', '0.5']);
        } catch (_) {}

        await _player.open(Media(widget.localVideoPath!));
        await _player.setSubtitleTrack(SubtitleTrack.no());
        await _player.setVolume(_volume);

        if (widget.localSubtitlePath != null && widget.localSubtitlePath!.isNotEmpty) {
          try {
            final subFile = File(widget.localSubtitlePath!);
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
          setState(() {
            _isLoading = false;
            _currentQuality = 'Lokal';
            _resolutionLabel = 'Offline';
          });
        }
        return;
      }

      // 1. Direct HLS Master Playlist extraction from VixSrc (includes full English audio track)
      final vixResult = await VixSrcStreamService.resolveStream(
        tmdbId: widget.tmdbId,
        imdbId: widget.imdbId,
        season: widget.season,
        episode: widget.episode,
      );

      if (vixResult != null && vixResult.playlistUrl.isNotEmpty) {
        debugPrint('[PlayerScreen] Playing native Master HLS M3U8: ${vixResult.playlistUrl}');
        _useNativePlayer = true;
        _streamSubtitles = vixResult.subtitles;

        if (mounted) {
          setState(() {
            _loadingStatus = 'Menyiapkan pemutaran cepat (buffer 7 detik)...';
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

    // 2. Fallback to Web Player if direct extraction fails
    debugPrint('[PlayerScreen] Falling back to Web Stream...');
    _useNativePlayer = false;
    final fallbackUrl = _buildFallbackUrl();

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) setState(() => _loadingStatus = 'Menyiapkan pemutar cadangan...');
          },
          onPageFinished: (url) {
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
                url.contains('betting')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    await controller.loadRequest(Uri.parse(fallbackUrl));

    if (mounted) {
      setState(() {
        _webViewController = controller;
        _isLoading = false;
      });
    }
  }

  String _buildFallbackUrl() {
    final cleanImdb = widget.imdbId != null && widget.imdbId!.isNotEmpty
        ? (widget.imdbId!.startsWith('tt') ? widget.imdbId! : 'tt${widget.imdbId}')
        : '';
    final s = widget.season ?? 1;
    final e = widget.episode ?? 1;

    if (widget.season != null && widget.episode != null) {
      return cleanImdb.isNotEmpty
          ? 'https://vidsrc.sh/embed/tv?imdb=$cleanImdb&season=$s&episode=$e'
          : 'https://vidsrc.sh/embed/tv?tmdb=${widget.tmdbId ?? 1399}&season=$s&episode=$e';
    } else {
      return cleanImdb.isNotEmpty
          ? 'https://vidsrc.sh/embed/movie?imdb=$cleanImdb'
          : 'https://vidsrc.sh/embed/movie?tmdb=${widget.tmdbId ?? 76600}';
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
        'var v = document.querySelector("video"); if (v) { v.paused ? v.play() : v.pause(); }'
      );
      setState(() => _isPlaying = !_isPlaying);
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
        'var v = document.querySelector("video"); if (v) { v.currentTime += $seconds; }'
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
        _resetControlsTimer();
      } else {
        _activePopup = popup;
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

  void _playNextEpisode() {
    setState(() => _nextEpisodeButtonVisible = false);
    if (widget.season == null || widget.episode == null) return;
    final nextEp = widget.episode! + 1;
    _saveWatchHistory(force: true);

    context.pushReplacementNamed(
      'player',
      extra: {
        'magnetLink': '',
        'title': widget.title,
        'imdbId': widget.imdbId,
        'season': widget.season,
        'episode': nextEp,
        'tmdbId': widget.tmdbId,
        'mediaType': 'tv',
        'posterPath': widget.posterPath,
        'backdropPath': widget.backdropPath,
        'episodeTitle': 'Episode $nextEp',
        'initialPositionMs': 0,
      },
    );
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

  Future<void> _launchExternalVlc() async {
    final magnet = widget.magnetLink;
    if (magnet.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pemutar langsung 60 FPS aktif di dalam aplikasi.'),
          backgroundColor: AppColors.surfaceVariant,
        ),
      );
      return;
    }

    try {
      final uri = Uri.parse(magnet);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        _showVlcNoticeDialog(magnet);
      }
    } catch (_) {
      if (mounted) _showVlcNoticeDialog(magnet);
    }
  }

  void _showVlcNoticeDialog(String magnet) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Iconsax.video_play, color: AppColors.primary, size: 24),
            SizedBox(width: 10),
            Text('Putar di VLC', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aplikasi VLC for Android siap memutar video dengan akselerasi perangkat keras 60 FPS bebas lag.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            SizedBox(height: 12),
            Text(
              'Salin link magnet jika VLC tidak terbuka otomatis:',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Clipboard.setData(ClipboardData(text: magnet));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Link magnet berhasil disalin!'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Iconsax.copy, size: 16),
            label: const Text('Salin Magnet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
          ),
        ],
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

  Widget _buildQualityMiniPopup() {
    const qualities = ['Auto', '1080p', '720p', '480p', '360p'];

    return _buildMiniPopupContainer(
      width: 250,
      title: 'Kualitas Video',
      icon: Iconsax.video_play,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: qualities.map((q) {
          final isSelected = _currentQuality == q;
          String label = q == 'Auto' ? 'Auto (Adaptif FHD)' : '$q HD';
          if (q == '1080p') label = '1080p FHD (Jernih)';
          if (q == '720p') label = '720p HD (Standar)';
          if (q == '480p') label = '480p SD (Hemat Kuota)';
          if (q == '360p') label = '360p Rendah (< 500 Kbps)';

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
        }).toList(),
      ),
    );
  }

  Widget _buildVolumeMiniPopup() {
    return _buildMiniPopupContainer(
      width: 270,
      title: 'Volume & Pengeras Suara',
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
                  child: const Text('Audio Boost', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
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
              _buildVolumePresetChip('Mute', 0.0),
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

  Widget _buildSubtitleMiniPopup() {
    return _buildMiniPopupContainer(
      width: 310,
      title: 'Pilih Subtitle',
      icon: Iconsax.subtitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Option: Matikan Subtitle
          InkWell(
            onTap: () async {
              ref.read(activeSubtitleCuesProvider.notifier).state = [];
              await _player.setSubtitleTrack(SubtitleTrack.no());
              setState(() {
                _selectedSubtitle = null;
                _isSubtitleTranslated = false;
                _activePopup = _PlayerMiniPopup.none;
              });
              _resetControlsTimer();
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              margin: const EdgeInsets.only(bottom: 6),
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
                  const Text('Matikan Subtitle', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          const Divider(color: Colors.white24, height: 12),

          // Subtitle tracks list
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 180),
            child: _availableSubtitles.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text('Tidak ada subtitle ditemukan', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _availableSubtitles.length,
                    itemBuilder: (ctx, i) {
                      final sub = _availableSubtitles[i];
                      final isSelected = _selectedSubtitle?.id == sub.id;
                      final isId = sub.language.toLowerCase() == 'id';

                      return InkWell(
                        onTap: () async {
                          final success = await _applySubtitle(sub);
                          if (!success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Gagal mengunduh subtitle ${sub.languageName}'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                          setState(() => _activePopup = _PlayerMiniPopup.none);
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
                                  color: isId ? AppColors.success.withValues(alpha: 0.25) : AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  sub.language.toUpperCase(),
                                  style: TextStyle(
                                    color: isId ? AppColors.success : Colors.white70,
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
                    },
                  ),
          ),

          // 1-Tap Auto-Translate Action if non-Indonesian subtitle is active
          if (_selectedSubtitle != null && _selectedSubtitle!.language.toLowerCase() != 'id') ...[
            const Divider(color: Colors.white24, height: 12),
            if (_isAutoTranslating) ...[
              LinearProgressIndicator(
                value: _translationProgress > 0 ? _translationProgress : null,
                color: AppColors.primary,
                backgroundColor: AppColors.surfaceElevated,
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text('Menerjemahkan ke Bahasa Indonesia...', style: TextStyle(color: AppColors.primary, fontSize: 11)),
              ),
            ] else ...[
              InkWell(
                onTap: () {
                  _applyAndAutoTranslateSubtitle(_selectedSubtitle!);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Iconsax.magic_star, color: AppColors.primary, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        _isSubtitleTranslated ? 'Terjemahan ID Aktif ✓' : 'Terjemahkan ke Indonesia',
                        style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSubtitleSettingsMiniPopup() {
    final style = ref.watch(subtitleStyleProvider);
    final notifier = ref.read(subtitleStyleProvider.notifier);

    return _buildMiniPopupContainer(
      width: 360,
      title: 'Pengaturan Subtitle',
      icon: Iconsax.setting_2,
      child: Column(
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
                        'Waktu (Sync)',
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
                        'Tampilan & Background',
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
                        ? 'Tepat Waktu (0.00s)'
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
                        ? 'Sinkronisasi default'
                        : style.syncOffsetMs > 0
                            ? 'Subtitle ditunda (lebih lambat)'
                            : 'Subtitle dimajukan (lebih cepat)',
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
                  child: const Text('Reset', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ),
                const SizedBox(width: 6),
                _buildSyncChip('+100ms', () => notifier.adjustSyncOffset(100)),
                const SizedBox(width: 6),
                _buildSyncChip('+500ms', () => notifier.adjustSyncOffset(500)),
              ],
            ),
          ] else ...[
            // Style & Background Tab (live sliders)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Background Opacity Controls (Transparan vs Background)
                    const Text('Background Subtitle:', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildBgChip('Transparan', 0.0, style.backgroundOpacity, notifier),
                        const SizedBox(width: 6),
                        _buildBgChip('Semi 40%', 0.4, style.backgroundOpacity, notifier),
                        const SizedBox(width: 6),
                        _buildBgChip('Gelap 75%', 0.75, style.backgroundOpacity, notifier),
                        const SizedBox(width: 6),
                        _buildBgChip('Solid 100%', 1.0, style.backgroundOpacity, notifier),
                      ],
                    ),
                    Row(
                      children: [
                        const SizedBox(width: 80, child: Text('Opasitas BG:', style: TextStyle(color: Colors.white70, fontSize: 11))),
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
                        const SizedBox(width: 80, child: Text('Ukuran:', style: TextStyle(color: Colors.white70, fontSize: 11))),
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
                        const SizedBox(width: 80, child: Text('Stroke Out:', style: TextStyle(color: Colors.white70, fontSize: 11))),
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
                        const SizedBox(width: 80, child: Text('Posisi:', style: TextStyle(color: Colors.white70, fontSize: 11))),
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
                        const SizedBox(width: 80, child: Text('Warna:', style: TextStyle(color: Colors.white70, fontSize: 11))),
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
              ),
            ),
          ],
        ],
      ),
    );
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

  Widget _buildMiniPopupContainer({
    required double width,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: width,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.76),
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
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() => _activePopup = _PlayerMiniPopup.none);
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
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      body: GestureDetector(
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
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── 1. Video Layer: Passes all the way through camera cutout / notch ──
            if (_useNativePlayer)
              Video(
                controller: _videoController,
                controls: NoVideoControls, // Guarantees NO built-in media_kit controls!
                subtitleViewConfiguration: const SubtitleViewConfiguration(
                  visible: false, // Ensures media_kit never renders its own internal subtitle
                ),
                fit: _fitMode,
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
              IgnorePointer(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.88),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
                        const SizedBox(height: 18),
                        Text(
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
                        const SizedBox(height: 8),
                        Text(
                          _loadingStatus,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Unified center buffering indicator when controls are hidden
            if (_useNativePlayer && !_showControls && _isBuffering && !_isLoading)
              IgnorePointer(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.45),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const SizedBox(
                      width: 42,
                      height: 42,
                      child: Padding(
                        padding: EdgeInsets.all(3),
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 3.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // ── 5. The ONLY Control Overlay: Cineva Custom Cinema Controls ──
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: _handleExit,
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
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
                                    if (widget.season != null && widget.episode != null)
                                      Text(
                                        'Season ${widget.season} • Episode ${widget.episode}',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // Mini Popup Button: Resolution & Quality
                              GestureDetector(
                                onTap: () => _togglePopup(_PlayerMiniPopup.quality),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: _activePopup == _PlayerMiniPopup.quality
                                        ? AppColors.primary
                                        : AppColors.primary.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.6)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.hd_rounded,
                                        color: _activePopup == _PlayerMiniPopup.quality ? Colors.black : AppColors.primary,
                                        size: 15,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _resolutionLabel,
                                        style: TextStyle(
                                          color: _activePopup == _PlayerMiniPopup.quality ? Colors.black : AppColors.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Mini Popup Button: Volume & Audio Boost
                              GestureDetector(
                                onTap: () => _togglePopup(_PlayerMiniPopup.volume),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: _activePopup == _PlayerMiniPopup.volume
                                        ? AppColors.primary
                                        : AppColors.surfaceVariant.withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _activePopup == _PlayerMiniPopup.volume ? AppColors.primary : AppColors.surfaceElevated,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.volume_up_rounded,
                                        color: _activePopup == _PlayerMiniPopup.volume ? Colors.black : Colors.white,
                                        size: 15,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_volume.toInt()}%',
                                        style: TextStyle(
                                          color: _activePopup == _PlayerMiniPopup.volume ? Colors.black : Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Mini Popup Button: Subtitle Selection
                              GestureDetector(
                                onTap: () => _togglePopup(_PlayerMiniPopup.subtitle),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: _activePopup == _PlayerMiniPopup.subtitle
                                        ? AppColors.primary
                                        : AppColors.surfaceVariant.withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _activePopup == _PlayerMiniPopup.subtitle ? AppColors.primary : AppColors.surfaceElevated,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Iconsax.subtitle,
                                        color: _activePopup == _PlayerMiniPopup.subtitle ? Colors.black : AppColors.primary,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _selectedSubtitle != null
                                            ? _isSubtitleTranslated
                                                ? 'Sub: ID (Auto)'
                                                : 'Sub: ${_selectedSubtitle!.language.toUpperCase()}'
                                            : 'Pilih Subtitle',
                                        style: TextStyle(
                                          color: _activePopup == _PlayerMiniPopup.subtitle ? Colors.black : Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Mini Popup Button: Subtitle Settings (Styling & Background)
                              GestureDetector(
                                onTap: () => _togglePopup(_PlayerMiniPopup.subtitleSettings),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: _activePopup == _PlayerMiniPopup.subtitleSettings
                                        ? AppColors.primary
                                        : AppColors.surfaceVariant.withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _activePopup == _PlayerMiniPopup.subtitleSettings ? AppColors.primary : AppColors.surfaceElevated,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Iconsax.setting_2,
                                        color: _activePopup == _PlayerMiniPopup.subtitleSettings ? Colors.black : Colors.white,
                                        size: 15,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Atur Sub',
                                        style: TextStyle(
                                          color: _activePopup == _PlayerMiniPopup.subtitleSettings ? Colors.black : Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // External VLC Button
                              GestureDetector(
                                onTap: _launchExternalVlc,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant.withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.surfaceElevated),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Iconsax.export_1, color: Colors.white, size: 14),
                                      SizedBox(width: 6),
                                      Text(
                                        'VLC',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Center Controls (Only shown for native player to avoid double controls) ──
                        if (_useNativePlayer)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: () => _seekRelative(-10),
                                icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 44),
                              ),
                              const SizedBox(width: 44),
                              GestureDetector(
                                onTap: (_isLoading || _isBuffering) ? null : _togglePlayPause,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.45),
                                        blurRadius: 24,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: (_isLoading || _isBuffering)
                                      ? const SizedBox(
                                          width: 42,
                                          height: 42,
                                          child: Padding(
                                            padding: EdgeInsets.all(3),
                                            child: CircularProgressIndicator(
                                              color: Colors.black,
                                              strokeWidth: 3.5,
                                            ),
                                          ),
                                        )
                                      : Icon(
                                          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                          color: Colors.black,
                                          size: 42,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 44),
                              IconButton(
                                onPressed: () => _seekRelative(10),
                                icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 44),
                              ),
                            ],
                          )
                        else
                          const SizedBox.shrink(),

                        // ── Bottom Timeline Scrubber (Only for native player to avoid double controls) ──
                        if (_useNativePlayer)
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
                          )
                        else
                          const SizedBox.shrink(),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── 5.5 Floating TV Series Next Episode Action (When <= 60s remaining) ──
            if (_useNativePlayer && !_isLoading && _nextEpisodeButtonVisible && (widget.season != null && widget.episode != null))
              Positioned(
                bottom: _showControls ? 78 : 28,
                right: 28,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildSkipPillButton(
                    key: const ValueKey('tv_next_episode_btn'),
                    icon: Icons.skip_next_rounded,
                    label: 'Episode ${(widget.episode ?? 1) + 1} Berikutnya',
                    onTap: _playNextEpisode,
                  ),
                ),
              ),

            // ── 6. Compact Semi-Transparent Mini Popups Layer ──
            if (_activePopup != _PlayerMiniPopup.none) ...[
              // Outside tap dismisser (transparent, non-blocking)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    setState(() => _activePopup = _PlayerMiniPopup.none);
                    _resetControlsTimer();
                  },
                ),
              ),

              // The active Mini Popup Card
              Positioned(
                top: 54,
                right: 16,
                child: switch (_activePopup) {
                  _PlayerMiniPopup.quality => _buildQualityMiniPopup(),
                  _PlayerMiniPopup.volume => _buildVolumeMiniPopup(),
                  _PlayerMiniPopup.subtitle => _buildSubtitleMiniPopup(),
                  _PlayerMiniPopup.subtitleSettings => _buildSubtitleSettingsMiniPopup(),
                  _PlayerMiniPopup.none => const SizedBox.shrink(),
                },
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
}
