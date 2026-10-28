import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../../core/localization/app_strings.dart';
import '../../data/datasources/live_tv_channels_data.dart';
import '../../domain/entities/live_tv_channel.dart';
import '../providers/live_tv_providers.dart';

/// Screen dedicated to browsing and streaming Live TV channels.
/// Features a YouTube-like interface:
/// - Top 16:9 responsive video player with in-place controls
/// - Bottom channels list with search and category filter chips
/// - Expandable to immersive full-screen via square fullscreen button
/// - Persistent bottom navigation bar in portrait mode
class LiveTvScreen extends ConsumerStatefulWidget {
  const LiveTvScreen({super.key});

  @override
  ConsumerState<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends ConsumerState<LiveTvScreen> {
  LiveTvChannel? _currentChannel;
  Player? _player;
  VideoController? _controller;

  bool _isFullscreen = false;
  bool _controlsVisible = true;
  Timer? _hideControlsTimer;
  bool _isLoading = false;
  bool _isPlaying = false;
  bool _hasError = false;
  String? _errorMessage;
  BoxFit _videoFit = BoxFit.contain;

  final TextEditingController _searchController = TextEditingController();

  bool get _isTesting => Platform.environment.containsKey('FLUTTER_TEST');

  @override
  void initState() {
    super.initState();
    _currentChannel = null;
    _isLoading = false;
    _isPlaying = false;
  }

  void _ensurePlayerInitialized() {
    if (_player == null && !_isTesting) {
      _player = Player(
        configuration: const PlayerConfiguration(
          bufferSize: 16 * 1024 * 1024,
        ),
      );
      _controller = VideoController(_player!);
      _listenPlayerEvents();
    }
  }

  void _listenPlayerEvents() {
    _player?.stream.buffering.listen((buffering) {
      if (mounted) {
        setState(() {
          _isLoading = buffering;
        });
      }
    });

    _player?.stream.playing.listen((playing) {
      if (mounted) {
        setState(() {
          _isPlaying = playing;
        });
      }
    });

    _player?.stream.error.listen((error) {
      if (mounted && error.isNotEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = error;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _playChannel(LiveTvChannel channel) async {
    _ensurePlayerInitialized();

    setState(() {
      _currentChannel = channel;
      _isLoading = true;
      _isPlaying = true;
      _hasError = false;
      _errorMessage = null;
    });

    // Notify provider to smoothly slide down and hide bottom navigation bar
    ref.read(liveTvIsPlayingProvider.notifier).state = true;
    _startHideTimer();

    if (_player != null) {
      try {
        await _player!.open(
          Media(
            channel.streamUrl,
            httpHeaders: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
            },
          ),
        );
        await _player!.play();
      } catch (e) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = e.toString();
            _isLoading = false;
          });
        }
      }
    }
  }

  void _stopPlayback() {
    _hideControlsTimer?.cancel();
    _player?.stop();
    setState(() {
      _currentChannel = null;
      _isPlaying = false;
      _isLoading = false;
      _hasError = false;
      _errorMessage = null;
    });
    ref.read(liveTvIsPlayingProvider.notifier).state = false;
    if (_isFullscreen) {
      _exitFullscreen();
    }
  }

  void _togglePlayPause() {
    _player?.playOrPause();
    _startHideTimer();
  }

