import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../../core/localization/app_strings.dart';
import '../../data/datasources/live_tv_channels_data.dart';
import '../../domain/entities/live_tv_channel.dart';
import '../providers/live_tv_providers.dart';

/// Dedicated Live TV Stream Player Screen.
///
/// Features:
/// - Smooth entry transition from Live TV channel catalog
/// - 16:9 responsive top player in portrait mode with channel switcher below
/// - Immersive fullscreen mode with landscape lock and quick channel drawer
/// - Realtime buffering, error handling, and aspect ratio controls
class LiveTvPlayerScreen extends ConsumerStatefulWidget {
  final LiveTvChannel? initialChannel;

  const LiveTvPlayerScreen({super.key, this.initialChannel});

  @override
  ConsumerState<LiveTvPlayerScreen> createState() => _LiveTvPlayerScreenState();
}

class _LiveTvPlayerScreenState extends ConsumerState<LiveTvPlayerScreen> {
  late LiveTvChannel _currentChannel;
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
  bool _isLandscapeChannelDrawerOpen = false;
  String _landscapeSelectedCategory = 'Semua';

  final TextEditingController _searchController = TextEditingController();

  bool get _isTesting => Platform.environment.containsKey('FLUTTER_TEST');

  @override
  void initState() {
    super.initState();
    _currentChannel =
        widget.initialChannel ?? LiveTvChannelsData.defaultChannels.first;
    _playChannel(_currentChannel);
  }

