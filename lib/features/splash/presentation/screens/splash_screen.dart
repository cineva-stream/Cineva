import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/modern_flag_badge.dart';
import '../../../../shared/widgets/google_brand_icon.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../backup/data/backup_restore_service.dart';
import '../../../backup/presentation/providers/backup_providers.dart';
import '../../../profile/data/profile_service.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../settings/data/settings_service.dart';

/// Modern Splash Screen featuring:
/// - Full-screen left-tilted (`\`) vertical movie & series poster columns counter-scrolling smoothly
/// - Bottom-to-top pure black gradient fading seamlessly into transparent poster visibility at the top
/// - Bottom foreground UI transitioning smoothly between Splash Intro, Language Selection, and Google Login
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {

  static const List<String> _allPosters = [
    'assets/images/spiderman_brand_new_day.webp',
    'assets/images/stranger_things.webp',
    'assets/images/squid_game.webp',
    'assets/images/game_of_thrones.webp',
    'assets/images/breaking_bad.webp',
    'assets/images/peaky_blinders.webp',
    'assets/images/house_of_the_dragon.webp',
    'assets/images/chernobyl.webp',
  ];

  late final AnimationController _marqueeController;
  Timer? _navTimer;
  bool _showLanguageSelection = false;
  bool _isGoogleSigningIn = false;
  bool _isRestoringFile = false;
  bool _didPrecachePosters = false;

  @override
  void initState() {
    super.initState();
    _marqueeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 42),
    )..repeat();

    _handleNavigationFlow();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didPrecachePosters &&
        !kIsWeb &&
        !Platform.environment.containsKey('FLUTTER_TEST')) {
      _didPrecachePosters = true;
      for (final path in _allPosters) {
        unawaited(
          precacheImage(ResizeImage(AssetImage(path), width: 320), context),
        );
      }
    }
  }

  void _handleNavigationFlow() {
    _navTimer = Timer(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      final profile = ref.read(userProfileProvider);
      final isConfigured = profile.isConfigured || ProfileService.hasConfiguredProfile();
      final hasAcceptedLegal = SettingsService.hasAcceptedLegal();

      if (isConfigured && hasAcceptedLegal) {
        // User has already set up their profile & accepted terms, proceed directly to Home
        context.go('/');
      } else if (isConfigured && !hasAcceptedLegal) {
        // Profile was created but terms not yet accepted
        context.go('/onboarding-legal');
      } else {
        // First-time user install: show initial language selection and CTA
        setState(() {
          _showLanguageSelection = true;
        });
      }
    });
  }

  List<String> _postersForColumn(int colIndex) {
    final shift = (colIndex * 3) % _allPosters.length;
    final rotated = [
      ..._allPosters.sublist(shift),
      ..._allPosters.sublist(0, shift),
    ];
    return colIndex.isOdd ? rotated.reversed.toList() : rotated;
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleSigningIn = true);
    final s = ref.read(appStringsProvider);
    try {
      final success =
          await ref.read(googleSyncProvider.notifier).signInWithGoogle(ref);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            content: Text(
              s.onboardingGoogleSyncSuccessGoHome,
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        );
        if (!SettingsService.hasAcceptedLegal()) {
          context.go('/onboarding-legal');
        } else {
          context.go('/');
        }
      } else {
        final err = ref.read(googleSyncProvider).errorMessage;
        if (err != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.surfaceElevated,
              content: Text(err, style: GoogleFonts.inter(color: Colors.white)),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isGoogleSigningIn = false);
    }
  }

  Future<void> _handleFileRestore() async {
    setState(() => _isRestoringFile = true);
    final s = ref.read(appStringsProvider);
    try {
      final result = await BackupRestoreService.pickAndRestoreBackupFile(ref);
      if (!mounted) return;
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            content: Text(
              s.backupImportSuccessSummary(
                  result.watchlistCount, result.historyCount),
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        );
        // Automatically enter main home screen directly
        context.go('/');
      } else if (result.errorMessage != null &&
          !result.errorMessage!.contains('dibatalkan')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            content: Text(result.errorMessage ?? s.backupImportFailed,
                style: GoogleFonts.inter(color: Colors.white)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRestoringFile = false);
    }
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _marqueeController.dispose();
    super.dispose();
  }

  void _onStartWatching() {
    final profile = ref.read(userProfileProvider);
    final isConfigured = profile.isConfigured || ProfileService.hasConfiguredProfile();
    if (!isConfigured) {
      context.push('/onboarding-profile');
    } else if (!SettingsService.hasAcceptedLegal()) {
      context.push('/onboarding-legal');
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 1: Full-Bleed Tilted (`\`) Vertical Counter-Scrolling Poster Wall ──
          Positioned.fill(
            child: _buildTiltedPosterWall(size),
          ),

          // ── Layer 2: Bottom-to-Top Pure Black Fade to Transparent ──
          Positioned.fill(
            child: RepaintBoundary(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: const [0.0, 0.36, 0.52, 0.68, 0.84, 0.95, 1.0],
                      colors: [
                        AppColors.background,
                        AppColors.background,
                        AppColors.background.withValues(alpha: 0.95),
                        AppColors.background.withValues(alpha: 0.68),
                        AppColors.background.withValues(alpha: 0.25),
                        AppColors.background.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Layer 3: Foreground Branding, Language Selection & Google Login ──
          Positioned.fill(
            child: RepaintBoundary(
              child: SafeArea(
                top: true,
                bottom: true,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      child: AnimatedCrossFade(
                        duration: const Duration(milliseconds: 650),
                        firstCurve: Curves.easeInOutCubic,
                        secondCurve: Curves.easeInOutCubic,
                        sizeCurve: Curves.easeInOutCubic,
                        crossFadeState: _showLanguageSelection
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        firstChild: _buildIntroPhase(
                          ref.watch(appStringsProvider),
                        ),
                        secondChild: _buildLanguagePhase(
                          ref.watch(appLanguageProvider),
                          ref.watch(appStringsProvider),
                        ),
                      ),
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

  Widget _buildTiltedPosterWall(Size size) {
    // Tilt top leaning left (`\`, ~ -9.2 deg)
    const double tiltAngle = -0.16;
    const double cardSpacing = 8.0;
    const int postersPerChunk = 2;

    final double cardWidth;
    if (size.width >= 720) {
      cardWidth = 152.0;
    } else if (size.width < 360) {
      cardWidth = 122.0;
    } else {
      cardWidth = 136.0;
    }
    final double cardHeight = (cardWidth * 1.485).roundToDouble();
    final double colExtent = cardWidth + cardSpacing;
    final double itemExtent = cardHeight + cardSpacing;
    final double chunkHeight = postersPerChunk * itemExtent;

    // Oversized bounding grid ensures rotated columns fill all corners with zero empty gaps
    final double absCos = math.cos(tiltAngle).abs();
    final double absSin = math.sin(tiltAngle).abs();
    final double gridWidth = size.width * absCos + size.height * absSin + 48.0;
    final double gridHeight = size.width * absSin + size.height * absCos + 64.0;

    final int columnCount =
        math.max(3, ((gridWidth + cardSpacing) / colExtent).ceil());
    final double totalGridWidth =
        columnCount * cardWidth + (columnCount - 1) * cardSpacing;
    final int chunksPerCycle =
        math.max(1, (_allPosters.length / postersPerChunk).ceil());
    final double cycleHeight = chunksPerCycle * chunkHeight;
    final int cyclesPerCol =
        ((gridHeight + chunkHeight) / cycleHeight).ceil().clamp(1, 10);
    final int chunksPerCol = cyclesPerCol * chunksPerCycle;

    return RepaintBoundary(
      child: ClipRect(
        child: OverflowBox(
          minWidth: 0,
          minHeight: 0,
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          alignment: Alignment.center,
          child: Transform.rotate(
            angle: tiltAngle,
            child: SizedBox(
              width: totalGridWidth,
              height: gridHeight,
              child: RepaintBoundary(
                child: ClipRect(
                  child: Flow(
                    delegate: _TiltedPosterFlowDelegate(
                      animation: _marqueeController,
                      columnCount: columnCount,
                      chunksPerCol: chunksPerCol,
                      cardWidth: cardWidth,
                      cardSpacing: cardSpacing,
                      chunkHeight: chunkHeight,
                      cycleHeight: cycleHeight,
                      gridHeight: gridHeight,
                    ),
                    children: [
                      for (int colIndex = 0; colIndex < columnCount; colIndex++)
                        ..._buildPosterColumnChunks(
                          colIndex: colIndex,
                          cyclesPerCol: cyclesPerCol,
                          chunksPerCycle: chunksPerCycle,
                          postersPerChunk: postersPerChunk,
                          cardWidth: cardWidth,
                          cardHeight: cardHeight,
                          cardSpacing: cardSpacing,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPosterColumnChunks({
    required int colIndex,
    required int cyclesPerCol,
    required int chunksPerCycle,
    required int postersPerChunk,
    required double cardWidth,
    required double cardHeight,
    required double cardSpacing,
  }) {
    final basePosters = _postersForColumn(colIndex);
    final chunks = <Widget>[];
    for (int cycle = 0; cycle < cyclesPerCol; cycle++) {
      for (int chunkInCycle = 0; chunkInCycle < chunksPerCycle; chunkInCycle++) {
        final start = chunkInCycle * postersPerChunk;
        chunks.add(
          RepaintBoundary(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int offset = 0; offset < postersPerChunk; offset++)
                  _buildPosterCard(
                    basePosters[(start + offset) % basePosters.length],
                    cardWidth,
                    cardHeight,
                    cardSpacing,
                  ),
              ],
            ),
          ),
        );
      }
    }
    return chunks;
  }

  Widget _buildPosterCard(
      String path, double width, double height, double bottomMargin) {
    final isNetwork = path.startsWith('http://') || path.startsWith('https://');
    final ImageProvider baseProvider = isNetwork
        ? CachedNetworkImageProvider(path)
        : AssetImage(path);

    return Container(
      width: width,
      height: height,
      margin: EdgeInsets.only(bottom: bottomMargin),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 0.8,
        ),
        image: DecorationImage(
          image: ResizeImage(baseProvider, width: 320),
          fit: BoxFit.cover,
          filterQuality: FilterQuality.low,
          onError: (exception, stackTrace) {},
        ),
      ),
    );
  }

  Widget _buildIntroPhase(AppStrings s) {
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
          s.isIndonesian
              ? 'Nonton Film & Serial TV Favorit Tanpa Batas'
              : 'Stream Unlimited Movies & TV Series',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ).animate(delay: 200.ms).fadeIn(duration: 450.ms),
        const SizedBox(height: 6),
        Text(
          s.isIndonesian
              ? 'Koleksi Terlengkap • Kualitas Ultra HD • Subtitle Indonesia'
              : 'Complete Library • Ultra HD Quality • World Subtitles',
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
          child: RepaintBoundary(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: const LinearProgressIndicator(
                backgroundColor: AppColors.surfaceElevated,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
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
          height: 68,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 10),
        Text(
          s.splashSelectLanguage,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 10),
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
        const SizedBox(height: 14),

        // ── Option 1: Masuk dengan Google ──
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 54),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.0,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isGoogleSigningIn ? null : _handleGoogleSignIn,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    if (_isGoogleSigningIn)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    else
                      const GoogleBrandIcon(size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.googleSignInTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            s.googleSignInSubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.textMuted,
                      size: 13,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // ── Option 2: Pulihkan dari File Cadangan ──
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 54),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.0,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isRestoringFile ? null : _handleFileRestore,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    if (_isRestoringFile)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    else
                      const Icon(
                        Iconsax.import_1,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.onboardingRestoreFromFile,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            s.onboardingRestoreFromFileDesc,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.folder_open_rounded,
                      color: AppColors.textMuted,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── Divider: "atau" / "or" ──
        Row(
          children: [
            Expanded(
              child: Container(
                height: 0.8,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                s.onboardingOrDivider,
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 0.8,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ── Primary Action: Mulai Menonton (Tanpa Akun) ──
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 48),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: ElevatedButton(
            onPressed: _onStartWatching,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.black,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    s.onboardingContinueWithoutAccount,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.black,
                  size: 17,
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
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

/// Composites cached 2-poster [RepaintBoundary] chunks directly on GPU layers
/// with viewport culling and zero widget rebuilds per VSync frame.
class _TiltedPosterFlowDelegate extends FlowDelegate {
  _TiltedPosterFlowDelegate({
    required this.animation,
    required this.columnCount,
    required this.chunksPerCol,
    required this.cardWidth,
    required this.cardSpacing,
    required this.chunkHeight,
    required this.cycleHeight,
    required this.gridHeight,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final int columnCount;
  final int chunksPerCol;
  final double cardWidth;
  final double cardSpacing;
  final double chunkHeight;
  final double cycleHeight;
  final double gridHeight;

  @override
  Size getSize(BoxConstraints constraints) {
    final double totalWidth =
        columnCount * cardWidth + math.max(0, columnCount - 1) * cardSpacing;
    return Size(totalWidth, gridHeight);
  }

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) {
    return BoxConstraints.tightFor(width: cardWidth, height: chunkHeight);
  }

  @override
  void paintChildren(FlowPaintingContext context) {
    final double colExtent = cardWidth + cardSpacing;
    final double totalLoopHeight = chunksPerCol * chunkHeight;
    if (totalLoopHeight <= 0) return;

    for (int colIndex = 0; colIndex < columnCount; colIndex++) {
      final double colX = colIndex * colExtent;
      final double phase = (colIndex * 0.27) % 1.0;
      final bool scrollUp = colIndex.isEven;
      final double progress = (animation.value + phase) % 1.0;
      final double dy =
          scrollUp ? -progress * cycleHeight : progress * cycleHeight;

      for (int chunkIndex = 0; chunkIndex < chunksPerCol; chunkIndex++) {
        final int childIndex = colIndex * chunksPerCol + chunkIndex;
        if (childIndex >= context.childCount) break;

        final double rawY = chunkIndex * chunkHeight + dy;
        final double wrappedY =
            ((rawY + chunkHeight) % totalLoopHeight) - chunkHeight;

        if (wrappedY + chunkHeight > 0.0 && wrappedY < gridHeight) {
          context.paintChild(
            childIndex,
            transform: Matrix4.translationValues(colX, wrappedY, 0.0),
          );
        }
      }
    }
  }

  @override
  bool shouldRelayout(covariant _TiltedPosterFlowDelegate oldDelegate) {
    return columnCount != oldDelegate.columnCount ||
        chunksPerCol != oldDelegate.chunksPerCol ||
        cardWidth != oldDelegate.cardWidth ||
        cardSpacing != oldDelegate.cardSpacing ||
        chunkHeight != oldDelegate.chunkHeight ||
        gridHeight != oldDelegate.gridHeight;
  }

  @override
  bool shouldRepaint(covariant _TiltedPosterFlowDelegate oldDelegate) {
    return animation != oldDelegate.animation ||
        columnCount != oldDelegate.columnCount ||
        chunksPerCol != oldDelegate.chunksPerCol ||
        cardWidth != oldDelegate.cardWidth ||
        cardSpacing != oldDelegate.cardSpacing ||
        chunkHeight != oldDelegate.chunkHeight ||
        cycleHeight != oldDelegate.cycleHeight ||
        gridHeight != oldDelegate.gridHeight;
  }
}
