import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_language.dart';
import '../../domain/entities/watch_insights.dart';
import '../../domain/models/user_profile.dart';
import 'avatar_display.dart';

/// Standard ISO/IEC 7810 ID-1 (KTP / ATM Card) aspect ratio: 85.60mm × 53.98mm = 1.5858.
const double kMemberCardAspectRatio = 1.586;

/// Renders a high-precision, shareable KTP (Kartu Tanda Penonton) or VIP Black Titanium ATM Card.
///
/// Uses an internal fixed logical resolution (540 × 340.5) inside a [FittedBox]
/// so that proportions, typography, QR code, and holographic details remain
/// razor-sharp at any display width and when exported at 3.0x pixelRatio.
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
              ? _KtpSinemaCardLayout(
                  profile: profile,
                  insights: insights,
                  language: language,
                )
              : _AtmBlackTitaniumCardLayout(
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

// ═══════════════════════════════════════════════════════════════════════════
// EDITION 1: KTP REPUBLIK SINEMA (KARTU TANDA PENONTON)
// ═══════════════════════════════════════════════════════════════════════════

class _KtpSinemaCardLayout extends StatelessWidget {
  final UserProfile profile;
  final WatchInsights insights;
  final AppLanguage language;

  const _KtpSinemaCardLayout({
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
    final durationStr = insights.formattedDurationVerbose(language);
    final movies = insights.moviesWatchedCount;
    final episodes = insights.episodesWatchedCount;
    final rating = insights.averageRating.toStringAsFixed(1);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0E1B2A),
            Color(0xFF0C1322),
            Color(0xFF171324),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.55),
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.14),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Subtle Holographic Guilloche Security Lines
          const Positioned.fill(
            child: CustomPaint(
              painter: _GuillochePatternPainter(isKtp: true),
            ),
          ),

          // Ambient holographic cyan & amber glow orbs
          Positioned(
            top: -50,
            right: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00E5FF).withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: 40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Card Content
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Official KTP Top Header ──
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFFFF8F00)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_movies_rounded,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _tr(
                              'REPUBLIK SINEMA CINEVA',
                              'REPUBLIC OF CINEVA CINEMA',
                              'सिनेवा सिनेमा गणराज्य',
                            ),
                            style: GoogleFonts.outfit(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.8,
                              color: AppColors.primaryLight,
                            ),
                          ),
                          Text(
                            _tr(
                              'KARTU TANDA PENONTON (KTP) • WARGA VIP',
                              'OFFICIAL VIEWER IDENTITY CARD (KTP) • VIP CITIZEN',
                              'आधिकारिक दर्शक पहचान पत्र (KTP) • VIP नागरिक',
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: const Color(0xFF7CE8FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Text(
                        'CINEVA.${insights.memberSinceYear}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                Container(
                  height: 1.2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        const Color(0xFF00E5FF).withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ── NIK Sinema Bar ──
                Row(
                  children: [
                    Text(
                      _tr('NIK SINEMA', 'CINEMA ID', 'सिनेमा आईडी'),
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        ':  ${insights.ktpNikNumber}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Main Body: Left Fields + Right Photo & QR ──
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Biodata & Watch Record Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _KtpFieldRow(
                              label: _tr('Nama Lengkap', 'Full Name', 'पूरा नाम'),
                              value: profile.name.toUpperCase(),
                              isBoldValue: true,
                            ),
                            _KtpFieldRow(
                              label: _tr('Username', 'Username', 'यूज़रनेम'),
                              value: '@${profile.username}',
                              valueColor: const Color(0xFF7CE8FF),
                            ),
                            _KtpFieldRow(
                              label: _tr('Pangkat / Gelar', 'Official Rank', 'आधिकारिक पद'),
                              value: 'LV.${insights.personaLevel} • $persona',
                              isHighlightBadge: true,
                            ),
                            _KtpFieldRow(
                              label: _tr('Jam Terbang', 'Watch Hours', 'देखने का समय'),
                              value: durationStr,
                              isBoldValue: true,
                            ),
                            _KtpFieldRow(
                              label: _tr('Rekor Tamat', 'Watch Record', 'रिकॉर्ड'),
                              value: _tr(
                                '$movies Film • $episodes Episode ($rating ⭐)',
                                '$movies Movies • $episodes Episodes ($rating ⭐)',
                                '$movies फ़िल्में • $episodes एपिसोड ($rating ⭐)',
                              ),
                            ),
                            _KtpFieldRow(
                              label: _tr('Domisili', 'Domicile', 'निवास'),
                              value: _tr(
                                'Kasur & Sofa Rebahan 4K',
                                'VIP Couch & 4K Home Theater',
                                'VIP सोफ़ा और 4K होम थिएटर',
                              ),
                            ),
                            _KtpFieldRow(
                              label: _tr('Berlaku Hingga', 'Valid Thru', 'वैधता'),
                              value: _tr(
                                'SEUMUR HIDUP (100% GRATIS)',
                                'LIFETIME (100% FREE FOREVER)',
                                'आजीवन (100% मुफ़्त)',
                              ),
                              valueColor: AppColors.success,
                              isBoldValue: true,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Right Column: Framed Avatar Photo + QR Download Stamp
                      SizedBox(
                        width: 132,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Framed KTP Avatar Photo Box
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primary.withValues(alpha: 0.25),
                                          const Color(0xFF00E5FF).withValues(alpha: 0.15),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: AppColors.primary.withValues(alpha: 0.6),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        AvatarDisplay(
                                          avatarId: profile.avatarId,
                                          customAvatarPath: profile.customAvatarPath,
                                          size: 58,
                                          borderWidth: 1.5,
                                          borderColor: AppColors.primaryLight,
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 1.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'VERIFIED',
                                            style: GoogleFonts.inter(
                                              fontSize: 7.5,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.8,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // QR Code + Callout
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 44,
                                          height: 44,
                                          child: QrImageView(
                                            data:
                                                'https://github.com/cineva-stream/Cineva/releases',
                                            size: 44,
                                            padding: EdgeInsets.zero,
                                            backgroundColor: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'GET APP',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              Text(
                                                'Scan & Stream Free on Cineva',
                                                style: GoogleFonts.inter(
                                                  fontSize: 6.8,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.black87,
                                                  height: 1.15,
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
                            ),
                          ],
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

class _KtpFieldRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBoldValue;
  final bool isHighlightBadge;
  final Color? valueColor;

  const _KtpFieldRow({
    required this.label,
    required this.value,
    this.isBoldValue = false,
    this.isHighlightBadge = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          ': ',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: isHighlightBadge
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.55),
                        width: 0.9,
                      ),
                    ),
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ),
                )
              : Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10.8,
                    fontWeight: isBoldValue ? FontWeight.w800 : FontWeight.w600,
                    color: valueColor ?? Colors.white,
                  ),
                ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EDITION 2: CINEVA BLACK TITANIUM VIP ATM CARD
// ═══════════════════════════════════════════════════════════════════════════

class _AtmBlackTitaniumCardLayout extends StatelessWidget {
  final UserProfile profile;
  final WatchInsights insights;
  final AppLanguage language;

  const _AtmBlackTitaniumCardLayout({
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
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF14141B),
            Color(0xFF0A0A0F),
            Color(0xFF1B1610),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFFFFC107).withValues(alpha: 0.45),
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Brushed Titanium Metallic Lines
          const Positioned.fill(
            child: CustomPaint(
              painter: _GuillochePatternPainter(isKtp: false),
            ),
          ),

          // Gold Metallic Specular Sheen
          Positioned(
            top: -80,
            right: -60,
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

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ── Top Row: Brand Logo + VIP Black Reserve + Contactless Icon ──
                Row(
                  children: [
                    Text(
                      'CINEVA',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3.5,
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.22),
                            AppColors.primary.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        'BLACK TITANIUM • VIP STREAM',
                        style: GoogleFonts.inter(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.contactless_rounded,
                      color: AppColors.primaryLight,
                      size: 26,
                    ),
                  ],
                ),

                // ── Middle Row: EMV Gold Smart Chip + Persona Tier Pill ──
                Row(
                  children: [
                    const _EmvSmartChipWidget(),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _tr(
                              'PANGKAT & STATUS REBAHAN',
                              'OFFICIAL BINGE TIER',
                              'आधिकारिक सिनेमा रैंक',
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'LV.${insights.personaLevel} • $persona',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AvatarDisplay(
                      avatarId: profile.avatarId,
                      customAvatarPath: profile.customAvatarPath,
                      size: 44,
                      borderWidth: 1.5,
                      borderColor: AppColors.primary,
                    ),
                  ],
                ),

                // ── Embossed 16-Digit ATM Card Number ──
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    insights.atmCardNumber,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.4,
                      color: const Color(0xFFF5E6C8),
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.85),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Bottom Row: Cardholder, Watch Balance, Catalog, QR Code ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Cardholder Name
                    Expanded(
                      flex: 4,
                      child: _AtmMetaColumn(
                        label: _tr('PEMEGANG KARTU', 'CARDHOLDER', 'कार्डधारक'),
                        value: profile.name.toUpperCase(),
                        subValue: '@${profile.username}',
                      ),
                    ),
                    // Watch Hours Balance
                    Expanded(
                      flex: 3,
                      child: _AtmMetaColumn(
                        label: _tr('SALDO JAM NONTON', 'WATCH BALANCE', 'कुल समय'),
                        value: compactDuration,
                        subValue: _tr(
                          'Hemat ~${insights.estimatedTicketsSaved} Tiket',
                          '~${insights.estimatedTicketsSaved} Tickets Saved',
                          '~${insights.estimatedTicketsSaved} टिकट बचत',
                        ),
                        highlightColor: AppColors.primaryLight,
                      ),
                    ),
                    // Catalog Completed
                    Expanded(
                      flex: 3,
                      child: _AtmMetaColumn(
                        label: _tr('REKOR TONTONAN', 'WATCH RECORD', 'रिकॉर्ड'),
                        value:
                            '${insights.moviesWatchedCount}F / ${insights.episodesWatchedCount}EP',
                        subValue: 'VALID: SELAMANYA',
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Mini QR Code for App Download
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SizedBox(
                        width: 46,
                        height: 46,
                        child: QrImageView(
                          data: 'https://github.com/cineva-stream/Cineva/releases',
                          size: 46,
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

class _AtmMetaColumn extends StatelessWidget {
  final String label;
  final String value;
  final String subValue;
  final Color? highlightColor;

  const _AtmMetaColumn({
    required this.label,
    required this.value,
    required this.subValue,
    this.highlightColor,
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
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: highlightColor ?? Colors.white,
          ),
        ),
        Text(
          subValue,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 8.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Realistic metallic gold EMV Smart Chip widget.
class _EmvSmartChipWidget extends StatelessWidget {
  const _EmvSmartChipWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFE082),
            Color(0xFFFFB300),
            Color(0xFFD4AF37),
            Color(0xFFFFE082),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFFFFF8E1).withValues(alpha: 0.7),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const CustomPaint(
        painter: _EmvChipLinesPainter(),
      ),
    );
  }
}

class _EmvChipLinesPainter extends CustomPainter {
  const _EmvChipLinesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF7A5901).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final w = size.width;
    final h = size.height;

    // Center rounded pad
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.30, h * 0.22, w * 0.40, h * 0.56),
        const Radius.circular(3),
      ),
      paint,
    );

    // Horizontal contact dividers
    canvas.drawLine(Offset(0, h * 0.36), Offset(w * 0.30, h * 0.36), paint);
    canvas.drawLine(Offset(0, h * 0.64), Offset(w * 0.30, h * 0.64), paint);
    canvas.drawLine(Offset(w * 0.70, h * 0.36), Offset(w, h * 0.36), paint);
    canvas.drawLine(Offset(w * 0.70, h * 0.64), Offset(w, h * 0.64), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GuillochePatternPainter extends CustomPainter {
  final bool isKtp;
  const _GuillochePatternPainter({required this.isKtp});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isKtp
          ? const Color(0xFF00E5FF).withValues(alpha: 0.045)
          : AppColors.primary.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int wave = 0; wave < 6; wave++) {
      final path = Path();
      final yOffset = size.height * (0.2 + wave * 0.13);
      path.moveTo(0, yOffset);
      for (double x = 0; x <= size.width; x += 12) {
        final y =
            yOffset + math.sin((x / size.width) * math.pi * 2.5 + wave) * 18;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
