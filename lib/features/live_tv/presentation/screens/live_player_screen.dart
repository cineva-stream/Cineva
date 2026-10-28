import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/datasources/live_tv_channels_data.dart';
import '../../domain/entities/live_tv_channel.dart';
import '../providers/live_tv_providers.dart';

/// Full-screen live television player powered by media_kit (MPV engine).
/// Features pure black background, real-time buffering indicator,
/// LIVE indicator badge, quick channel switcher sheet, and gesture controls.
class LivePlayerScreen extends ConsumerStatefulWidget {
  final LiveTvChannel channel;

  const LivePlayerScreen({
    super.key,
    required this.channel,
  });

  @override
  ConsumerState<LivePlayerScreen> createState() => _LivePlayerScreenState();
}

class _LivePlayerScreenState extends ConsumerState<LivePlayerScreen> {
  late LiveTvChannel _currentChannel;
  late final Player _player;
  late final VideoController _controller;

  bool _controlsVisible = true;
  Timer? _hideControlsTimer;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  BoxFit _videoFit = BoxFit.contain;

  @override
  void initState() {
    super.initState();
    _currentChannel = widget.channel;

    _player = Player(
      configuration: const PlayerConfiguration(
        bufferSize: 16 * 1024 * 1024,
      ),
    );
    _controller = VideoController(_player);

    _listenPlayerEvents();
    _playChannel(_currentChannel);

    // Hide system bars for cinematic experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _startHideTimer();
  }

  void _listenPlayerEvents() {
    _player.stream.buffering.listen((buffering) {
      if (mounted) {
        setState(() {
          _isLoading = buffering;
        });
      }
    });

    _player.stream.error.listen((error) {
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
    setState(() {
      _currentChannel = channel;
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      await _player.open(
        Media(
          channel.streamUrl,
          httpHeaders: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
          },
        ),
      );
      await _player.play();
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
                    final isCurrent = ch.id == _currentChannel.id;
                    return ListTile(
                      dense: true,
                      leading: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
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
    _player.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favoritesNotifier = ref.read(liveTvFavoritesProvider.notifier);
    final isFav = ref.watch(liveTvFavoritesProvider).contains(_currentChannel.id);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Video Surface ──
            Center(
              child: Video(
                controller: _controller,
                fit: _videoFit,
                controls: NoVideoControls,
              ),
            ),

            // ── Loading Spinner ──
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
                        'Menghubungkan ke siaran live...',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Error State ──
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
                          'Gagal Memuat Siaran Live',
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
                          onPressed: () => _playChannel(_currentChannel),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Coba Lagi'),
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

            // ── Overlay Controls ──
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
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.arrow_back_rounded,
                                    color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            _currentChannel.name,
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
                                      '${_currentChannel.category} • ${_currentChannel.quality}',
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
                                    favoritesNotifier.toggleFavorite(_currentChannel.id),
                                icon: Icon(
                                  isFav ? Icons.star_rounded : Icons.star_border_rounded,
                                  color: isFav ? AppColors.star : Colors.white70,
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Bottom Action Bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                onPressed: _showQuickChannelDrawer,
                                icon: const Icon(Icons.list_rounded, size: 18),
                                label: const Text('Daftar Saluran'),
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
                                    onPressed: () => _playChannel(_currentChannel),
                                    tooltip: 'Muat Ulang',
                                    icon: const Icon(Icons.refresh_rounded,
                                        color: Colors.white70, size: 20),
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
      ),
    );
  }
}
