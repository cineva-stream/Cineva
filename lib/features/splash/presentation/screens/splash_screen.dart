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
    'assets/images/spiderman_brand_new_day.webp',
    'assets/images/stranger_things.webp',
    'assets/images/squid_game.webp',
    'assets/images/game_of_thrones.webp',
    'assets/images/breaking_bad.webp',
    'assets/images/peaky_blinders.webp',
    'assets/images/house_of_the_dragon.webp',
    'assets/images/chernobyl.webp',
  ];

  static const List<String> _postersRow2 = [
    'assets/images/chernobyl.webp',
    'assets/images/house_of_the_dragon.webp',
    'assets/images/peaky_blinders.webp',
    'assets/images/breaking_bad.webp',
    'assets/images/game_of_thrones.webp',
    'assets/images/squid_game.webp',
    'assets/images/stranger_things.webp',
    'assets/images/spiderman_brand_new_day.webp',
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
    await Future.delayed(const Duration(milliseconds: 5000));
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final posterZoneHeight = size.height * 0.62;
    final brandingZoneHeight = size.height * 0.40;

    const double cardWidth = 115.0;
    const double cardHeight = 170.0;
    const double cardSpacing = 14.0;
    final double cycleWidth = (_postersRow1.length) * (cardWidth + cardSpacing);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Top Area: Counter-scrolling Movie & TV Series Poster Marquee ──
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
                      // Row 1: Movies Scrolling Right-to-Left
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
                      // Row 2: TV Series Scrolling Left-to-Right
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

          // ── Gradient Overlay: Smooth transition from transparent to solid obsidian black ──
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.12, 0.35, 0.55, 0.65, 1.0],
                  colors: [
                    AppColors.background.withValues(alpha: 0.55),
                    Colors.transparent,
                    Colors.transparent,
                    AppColors.background.withValues(alpha: 0.75),
                    AppColors.background,
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom Area: Cineva Logo, Indonesian Description & Footer ──
          Positioned(
            left: 24,
            right: 24,
            bottom: 0,
            height: brandingZoneHeight,
            child: SafeArea(
              top: false,
              bottom: true,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Spacer(),

                  // Cineva Logo Image (berisi ikon play oranye & teks CINEVA)
                  Image.asset(
                    'assets/images/logo_cineva.png',
                    height: 96,
                    fit: BoxFit.contain,
                  )
                      .animate()
                      .fadeIn(duration: 650.ms, curve: Curves.easeOut)
                      .scale(
                        begin: const Offset(0.92, 0.92),
                        end: const Offset(1, 1),
                        duration: 650.ms,
                        curve: Curves.easeOutCubic,
                      ),

                  const SizedBox(height: 16),

                  // Deskripsi Singkat dalam Bahasa Indonesia (Diperbesar)
                  Text(
                    'Nonton Film & Serial TV Favorit Tanpa Batas',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  )
                      .animate(delay: 200.ms)
                      .fadeIn(duration: 500.ms),

                  const SizedBox(height: 6),

                  Text(
                    'Koleksi Terlengkap • Kualitas Ultra HD • Subtitle Indonesia',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2,
                    ),
                  )
                      .animate(delay: 350.ms)
                      .fadeIn(duration: 500.ms),

                  const SizedBox(height: 22),

                  // Sleek Amber Progress Line (Diperbesar)
                  SizedBox(
                    width: 140,
                    height: 3.5,
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

                  const Spacer(),

                  // Footer: Made with ❤️ by Cineva Group (Diperbesar)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Made with ❤️ by Cineva Group',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: AppColors.textMuted.withValues(alpha: 0.85),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.4,
                      ),
                    ),
                  )
                      .animate(delay: 600.ms)
                      .fadeIn(duration: 500.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPosterCard(
      String path, double width, double height, double rightMargin) {
    final isNetwork = path.startsWith('http://') || path.startsWith('https://');

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
        child: isNetwork
            ? CachedNetworkImage(
                imageUrl: path,
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
              )
            : Image.asset(
                path,
                fit: BoxFit.cover,
                cacheWidth: 230,
                cacheHeight: 340,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.surfaceVariant,
                  child: const Icon(Icons.movie_outlined,
                      color: AppColors.textMuted, size: 28),
                ),
              ),
      ),
    );
  }
}
