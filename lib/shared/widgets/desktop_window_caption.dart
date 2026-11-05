import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:window_manager/window_manager.dart';

import '../../app/theme/app_colors.dart';

/// Modern, frameless Windows Title Bar with native-like custom window caption buttons.
///
/// Features:
/// - Hidden native OS title bar (clean, borderless OLED look).
/// - Full-width draggable area ([DragToMoveArea]) with double-click to toggle maximize.
/// - Custom Minimize, Maximize/Restore, and Close buttons (with native red close hover).
/// - Only renders on Desktop platforms (Windows, macOS, Linux). Returns [SizedBox.shrink] elsewhere.
class DesktopWindowCaption extends StatefulWidget {
  final Widget? leading;
  final String? title;
  final Color? backgroundColor;
  final double height;

  const DesktopWindowCaption({
    super.key,
    this.leading,
    this.title,
    this.backgroundColor,
    this.height = 36.0,
  });

  @override
  State<DesktopWindowCaption> createState() => _DesktopWindowCaptionState();
}

class _DesktopWindowCaptionState extends State<DesktopWindowCaption>
    with WindowListener {
  bool _isMaximized = true;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb &&
        !Platform.environment.containsKey('FLUTTER_TEST') &&
        (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      windowManager.addListener(this);
      _checkMaximized();
    }
  }

  @override
  void dispose() {
    if (!kIsWeb &&
        !Platform.environment.containsKey('FLUTTER_TEST') &&
        (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  Future<void> _checkMaximized() async {
    try {
      final maximized = await windowManager.isMaximized();
      if (mounted) {
        setState(() {
          _isMaximized = maximized;
        });
      }
    } catch (_) {}
  }

  @override
  void onWindowMaximize() {
    if (mounted) setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) setState(() => _isMaximized = false);
  }

  @override
  void onWindowRestore() {
    if (mounted) setState(() => _isMaximized = false);
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb ||
        Platform.environment.containsKey('FLUTTER_TEST') ||
        !(Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      return const SizedBox.shrink();
    }

    return Container(
      height: widget.height,
      color: widget.backgroundColor ?? AppColors.background,
      child: Row(
        children: [
          if (widget.leading != null) widget.leading!,
          // Draggable central area
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onDoubleTap: () async {
                if (await windowManager.isMaximized()) {
                  await windowManager.unmaximize();
                } else {
                  await windowManager.maximize();
                }
              },
              child: DragToMoveArea(
                child: SizedBox(
                  height: widget.height,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: widget.title != null
                          ? Text(
                              widget.title!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Window Caption Buttons: Minimize, Maximize/Restore, Close
          _CaptionButton(
            icon: Icons.remove_rounded,
            tooltip: 'Minimize',
            onTap: () => windowManager.minimize(),
          ),
          _CaptionButton(
            icon: _isMaximized
                ? Icons.filter_none_rounded
                : Icons.crop_square_rounded,
            iconSize: _isMaximized ? 13 : 15,
            tooltip: _isMaximized ? 'Restore' : 'Maximize',
            onTap: () async {
              if (await windowManager.isMaximized()) {
                await windowManager.unmaximize();
              } else {
                await windowManager.maximize();
              }
            },
          ),
          _CaptionButton(
            icon: Icons.close_rounded,
            tooltip: 'Close',
            isClose: true,
            onTap: () => windowManager.close(),
          ),
        ],
      ),
    );
  }
}

class _CaptionButton extends StatefulWidget {
  final IconData icon;
  final double iconSize;
  final String tooltip;
  final VoidCallback onTap;
  final bool isClose;

  const _CaptionButton({
    required this.icon,
    this.iconSize = 16,
    required this.tooltip,
    required this.onTap,
    this.isClose = false,
  });

  @override
  State<_CaptionButton> createState() => _CaptionButtonState();
}

class _CaptionButtonState extends State<_CaptionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final hoverColor = widget.isClose
        ? const Color(0xFFE81123)
        : Colors.white.withValues(alpha: 0.12);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 46,
          height: double.infinity,
          color: _isHovered ? hoverColor : Colors.transparent,
          alignment: Alignment.center,
          child: Icon(
            widget.icon,
            size: widget.iconSize,
            color: _isHovered && widget.isClose
                ? Colors.white
                : Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}
