import 'package:flutter/material.dart';

/// Clean, crisp vector GitHub brand icon using the official Octocat silhouette.
class GithubBrandIcon extends StatelessWidget {
  final double size;
  final Color color;

  const GithubBrandIcon({
    super.key,
    this.size = 20.0,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GithubBrandPainter(color: color),
    );
  }
}

class _GithubBrandPainter extends CustomPainter {
  final Color color;

  _GithubBrandPainter({required this.color});

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

    // Official GitHub Octocat vector path
    path.moveTo(12, 2);
    path.cubicTo(6.477, 2, 2, 6.484, 2, 12.017);
    path.cubicTo(2, 16.442, 4.865, 20.197, 8.839, 21.521);
    path.cubicTo(9.339, 21.613, 9.521, 21.304, 9.521, 21.038);
    path.cubicTo(9.521, 20.801, 9.513, 20.17, 9.508, 19.335);
    path.cubicTo(6.726, 19.94, 6.139, 17.992, 6.139, 17.992);
    path.cubicTo(5.685, 16.834, 5.029, 16.526, 5.029, 16.526);
    path.cubicTo(4.121, 15.906, 5.098, 15.918, 5.098, 15.918);
    path.cubicTo(6.101, 15.988, 6.628, 16.95, 6.628, 16.95);
    path.cubicTo(7.52, 18.48, 8.969, 18.038, 9.538, 17.782);
    path.cubicTo(9.63, 17.135, 9.888, 16.694, 10.174, 16.444);
    path.cubicTo(7.954, 16.191, 5.619, 15.331, 5.619, 11.493);
    path.cubicTo(5.619, 10.4, 6.009, 9.505, 6.648, 8.805);
    path.cubicTo(6.545, 8.552, 6.202, 7.533, 6.746, 6.155);
    path.cubicTo(6.746, 6.155, 7.586, 5.885, 9.496, 7.181);
    path.cubicTo(10.294, 6.959, 11.149, 6.848, 12, 6.844);
    path.cubicTo(12.85, 6.848, 13.706, 6.959, 14.505, 7.181);
    path.cubicTo(16.414, 5.885, 17.253, 6.155, 17.253, 6.155);
    path.cubicTo(17.799, 7.533, 17.456, 8.552, 17.353, 8.805);
    path.cubicTo(17.993, 9.505, 18.381, 10.4, 18.381, 11.493);
    path.cubicTo(18.381, 15.341, 16.042, 16.188, 13.815, 16.436);
    path.cubicTo(14.174, 16.745, 14.493, 17.356, 14.493, 18.291);
    path.cubicTo(14.493, 19.629, 14.481, 20.71, 14.481, 21.038);
    path.cubicTo(14.481, 21.306, 14.661, 21.618, 15.169, 21.52);
    path.cubicTo(19.141, 20.194, 22, 16.441, 22, 12.017);
    path.cubicTo(22, 6.484, 17.522, 2, 12, 2);
    path.close();

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GithubBrandPainter oldDelegate) =>
      oldDelegate.color != color;
}
