import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_language.dart';
import '../../domain/entities/watch_insights.dart';
import '../../domain/models/user_profile.dart';
import 'avatar_display.dart';

/// Standard ISO/IEC 7810 ID-1 (ID / ATM Card) aspect ratio: 85.60mm × 53.98mm = 1.5858.
const double kMemberCardAspectRatio = 1.586;

/// Instagram-inspired Verified Blue color for the user's name badge.
const Color kVerifiedBlueColor = Color(0xFF0095F6);

/// Renders an executive, modern, high-legibility shareable Cineva Member Card
/// with an Instagram-style Blue Verified Badge (`Icons.verified_rounded`) next to the user's name.
class CinevaMemberCardWidget extends StatelessWidget {
  final UserProfile profile;
  final WatchInsights insights;
  final AppLanguage language;
  final MemberCardStyle style;
  final GlobalKey? repaintBoundaryKey;

  const CinevaMemberCardWidget({
    super.key,
    required this.profile,
    required this.insights,
    required this.language,
    required this.style,
    this.repaintBoundaryKey,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardCanvas = AspectRatio(
      aspectRatio: kMemberCardAspectRatio,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 540,
          height: 540 / kMemberCardAspectRatio, // ~340.48
          child: style == MemberCardStyle.ktp
              ? _ModernMemberIdCardLayout(
                  profile: profile,
                  insights: insights,
                  language: language,
                )
              : _ExecutiveMetalCardLayout(
                  profile: profile,
                  insights: insights,
                  language: language,
                ),
        ),
      ),
    );

    if (repaintBoundaryKey != null) {
      cardCanvas = RepaintBoundary(
        key: repaintBoundaryKey,
        child: cardCanvas,
      );
    }

    return cardCanvas;
  }
}

