import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_colors.dart';

/// Reusable focusable wrapper for Android TV D-Pad and Desktop keyboard navigation.
///
/// Features requested:
/// - 1.11x scale magnification on focus with smooth cubic easing.
/// - Atmospheric Cinema Amber ambient smooth glow behind the child (no harsh borders).
/// - Automatic centering in view via [Scrollable.ensureVisible].
/// - Remote D-Pad (OK/Select) and Keyboard (Enter/Space) activation.
class TvFocusable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final FocusNode? focusNode;
  final bool autofocus;
  final double focusedScale;
  final Color? glowColor;
  final double glowBlurRadius;
  final double glowSpreadRadius;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;
  final ValueChanged<bool>? onFocusChange;

  const TvFocusable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.focusNode,
    this.autofocus = false,
    this.focusedScale = 1.11, // User preference: 1.11x magnification
    this.glowColor,
    this.glowBlurRadius = 16.0,
    this.glowSpreadRadius = 1.0,
    this.borderRadius,
    this.padding = EdgeInsets.zero,
    this.onFocusChange,
  });

  @override
  State<TvFocusable> createState() => _TvFocusableState();
}

class _TvFocusableState extends State<TvFocusable> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(TvFocusable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChange);
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_handleFocusChange);
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (!mounted) return;
    final hasFocus = _focusNode.hasFocus;
    if (_isFocused != hasFocus) {
      setState(() {
        _isFocused = hasFocus;
      });
      widget.onFocusChange?.call(hasFocus);

      if (hasFocus) {
        // Auto-center in viewport when focused via D-Pad remote or keyboard
        Scrollable.ensureVisible(
          context,
          alignment: 0.5,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.select ||
          key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.space ||
          key == LogicalKeyboardKey.gameButtonA) {
        widget.onTap?.call();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveGlowColor = widget.glowColor ?? AppColors.primary;
    final isHighlighted = _isFocused || _isHovered;
    final radius = widget.borderRadius ?? BorderRadius.circular(14);

    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: _handleKeyEvent,
      child: MouseRegion(
        cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: widget.padding,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 1.0,
                end: isHighlighted ? widget.focusedScale : 1.0,
              ),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  alignment: Alignment.center,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Atmospheric smooth ambient glow layer behind the poster (no border)
                      if (isHighlighted)
                        Positioned.fill(
                          child: AnimatedOpacity(
                            opacity: isHighlighted ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: radius,
                                boxShadow: [
                                  BoxShadow(
                                    color: effectiveGlowColor.withValues(alpha: 0.32),
                                    blurRadius: widget.glowBlurRadius,
                                    spreadRadius: widget.glowSpreadRadius,
                                    offset: Offset.zero,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      // Child content
                      widget.child,
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