  void _ensurePlayerInitialized() {
    if (_player == null && !_isTesting) {
      _player = Player(
        configuration: const PlayerConfiguration(bufferSize: 16 * 1024 * 1024),
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
          if (!buffering && _isPlaying) {
            _hasError = false;
          }
        });
      }
    });

    _player?.stream.playing.listen((playing) {
      if (mounted) {
        setState(() {
          _isPlaying = playing;
          if (playing) {
            _hasError = false;
            _errorMessage = null;
          }
        });
      }
    });

    _player?.stream.error.listen((error) {
      debugPrint('[LiveTvPlayer] mpv stream warning/event: $error');
      // Transient non-fatal decoder and networking warnings (e.g. dropped audio frames,
      // temporary TCP reconnects) must never interrupt or obscure an active broadcast.
      if (mounted && error.isNotEmpty && !_isPlaying) {
        final isTransient =
            error.contains('Error decoding audio') ||
            error.contains('ffurl_read') ||
            error.contains('tcp:') ||
            error.contains('tls:') ||
            error.contains('hls:') ||
            error.contains('non-existing') ||
            error.contains('header missing') ||
            error.contains('decode_slice_header');
        if (!isTransient) {
          setState(() {
            _hasError = true;
            _errorMessage = error;
            _isLoading = false;
          });
        }
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

    Future.microtask(() {
      if (mounted) {
        ref.read(liveTvIsPlayingProvider.notifier).state = true;
      }
    });
    _startHideTimer();

    if (_player != null) {
      try {
        final headers = <String, String>{
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
        };
        if (channel.streamUrl.contains('dens.tv')) {
          headers['Referer'] = 'https://www.dens.tv/';
          headers['Origin'] = 'https://www.dens.tv';
        } else if (channel.streamUrl.contains('cnbcindonesia.com') ||
            channel.streamUrl.contains('detik.com')) {
          headers['Referer'] = 'https://video.detik.com/';
        }

        await _player!.open(Media(channel.streamUrl, httpHeaders: headers));
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

  void _reloadStream() {
    _playChannel(_currentChannel);
  }

  void _toggleVideoFit() {
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
    ]);
    _startHideTimer();
  }

  void _exitFullscreen() {
    setState(() {
      _isFullscreen = false;
      _isLandscapeChannelDrawerOpen = false;
    });
    ref.read(liveTvFullscreenProvider.notifier).state = false;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _startHideTimer();
  }

  void _toggleLandscapeChannelDrawer() {
    setState(() {
      _isLandscapeChannelDrawerOpen = !_isLandscapeChannelDrawerOpen;
    });
    _startHideTimer();
  }

  void _navigateBack() {
    if (_isFullscreen) {
      if (_isLandscapeChannelDrawerOpen) {
        setState(() {
          _isLandscapeChannelDrawerOpen = false;
        });
        _startHideTimer();
        return;
      }
      _exitFullscreen();
    }
    ref.read(liveTvIsPlayingProvider.notifier).state = false;
    ref.read(liveTvFullscreenProvider.notifier).state = false;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/live-tv');
    }
  }

  @override
  void deactivate() {
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
    ref.read(liveTvIsPlayingProvider.notifier).state = false;
    ref.read(liveTvFullscreenProvider.notifier).state = false;
    super.deactivate();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _player?.dispose();
    _searchController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    Future.microtask(() {
      try {
        ref.read(liveTvIsPlayingProvider.notifier).state = false;
        ref.read(liveTvFullscreenProvider.notifier).state = false;
      } catch (_) {}
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final selectedCategory = ref.watch(liveTvCategoryProvider);
    final channels = ref.watch(filteredLiveTvChannelsProvider);
    final favoritesNotifier = ref.read(liveTvFavoritesProvider.notifier);
    final favorites = ref.watch(liveTvFavoritesProvider);
    final isFav = favorites.contains(_currentChannel.id);
    final bottomPadding = MediaQuery.of(context).padding.bottom + 24;

    final categories = [...LiveTvChannelsData.categories, 'Favorit'];

    return PopScope(
      canPop: !_isFullscreen,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          ref.read(liveTvIsPlayingProvider.notifier).state = false;
          ref.read(liveTvFullscreenProvider.notifier).state = false;
          return;
        }
        if (_isFullscreen) {
          if (_isLandscapeChannelDrawerOpen) {
            setState(() {
              _isLandscapeChannelDrawerOpen = false;
            });
            _startHideTimer();
            return;
          }
          _exitFullscreen();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: _isFullscreen
            ? _buildFullscreenPlayer(s, isFav, favoritesNotifier, favorites)
            : SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // ── 1. Top 16:9 Video Player ──
                    _buildTopPlayer(s, _currentChannel),

                    // ── 2. Scrollable Channel Info & Other Channels Switcher ──
                    Expanded(
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          // Active Channel Info Header
                          SliverToBoxAdapter(
                            child: _buildActiveChannelHeader(
                              s,
                              isFav,
                              favoritesNotifier,
                              _currentChannel,
                            ),
                          ),

                          // Search Bar
                          SliverToBoxAdapter(child: _buildSearchBar(s)),

                          // Category Filter Chips
                          SliverToBoxAdapter(
                            child: _buildCategoryChips(
                              s,
                              categories,
                              selectedCategory,
                            ),
                          ),

                          const SliverToBoxAdapter(child: SizedBox(height: 12)),

                          // Channel List Items
                          if (channels.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.tv_off_rounded,
                                      size: 44,
                                      color: AppColors.textMuted,
                                    ),
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
                            _buildChannelList(
                              s,
                              channels,
                              favorites,
                              bottomPadding,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  /// 16:9 Video Player Container at Top
  Widget _buildTopPlayer(AppStrings s, LiveTvChannel channel) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video / Placeholder
            if (_controller != null && !_isTesting)
              Video(
                controller: _controller!,
                fit: _videoFit,
                controls: NoVideoControls,
              )
            else
              _buildStreamCover(channel),

            // Tap detector
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleControls,
                child: const SizedBox.expand(),
              ),
            ),

            // Error Overlay
            if (_hasError && !_isPlaying)
              Container(
                color: Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage ?? s.liveTvConnectionError,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _reloadStream,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: Text(
                        s.liveTvReload,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Buffering Spinner
            if (_isLoading && !_hasError)
              const Center(
                child: SizedBox(
                  width: 38,
                  height: 38,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ),

            // Overlay Controls
            AnimatedOpacity(
              opacity: _controlsVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 220),
              child: IgnorePointer(
                ignoring: !_controlsVisible,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.75),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Top Row: Back Button, Channel Name & Fullscreen Button
                      Positioned(
                        top: 8,
                        left: 8,
                        right: 8,
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: _navigateBack,
                              icon: const Icon(
                                Icons.chevron_left_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                              tooltip: s.liveTvBackToChannels,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                channel.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Square Fullscreen Button
                            Material(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                onTap: _enterFullscreen,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.fullscreen_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bottom Row: Aspect Ratio Toggle & Reload Button
                      Positioned(
                        bottom: 8,
                        left: 12,
                        right: 12,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Aspect Ratio Pill
                            GestureDetector(
                              onTap: _toggleVideoFit,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.white24,
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.aspect_ratio_rounded,
                                      size: 13,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _videoFit == BoxFit.contain
                                          ? '16:9'
                                          : (_videoFit == BoxFit.cover
                                                ? 'Cover'
                                                : 'Fill'),
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Reload Button
                            GestureDetector(
                              onTap: _reloadStream,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.white24,
                                    width: 0.8,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.refresh_rounded,
                                  size: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
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

  /// Cover displayed when video controller is not ready or during testing
  Widget _buildStreamCover(LiveTvChannel channel) {
    return Container(
      color: const Color(0xFF0F172A),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (channel.logoUrl != null && channel.logoUrl!.isNotEmpty)
            Container(
              width: 58,
              height: 58,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CachedNetworkImage(
                imageUrl: channel.logoUrl!,
                httpHeaders: const {
                  'User-Agent':
                      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
                },
                fit: BoxFit.contain,
                errorWidget: (_, _, _) => const Icon(
                  Icons.tv_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
            )
          else
            const Icon(Icons.tv_rounded, color: AppColors.primary, size: 40),
          const SizedBox(height: 10),
          Text(
            channel.name,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'LIVE STREAM',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.redAccent,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Active Channel Information Header below top player
  Widget _buildActiveChannelHeader(
    AppStrings s,
    bool isFav,
    dynamic favoritesNotifier,
    LiveTvChannel channel,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        children: [
          // Channel Logo / Icon
          Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
                width: 1,
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

          // Channel Name & Category
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        channel.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.6),
                          width: 0.6,
                        ),
                      ),
                      child: Text(
                        'LIVE',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.redAccent,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  s.liveTvCategoryLabel(channel.category),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Favorite Toggle Button
          IconButton(
            onPressed: () {
              favoritesNotifier.toggleFavorite(channel.id);
            },
            icon: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFav ? Colors.redAccent : Colors.white60,
              size: 22,
            ),
            tooltip: isFav ? s.liveTvRemoveFavorite : s.liveTvAddFavorite,
          ),
        ],
      ),
    );
  }

  /// Search Bar for Filtering Channels
  Widget _buildSearchBar(AppStrings s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: TextField(
          controller: _searchController,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
          onChanged: (val) {
            ref.read(liveTvSearchQueryProvider.notifier).state = val;
          },
          decoration: InputDecoration(
            hintText: s.liveTvSearchHint,
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textMuted,
              size: 18,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.clear_rounded,
                      color: AppColors.textMuted,
                      size: 16,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(liveTvSearchQueryProvider.notifier).state = '';
                      setState(() {});
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }

  /// Category Filter Chips Row
  Widget _buildCategoryChips(
    AppStrings s,
    List<String> categories,
    String selectedCategory,
  ) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat == selectedCategory;
          return FilterChip(
            selected: isSelected,
            label: Text(
              s.liveTvCategoryLabel(cat),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.black : Colors.white70,
              ),
            ),
            backgroundColor: AppColors.surface,
            selectedColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.08),
                width: 0.8,
              ),
            ),
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
            onSelected: (_) {
              ref.read(liveTvCategoryProvider.notifier).state = cat;
            },
          );
        },
      ),
    );
  }

  /// Channels List
  Widget _buildChannelList(
    AppStrings s,
    List<LiveTvChannel> channels,
    Set<String> favorites,
    double bottomPadding,
  ) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final ch = channels[index];
          final isPlaying = ch.id == _currentChannel.id;
          final isFav = favorites.contains(ch.id);

          return _buildChannelCard(s, ch, isPlaying, isFav);
        }, childCount: channels.length),
      ),
    );
  }

  /// Single Channel Card
  Widget _buildChannelCard(
    AppStrings s,
    LiveTvChannel channel,
    bool isPlaying,
    bool isFavorite,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isPlaying
            ? AppColors.primary.withValues(alpha: 0.10)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: isPlaying
                ? AppColors.primary.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _playChannel(channel);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Channel Logo (Clean, no background box)
                SizedBox(
                  width: 40,
                  height: 40,
                  child: channel.logoUrl != null && channel.logoUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: channel.logoUrl!,
                          httpHeaders: const {
                            'User-Agent':
                                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
                          },
                          fit: BoxFit.contain,
                          errorWidget: (_, _, _) => Icon(
                            Icons.tv_rounded,
                            color: isPlaying
                                ? AppColors.primary
                                : Colors.white70,
                            size: 20,
                          ),
                        )
                      : Icon(
                          Icons.tv_rounded,
                          color: isPlaying ? AppColors.primary : Colors.white70,
                          size: 20,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              channel.name,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: isPlaying
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isPlaying
                                    ? AppColors.primary
                                    : Colors.white,
                              ),
                            ),
                          ),
                          if (isPlaying)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                s.liveTvNowPlaying.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.liveTvCategoryLabel(channel.category),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isFavorite)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.favorite_rounded,
                      color: Colors.redAccent,
                      size: 16,
                    ),
                  ),
                Icon(
                  isPlaying
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_fill_rounded,
                  color: isPlaying ? AppColors.primary : Colors.white60,
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Immersive Fullscreen Video Player
  Widget _buildFullscreenPlayer(
    AppStrings s,
    bool isFav,
    dynamic favoritesNotifier,
    Set<String> favorites,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final totalHeight = constraints.maxHeight;
        final drawerWidth = (totalWidth * 0.38).clamp(280.0, 380.0);
        final videoWidth = _isLandscapeChannelDrawerOpen
            ? totalWidth - drawerWidth
            : totalWidth;

        return Container(
          color: Colors.black,
          width: totalWidth,
          height: totalHeight,
          child: Row(
            children: [
              // 1. Left: Video Player with smooth animated width
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                width: videoWidth,
                height: totalHeight,
                child: ClipRect(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Video / Placeholder
                      if (_controller != null && !_isTesting)
                        Video(
                          controller: _controller!,
                          fit: _videoFit,
                          controls: NoVideoControls,
                        )
                      else
                        _buildStreamCover(_currentChannel),

                      // Tap detector
                      Positioned.fill(
                        child: GestureDetector(
                          key: const Key('fullscreen_video_tap_detector'),
                          behavior: HitTestBehavior.opaque,
                          onTap: _toggleControls,
                          child: const SizedBox.expand(),
                        ),
                      ),

                      // Buffering Indicator
                      if (_isLoading && !_hasError)
                        const Center(
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.8,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                        ),

                      // Error Overlay in Fullscreen
                      if (_hasError && !_isPlaying)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: AppColors.error,
                                  size: 40,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _errorMessage ?? s.liveTvConnectionError,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: _reloadStream,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.black,
                                  ),
                                  icon: const Icon(
                                    Icons.refresh_rounded,
                                    size: 16,
                                  ),
                                  label: Text(s.liveTvReload),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Controls Overlay
                      AnimatedOpacity(
                        opacity: _controlsVisible ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 220),
                        child: IgnorePointer(
                          ignoring: !_controlsVisible,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.8),
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.8),
                                ],
                              ),
                            ),
                            child: SafeArea(
                              child: Stack(
                                children: [
                                  // Top Row: Exit Fullscreen, Channel Name, Favorite, Aspect Ratio
                                  Positioned(
                                    top: 10,
                                    left: 16,
                                    right: 16,
                                    child: Row(
                                      children: [
                                        Material(
                                          color: Colors.black45,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: InkWell(
                                            onTap: _exitFullscreen,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              child: const Icon(
                                                Icons.fullscreen_exit_rounded,
                                                color: Colors.white,
                                                size: 22,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                _currentChannel.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              Text(
                                                s.liveTvCategoryLabel(_currentChannel.category),
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Aspect Ratio
                                        GestureDetector(
                                          onTap: _toggleVideoFit,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black45,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.white24,
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Text(
                                              _videoFit == BoxFit.contain
                                                  ? '16:9'
                                                  : (_videoFit == BoxFit.cover
                                                        ? 'Cover'
                                                        : 'Fill'),
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Reload Button
                                        Material(
                                          color: Colors.black45,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: InkWell(
                                            onTap: _reloadStream,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              child: const Icon(
                                                Icons.refresh_rounded,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Favorite Button
                                        Material(
                                          color: Colors.black45,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: InkWell(
                                            onTap: () => favoritesNotifier
                                                .toggleFavorite(
                                                  _currentChannel.id,
                                                ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              child: Icon(
                                                isFav
                                                    ? Icons.favorite_rounded
                                                    : Icons
                                                          .favorite_border_rounded,
                                                color: isFav
                                                    ? Colors.redAccent
                                                    : Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Bottom Right: Quick Channel Switcher Drawer Toggle Button
                                  Positioned(
                                    bottom: 16,
                                    right: 16,
                                    child: ElevatedButton.icon(
                                      onPressed: _toggleLandscapeChannelDrawer,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            _isLandscapeChannelDrawerOpen
                                            ? AppColors.primary
                                            : Colors.black54,
                                        foregroundColor:
                                            _isLandscapeChannelDrawerOpen
                                            ? Colors.black
                                            : Colors.white,
                                        side: BorderSide(
                                          color: _isLandscapeChannelDrawerOpen
                                              ? AppColors.primary
                                              : Colors.white24,
                                          width: 0.8,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      icon: Icon(
                                        _isLandscapeChannelDrawerOpen
                                            ? Icons.chevron_right_rounded
                                            : Icons.list_rounded,
                                        size: 18,
                                      ),
                                      label: Text(
                                        _isLandscapeChannelDrawerOpen
                                            ? s.liveTvClose
                                            : s.liveTvSwitchChannel,
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
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
                ),
              ),

              // 2. Right: YouTube-style Landscape Channel Selection Drawer
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                width: _isLandscapeChannelDrawerOpen ? drawerWidth : 0.0,
                height: totalHeight,
                child: ClipRect(
                  child: OverflowBox(
                    minWidth: drawerWidth,
                    maxWidth: drawerWidth,
                    minHeight: totalHeight,
                    maxHeight: totalHeight,
                    alignment: Alignment.topRight,
                    child: _buildLandscapeChannelDrawer(s, favorites),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// YouTube-style Landscape Channel Drawer
  Widget _buildLandscapeChannelDrawer(
    AppStrings s,
    Set<String> favorites,
  ) {
    final allChannels = LiveTvChannelsData.defaultChannels;
    final categories = [...LiveTvChannelsData.categories, 'Favorit'];

    List<LiveTvChannel> displayedChannels = allChannels;
    if (_landscapeSelectedCategory == 'Favorit') {
      displayedChannels = allChannels
          .where((c) => favorites.contains(c.id))
          .toList();
    } else if (_landscapeSelectedCategory != 'Semua') {
      displayedChannels = allChannels
          .where((c) => c.category == _landscapeSelectedCategory)
          .toList();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          left: BorderSide(
            color: Colors.white.withValues(alpha: 0.12),
            width: 0.8,
          ),
        ),
      ),
      child: SafeArea(
        left: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.live_tv_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s.liveTvSelectChannel,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${displayedChannels.length}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                    onPressed: _toggleLandscapeChannelDrawer,
                    splashRadius: 18,
                    tooltip: s.liveTvClose,
                  ),
                ],
              ),
            ),

            // Horizontal Category Filter Chips
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = cat == _landscapeSelectedCategory;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _landscapeSelectedCategory = cat;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.white.withValues(alpha: 0.12),
                          width: 0.8,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          s.liveTvCategoryLabel(cat),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected ? Colors.black : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Subtle smooth divider
            Divider(
              color: Colors.white.withValues(alpha: 0.08),
              height: 1,
              thickness: 0.8,
            ),

            // Channels List (without card, smooth thin borders)
            Expanded(
              child: displayedChannels.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _landscapeSelectedCategory == 'Favorit'
                              ? s.liveTvNoFavorites
                              : s.liveTvNoChannels,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: displayedChannels.length,
                      itemBuilder: (context, index) {
                        final ch = displayedChannels[index];
                        final isPlaying = ch.id == _currentChannel.id;

                        return Container(
                          decoration: BoxDecoration(
                            color: isPlaying
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : Colors.transparent,
                            border: Border(
                              bottom: BorderSide(
                                color: isPlaying
                                    ? AppColors.primary.withValues(alpha: 0.4)
                                    : Colors.white.withValues(alpha: 0.08),
                                width: 0.8,
                              ),
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                _playChannel(ch);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    // Channel Logo (Clean, no background box)
                                    SizedBox(
                                      width: 32,
                                      height: 32,
                                      child:
                                          ch.logoUrl != null &&
                                              ch.logoUrl!.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: ch.logoUrl!,
                                              httpHeaders: const {
                                                'User-Agent':
                                                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
                                              },
                                              fit: BoxFit.contain,
                                              errorWidget: (_, _, _) => Icon(
                                                Icons.tv_rounded,
                                                color: isPlaying
                                                    ? AppColors.primary
                                                    : Colors.white70,
                                                size: 18,
                                              ),
                                            )
                                          : Icon(
                                              Icons.tv_rounded,
                                              color: isPlaying
                                                  ? AppColors.primary
                                                  : Colors.white70,
                                              size: 18,
                                            ),
                                    ),
                                    const SizedBox(width: 10),

                                    // Channel Name & Category
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            ch.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              fontWeight: isPlaying
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: isPlaying
                                                  ? AppColors.primary
                                                  : Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            s.liveTvCategoryLabel(ch.category),
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Playing Indicator Badge
                                    if (isPlaying)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          s.liveTvNowPlaying.toUpperCase(),
                                          style: GoogleFonts.inter(
                                            fontSize: 7.5,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.black,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
