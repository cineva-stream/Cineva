import 'package:flutter/material.dart';

/// Clean, crisp vector Telegram brand icon using the official Telegram paper-plane silhouette.
class TelegramBrandIcon extends StatelessWidget {
  final double size;
  final Color color;

  const TelegramBrandIcon({
    super.key,
    this.size = 22.0,
    this.color = const Color(0xFF2AABEE),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _TelegramBrandPainter(color: color),
    );
  }
}

class _TelegramBrandPainter extends CustomPainter {
  final Color color;

  _TelegramBrandPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path();
    canvas.save();
    canvas.scale(scale, scale);

    // Official Telegram paper-plane vector silhouette (24x24 viewBox)
    path.moveTo(20.665, 3.717);
    path.lineTo(2.93, 10.554);
    path.cubicTo(1.72, 11.04, 1.727, 11.715, 2.708, 12.016);
    path.lineTo(7.261, 13.436);
    path.lineTo(17.797, 6.791);
    path.cubicTo(18.295, 6.488, 18.75, 6.651, 18.376, 6.983);
    path.lineTo(9.84, 14.684);
    path.lineTo(9.526, 19.374);
    path.cubicTo(9.986, 19.374, 10.19, 19.163, 10.448, 18.913);
    path.lineTo(12.661, 16.762);
    path.lineTo(17.265, 20.164);
    path.cubicTo(18.114, 20.631, 18.723, 20.391, 18.934, 19.376);
    path.lineTo(21.957, 5.131);
    path.cubicTo(22.266, 3.892, 21.484, 3.331, 20.665, 3.717);
    path.close();

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TelegramBrandPainter oldDelegate) =>
      oldDelegate.color != color;
}