/// Reusable Instagram-style Blue Verified Badge (`Icons.verified_rounded`)
/// adapted from the Version Badge in `AboutInfoScreen`.
class _BlueVerifiedNameBadge extends StatelessWidget {
  final double size;
  const _BlueVerifiedNameBadge({this.size = 22});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: kVerifiedBlueColor.withValues(alpha: 0.45),
            blurRadius: 8,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // White inner backing so the checkmark inside Icons.verified_rounded pops cleanly
          Container(
            width: size * 0.48,
            height: size * 0.48,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          Icon(
            Icons.verified_rounded,
            size: size,
            color: kVerifiedBlueColor,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STYLE 1: MODERN MEMBER ID CARD (Rich Obsidian, Blue Verified Badge & Glass Dock)
// ═══════════════════════════════════════════════════════════════════════════

class _ModernMemberIdCardLayout extends StatelessWidget {
  final UserProfile profile;
  final WatchInsights insights;
  final AppLanguage language;

  const _ModernMemberIdCardLayout({
    required this.profile,
    required this.insights,
    required this.language,
  });

  String _tr(String id, String en, String hi) {
    if (language.isHindi) return hi;
    if (language.isIndonesian) return id;
    return en;
  }

  @override
  Widget build(BuildContext context) {
    final persona = insights.personaTitle(language);
    final durationStr = insights.formattedDurationCompact(language);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0E1422),
            Color(0xFF0A0D16),
            Color(0xFF141122),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Subtle geometric luxury wave mesh
          const Positioned.fill(
            child: CustomPaint(
              painter: _ModernCardMeshPainter(isMetal: false),
            ),
          ),

          // Top-right Cinema Amber ambient glow
          Positioned(
            top: -75,
            right: -45,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Bottom-left Verified Blue ambient glow
          Positioned(
            bottom: -85,
            left: -40,
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    kVerifiedBlueColor.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(28, 22, 28, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ── 1. Top Header: CINEVA. Brand + Frosted Member ID Pill ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, Color(0xFFFF8F00)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.black,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'CINEVA',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3.0,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 3, top: 4),
                          width: 5.5,
                          height: 5.5,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          'ID • ${insights.ktpNikNumber}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // ── 2. Center Hero: Framed Avatar + Name with Blue Verified Badge ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Dual-ring glowing avatar frame
                    Container(
                      padding: const EdgeInsets.all(3.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primary,
                            kVerifiedBlueColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: AvatarDisplay(
                        avatarId: profile.avatarId,
                        customAvatarPath: profile.customAvatarPath,
                        size: 74,
                        borderWidth: 2.0,
                        borderColor: const Color(0xFF0A0D16),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Name + Instagram-style Blue Verified Badge
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  profile.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 25,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.4,
                                    height: 1.15,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 7),
                              const _BlueVerifiedNameBadge(size: 22),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '@${profile.username}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Subtle frosted persona pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              persona,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ── 3. Bottom Bar: Frosted Glass Stats Dock + Scannable QR ──
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.07),
                        Colors.white.withValues(alpha: 0.03),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _LargeCardMetric(
                          label: _tr('WAKTU NONTON', 'WATCH TIME', 'देखने का समय'),
                          value: durationStr,
                          valueColor: AppColors.primaryLight,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 34,
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: _LargeCardMetric(
                          label: _tr('FILM', 'MOVIES', 'फ़िल्में'),
                          value: '${insights.moviesWatchedCount}',
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 34,
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: _LargeCardMetric(
                          label: _tr('EPISODE', 'EPISODES', 'एपिसोड'),
                          value: '${insights.episodesWatchedCount}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: QrImageView(
                            data:
                                'https://github.com/cineva-stream/Cineva/releases',
                            size: 48,
                            padding: EdgeInsets.zero,
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LargeCardMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _LargeCardMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: valueColor ?? Colors.white,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STYLE 2: EXECUTIVE METAL CARD (Brushed Titanium, Blue Verified Badge & EMV Chip)
// ═══════════════════════════════════════════════════════════════════════════

class _ExecutiveMetalCardLayout extends StatelessWidget {
  final UserProfile profile;
  final WatchInsights insights;
  final AppLanguage language;

  const _ExecutiveMetalCardLayout({
    required this.profile,
    required this.insights,
    required this.language,
  });

  String _tr(String id, String en, String hi) {
    if (language.isHindi) return hi;
    if (language.isIndonesian) return id;
    return en;
  }

  @override
  Widget build(BuildContext context) {
    final persona = insights.personaTitle(language);
    final compactDuration = insights.formattedDurationCompact(language);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A1B23),
            Color(0xFF0D0E13),
            Color(0xFF1C1712),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.38),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Brushed Titanium diagonal sheen
          const Positioned.fill(
            child: CustomPaint(
              painter: _ModernCardMeshPainter(isMetal: true),
            ),
          ),

          // Warm gold top-right specular sheen
          Positioned(
            top: -85,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(28, 22, 28, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ── 1. Top Row: Brand Wordmark + Persona + Avatar ──
                Row(
                  children: [
                    Text(
                      'CINEVA',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3.4,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 3, top: 4),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        persona,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    AvatarDisplay(
                      avatarId: profile.avatarId,
                      customAvatarPath: profile.customAvatarPath,
                      size: 44,
                      borderWidth: 1.5,
                      borderColor: AppColors.primary,
                    ),
                  ],
                ),

                // ── 2. Middle Row: Metallic Smart Chip + Crisp 16-Digit Number ──
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const _MinimalSmartChip(),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.contactless_rounded,
                          color: Colors.white.withValues(alpha: 0.55),
                          size: 24,
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        insights.atmCardNumber,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.8,
                          color: const Color(0xFFF5E8D0),
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.75),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // ── 3. Bottom Row: Cardholder (with Blue Verified Badge), Watch Time, Titles + QR ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _MetalMetaColumn(
                        label: _tr('PEMILIK KARTU', 'CARDHOLDER', 'कार्डधारक'),
                        value: profile.name,
                        subValue: '@${profile.username}',
                        showVerifiedBadge: true,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: _MetalMetaColumn(
                        label: _tr('TOTAL DURASI', 'WATCH TIME', 'कुल समय'),
                        value: compactDuration,
                        subValue: _tr(
                          '${insights.activeDaysCount} hari aktif',
                          '${insights.activeDaysCount} active days',
                          '${insights.activeDaysCount} सक्रिय दिन',
                        ),
                        valueColor: AppColors.primaryLight,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: _MetalMetaColumn(
                        label: _tr('TONTONAN', 'WATCHED', 'देखे गए'),
                        value:
                            '${insights.moviesWatchedCount}F • ${insights.episodesWatchedCount}EP',
                        subValue: '${insights.completionRatePercent}% selesai',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: QrImageView(
                          data:
                              'https://github.com/cineva-stream/Cineva/releases',
                          size: 48,
                          padding: EdgeInsets.zero,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetalMetaColumn extends StatelessWidget {
  final String label;
  final String value;
  final String subValue;
  final Color? valueColor;
  final bool showVerifiedBadge;

  const _MetalMetaColumn({
    required this.label,
    required this.value,
    required this.subValue,
    this.valueColor,
    this.showVerifiedBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? Colors.white,
                ),
              ),
            ),
            if (showVerifiedBadge) ...[
              const SizedBox(width: 5),
              const _BlueVerifiedNameBadge(size: 17),
            ],
          ],
        ),
        const SizedBox(height: 1),
        Text(
          subValue,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _MinimalSmartChip extends StatelessWidget {
  const _MinimalSmartChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 35,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF3D98B),
            Color(0xFFC89D28),
            Color(0xFFF3D98B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 0.7,
        ),
      ),
      child: CustomPaint(
        painter: _ChipLinePainter(),
      ),
    );
  }
}

class _ChipLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF5E4708).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final w = size.width;
    final h = size.height;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.30, h * 0.22, w * 0.40, h * 0.56),
        const Radius.circular(3),
      ),
      paint,
    );
    canvas.drawLine(Offset(0, h * 0.36), Offset(w * 0.30, h * 0.36), paint);
    canvas.drawLine(Offset(0, h * 0.64), Offset(w * 0.30, h * 0.64), paint);
    canvas.drawLine(Offset(w * 0.70, h * 0.36), Offset(w, h * 0.36), paint);
    canvas.drawLine(Offset(w * 0.70, h * 0.64), Offset(w, h * 0.64), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ModernCardMeshPainter extends CustomPainter {
  final bool isMetal;
  const _ModernCardMeshPainter({required this.isMetal});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isMetal
          ? Colors.white.withValues(alpha: 0.028)
          : kVerifiedBlueColor.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 5; i++) {
      final path = Path();
      final startY = size.height * (0.18 + i * 0.16);
      path.moveTo(0, startY);
      for (double x = 0; x <= size.width; x += 14) {
        final y =
            startY + math.sin((x / size.width) * math.pi * 2.2 + i * 0.7) * 16;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
