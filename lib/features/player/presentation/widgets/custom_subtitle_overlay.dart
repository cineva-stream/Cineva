import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/models/subtitle_cue.dart';
import '../../data/models/subtitle_style_settings.dart';

/// Renders synchronized custom subtitles with customizable stroke outline,
/// font size, text color, bottom position, and background container.
///
/// Optimized to prevent frequent rebuilds: only updates when the active subtitle text changes.
class CustomSubtitleOverlay extends StatefulWidget {
  final List<SubtitleCue> cues;
  final ValueListenable<Duration>? positionListenable;
  final Duration? currentPosition;
  final SubtitleStyleSettings settings;

  const CustomSubtitleOverlay({
    super.key,
    required this.cues,
    this.positionListenable,
    this.currentPosition,
    required this.settings,
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
    _checkActiveCue(widget.positionListenable?.value ?? widget.currentPosition ?? Duration.zero);
  }

  @override
  void didUpdateWidget(CustomSubtitleOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.positionListenable != widget.positionListenable) {
      oldWidget.positionListenable?.removeListener(_onPositionChanged);
      widget.positionListenable?.addListener(_onPositionChanged);
    }
    _checkActiveCue(widget.positionListenable?.value ?? widget.currentPosition ?? Duration.zero);
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

    final adjustedPosition = position + Duration(milliseconds: widget.settings.syncOffsetMs);

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

    final screenWidth = MediaQuery.of(context).size.width;
    final maxSubtitleWidth = (screenWidth - 64).clamp(240.0, 860.0);

    // Responsive font scaling for long text cues to guarantee zero screen overflow
    final text = _currentCue!.text;
    final textLength = text.length;
    double effectiveFontSize = widget.settings.fontSize;
    if (textLength > 90) {
      effectiveFontSize = (widget.settings.fontSize * 0.85).clamp(12.0, 24.0);
    } else if (textLength > 60) {
      effectiveFontSize = (widget.settings.fontSize * 0.92).clamp(13.0, 26.0);
    }

    // Direct Positioned child for Stack with bottom offset from settings
    return Positioned(
      left: 24,
      right: 24,
      bottom: widget.settings.bottomOffset,
      child: IgnorePointer(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxSubtitleWidth),
            padding: EdgeInsets.symmetric(
              horizontal: widget.settings.backgroundOpacity > 0 ? 12 : 0,
              vertical: widget.settings.backgroundOpacity > 0 ? 4 : 0,
            ),
            decoration: BoxDecoration(
              color: widget.settings.backgroundOpacity > 0
                  ? Colors.black.withValues(alpha: widget.settings.backgroundOpacity)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ── Stroke / Outline Layer ──
                if (widget.settings.strokeWidth > 0)
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
                        ..strokeWidth = widget.settings.strokeWidth * 2
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
                    shadows: widget.settings.strokeWidth <= 0
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
