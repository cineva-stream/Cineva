import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';

/// Floating cinematic 16:9 preview bubble rendered directly above the seek bar
/// during touch scrubbing (Android/Mobile) or mouse hover (Windows/Desktop).
///
/// Features:
/// - Prominent digital timestamp in HH:MM:SS or MM:SS format.
/// - Relative seek delta indicator (+05:30 forward in emerald / -02:15 backward in coral).
/// - 16:9 cinematic preview card with title and backdrop vignette.
/// - Relative progress track percentage.
/// - Downward pointing triangular beak/indicator aligned to the hover/thumb position.
/// - Horizontal boundary clamping preventing overflow at screen borders.
class TimelineMiniPreviewBubble extends StatelessWidget {
  final Duration targetTime;
  final Duration currentTime;
  final Duration totalDuration;
  final String? backdropUrl;
  final String? title;
  final double pointerPositionX;
  final double trackWidth;

  static const double bubbleWidth = 160.0;
  static const double bubbleHeight = 94.0;
  static const double beakHeight = 6.0;

  const TimelineMiniPreviewBubble({
    super.key,
    required this.targetTime,
    required this.currentTime,
    required this.totalDuration,
    this.backdropUrl,
    this.title,
    required this.pointerPositionX,
    required this.trackWidth,
  });

  /// Formats duration into digital timecode format (HH:MM:SS or MM:SS).
  static String formatTimestamp(Duration d, {bool forceHours = false}) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0 || forceHours) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  /// Formats delta duration compared to current playback position (+05:30 / -02:15).
  static String formatDelta(Duration target, Duration current) {
    final diffMs = target.inMilliseconds - current.inMilliseconds;
    if (diffMs.abs() < 1000) return '00:00';
    final sign = diffMs > 0 ? '+' : '-';
    final absDuration = Duration(milliseconds: diffMs.abs());
    return '$sign${formatTimestamp(absDuration, forceHours: absDuration.inHours > 0)}';
  }

  @override
  Widget build(BuildContext context) {
    if (trackWidth <= 0) return const SizedBox.shrink();

    // 1. Calculate clamped left offset for bubble container
    final rawLeft = pointerPositionX - (bubbleWidth / 2);
    final maxLeft = math.max(0.0, trackWidth - bubbleWidth);
    final clampedLeft = rawLeft.clamp(0.0, maxLeft);

    // 2. Calculate beak position relative to the bubble card
    final beakX = (pointerPositionX - clampedLeft).clamp(14.0, bubbleWidth - 14.0);

    // 3. Percentage calculation
    final totalSec = totalDuration.inSeconds;
    final targetSec = targetTime.inSeconds;
    final percent = totalSec > 0 ? (targetSec / totalSec).clamp(0.0, 1.0) : 0.0;

    final hasHours = totalDuration.inHours > 0 || targetTime.inHours > 0;
    final formattedTime = formatTimestamp(targetTime, forceHours: hasHours);
    final deltaText = formatDelta(targetTime, currentTime);
    final isForward = targetTime > currentTime;
    final isSignificantDelta = (targetTime.inSeconds - currentTime.inSeconds).abs() >= 1;

    return Positioned(
      left: clampedLeft,
      bottom: 24, // Sits comfortably above the slider track
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── The 16:9 Glassmorphic Card ──
          Container(
            width: bubbleWidth,
            height: bubbleHeight,
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.85),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Layer 1: Backdrop Image (if available)
                  if (backdropUrl != null && backdropUrl!.trim().isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: backdropUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: const Color(0xFF141416)),
                      errorWidget: (context, url, error) => Container(color: const Color(0xFF141416)),
                    )
                  else
                    Container(
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.9,
                          colors: [
                            Color(0xFF22242B),
                            Color(0xFF0F1014),
                          ],
                        ),
                      ),
                    ),

                  // Layer 2: OLED Vignette & Multi-stop Dark Gradient
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.65),
                            Colors.black.withValues(alpha: 0.40),
                            Colors.black.withValues(alpha: 0.85),
                            Colors.black.withValues(alpha: 0.96),
                          ],
                          stops: const [0.0, 0.35, 0.70, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Layer 3: Title Header (Top)
                  if (title != null && title!.trim().isNotEmpty)
                    Positioned(
                      top: 6,
                      left: 8,
                      right: 8,
                      child: Text(
                        title!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),

                  // Layer 4: Center Main Digital Timecode & Delta Pill
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (title != null && title!.trim().isNotEmpty)
                          const SizedBox(height: 6),
                        // Prominent Digital Time (HH:MM:SS)
                        Text(
                          formattedTime,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: hasHours ? 17.5 : 19.0,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.9),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 3),
                        // Seek Delta Indicator Pill
                        if (isSignificantDelta)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: isForward
                                  ? const Color(0xFF00E5FF).withValues(alpha: 0.18)
                                  : const Color(0xFFFF9100).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isForward
                                    ? const Color(0xFF00E5FF).withValues(alpha: 0.45)
                                    : const Color(0xFFFF9100).withValues(alpha: 0.45),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isForward
                                      ? Icons.fast_forward_rounded
                                      : Icons.fast_rewind_rounded,
                                  size: 10,
                                  color: isForward
                                      ? const Color(0xFF00E5FF)
                                      : const Color(0xFFFF9100),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  deltaText,
                                  style: GoogleFonts.inter(
                                    color: isForward
                                        ? const Color(0xFF00E5FF)
                                        : const Color(0xFFFF9100),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Layer 5: Mini Bottom Scrubber Bar & Percentage
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 3.5,
                      color: Colors.white12,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: percent,
                        child: Container(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Downward Pointer Beak / Arrow ──
          CustomPaint(
            size: const Size(bubbleWidth, beakHeight),
            painter: _BeakPainter(
              beakX: beakX,
              color: AppColors.background.withValues(alpha: 0.96),
              borderColor: Colors.white.withValues(alpha: 0.18),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the downward triangular beak pointer.
class _BeakPainter extends CustomPainter {
  final double beakX;
  final Color color;
  final Color borderColor;

  const _BeakPainter({
    required this.beakX,
    required this.color,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const halfWidth = 6.0;
    final path = Path()
      ..moveTo(beakX - halfWidth, 0)
      ..lineTo(beakX, size.height)
      ..lineTo(beakX + halfWidth, 0)
      ..close();

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final borderPath = Path()
      ..moveTo(beakX - halfWidth, 0)
      ..lineTo(beakX, size.height)
      ..lineTo(beakX + halfWidth, 0);
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _BeakPainter oldDelegate) {
    return oldDelegate.beakX != beakX ||
        oldDelegate.color != color ||
        oldDelegate.borderColor != borderColor;
  }
}
