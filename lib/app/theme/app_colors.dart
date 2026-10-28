import 'package:flutter/material.dart';

/// Color palette for Cineva — cinematic dark theme.
///
/// Deep Obsidian base with Cinema Amber accents and crisp white highlights
/// matching the launcher icon for an elite streaming experience.
class AppColors {
  AppColors._();

  // ── Primary Palette (Cinema Amber / Warm Orange) ──
  static const Color primary = Color(0xFFFF9500);       // Cinema Amber Orange
  static const Color primaryDark = Color(0xFFE67E00);
  static const Color primaryLight = Color(0xFFFFB347);

  // ── Accent / Secondary (Warm Gold / Ember) ──
  static const Color accent = Color(0xFFFFB800);         // Warm Gold
  static const Color accentDark = Color(0xFFCC9300);
  static const Color accentLight = Color(0xFFFFD466);

  // ── Background (Pure Smooth Black OLED) ──
  static const Color background = Color(0xFF000000);     // Pure Smooth Black
  static const Color surface = Color(0xFF121217);        // Charcoal Obsidian
  static const Color surfaceVariant = Color(0xFF181820); // Card Backgrounds
  static const Color surfaceElevated = Color(0xFF22222E);// Elevated Modals / Popups

  // ── Text ──
  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textMuted = Color(0xFF71717A);

  // ── Semantic ──
  static const Color error = Color(0xFFFF453A);
  static const Color success = Color(0xFF30D158);
  static const Color warning = Color(0xFFFFD60A);
  static const Color info = Color(0xFF0A84FF);

  // ── Rating Star ──
  static const Color star = Color(0xFFFFC107);

  // ── Gradients ──
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF9500), Color(0xFFFF5E3A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF16161E), Color(0xFF1F1F2B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient heroOverlay = LinearGradient(
    colors: [Colors.transparent, Color(0x99000000), Color(0xFF000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.65, 1.0],
  );

  // ── Shimmer ──
  static const Color shimmerBase = Color(0xFF181820);
  static const Color shimmerHighlight = Color(0xFF282834);
}

