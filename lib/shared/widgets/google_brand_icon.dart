import 'package:flutter/material.dart';

/// Clean Google brand icon loaded from assets/images/google-icon.png.
class GoogleBrandIcon extends StatelessWidget {
  final double size;

  const GoogleBrandIcon({
    super.key,
    this.size = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/google-icon.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.g_mobiledata_rounded,
        size: size,
        color: Colors.white,
      ),
    );
  }
}
