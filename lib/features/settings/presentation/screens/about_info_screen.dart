import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../../core/localization/app_strings.dart';

/// Modern "Info" screen displaying an edge-to-edge seamless poster collage hero banner,
/// transparent gradient blend, application branding, version specs, and full descriptions.
class AboutInfoScreen extends ConsumerStatefulWidget {
  const AboutInfoScreen({super.key});

  @override
  ConsumerState<AboutInfoScreen> createState() => _AboutInfoScreenState();
}

class _AboutInfoScreenState extends ConsumerState<AboutInfoScreen> {
  String _version = '1.1.6';
  String _buildNumber = '18';

  // High quality curated local poster collection for seamless borderless hero collage
  final List<String> _localPosters = const [
    'assets/images/spiderman_brand_new_day.webp',
    'assets/images/breaking_bad.webp',
    'assets/images/game_of_thrones.webp',
    'assets/images/stranger_things.webp',
    'assets/images/peaky_blinders.webp',
    'assets/images/squid_game.webp',
    'assets/images/house_of_the_dragon.webp',
    'assets/images/chernobyl.webp',
  ];

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          if (info.version.isNotEmpty) _version = info.version;
          if (info.buildNumber.isNotEmpty) _buildNumber = info.buildNumber;
        });
      }
    } catch (_) {
      // Fallback to defaults
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(appLanguageProvider);
    final s = AppStrings(language);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Sliver App Bar with Seamless Poster Collage ──
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.55),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: s.isIndonesian ? 'Kembali' : 'Back',
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Poster Collage Mosaic (Borderless & Tightly Packed)
                  _buildPosterMosaic(),

                  // 2. Multi-stop Gradient (Translucent at top, completely solid at bottom)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.4),
                            Colors.transparent,
                            AppColors.background.withValues(alpha: 0.5),
                            AppColors.background.withValues(alpha: 0.85),
                            AppColors.background,
                          ],
                          stops: const [0.0, 0.25, 0.65, 0.85, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // 3. Subtle horizontal vignette gradient
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 1.1,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.35),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── App Identity & Detailed Content ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Icon & Title Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 1.2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(17),
                          child: Image.asset(
                            'assets/images/cineva_icon.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppConstants.appName,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              s.aboutTagline,
                              style: GoogleFonts.inter(
                                color: AppColors.primaryLight,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Version & Build Badge
                  _buildBadge(
                    icon: Icons.verified_rounded,
                    label: 'v$_version (Build $_buildNumber)',
                    isPrimary: true,
                  ),

                  const SizedBox(height: 24),

                  // Divider
                  Container(
                    height: 1,
                    width: double.infinity,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),

                  const SizedBox(height: 20),

                  // Comprehensive App Description
                  Text(
                    s.isIndonesian ? 'Tentang Aplikasi' : 'About the Application',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    s.aboutDescription,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.65,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Feature Pillars (Modern Design)
                  Text(
                    s.isIndonesian ? 'Fitur & Arsitektur Utama' : 'Core Features & Architecture',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),

                  _buildFeatureTile(
                    icon: Icons.hub_rounded,
                    title: s.aboutFeatureP2PTitle,
                    description: s.aboutFeatureP2PDesc,
                  ),
                  _buildFeatureTile(
                    icon: Icons.speed_rounded,
                    title: s.aboutFeatureHwTitle,
                    description: s.aboutFeatureHwDesc,
                  ),
                  _buildFeatureTile(
                    icon: Icons.subtitles_rounded,
                    title: s.aboutFeatureSubTitle,
                    description: s.aboutFeatureSubDesc,
                  ),
                  _buildFeatureTile(
                    icon: Icons.offline_pin_rounded,
                    title: s.aboutFeatureDownloadTitle,
                    description: s.aboutFeatureDownloadDesc,
                  ),
                  _buildFeatureTile(
                    icon: Icons.volunteer_activism_rounded,
                    title: s.aboutFeatureFreeTitle,
                    description: s.aboutFeatureFreeDesc,
                  ),

                  const SizedBox(height: 20),

                  // Open Source & Community Acknowledgments
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              s.aboutCreditsTitle,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          s.aboutCreditsDesc,
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Copyright & Non-Commercial Notice
                  Center(
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Made With ',
                              style: GoogleFonts.inter(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Icon(
                              Icons.favorite_rounded,
                              color: AppColors.primary,
                              size: 14,
                            ),
                            Text(
                              ' by Cineva Group',
                              style: GoogleFonts.inter(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.isIndonesian
                              ? 'Hak cipta seluruh konten film & TV series adalah milik masing-masing studio pembuatnya.'
                              : 'All film and TV series intellectual properties remain with their respective studios.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: AppColors.textMuted.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a tight, seamless movie poster mosaic without borders or spacing.
  Widget _buildPosterMosaic() {
    // 2 rows of 4 posters tightly packed together
    return Column(
      children: [
        Expanded(
          child: Row(
            children: List.generate(4, (index) {
              final posterIndex = index % _localPosters.length;
              return Expanded(
                child: Image.asset(
                  _localPosters[posterIndex],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              );
            }),
          ),
        ),
        Expanded(
          child: Row(
            children: List.generate(4, (index) {
              final posterIndex = (index + 4) % _localPosters.length;
              return Expanded(
                child: Image.asset(
                  _localPosters[posterIndex],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required bool isPrimary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isPrimary
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.surfaceVariant.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPrimary
              ? AppColors.primary.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: isPrimary ? AppColors.primaryLight : AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: isPrimary ? AppColors.primaryLight : AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
                width: 0.8,
              ),
            ),
            child: Icon(icon, color: AppColors.primaryLight, size: 19),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.45,
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
