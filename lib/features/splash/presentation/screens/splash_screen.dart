import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';

/// Modern Splash Screen featuring:
/// - Top 70%: Dual-lane movie posters counter-scrolling in opposite directions
/// - Gradient fade from transparent to solid obsidian background
/// - Bottom 30%: Typographic "Cineva" branding, descriptive tagline, and smooth loader
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _marqueeController;

  static const List<String> _postersRow1 = [
    'https://image.tmdb.org/t/p/w342/8cdWjvZQUExUUTzyp4t6EDMubfO.jpg', // Dune: Part Two
    'https://image.tmdb.org/t/p/w342/ptpr0kGAckfQkJeJIt8st5dglvd.jpg', // Oppenheimer
    'https://image.tmdb.org/t/p/w342/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg', // Across the Spider-Verse
    'https://image.tmdb.org/t/p/w342/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg', // Interstellar
    'https://image.tmdb.org/t/p/w342/qJ2tW6WMUDux911r6m7haRef0WH.jpg', // The Dark Knight
    'https://image.tmdb.org/t/p/w342/7WsyChQLEftFiDOVTGkv3hFpyyt.jpg', // Avengers: Infinity War
    'https://image.tmdb.org/t/p/w342/oYuLEt3zVCKq57qu2F8dT7NIa6f.jpg', // Inception
    'https://image.tmdb.org/t/p/w342/d5iIlFn5s0ImszYzBPb8JPIfbXD.jpg', // Pulp Fiction
  ];

  static const List<String> _postersRow2 = [
    'https://image.tmdb.org/t/p/w342/kCGlIMHnOm8JPXq3rXM6c5wMxcT.jpg', // The Batman
    'https://image.tmdb.org/t/p/w342/t6HIqrRAclMCA60NsSmeqe9RmNV.jpg', // Avatar 2
    'https://image.tmdb.org/t/p/w342/vqzNJax09Vk53HoZ244a3z9i7yt.jpg', // Blade Runner 2049
    'https://image.tmdb.org/t/p/w342/4m1Au3YkjqsxF8YrQvy7Fe7ScQn.jpg', // Stranger Things
    'https://image.tmdb.org/t/p/w342/fqv8v6A9pnivveuOGfZKi83av2L.jpg', // Arcane
    'https://image.tmdb.org/t/p/w342/1E5baAaEse26fej7uHcjOgEE2t2.jpg', // Fast X
    'https://image.tmdb.org/t/p/w342/3bhkrj58Vtu7enYsRolD1fZdja1.jpg', // The Godfather
    'https://image.tmdb.org/t/p/w342/A7EByudX09ZezGlASLe2YH8xrR5.jpg', // Gladiator II
  ];

  @override
  void initState() {
    super.initState();
    _marqueeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 35),
    )..repeat();

    _navigateToHome();
  }

  @override
  void dispose() {
    _marqueeController.dispose();
    super.dispose();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(milliseconds: 3500));
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final posterZoneHeight = size.height * 0.70;
    final brandingZoneHeight = size.height * 0.30;

    const double cardWidth = 115.0;
    const double cardHeight = 170.0;
    const double cardSpacing = 14.0;
    final double cycleWidth = (_postersRow1.length) * (cardWidth + cardSpacing);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 70% Top Area: Counter-scrolling Movie Poster Marquee ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: posterZoneHeight,
            child: ClipRect(
              child: AnimatedBuilder(
                animation: _marqueeController,
                builder: (context, _) {
                  final progress = _marqueeController.value;
                  final offsetRow1 = progress * cycleWidth;
                  final offsetRow2 = (1.0 - progress) * cycleWidth;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Row 1: Scrolling Right-to-Left
                      SizedBox(
                        height: cardHeight,
                        child: OverflowBox(
                          maxWidth: cycleWidth * 3,
                          alignment: Alignment.centerLeft,
                          child: Transform.translate(
                            offset: Offset(-offsetRow1, 0),
                            child: Row(
                              children: [
                                ..._postersRow1,
                                ..._postersRow1,
                                ..._postersRow1,
                              ].map((url) => _buildPosterCard(url, cardWidth, cardHeight, cardSpacing)).toList(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Row 2: Scrolling Left-to-Right (Opposite Direction)
                      SizedBox(
                        height: cardHeight,
                        child: OverflowBox(
                          maxWidth: cycleWidth * 3,
                          alignment: Alignment.centerLeft,
                          child: Transform.translate(
                            offset: Offset(-offsetRow2, 0),
                            child: Row(
                              children: [
                                ..._postersRow2,
                                ..._postersRow2,
                                ..._postersRow2,
                              ].map((url) => _buildPosterCard(url, cardWidth, cardHeight, cardSpacing)).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // ── Gradient Overlay: Transparent over posters fading to solid background ──
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.20, 0.50, 0.70, 0.75, 1.0],
                  colors: [
                    AppColors.background.withValues(alpha: 0.6),
                    Colors.black.withValues(alpha: 0.2),
                    Colors.transparent,
                    AppColors.background.withValues(alpha: 0.85),
                    AppColors.background,
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),

          // ── 30% Bottom Area: Clean Typography & Description ──
          Positioned(
            left: 24,
            right: 24,
            bottom: 0,
            height: brandingZoneHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Cineva Typographic Branding (No icon / No image logo)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'CINEVA',
                      style: GoogleFonts.outfit(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary,
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                    .slideY(begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOutCubic),

                const SizedBox(height: 10),

                // Main Tagline
                Text(
                  'Streaming Film & Serial TV Tanpa Batas',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                )
                    .animate(delay: 200.ms)
                    .fadeIn(duration: 500.ms),

                const SizedBox(height: 6),

                // Secondary Description
                Text(
                  'Koleksi Terlengkap • Kualitas Ultra HD • Subtitle Indonesia',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.2,
                  ),
                )
                    .animate(delay: 350.ms)
                    .fadeIn(duration: 500.ms),

                const SizedBox(height: 28),

                // Sleek Amber Progress Line
                SizedBox(
                  width: 130,
                  height: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      backgroundColor: AppColors.surfaceElevated,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                )
                    .animate(delay: 500.ms)
                    .fadeIn(duration: 400.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPosterCard(
      String url, double width, double height, double rightMargin) {
    return Container(
      width: width,
      height: height,
      margin: EdgeInsets.only(right: rightMargin),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: url,
          memCacheWidth: 230,
          memCacheHeight: 340,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: AppColors.surfaceVariant,
          ),
          errorWidget: (context, url, error) => Container(
            color: AppColors.surfaceVariant,
            child: const Icon(Icons.movie_outlined,
                color: AppColors.textMuted, size: 28),
          ),
        ),
      ),
    );
  }
}
