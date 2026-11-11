import 'package:flutter/material.dart';

/// Refined Color Palette for Cineva based on the 60-30-10 Design Rule.
///
/// Hierarchy:
/// - 60% Dominant Base: Pure OLED Pitch Black & Deep Obsidian canvas.
/// - 30% Secondary Structure: Charcoal Glass surfaces, frosted card containers, and squircle borders.
/// - 10% Focal Accent: Cinema Amber Gold and Adaptive Media-driven Vibrant Accents.
class AppColors {
  AppColors._();

  // ── 10% Focal Accent (Cinema Amber & Golden Ember) ──
  static const Color primary = Color(0xFFFF9500);       // Cinema Amber
  static const Color primaryDark = Color(0xFFE67E00);
  static const Color primaryLight = Color(0xFFFFB347);
  static const Color primaryVibrant = Color(0xFFFF8000);

  static const Color accent = Color(0xFFFFB800);         // Warm Gold
  static const Color accentDark = Color(0xFFCC9300);
  static const Color accentLight = Color(0xFFFFD466);

  // ── 60% Dominant Base Canvas (Pure OLED Black) ──
  static const Color background = Color(0xFF000000);     // Pure OLED Black
  static const Color canvas = Color(0xFF07070A);         // Deep Space Obsidian

  // ── 30% Secondary Structured Surfaces (Glass & Cards) ──
  static const Color surface = Color(0xFF121217);        // Charcoal Slate
  static const Color surfaceVariant = Color(0xFF161622); // Card Surfaces
  static const Color surfaceElevated = Color(0xFF1F1F2E);// Modals & Dialogs
  static const Color surfaceGlass = Color(0xD9161622);   // Frosted Glassmorphism

  // ── Borders & Outlines ──
  static const Color borderSubtle = Color(0x14FFFFFF);   // 8% White Border
  static const Color borderFocused = Color(0x33FFFFFF);  // 20% White Border
  static const Color borderGlow = Color(0x40FF9500);     // 25% Amber Border

  // ── Text Hierarchy ──
  static const Color textPrimary = Color(0xFFF8F8FA);    // High contrast crisp white
  static const Color textSecondary = Color(0xFFA1A1AA);  // Slate grey
  static const Color textMuted = Color(0xFF71717A);      // Muted caption grey

  // ── Semantic & Functional ──
  static const Color error = Color(0xFFFF453A);
  static const Color success = Color(0xFF30D158);
  static const Color warning = Color(0xFFFFD60A);
  static const Color info = Color(0xFF0A84FF);
  static const Color star = Color(0xFFFFC107);

  // ── Gradients ──
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF9500), Color(0xFFFF5E3A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF151520), Color(0xFF1A1A28)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient heroOverlay = LinearGradient(
    colors: [Colors.transparent, Color(0x99000000), Color(0xFF000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.65, 1.0],
  );

  // ── Dynamic Ambient Mesh Gradients ──
  /// Builds a smooth ambient mesh gradient that softly bleeds media color into pure black.
  static LinearGradient ambientMesh(Color tintColor, {double opacity = 0.28}) {
    return LinearGradient(
      colors: [
        tintColor.withValues(alpha: opacity),
        tintColor.withValues(alpha: opacity * 0.4),
        Colors.transparent,
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: const [0.0, 0.45, 1.0],
    );
  }

  /// Builds a soft radial glow centered on hero media.
  static RadialGradient ambientRadial(Color tintColor, {double opacity = 0.35}) {
    return RadialGradient(
      center: const Alignment(0.0, -0.2),
      radius: 0.95,
      colors: [
        tintColor.withValues(alpha: opacity),
        tintColor.withValues(alpha: opacity * 0.3),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  // ── Shimmer Effects ──
  static const Color shimmerBase = Color(0xFF151520);
  static const Color shimmerHighlight = Color(0xFF262638);
}
