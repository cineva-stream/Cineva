import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../../app/routes/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/tv_focusable.dart';
import '../providers/mini_player_provider.dart';

/// Floating, draggable, smoothly animated In-App Picture-in-Picture (Mini-Player)
/// overlay that preserves the live [Player] and [VideoController] without
/// restarting playback or dropping audio.
class MiniPlayerOverlay extends ConsumerStatefulWidget {
  const MiniPlayerOverlay({super.key});

  @override
  ConsumerState<MiniPlayerOverlay> createState() => _MiniPlayerOverlayState();
}

enum _MiniCorner { topLeft, topRight, bottomLeft, bottomRight }

class _MiniPlayerOverlayState extends ConsumerState<MiniPlayerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  _MiniCorner _corner = _MiniCorner.bottomRight;
  Offset? _dragOffset;
  bool _isDragging = false;
  bool _showControls = true;
  bool _isHovering = false;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
      reverseDuration: const Duration(milliseconds: 240),
    );
    final curved = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _scaleAnim = Tween<double>(begin: 0.82, end: 1.0).animate(curved);
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.0, 0.14),
      end: Offset.zero,
    ).animate(curved);
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _scheduleHideControls() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_isHovering) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleMiniControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _scheduleHideControls();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  Future<void> _expandToFullPlayer(MiniPlayerSession session) async {
    _hideControlsTimer?.cancel();
    await _animController.reverse();
    ref.read(miniPlayerProvider.notifier).prepareForExpand();
    appRouter.push('/player', extra: session.toRouteExtra());
  }

  Future<void> _closeMiniPlayer() async {
    _hideControlsTimer?.cancel();
    await _animController.reverse();
    await ref.read(miniPlayerProvider.notifier).closeAndDispose();
  }

  Offset _computeCornerPosition({
    required Size screenSize,
    required EdgeInsets padding,
    required double width,
    required double height,
  }) {
    const margin = 16.0;
    final topMin = padding.top + margin + 12.0;
    // Leave clearance above bottom navigation bar on mobile/tablet
    final bottomReserve = screenSize.width < 700 ? 78.0 : 24.0;
    final bottomMax =
        (screenSize.height - padding.bottom - bottomReserve - height).clamp(
          topMin,
          screenSize.height - height - margin,
        );
    final leftMin = padding.left + margin;
    final rightMax = (screenSize.width - padding.right - width - margin).clamp(
      leftMin,
      screenSize.width - width - margin,
    );

    return switch (_corner) {
      _MiniCorner.topLeft => Offset(leftMin, topMin),
      _MiniCorner.topRight => Offset(rightMax, topMin),
      _MiniCorner.bottomLeft => Offset(leftMin, bottomMax),
      _MiniCorner.bottomRight => Offset(rightMax, bottomMax),
    };
  }

  void _snapToNearestCorner(
    Offset currentOffset,
    Size screenSize,
    double width,
    double height,
  ) {
    final centerX = currentOffset.dx + width / 2;
    final centerY = currentOffset.dy + height / 2;
    final isLeft = centerX < screenSize.width / 2;
    final isTop = centerY < screenSize.height / 2;

    setState(() {
      _isDragging = false;
      _dragOffset = null;
      if (isTop && isLeft) {
        _corner = _MiniCorner.topLeft;
      } else if (isTop && !isLeft) {
        _corner = _MiniCorner.topRight;
      } else if (!isTop && isLeft) {
        _corner = _MiniCorner.bottomLeft;
      } else {
        _corner = _MiniCorner.bottomRight;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(miniPlayerProvider);
    if (session == null || session.isExpandingToFullPlayer) {
      if (_animController.value > 0 && !_animController.isAnimating) {
        _animController.reset();
      }
      return const SizedBox.shrink();
    }

    if (_animController.status == AnimationStatus.dismissed) {
      _animController.forward();
      _showControls = true;
      _scheduleHideControls();
    }

    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final isWide = screenSize.width >= 700;
    final miniWidth = isWide ? 320.0 : 236.0;
    final miniHeight = isWide ? 180.0 : 133.0;

    final targetCornerPos = _computeCornerPosition(
      screenSize: screenSize,
      padding: mediaQuery.padding,
      width: miniWidth,
      height: miniHeight,
    );
    final activePos = _isDragging && _dragOffset != null
        ? _dragOffset!
        : targetCornerPos;

    final posListenable = ref.read(miniPlayerProvider.notifier).positionNotifier;
    final controlsVisible = _showControls || _isHovering;

    return Stack(
      children: [
        AnimatedPositioned(
          duration: _isDragging
              ? Duration.zero
              : const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          left: activePos.dx,
          top: activePos.dy,
          width: miniWidth,
          height: miniHeight,
          child: SlideTransition(
            position: _slideAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: MouseRegion(
                  onEnter: (_) {
                    setState(() {
                      _isHovering = true;
                      _showControls = true;
                    });
                    _hideControlsTimer?.cancel();
                  },
                  onExit: (_) {
                    setState(() => _isHovering = false);
                    _scheduleHideControls();
                  },
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _toggleMiniControls,
                    onDoubleTap: () => _expandToFullPlayer(session),
                    onPanStart: (_) {
                      setState(() {
                        _isDragging = true;
                        _dragOffset = targetCornerPos;
                      });
                    },
                    onPanUpdate: (details) {
                      final next = (_dragOffset ?? targetCornerPos) + details.delta;
                      setState(() {
                        _dragOffset = Offset(
                          next.dx.clamp(
                            8.0,
                            (screenSize.width - miniWidth - 8.0).clamp(8.0, double.infinity),
                          ),
                          next.dy.clamp(
                            8.0,
                            (screenSize.height - miniHeight - 8.0).clamp(8.0, double.infinity),
                          ),
                        );
                      });
                    },
                    onPanEnd: (_) {
                      _snapToNearestCorner(
                        _dragOffset ?? targetCornerPos,
                        screenSize,
                        miniWidth,
                        miniHeight,
                      );
                    },
                    child: Material(
                      color: Colors.transparent,
                      elevation: 18,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B0B0F),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.45),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.75),
                              blurRadius: 22,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // 1. Live Uninterrupted Video Surface
                              IgnorePointer(
                                child: Video(
                                  controller: session.videoController,
                                  controls: NoVideoControls,
                                  subtitleViewConfiguration:
                                      const SubtitleViewConfiguration(
                                        visible: false,
                                      ),
                                  fit: BoxFit.cover,
                                ),
                              ),

                              // 2. Buffering Indicator
                              if (session.isBuffering)
                                const IgnorePointer(
                                  child: Center(
                                    child: SizedBox(
                                      width: 26,
                                      height: 26,
                                      child: CircularProgressIndicator(
                                        color: AppColors.primary,
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                  ),
                                ),

                              // 3. Interactive Controls Overlay
                              AnimatedOpacity(
                                opacity: controlsVisible ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 180),
                                child: IgnorePointer(
                                  ignoring: !controlsVisible,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.black.withValues(alpha: 0.8),
                                          Colors.black.withValues(alpha: 0.35),
                                          Colors.black.withValues(alpha: 0.8),
                                        ],
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Top Row: Title + Expand + Close
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            10,
                                            6,
                                            6,
                                            0,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      session.title,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11.5,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                    if (session.season !=
                                                            null &&
                                                        session.episode != null)
                                                      Text(
                                                        'S${session.season}:E${session.episode}',
                                                        style: const TextStyle(
                                                          color:
                                                              AppColors.primary,
                                                          fontSize: 9.5,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              TvFocusable(
                                                onTap: () =>
                                                    _expandToFullPlayer(session),
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(5),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withValues(
                                                          alpha: 0.14,
                                                        ),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.open_in_full_rounded,
                                                    color: Colors.white,
                                                    size: 14,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              TvFocusable(
                                                onTap: _closeMiniPlayer,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(5),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withValues(
                                                          alpha: 0.14,
                                                        ),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.close_rounded,
                                                    color: Colors.white,
                                                    size: 14,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Center Row: -10s, Play/Pause, +10s
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            TvFocusable(
                                              onTap: () {
                                                ref
                                                    .read(
                                                      miniPlayerProvider
                                                          .notifier,
                                                    )
                                                    .seekRelative(-10);
                                                _scheduleHideControls();
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              child: const Padding(
                                                padding: EdgeInsets.all(6),
                                                child: Icon(
                                                  Icons.replay_10_rounded,
                                                  color: Colors.white,
                                                  size: 22,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            TvFocusable(
                                              onTap: () {
                                                ref
                                                    .read(
                                                      miniPlayerProvider
                                                          .notifier,
                                                    )
                                                    .togglePlayPause();
                                                _scheduleHideControls();
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(22),
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary
                                                      .withValues(alpha: 0.2),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  session.isPlaying
                                                      ? Icons.pause_rounded
                                                      : Icons.play_arrow_rounded,
                                                  color: AppColors.primary,
                                                  size: 28,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            TvFocusable(
                                              onTap: () {
                                                ref
                                                    .read(
                                                      miniPlayerProvider
                                                          .notifier,
                                                    )
                                                    .seekRelative(10);
                                                _scheduleHideControls();
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              child: const Padding(
                                                padding: EdgeInsets.all(6),
                                                child: Icon(
                                                  Icons.forward_10_rounded,
                                                  color: Colors.white,
                                                  size: 22,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 6),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // 4. Bottom Live Progress Bar
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: ValueListenableBuilder<Duration>(
                                  valueListenable: posListenable,
                                  builder: (context, pos, _) {
                                    final durMs =
                                        session.duration.inMilliseconds;
                                    final progress = durMs > 0
                                        ? (pos.inMilliseconds / durMs).clamp(
                                            0.0,
                                            1.0,
                                          )
                                        : 0.0;
                                    return LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 3.0,
                                      backgroundColor: Colors.white24,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            AppColors.primary,
                                          ),
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
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

