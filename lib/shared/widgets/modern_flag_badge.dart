import 'package:flutter/material.dart';

/// A modern, crisp flag badge widget for Cineva.
///
/// Features:
/// - Smooth rounded corners and subtle hairline border
/// - Ambient shadow for depth on dark obsidian backgrounds
/// - Pixel-perfect custom vector painters for key flags (ID & US)
/// - High-fidelity regional indicator emoji rendering for all 65+ world countries
class ModernFlagBadge extends StatelessWidget {
  final String countryCode;
  final double width;
  final double height;
  final double borderRadius;

  const ModernFlagBadge({
    super.key,
    required this.countryCode,
    this.width = 26,
    this.height = 18,
    this.borderRadius = 4.0,
  });

  /// Converts 2-letter ISO country code to regional indicator flag emoji
  static String countryCodeToEmoji(String countryCode) {
    if (countryCode.length != 2) return '';
    final code = countryCode.toUpperCase();
    final firstChar = code.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final secondChar = code.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCodes([firstChar, secondChar]);
  }

  @override
  Widget build(BuildContext context) {
    final code = countryCode.toUpperCase();

    Widget flagContent;
    if (code == 'ID') {
      flagContent = const _IndonesiaFlagPainterWidget();
    } else if (code == 'US') {
      flagContent = const _UnitedStatesFlagPainterWidget();
    } else {
      // General world flag using regional indicator emoji
      final emoji = countryCodeToEmoji(code);
      flagContent = Center(
        child: Text(
          emoji,
          style: TextStyle(
            fontSize: height * 0.85,
            height: 1.0,
          ),
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2028),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - 0.5),
        child: flagContent,
      ),
    );
  }
}

/// Pixel-perfect vector representation of the Indonesian flag (Sang Saka Merah Putih)
class _IndonesiaFlagPainterWidget extends StatelessWidget {
  const _IndonesiaFlagPainterWidget();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(color: const Color(0xFFE70011)),
        ),
        Expanded(
          child: Container(color: const Color(0xFFFFFFFF)),
        ),
      ],
    );
  }
}

/// Modern stylized vector representation of the United States flag (Stars & Stripes)
class _UnitedStatesFlagPainterWidget extends StatelessWidget {
  const _UnitedStatesFlagPainterWidget();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 7 stripes (simplified for micro badge clarity)
        Column(
          children: List.generate(7, (index) {
            return Expanded(
              child: Container(
                color: index.isEven ? const Color(0xFFB22234) : const Color(0xFFFFFFFF),
              ),
            );
          }),
        ),
        // Blue canton in upper left
        FractionallySizedBox(
          widthFactor: 0.44,
          heightFactor: 0.58,
          child: Container(
            color: const Color(0xFF0A3161),
            alignment: Alignment.center,
            child: const Text(
              '★',
              style: TextStyle(
                color: Colors.white,
                fontSize: 6.5,
                height: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
