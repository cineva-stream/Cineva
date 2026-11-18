import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/platform/device_form_factor.dart';
import '../../data/models/subtitle_cue.dart';
import '../../data/models/subtitle_style_settings.dart';

/// Renders synchronized custom subtitles with customizable stroke outline,
/// font size, text color, bottom position, and background container.
///
/// Features intelligent responsive scaling for 1080p+ Windows Desktop and Android TV,
/// ensuring subtitles are effortlessly readable from couch viewing distance.
///
/// Optimized to prevent frequent rebuilds: only updates when the active subtitle text changes.
class CustomSubtitleOverlay extends StatefulWidget {
  final List<SubtitleCue> cues;
  final ValueListenable<Duration>? positionListenable;
  final Duration? currentPosition;
  final SubtitleStyleSettings settings;
  final bool? is1080pDesktopOrTvOverride;

  const CustomSubtitleOverlay({
    super.key,
    required this.cues,
    this.positionListenable,
    this.currentPosition,
    required this.settings,
    this.is1080pDesktopOrTvOverride,
  });

  @override
  State<CustomSubtitleOverlay> createState() => _CustomSubtitleOverlayState();
}

class _CustomSubtitleOverlayState extends State<CustomSubtitleOverlay> {
  SubtitleCue? _currentCue;

  @override
  void initState() {
    super.initState();
    widget.positionListenable?.addListener(_onPositionChanged);
    _checkActiveCue(
      widget.positionListenable?.value ??
          widget.currentPosition ??
          Duration.zero,
    );
  }

  @override
  void didUpdateWidget(CustomSubtitleOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.positionListenable != widget.positionListenable) {
      oldWidget.positionListenable?.removeListener(_onPositionChanged);
      widget.positionListenable?.addListener(_onPositionChanged);
    }
    _checkActiveCue(
      widget.positionListenable?.value ??
          widget.currentPosition ??
          Duration.zero,
    );
  }

  @override
  void dispose() {
    widget.positionListenable?.removeListener(_onPositionChanged);
    super.dispose();
  }

  void _onPositionChanged() {
    if (widget.positionListenable != null) {
      _checkActiveCue(widget.positionListenable!.value);
    }
  }

  void _checkActiveCue(Duration position) {
    if (widget.cues.isEmpty) {
      if (_currentCue != null) setState(() => _currentCue = null);
      return;
    }

    final adjustedPosition =
        position + Duration(milliseconds: widget.settings.syncOffsetMs);

    // If current cue is still active, avoid any rebuild!
    if (_currentCue != null && _currentCue!.isActiveAt(adjustedPosition)) {
      return;
    }

    SubtitleCue? matchingCue;
    for (final cue in widget.cues) {
      if (cue.isActiveAt(adjustedPosition)) {
        matchingCue = cue;
        break;
      }
    }

    if (matchingCue?.text != _currentCue?.text) {
      setState(() => _currentCue = matchingCue);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentCue == null || _currentCue!.text.isEmpty) {
      return const SizedBox.shrink();
    }

    final is1080pDesktopOrTv =
        widget.is1080pDesktopOrTvOverride ??
        is1080pOrHigherDesktopOrTv(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final maxSubtitleWidth = is1080pDesktopOrTv
        ? (screenWidth * 0.78).clamp(360.0, 1400.0)
        : (screenWidth - 64).clamp(240.0, 860.0);

    // Responsive font scaling for long text cues to guarantee zero screen overflow
    final text = _currentCue!.text;
    final textLength = text.length;

    double effectiveFontSize;
    if (is1080pDesktopOrTv) {
      // Enhanced 1.5x scale for Windows Desktop and Android TV at 1080p or higher (e.g. 20pt -> 30pt)
      // providing ideal contrast and readability for sofa/couch viewing distance.
      final baseSize = widget.settings.fontSize * 1.5;
      if (textLength > 90) {
        effectiveFontSize = (baseSize * 0.88).clamp(20.0, 36.0);
      } else if (textLength > 60) {
        effectiveFontSize = (baseSize * 0.94).clamp(22.0, 40.0);
      } else {
        effectiveFontSize = baseSize;
      }
    } else {
      effectiveFontSize = widget.settings.fontSize;
      if (textLength > 90) {
        effectiveFontSize = (widget.settings.fontSize * 0.85).clamp(12.0, 24.0);
      } else if (textLength > 60) {
        effectiveFontSize = (widget.settings.fontSize * 0.92).clamp(13.0, 26.0);
      }
    }

    final effectiveStrokeWidth = is1080pDesktopOrTv
        ? widget.settings.strokeWidth * 1.3
        : widget.settings.strokeWidth;

    final effectiveBottomOffset = is1080pDesktopOrTv
        ? (widget.settings.bottomOffset + 12.0)
        : widget.settings.bottomOffset;

    final paddingH = is1080pDesktopOrTv
        ? (widget.settings.backgroundOpacity > 0 ? 16.0 : 0.0)
        : (widget.settings.backgroundOpacity > 0 ? 12.0 : 0.0);
    final paddingV = is1080pDesktopOrTv
        ? (widget.settings.backgroundOpacity > 0 ? 6.0 : 0.0)
        : (widget.settings.backgroundOpacity > 0 ? 4.0 : 0.0);
    final containerRadius = is1080pDesktopOrTv ? 10.0 : 8.0;

    // Direct Positioned child for Stack with bottom offset from settings
    return Positioned(
      left: 24,
      right: 24,
      bottom: effectiveBottomOffset,
      child: IgnorePointer(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxSubtitleWidth),
            padding: EdgeInsets.symmetric(
              horizontal: paddingH,
              vertical: paddingV,
            ),
            decoration: BoxDecoration(
              color: widget.settings.backgroundOpacity > 0
                  ? Colors.black.withValues(
                      alpha: widget.settings.backgroundOpacity,
                    )
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(containerRadius),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ── Stroke / Outline Layer ──
                if (effectiveStrokeWidth > 0)
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    maxLines: 4,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                      fontSize: effectiveFontSize,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = effectiveStrokeWidth * 2
                        ..color = widget.settings.strokeColor,
                    ),
                  ),

                // ── Main Fill Text Layer ──
                Text(
                  text,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  maxLines: 4,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    fontSize: effectiveFontSize,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: widget.settings.textColor,
                    shadows: effectiveStrokeWidth <= 0
                        ? const [
                            Shadow(
                              blurRadius: 4.0,
                              color: Colors.black,
                              offset: Offset(1.5, 1.5),
                            ),
                          ]
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
