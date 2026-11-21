import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/models/watch_party_room.dart';

/// Smooth, floating notification ala Dynamic Island iPhone for Watch Party.
/// Appears at the top-center of the player screen when player controls are hidden
/// and automatically dismisses after 5 seconds or via swipe-up / tap.
class WatchPartyDynamicIsland extends StatefulWidget {
  final WatchPartyMessage message;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const WatchPartyDynamicIsland({
    super.key,
    required this.message,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  State<WatchPartyDynamicIsland> createState() =>
      _WatchPartyDynamicIslandState();
}

class _WatchPartyDynamicIslandState extends State<WatchPartyDynamicIsland>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  Timer? _dismissTimer;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 240),
    );

    _scaleAnimation = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.6),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _controller.forward();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant WatchPartyDynamicIsland oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.id != widget.message.id) {
      _isDismissing = false;
      _controller.forward(from: 0.2);
      _startTimer();
    }
  }

  void _startTimer() {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 8), () {
      _handleDismiss();
    });
  }

  void _handleDismiss() {
    if (!mounted || _isDismissing) return;
    _isDismissing = true;
    _dismissTimer?.cancel();
    _controller.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  void _handleTap() {
    _dismissTimer?.cancel();
    widget.onTap();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    final isEmoji = msg.type == 'emoji' && msg.emoji != null;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: GestureDetector(
            onTap: _handleTap,
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null &&
                  details.primaryVelocity! < -80) {
                _handleDismiss();
              }
            },
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 160,
                      maxWidth: 360,
                      minHeight: 46,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.75),
                          blurRadius: 24,
                          spreadRadius: 2,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          blurRadius: 16,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Left Avatar / Icon
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: msg.isHost
                                ? const Color(0xFFFFD54F).withValues(alpha: 0.18)
                                : AppColors.primary.withValues(alpha: 0.2),
                          ),
                          child: Center(
                            child: msg.isHost
                                ? const Text(
                                    '👑',
                                    style: TextStyle(fontSize: 13),
                                  )
                                : const Icon(
                                    Iconsax.messages_2,
                                    size: 15,
                                    color: AppColors.primary,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Center Message Preview
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      msg.senderName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: msg.isHost
                                            ? const Color(0xFFFFD54F)
                                            : Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                  if (msg.isHost) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFD54F)
                                            .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'HOST',
                                        style: TextStyle(
                                          color: Color(0xFFFFD54F),
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isEmoji ? msg.emoji! : msg.text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  fontSize: isEmoji ? 18 : 12,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Right Pill / Arrow Indicator
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 10,
                            color: AppColors.textSecondary,
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
    );
  }
}