  void _toggleControls() {
    setState(() {
      _controlsVisible = !_controlsVisible;
    });
    if (_controlsVisible) {
      _startHideTimer();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  void _startHideTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _controlsVisible) {
        setState(() {
          _controlsVisible = false;
        });
      }
    });
  }

  void _cycleVideoFit() {
    setState(() {
      if (_videoFit == BoxFit.contain) {
        _videoFit = BoxFit.cover;
      } else if (_videoFit == BoxFit.cover) {
        _videoFit = BoxFit.fill;
      } else {
        _videoFit = BoxFit.contain;
      }
    });
    _startHideTimer();
  }

  void _enterFullscreen() {
    setState(() {
      _isFullscreen = true;
    });
    ref.read(liveTvFullscreenProvider.notifier).state = true;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    _startHideTimer();
  }

  void _exitFullscreen() {
    setState(() {
      _isFullscreen = false;
    });
    ref.read(liveTvFullscreenProvider.notifier).state = false;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _startHideTimer();
  }

  void _showQuickChannelDrawer() {
    _hideControlsTimer?.cancel();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Colors.white12, width: 0.8),
      ),
      builder: (context) {
        final channels = LiveTvChannelsData.defaultChannels;
        return Container(
          height: 380,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.live_tv_rounded, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Pilih Saluran TV',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Divider(color: Colors.white10, height: 1),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: channels.length,
                  separatorBuilder: (_, _) => const Divider(
                    color: Colors.white10,
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  itemBuilder: (context, index) {
                    final ch = channels[index];
                    final isCurrent = _currentChannel != null && ch.id == _currentChannel!.id;
                    return ListTile(
                      dense: true,
                      leading: Container(
                        width: 36,
                        height: 36,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCurrent
                                ? AppColors.primary.withValues(alpha: 0.6)
                                : Colors.white10,
                            width: 0.8,
                          ),
                        ),
                        child: ch.logoUrl != null && ch.logoUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: ch.logoUrl!,
                                fit: BoxFit.contain,
                                errorWidget: (_, _, _) => Icon(
                                  Icons.tv_rounded,
                                  color: isCurrent ? AppColors.primary : Colors.white70,
                                  size: 16,
                                ),
                              )
                            : Icon(
                                Icons.tv_rounded,
                                color: isCurrent ? AppColors.primary : Colors.white70,
                                size: 16,
                              ),
                      ),
                      title: Text(
                        ch.name,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                          color: isCurrent ? AppColors.primary : Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        ch.category,
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                      ),
                      trailing: isCurrent
                          ? const Icon(Icons.play_circle_fill_rounded,
                              color: AppColors.primary, size: 18)
                          : null,
                      onTap: () {
                        Navigator.of(context).pop();
                        _playChannel(ch);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) => _startHideTimer());
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _player?.dispose();
    _searchController.dispose();
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final selectedCategory = ref.watch(liveTvCategoryProvider);
    final channels = ref.watch(filteredLiveTvChannelsProvider);
    final favoritesNotifier = ref.read(liveTvFavoritesProvider.notifier);
    final favorites = ref.watch(liveTvFavoritesProvider);
    final isFav = _currentChannel != null && favorites.contains(_currentChannel!.id);
    final bottomPadding = MediaQuery.of(context).padding.bottom + 80;

    final categories = [
      ...LiveTvChannelsData.categories,
      'Favorit',
    ];

    return PopScope(
      canPop: !_isFullscreen && _currentChannel == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isFullscreen) {
          _exitFullscreen();
          return;
        }
        if (_currentChannel != null) {
          _stopPlayback();
          return;
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: (_isFullscreen && _currentChannel != null)
            ? _buildFullscreenPlayer(s, isFav, favoritesNotifier)
            : SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // ── 1. Top YouTube-Style 16:9 Video Player or Placeholder ──
                    if (_currentChannel != null)
                      _buildTopPlayer(s, _currentChannel!)
                    else
                      _buildPlaceholder(s),

                    // ── 2. Scrollable Channels List & Filter Chips ──
                    Expanded(
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          // Active Channel Info Header (shown only when a channel is actively selected)
                          if (_currentChannel != null)
                            SliverToBoxAdapter(
                              child: _buildActiveChannelHeader(
                                  s, isFav, favoritesNotifier, _currentChannel!),
                            ),

                          // Search Bar
                          SliverToBoxAdapter(
                            child: _buildSearchBar(s),
                          ),

                          // Category Filter Chips
                          SliverToBoxAdapter(
                            child: _buildCategoryChips(categories, selectedCategory),
                          ),

                          const SliverToBoxAdapter(
                            child: SizedBox(height: 12),
                          ),

                          // Channel List Items
                          if (channels.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.tv_off_rounded,
                                        size: 44, color: AppColors.textMuted),
                                    const SizedBox(height: 12),
                                    Text(
                                      s.liveTvNoChannels,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            _buildChannelList(channels, favorites, bottomPadding),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  /// Elegant placeholder when no channel is actively chosen yet
  Widget _buildPlaceholder(AppStrings s) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        decoration: BoxDecoration(
          color: const Color(0xFF141416),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 0.8,
          ),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF18181C),
              Color(0xFF0E0E10),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.live_tv_rounded,
                  size: 30,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                s.liveTvTitle,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pilih saluran siaran TV di bawah untuk mulai menonton',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Top 16:9 video player widget formatted like YouTube
  Widget _buildTopPlayer(AppStrings s, LiveTvChannel channel) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.black,
        child: GestureDetector(
          onTap: _toggleControls,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video Surface
              if (_controller != null)
                Video(
                  controller: _controller!,
                  fit: _videoFit,
                  controls: NoVideoControls,
                )
              else
                Container(
                  color: Colors.black,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.live_tv_rounded, size: 36, color: AppColors.primary),
                        const SizedBox(height: 6),
                        Text(
                          channel.name,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Buffering / Loading Indicator
              if (_isLoading && !_hasError)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.liveTvConnecting,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Error State
              if (_hasError)
                Container(
                  color: Colors.black87,
                  padding: const EdgeInsets.all(12),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 28),
                        const SizedBox(height: 6),
                        Text(
                          s.liveTvFailed,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _playChannel(channel),
                          icon: const Icon(Icons.refresh_rounded, size: 14),
                          label: Text(s.liveTvRetry, style: const TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Overlay Controls
              AnimatedOpacity(
                opacity: _controlsVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_controlsVisible,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black87,
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black87,
                        ],
                        stops: [0.0, 0.28, 0.72, 1.0],
                      ),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top Info Row (Badge "TV Live" is removed per user request)
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'LIVE',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                channel.name,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                channel.quality,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Close/Stop Button
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                              tooltip: 'Tutup Siaran',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: _stopPlayback,
                            ),
                          ],
                        ),

                        // Center Play / Pause Action
                        IconButton(
                          iconSize: 38,
                          icon: Icon(
                            _isPlaying
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_filled_rounded,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          onPressed: _togglePlayPause,
                        ),

                        // Bottom Actions Row with SQUARE FULLSCREEN ICON
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.aspect_ratio_rounded,
                                  color: Colors.white, size: 20),
                              tooltip: 'Aspek Rasio',
                              onPressed: _cycleVideoFit,
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded,
                                  color: Colors.white, size: 20),
                              tooltip: s.liveTvRetry,
                              onPressed: () => _playChannel(channel),
                            ),
                            // Square Fullscreen Control Icon
                            IconButton(
                              icon: const Icon(Icons.fullscreen_rounded,
                                  color: Colors.white, size: 24),
                              tooltip: s.liveTvFullscreen,
                              onPressed: _enterFullscreen,
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
      ),
    );
  }

  /// Active channel banner displayed right below the YouTube top player
  Widget _buildActiveChannelHeader(
    AppStrings s,
    bool isFav,
    LiveTvFavoritesNotifier favoritesNotifier,
    LiveTvChannel channel,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          // Channel Logo Plate
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 0.8,
              ),
            ),
            child: channel.logoUrl != null && channel.logoUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: channel.logoUrl!,
                    fit: BoxFit.contain,
                    errorWidget: (_, _, _) => const Icon(
                      Icons.tv_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  )
                : const Icon(
                    Icons.tv_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
          ),
          const SizedBox(width: 12),
          // Channel Info & Category
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        channel.name,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.6),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        'LIVE',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${s.liveTvTitle} • ${channel.category} • ${channel.quality} • ${channel.country}',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Favorite Star Toggle
          IconButton(
            onPressed: () => favoritesNotifier.toggleFavorite(channel.id),
            icon: Icon(
              isFav ? Icons.star_rounded : Icons.star_border_rounded,
              color: isFav ? AppColors.star : Colors.white60,
              size: 24,
            ),
          ),
          // Close / Stop Playback Button
          IconButton(
            onPressed: _stopPlayback,
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white60,
              size: 22,
            ),
            tooltip: 'Tutup Siaran',
          ),
        ],
      ),
    );
  }

  /// Search bar for quickly finding live channels
  Widget _buildSearchBar(AppStrings s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) {
            ref.read(liveTvSearchQueryProvider.notifier).state = val;
          },
          style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: s.liveTvSearchHint,
            hintStyle: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.textMuted),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(liveTvSearchQueryProvider.notifier).state = '';
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 9),
          ),
        ),
      ),
    );
  }

  /// Category filter chips underneath search bar
  Widget _buildCategoryChips(List<String> categories, String selectedCategory) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: categories.map((cat) {
          final isSelected = selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                ref.read(liveTvCategoryProvider.notifier).state = cat;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.1),
                    width: isSelected ? 1.2 : 0.8,
                  ),
                ),
                child: Text(
                  cat,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Channel list with live playback status
  Widget _buildChannelList(
    List<LiveTvChannel> channels,
    Set<String> favorites,
    double bottomPadding,
  ) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final ch = channels[index];
            final isCurrent = _currentChannel != null && ch.id == _currentChannel!.id;
            final isFav = favorites.contains(ch.id);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _playChannel(ch),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? AppColors.primary.withValues(alpha: 0.14)
                          : AppColors.surfaceVariant.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrent
                            ? AppColors.primary.withValues(alpha: 0.6)
                            : Colors.white.withValues(alpha: 0.06),
                        width: isCurrent ? 1.2 : 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Logo Plate
                        Container(
                          width: 42,
                          height: 42,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? AppColors.primary.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isCurrent
                                  ? AppColors.primary.withValues(alpha: 0.6)
                                  : Colors.white10,
                              width: 0.8,
                            ),
                          ),
                          child: ch.logoUrl != null && ch.logoUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: ch.logoUrl!,
                                  fit: BoxFit.contain,
                                  errorWidget: (_, _, _) => Icon(
                                    Icons.tv_rounded,
                                    color: isCurrent ? AppColors.primary : Colors.white70,
                                    size: 18,
                                  ),
                                )
                              : Icon(
                                  Icons.tv_rounded,
                                  color: isCurrent ? AppColors.primary : Colors.white70,
                                  size: 18,
                                ),
                        ),
                        const SizedBox(width: 12),
                        // Channel Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ch.name,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                                  color: isCurrent ? AppColors.primary : Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    ch.category,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: isCurrent
                                          ? AppColors.primary.withValues(alpha: 0.8)
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      ch.quality,
                                      style: GoogleFonts.inter(
                                        fontSize: 9.5,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Status or Favorite
                        if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primary, width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.play_circle_fill_rounded,
                                    color: AppColors.primary, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'Diputar',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (isFav)
                          const Icon(Icons.star_rounded, color: AppColors.star, size: 20)
                        else
                          const Icon(Icons.play_arrow_rounded, color: Colors.white38, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          childCount: channels.length,
        ),
      ),
    );
  }

  /// Fullscreen live player view (triggered via square fullscreen button)
  Widget _buildFullscreenPlayer(
    AppStrings s,
    bool isFav,
    LiveTvFavoritesNotifier favoritesNotifier,
  ) {
    final channel = _currentChannel;
    if (channel == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _toggleControls,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video Surface
          Center(
            child: _controller != null
                ? Video(
                    controller: _controller!,
                    fit: _videoFit,
                    controls: NoVideoControls,
                  )
                : const SizedBox.shrink(),
          ),

          // Buffering Indicator
          if (_isLoading && !_hasError)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      s.liveTvConnecting,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Error State
          if (_hasError)
            Container(
              color: Colors.black87,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        s.liveTvFailed,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _errorMessage ?? 'Saluran sedang tidak dapat dijangkau.',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        onPressed: () => _playChannel(channel),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: Text(s.liveTvRetry),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Fullscreen Overlay Controls
          AnimatedOpacity(
            opacity: _controlsVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: IgnorePointer(
              ignoring: !_controlsVisible,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black87,
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black87,
                    ],
                    stops: [0.0, 0.25, 0.75, 1.0],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: _exitFullscreen,
                              icon: const Icon(Icons.arrow_back_rounded,
                                  color: Colors.white, size: 22),
                            ),
                            if (channel.logoUrl != null &&
                                channel.logoUrl!.isNotEmpty) ...[
                              Container(
                                width: 32,
                                height: 32,
                                padding: const EdgeInsets.all(3),
                                margin: const EdgeInsets.only(left: 4, right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: CachedNetworkImage(
                                  imageUrl: channel.logoUrl!,
                                  fit: BoxFit.contain,
                                  errorWidget: (_, _, _) => const Icon(
                                    Icons.tv_rounded,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ] else
                              const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          channel.name,
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 5,
                                              height: 5,
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'LIVE',
                                              style: GoogleFonts.inter(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${channel.category} • ${channel.quality}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  favoritesNotifier.toggleFavorite(channel.id),
                              icon: Icon(
                                isFav ? Icons.star_rounded : Icons.star_border_rounded,
                                color: isFav ? AppColors.star : Colors.white70,
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Center Play/Pause button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            iconSize: 48,
                            icon: Icon(
                              _isPlaying
                                  ? Icons.pause_circle_filled_rounded
                                  : Icons.play_circle_filled_rounded,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            onPressed: _togglePlayPause,
                          ),
                        ],
                      ),

                      // Bottom Action Bar with SQUARE EXIT FULLSCREEN BUTTON
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: _showQuickChannelDrawer,
                              icon: const Icon(Icons.list_rounded, size: 18),
                              label: Text(s.liveTvChannelList),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.white.withValues(alpha: 0.1),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: _cycleVideoFit,
                                  tooltip: 'Aspek Rasio',
                                  icon: const Icon(Icons.aspect_ratio_rounded,
                                      color: Colors.white70, size: 20),
                                ),
                                IconButton(
                                  onPressed: () => _playChannel(channel),
                                  tooltip: s.liveTvRetry,
                                  icon: const Icon(Icons.refresh_rounded,
                                      color: Colors.white70, size: 20),
                                ),
                                // Square Exit Fullscreen Icon
                                IconButton(
                                  onPressed: _exitFullscreen,
                                  tooltip: s.liveTvExitFullscreen,
                                  icon: const Icon(Icons.fullscreen_exit_rounded,
                                      color: Colors.white, size: 24),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
