import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../shared/widgets/github_brand_icon.dart';

/// Clean and minimalist "Info" screen displaying an edge-to-edge seamless poster
/// collage hero banner, transparent gradient blend, application branding, version specs,
/// official Cineva Group GitHub link, developer email contact, and clean architecture pillars.
class AboutInfoScreen extends ConsumerStatefulWidget {
  const AboutInfoScreen({super.key});

  @override
  ConsumerState<AboutInfoScreen> createState() => _AboutInfoScreenState();
}

class _AboutInfoScreenState extends ConsumerState<AboutInfoScreen> {
  String _version = '1.1.9';
  String _buildNumber = '21';

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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('[AboutInfoScreen] Error launching $url: $e');
    }
  }

  Future<void> _launchEmail(String email) async {
    final isIndo = ref.read(appStringsProvider).isIndonesian;
    final fallbackMsg = isIndo
        ? 'Email disalin ke papan klip'
        : 'Email copied to clipboard';
    final mailUri = Uri.parse(
      'mailto:$email?subject=Cineva%20Feedback%20%2F%20Bug%20Report',
    );
    try {
      final launched = await launchUrl(mailUri);
      if (!launched) {
        _copyToClipboard(email, fallbackMsg);
      }
    } catch (_) {
      _copyToClipboard(email, fallbackMsg);
    }
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
          // ── 1. Sliver App Bar with Seamless Poster Collage ──
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.6),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
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
                  // Poster Collage Mosaic (Borderless & Seamless)
                  _buildPosterMosaic(),

                  // Multi-stop Gradient to OLED Black
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.45),
                            Colors.transparent,
                            AppColors.background.withValues(alpha: 0.5),
                            AppColors.background.withValues(alpha: 0.88),
                            AppColors.background,
                          ],
                          stops: const [0.0, 0.25, 0.65, 0.85, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Vignette overlay
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

          // ── 2. Content ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Icon & Header Title
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
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

                  // Minimalist Clean Badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildCleanBadge(
                        icon: Icons.verified_rounded,
                        label: 'v$_version (Build $_buildNumber)',
                        isPrimary: true,
                      ),
                      _buildCleanBadge(
                        icon: Icons.gavel_rounded,
                        label: 'GPL-3.0 License',
                        isPrimary: false,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── 3. Developer & Community Connect Cards ──
                  Text(
                    s.isIndonesian
                        ? 'Komunitas & Pengembang'
                        : 'Community & Developer',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // GitHub Card: Cineva Group -> https://github.com/cineva-stream
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () =>
                          _launchUrl('https://github.com/cineva-stream'),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant.withValues(
                            alpha: 0.45,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: GithubBrandIcon(
                                  size: 22,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Cineva Group',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.18,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          'GitHub',
                                          style: GoogleFonts.inter(
                                            color: AppColors.primaryLight,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'https://github.com/cineva-stream',
                                    style: GoogleFonts.inter(
                                      color: AppColors.textSecondary,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.north_east_rounded,
                              color: AppColors.primaryLight,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Developer Email Card: cineva.dev@gmail.com
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _launchEmail('cineva.dev@gmail.com'),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant.withValues(
                            alpha: 0.45,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.14,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Iconsax.sms,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.isIndonesian
                                        ? 'Email Pengembang'
                                        : 'Developer Contact',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'cineva.dev@gmail.com',
                                    style: GoogleFonts.inter(
                                      color: AppColors.primaryLight,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    s.isIndonesian
                                        ? 'Hubungi kami jika memiliki rekomendasi fitur atau laporan bug'
                                        : 'Contact us for recommendations or bug reports',
                                    style: GoogleFonts.inter(
                                      color: AppColors.textSecondary,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.copy_rounded,
                                color: AppColors.textMuted,
                                size: 18,
                              ),
                              tooltip: s.isIndonesian
                                  ? 'Salin Email'
                                  : 'Copy Email',
                              onPressed: () => _copyToClipboard(
                                'cineva.dev@gmail.com',
                                s.isIndonesian
                                    ? 'Email cineva.dev@gmail.com disalin'
                                    : 'Email cineva.dev@gmail.com copied',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),

                  // ── 4. App Description ──
                  Text(
                    s.isIndonesian
                        ? 'Tentang Aplikasi'
                        : 'About the Application',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.aboutDescription,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 13.5,
                      height: 1.6,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 26),

                  // ── 5. Clean Architecture Pillars ──
                  Text(
                    s.isIndonesian
                        ? 'Fitur & Keunggulan'
                        : 'Features & Architecture',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildCleanFeatureTile(
                    icon: Icons.hub_rounded,
                    title: s.aboutFeatureP2PTitle,
                    description: s.aboutFeatureP2PDesc,
                  ),
                  _buildCleanFeatureTile(
                    icon: Icons.speed_rounded,
                    title: s.aboutFeatureHwTitle,
                    description: s.aboutFeatureHwDesc,
                  ),
                  _buildCleanFeatureTile(
                    icon: Icons.subtitles_rounded,
                    title: s.aboutFeatureSubTitle,
                    description: s.aboutFeatureSubDesc,
                  ),
                  _buildCleanFeatureTile(
                    icon: Icons.offline_pin_rounded,
                    title: s.aboutFeatureDownloadTitle,
                    description: s.aboutFeatureDownloadDesc,
                  ),
                  _buildCleanFeatureTile(
                    icon: Icons.volunteer_activism_rounded,
                    title: s.aboutFeatureFreeTitle,
                    description: s.aboutFeatureFreeDesc,
                  ),

                  const SizedBox(height: 20),

                  // ── 6. Open Source & Ecosystem Credits ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.favorite_rounded,
                              color: AppColors.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              s.aboutCreditsTitle,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.aboutCreditsDesc,
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── 7. Clean Minimalist Footer ──
                  Center(
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Made with ',
                              style: GoogleFonts.inter(
                                color: AppColors.textMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Icon(
                              Icons.favorite_rounded,
                              color: AppColors.primary,
                              size: 15,
                            ),
                            Text(
                              ' by Cineva Group',
                              style: GoogleFonts.inter(
                                color: AppColors.textMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.isIndonesian
                              ? 'Hak cipta seluruh konten film & TV series adalah milik masing-masing studio pembuatnya.'
                              : 'All film and TV series intellectual properties remain with their respective studios.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: AppColors.textMuted.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),
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

  Widget _buildCleanBadge({
    required IconData icon,
    required String label,
    required bool isPrimary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isPrimary
            ? AppColors.primary.withValues(alpha: 0.16)
            : AppColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
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
              color: isPrimary
                  ? AppColors.primaryLight
                  : AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanFeatureTile({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primaryLight, size: 18),
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
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.45,
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
}
