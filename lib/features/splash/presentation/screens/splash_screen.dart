import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/modern_flag_badge.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../settings/data/settings_service.dart';

/// Modern Splash Screen featuring:
/// - Top 58%: Dual-lane movie posters counter-scrolling in opposite directions
/// - Gradient fade from transparent to solid obsidian background
/// - Bottom 42%: Typographic "Cineva" branding, descriptive tagline, and "Mulai Menonton" CTA
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {

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

  late final AnimationController _marqueeController;
  bool _showLanguageSelection = false;

  @override
  void initState() {
    super.initState();
    _marqueeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 35),
    )..repeat();

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        setState(() {
          _showLanguageSelection = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _marqueeController.dispose();
    super.dispose();
  }

  void _onStartWatching() {
    final profile = ref.read(userProfileProvider);
    if (!profile.isConfigured) {
      context.push('/onboarding-profile');
    } else if (!SettingsService.hasAcceptedLegal()) {
      context.push('/onboarding-legal');
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final posterZoneHeight = size.height * 0.54;
    final brandingZoneHeight = size.height * 0.48;

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

          // ── Bottom Area: Smooth AnimatedCrossFade (Intro -> Language Selection & CTA) ──
          Positioned(
            left: 20,
            right: 20,
            bottom: 0,
            height: brandingZoneHeight,
            child: SafeArea(
              top: false,
              bottom: true,
              child: Center(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: AnimatedCrossFade(
                    duration: const Duration(milliseconds: 650),
                    firstCurve: Curves.easeInOutCubic,
                    secondCurve: Curves.easeInOutCubic,
                    sizeCurve: Curves.easeInOutCubic,
                    crossFadeState: _showLanguageSelection
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: _buildIntroPhase(),
                    secondChild: _buildLanguagePhase(
                      ref.watch(appLanguageProvider),
                      ref.watch(appStringsProvider),
                    ),
                  ),
                ),
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

  Widget _buildIntroPhase() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo_cineva.png',
          height: 92,
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
        const SizedBox(height: 14),
        Text(
          'Nonton Film & Serial TV Favorit Tanpa Batas',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ).animate(delay: 200.ms).fadeIn(duration: 450.ms),
        const SizedBox(height: 6),
        Text(
          'Koleksi Terlengkap • Kualitas Ultra HD • Subtitle Indonesia',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: AppColors.textMuted,
            fontSize: 12.5,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.2,
          ),
        ).animate(delay: 350.ms).fadeIn(duration: 450.ms),
        const SizedBox(height: 20),
        SizedBox(
          width: 140,
          height: 3.5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: const LinearProgressIndicator(
              backgroundColor: AppColors.surfaceElevated,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ).animate(delay: 450.ms).fadeIn(duration: 400.ms),
        const SizedBox(height: 18),
        Text(
          'Made with ❤️ by Cineva Group',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: AppColors.textMuted.withValues(alpha: 0.85),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
        ).animate(delay: 550.ms).fadeIn(duration: 400.ms),
      ],
    );
  }

  Widget _buildLanguagePhase(AppLanguage currentLang, AppStrings s) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo_cineva.png',
          height: 88,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 14),
        Text(
          s.splashSelectLanguage,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildLanguageCard(
                lang: AppLanguage.id,
                isSelected: currentLang == AppLanguage.id,
                onTap: () {
                  ref
                      .read(appLanguageProvider.notifier)
                      .setLanguage(AppLanguage.id);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildLanguageCard(
                lang: AppLanguage.en,
                isSelected: currentLang == AppLanguage.en,
                onTap: () {
                  ref
                      .read(appLanguageProvider.notifier)
                      .setLanguage(AppLanguage.en);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(15),
          ),
          child: ElevatedButton(
            onPressed: _onStartWatching,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.black,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  s.splashStartWatching,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.black,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Made with ❤️ by Cineva Group',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: AppColors.textMuted.withValues(alpha: 0.85),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageCard({
    required AppLanguage lang,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.14),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ModernFlagBadge(
              countryCode: lang.flagCountryCode,
              width: 26,
              height: 18,
              borderRadius: 3.5,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                lang.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: isSelected ? AppColors.primary : Colors.white,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
