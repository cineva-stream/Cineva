import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../../core/platform/device_form_factor.dart';
import '../../../../shared/widgets/tv_focusable.dart';
import '../providers/home_providers.dart';

/// Highly modern, cinematic Airing Calendar promotional banner.
///
/// Supports two adaptive presentations:
/// 1. [isCompanion: false] - Classic full-width horizontal banner for mobile portrait.
/// 2. [isCompanion: true]  - Vertical companion card for Desktop (Windows) and Android TV (720p/1080p/4K),
///    rendered side-by-side with the Hero Billboard Carousel.
class AiringCalendarBanner extends ConsumerStatefulWidget {
  final bool isCompanion;
  final double? height;

  const AiringCalendarBanner({
    super.key,
    this.isCompanion = false,
    this.height,
  });

  @override
  ConsumerState<AiringCalendarBanner> createState() => _AiringCalendarBannerState();
}

class _AiringCalendarBannerState extends ConsumerState<AiringCalendarBanner> {
  Timer? _rotationTimer;
  int _currentIndex = 0;

  // Curated high-resolution fallback backdrops to guarantee zero blank states
  static const _defaultBackdrops = [
    '/2OMB0ynKlyIenMJWI2Dy9IWT4c.jpg', // House of the Dragon
    '/xOMo8BRK7PfcJv9JCnx7s5207c7.jpg', // Dune 2
    '/56v2ox9qag31wD9p4iNl940m8a9.jpg', // Stranger Things
    '/tsRy63Mu5cu8etL1X7ZLyf7UP1M.jpg', // Breaking Bad
    '/vIohhH61p2iWJp6VnQ67Q5o8V7y.jpg', // Naruto
  ];

