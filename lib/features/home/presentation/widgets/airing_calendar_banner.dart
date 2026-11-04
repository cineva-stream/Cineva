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
import '../providers/home_providers.dart';

/// Highly modern, cinematic Airing Calendar promotional banner.
///
/// Features high-contrast visibility against OLED black backgrounds,
/// a vibrant rotating backdrop from upcoming movies and TV series,
/// an illuminated live amber indicator, and an eye-catching CTA.
class AiringCalendarBanner extends ConsumerStatefulWidget {
  const AiringCalendarBanner({super.key});

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