  @override
  void initState() {
    super.initState();
    _rotationTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        setState(() {
          _currentIndex++;
        });
      }
    });
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final upcoming = ref.watch(upcomingMoviesProvider).valueOrNull ?? [];
    final popularTv = ref.watch(popularTvProvider).valueOrNull ?? [];
    final trendingMovies = ref.watch(trendingMoviesProvider).valueOrNull ?? [];

    // Extract non-empty backdrop and poster paths
    final dynamicImages = [
      ...upcoming.map((m) => m.backdropPath ?? m.posterPath),
      ...popularTv.map((t) => t.backdropPath ?? t.posterPath),
      ...trendingMovies.map((m) => m.backdropPath ?? m.posterPath),
    ].whereType<String>().where((p) => p.isNotEmpty).toList();

    final allImages = dynamicImages.isNotEmpty ? dynamicImages : _defaultBackdrops;
    final currentImage = allImages[_currentIndex % allImages.length];

    if (widget.isCompanion) {
      return _buildCompanionCard(context, s, currentImage, upcoming);
    }

    return _buildHorizontalBanner(context, s, currentImage);
  }

  /// Vertical companion card designed for Windows Desktop & Android TV (placed beside Hero Carousel)
  Widget _buildCompanionCard(
    BuildContext context,
    dynamic s,
    String currentImage,
    List<dynamic> upcoming,
  ) {
    final isTv = ref.watch(isTvProvider);
    final isWide = isWideScreenLayout(context, isTv: isTv);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isCompact = screenWidth < 360;
    final cardHeight = widget.height ??
        (isWide ? (screenHeight < 650 ? 400.0 : 490.0) : (isCompact ? 375.0 : 430.0));
    final horizontalPad = screenWidth < 960 ? 14.0 : 18.0;

    // Curate up to 2 upcoming highlights for the live preview widget
    final previewItems = upcoming.take(2).toList();

    return TvFocusable(
      focusedScale: 1.02,
      glowBlurRadius: 18,
      borderRadius: BorderRadius.circular(28),
      onTap: () => context.push('/calendar'),
      child: Container(
        height: cardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: const Color(0xFF13131D),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.28),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.65),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.10),
              blurRadius: 24,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Rotating High-Res Cinematic Backdrop Artwork ──
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 900),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: CachedNetworkImage(
                  key: ValueKey<String>(currentImage),
                  imageUrl: ApiConstants.imageUrl(
                    currentImage,
                    size: ApiConstants.backdropMedium,
                  ),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),

            // ── Deep OLED Dark Multi-Stop Gradient Scrim ──
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0F0F18).withValues(alpha: 0.90),
                    const Color(0xFF0D0D16).withValues(alpha: 0.72),
                    const Color(0xFF09090F).withValues(alpha: 0.94),
                    const Color(0xFF050508).withValues(alpha: 0.98),
                  ],
                  stops: const [0.0, 0.35, 0.72, 1.0],
                ),
              ),
            ),

            // ── Atmospheric Amber Radial Glow at Bottom-Right ──
            Positioned(
              right: -30,
              bottom: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.14),
                ),
              ),
            ),

            // ── Card Foreground Content ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Live Status & Squircle Icon
                  Row(
                    children: [
                      // Live Pulsing Dot & Label
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.9),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'LIVE RADAR',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryLight,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // 2-TAB Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '2 TAB',
                          style: GoogleFonts.inter(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Squircle Calendar Icon
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary.withValues(alpha: 0.30),
                              AppColors.primary.withValues(alpha: 0.12),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            width: 1.0,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Iconsax.calendar_tick,
                            color: AppColors.primary,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Main Heading
                  Text(
                    s.calendarBannerTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.18,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Subtitle
                  Text(
                    s.calendarBannerSubtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFFB0B0C4),
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Mini Upcoming Highlights or Feature Chips ──
                  if (previewItems.isNotEmpty) ...[
                    ...previewItems.map((item) {
                      final title = item.title ?? '';
                      final poster = item.posterPath ?? '';
                      final release = (item.releaseDate as String?) ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.09),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: ApiConstants.imageUrl(
                                  poster,
                                  size: ApiConstants.posterSmall,
                                ),
                                width: 34,
                                height: 48,
                                fit: BoxFit.cover,
                                errorWidget: (context, error, stackTrace) => Container(
                                  width: 34,
                                  height: 48,
                                  color: AppColors.surfaceVariant,
                                  child: const Icon(Icons.movie, size: 16, color: Colors.white30),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          release.isNotEmpty ? release : (s.isIndonesian ? 'Segera' : 'Soon'),
                                          style: GoogleFonts.inter(
                                            color: AppColors.primaryLight,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 9.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.star_rounded, color: AppColors.star, size: 12),
                                      const SizedBox(width: 2),
                                      Text(
                                        item.voteAverage.toStringAsFixed(1),
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
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
                    }),
                  ] else ...[
                    _buildFeatureChip(Icons.calendar_month_rounded, s.isIndonesian ? '14 Hari Jadwal Siaran' : '14-Day Weekly Broadcast'),
                    const SizedBox(height: 6),
                    _buildFeatureChip(Icons.movie_filter_rounded, s.isIndonesian ? 'Radar Film Bioskop & TV' : 'Theatrical & TV Radar'),
                    const SizedBox(height: 6),
                    _buildFeatureChip(Icons.bookmark_add_rounded, s.isIndonesian ? 'Simpan ke Watchlist' : '1-Tap Watchlist Save'),
                  ],

                  const Spacer(),

                  // ── Action CTA Button ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFB800),
                          Color(0xFFFF9500),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF9500).withValues(alpha: 0.38),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Iconsax.calendar_1,
                          color: Colors.black,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            s.isIndonesian ? 'Buka Jadwal Lengkap' : 'Explore Full Schedule',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.black,
                          size: 13,
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
    );
  }

  Widget _buildFeatureChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Classic full-width horizontal banner for mobile portrait
  Widget _buildHorizontalBanner(
    BuildContext context,
    dynamic s,
    String currentImage,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () => context.push('/calendar'),
        child: Container(
          height: 108,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: const Color(0xFF14141C),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.22),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Smooth 4-second Rotating Cinematic Artwork (Right-biased & vibrant) ──
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 900),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: CachedNetworkImage(
                    key: ValueKey<String>(currentImage),
                    imageUrl: ApiConstants.imageUrl(
                      currentImage,
                      size: ApiConstants.backdropMedium,
                    ),
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),

              // ── Modern Scrim: Rich dark gradient on left for text legibility, transparent on right for artwork ──
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      const Color(0xFF0F0F16).withValues(alpha: 0.96),
                      const Color(0xFF0F0F16).withValues(alpha: 0.88),
                      const Color(0xFF0F0F16).withValues(alpha: 0.55),
                      const Color(0xFF0F0F16).withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.42, 0.65, 0.85, 1.0],
                  ),
                ),
              ),

              // ── Subtle Top/Bottom Edge Vignette ──
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.25),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),

              // ── Ambient Amber Accent Glow at Bottom-Left ──
              Positioned(
                left: -20,
                bottom: -20,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.12),
                  ),
                ),
              ),

              // ── Content Layout ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Modern Squircle Icon Container
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary.withValues(alpha: 0.25),
                            AppColors.primary.withValues(alpha: 0.10),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          width: 1.0,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Iconsax.calendar_tick,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Information Column
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Live Indicator & Tag
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.8),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                s.calendarTitle.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '2 TAB',
                                  style: GoogleFonts.inter(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Main Title
                          Text(
                            s.calendarBannerTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),

                          // Subtitle
                          Text(
                            s.calendarBannerSubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFB0B0C0),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Modern Cinema Amber Action Button
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFB800),
                            Color(0xFFFF9500),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF9500).withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            s.isIndonesian ? 'Buka' : 'Open',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.black,
                            size: 13,
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
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.04, end: 0);
  }
}
