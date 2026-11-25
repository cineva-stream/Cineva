import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../shared/widgets/tv_focusable.dart';
import '../../data/member_card_share_service.dart';
import '../../domain/entities/watch_insights.dart';
import '../../domain/models/user_profile.dart';
import '../providers/profile_provider.dart';
import '../providers/watch_insights_provider.dart';
import '../widgets/cineva_member_card_widget.dart';

/// Clean, modern, and interactive Watch Statistics & Shareable Member Card screen.
///
/// Features:
/// - Smooth count-up text & progress animations on screen open.
/// - Interactive Weekly Activity Chart (tap/touch any day bar to focus & inspect duration).
/// - Accurate multi-season TV series aggregation in Most Watched.
class CinevaInsightsScreen extends ConsumerStatefulWidget {
  const CinevaInsightsScreen({super.key});

  @override
  ConsumerState<CinevaInsightsScreen> createState() =>
      _CinevaInsightsScreenState();
}

class _CinevaInsightsScreenState extends ConsumerState<CinevaInsightsScreen> {
  final GlobalKey _cardBoundaryKey = GlobalKey();
  bool _isSharing = false;
  bool _isSaving = false;

  Future<void> _handleShareCard({
    required String caption,
    required String username,
    required AppStrings s,
  }) async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      final ok = await MemberCardShareService.shareCardWithCaption(
        boundaryKey: _cardBoundaryKey,
        captionText: caption,
        username: username,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          content: Text(
            ok
                ? s.tr(
                    'Kartu Member siap dibagikan (caption telah disalin).',
                    'Member Card ready to share (caption copied).',
                    'मेंबर कार्ड साझा करने के लिए तैयार है।',
                  )
                : s.insightsCaptionCopied,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _handleSaveCard({
    required String username,
    required AppStrings s,
  }) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final savedPath = await MemberCardShareService.saveCardToDevice(
        boundaryKey: _cardBoundaryKey,
        username: username,
      );
      if (!mounted || savedPath == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          content: Text(
            s.insightsCardSaved,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleCopyCaption({
    required String caption,
    required AppStrings s,
  }) async {
    await Clipboard.setData(ClipboardData(text: caption));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        content: Text(
          s.insightsCaptionCopied,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final lang = ref.watch(appLanguageProvider);
    final profile = ref.watch(userProfileProvider);
    final insights = ref.watch(watchInsightsProvider);
    final cardStyle = ref.watch(memberCardStyleProvider);
    final captionIndex = ref.watch(humorousCaptionIndexProvider);

    final captions = insights.generateHumorousCaptions(
      lang: lang,
      profile: profile,
    );
    final safeCaptionIdx = captionIndex % captions.length;
    final activeCaption = captions[safeCaptionIdx];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/settings');
            }
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 21,
          ),
        ),
        title: Text(
          s.insightsScreenTitle,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withValues(alpha: 0.07),
            height: 0.8,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSplitWide = constraints.maxWidth >= 860;

            final cardSection = _buildCardPanel(
              s: s,
              lang: lang,
              profile: profile,
              insights: insights,
              cardStyle: cardStyle,
              activeCaption: activeCaption,
              captionIndex: safeCaptionIdx,
              totalCaptions: captions.length,
            );

            final statsSection = _buildStatsPanel(
              context: context,
              s: s,
              lang: lang,
              insights: insights,
            );

            if (isSplitWide) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 48),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1140),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 48,
                          child: cardSection,
                        ),
                        const SizedBox(width: 28),
                        Expanded(
                          flex: 52,
                          child: statsSection,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 48),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 580),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      cardSection,
                      const SizedBox(height: 24),
                      statsSection,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // LEFT / TOP: MEMBER CARD & COMPACT CAPTION BAR
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildCardPanel({
    required AppStrings s,
    required AppLanguage lang,
    required UserProfile profile,
    required WatchInsights insights,
    required MemberCardStyle cardStyle,
    required String activeCaption,
    required int captionIndex,
    required int totalCaptions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 1. Clean Segmented Style Toggle (Member ID | Metal Card) ──
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _StyleToggleSegment(
                  label: s.insightsCardModeId,
                  isSelected: cardStyle == MemberCardStyle.idCard,
                  onTap: () => ref
                      .read(memberCardStyleProvider.notifier)
                      .state = MemberCardStyle.idCard,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _StyleToggleSegment(
                  label: s.insightsCardModeAtm,
                  isSelected: cardStyle == MemberCardStyle.atm,
                  onTap: () => ref
                      .read(memberCardStyleProvider.notifier)
                      .state = MemberCardStyle.atm,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── 2. Member Card Preview ──
        CinevaMemberCardWidget(
          profile: profile,
          insights: insights,
          language: lang,
          style: cardStyle,
          repaintBoundaryKey: _cardBoundaryKey,
        )
            .animate(key: ValueKey(cardStyle))
            .fadeIn(duration: 280.ms)
            .scale(
              begin: const Offset(0.97, 0.97),
              end: const Offset(1.0, 1.0),
              duration: 280.ms,
              curve: Curves.easeOutCubic,
            ),

        const SizedBox(height: 16),

        // ── 3. Clean Share & Save Action Row ──
        Row(
          children: [
            Expanded(
              flex: 6,
              child: TvFocusable(
                focusedScale: 1.02,
                borderRadius: BorderRadius.circular(12),
                onTap: () => _handleShareCard(
                  caption: activeCaption,
                  username: profile.username,
                  s: s,
                ),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSharing)
                        const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      else
                        const Icon(
                          Icons.ios_share_rounded,
                          color: Colors.black,
                          size: 18,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        s.insightsShareCardBtn,
                        style: GoogleFonts.outfit(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 4,
              child: TvFocusable(
                focusedScale: 1.02,
                borderRadius: BorderRadius.circular(12),
                onTap: () => _handleSaveCard(
                  username: profile.username,
                  s: s,
                ),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSaving)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else
                        const Icon(
                          Icons.download_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      const SizedBox(width: 6),
                      Text(
                        s.insightsSaveCardBtn,
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ── 4. Compact Caption Bar ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    s.tr('Caption Bagikan', 'Share Caption', 'शेयर कैप्शन'),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  TvFocusable(
                    focusedScale: 1.05,
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      ref.read(humorousCaptionIndexProvider.notifier).state =
                          (captionIndex + 1) % totalCaptions;
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.refresh_rounded,
                            size: 14,
                            color: AppColors.primaryLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            s.insightsShuffleCaptionBtn,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  TvFocusable(
                    focusedScale: 1.05,
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _handleCopyCaption(
                      caption: activeCaption,
                      s: s,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.copy_rounded,
                            size: 13.5,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            s.insightsCopyCaptionBtn,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Text(
                  activeCaption,
                  key: ValueKey(captionIndex),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.45,
                    color: AppColors.textPrimary.withValues(alpha: 0.88),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // RIGHT / BOTTOM: ANIMATED WATCH STATISTICS & INTERACTIVE CHART
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildStatsPanel({
    required BuildContext context,
    required AppStrings s,
    required AppLanguage lang,
    required WatchInsights insights,
  }) {
    final persona = insights.personaTitle(lang);
    final tagline = insights.personaTagline(lang);
    final nextPersona = insights.nextPersonaTitle(lang);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 950),
      curve: Curves.easeOutCubic,
      builder: (context, animVal, _) {
        final animatedMovies =
            (insights.moviesWatchedCount * animVal).round();
        final animatedEpisodes =
            (insights.episodesWatchedCount * animVal).round();
        final animatedCompleted =
            (insights.completedTitlesCount * animVal).round();
        final animatedCompletionRate =
            (insights.completionRatePercent * animVal).round();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. Clean Persona Summary Card with Animated Progress ──
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          persona,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        '${insights.formattedDurationCompact(lang, progressFactor: animVal)} / ${insights.nextLevelTargetHours}h',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tagline,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: insights.levelProgress * animVal,
                      minHeight: 5,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  if (insights.personaLevel < 5) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${s.tr('Berikutnya:', 'Next:', 'अगला:')} $nextPersona',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.04, end: 0),

            const SizedBox(height: 14),

            // ── 2. Clean 2×2 Core Metric Grid with Count-Up Text ──
            Row(
              children: [
                Expanded(
                  child: _CleanMetricCard(
                    icon: Iconsax.timer_1,
                    label: s.tr('Waktu Menonton', 'Watch Time', 'देखने का समय'),
                    value: insights.formattedDurationCompact(
                      lang,
                      progressFactor: animVal,
                    ),
                    subLabel: s.tr(
                      '${insights.activeDaysCount} hari aktif',
                      '${insights.activeDaysCount} active days',
                      '${insights.activeDaysCount} सक्रिय दिन',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CleanMetricCard(
                    icon: Iconsax.video_play,
                    label: s.tr(
                      'Film Ditonton',
                      'Movies Watched',
                      'देखी गई फ़िल्में',
                    ),
                    value: '$animatedMovies',
                    subLabel: s.tr(
                      '${insights.watchlistCount} di daftar tonton',
                      '${insights.watchlistCount} in watchlist',
                      '${insights.watchlistCount} वॉचलिस्ट में',
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 60.ms, duration: 320.ms).slideY(
                  begin: 0.04,
                  end: 0,
                ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _CleanMetricCard(
                    icon: Iconsax.monitor,
                    label: s.tr(
                      'Episode Serial',
                      'Episodes Watched',
                      'देखे गए एपिसोड',
                    ),
                    value: '$animatedEpisodes',
                    subLabel: s.tr(
                      '${insights.tvSeriesWatchedCount} serial TV',
                      '${insights.tvSeriesWatchedCount} TV series',
                      '${insights.tvSeriesWatchedCount} टीवी सीरीज़',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CleanMetricCard(
                    icon: Iconsax.tick_circle,
                    label: s.tr('Selesai Ditonton', 'Completed', 'पूरे किए गए'),
                    value: '$animatedCompleted',
                    subLabel: s.tr(
                      '$animatedCompletionRate% tingkat selesai',
                      '$animatedCompletionRate% completion rate',
                      '$animatedCompletionRate% पूर्णता दर',
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 110.ms, duration: 320.ms).slideY(
                  begin: 0.04,
                  end: 0,
                ),

            const SizedBox(height: 14),

            // ── 3. Interactive Touch-to-Focus Weekly Activity Bar Chart ──
            _InteractiveWeeklyChartCard(
              s: s,
              lang: lang,
              weeklyMinutes: insights.weeklyMinutesByWeekday,
              entranceProgress: animVal,
            ).animate().fadeIn(delay: 160.ms, duration: 340.ms).slideY(
                  begin: 0.04,
                  end: 0,
                ),

            // ── 4. Top Watched Titles (Aggregated Multi-Season TV & Movies) ──
            if (insights.topWatchedTitles.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.tr(
                        'Tontonan Teratas',
                        'Most Watched',
                        'सबसे ज़्यादा देखे गए',
                      ),
                      style: GoogleFonts.outfit(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...insights.topWatchedTitles.take(4).map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TvFocusable(
                          focusedScale: 1.01,
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => context.push(
                            item.isTv
                                ? '/tv/${item.id}'
                                : '/movie/${item.id}',
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: item.posterPath != null &&
                                        item.posterPath!.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: ApiConstants.imageUrl(
                                          item.posterPath!,
                                          size: ApiConstants.posterSmall,
                                        ),
                                        width: 40,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, _, _) => Container(
                                          width: 40,
                                          height: 56,
                                          color: AppColors.surfaceVariant,
                                          child: const Icon(
                                            Icons.movie_rounded,
                                            color: AppColors.textMuted,
                                            size: 18,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        width: 40,
                                        height: 56,
                                        color: AppColors.surfaceVariant,
                                        child: const Icon(
                                          Icons.movie_rounded,
                                          color: AppColors.textMuted,
                                          size: 18,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.formattedSubtitle(lang),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                item.formattedDuration(
                                  lang,
                                  progressFactor: animVal,
                                ),
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ).animate().fadeIn(delay: 210.ms, duration: 340.ms).slideY(
                    begin: 0.04,
                    end: 0,
                  ),
            ],
          ],
        );
      },
    );
  }
}

class _StyleToggleSegment extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _StyleToggleSegment({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      focusedScale: 1.01,
      borderRadius: BorderRadius.circular(9),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _CleanMetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subLabel;

  const _CleanMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryLight, size: 16),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Interactive Weekly Activity Chart where tapping any day column focuses on that bar,
/// dims unselected bars, and shows a dynamic duration readout for the focused day.
class _InteractiveWeeklyChartCard extends StatefulWidget {
  final AppStrings s;
  final AppLanguage lang;
  final List<int> weeklyMinutes;
  final double entranceProgress;

  const _InteractiveWeeklyChartCard({
    required this.s,
    required this.lang,
    required this.weeklyMinutes,
    required this.entranceProgress,
  });

  @override
  State<_InteractiveWeeklyChartCard> createState() =>
      _InteractiveWeeklyChartCardState();
}

class _InteractiveWeeklyChartCardState
    extends State<_InteractiveWeeklyChartCard> {
  int? _focusedDayIndex;

  String _formatDayMinutes(int mins) {
    final h = mins ~/ 60;
    final m = mins % 60;
    if (widget.lang.isHindi) {
      if (h == 0) return '$m मि';
      if (m == 0) return '$h घं';
      return '$hघं $mमि';
    }
    if (widget.lang.isIndonesian) {
      if (h == 0) return '$m mnt';
      if (m == 0) return '${h}j';
      return '${h}j ${m}m';
    }
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final shortDayLabels = widget.lang.isHindi
        ? const ['सोम', 'मंगल', 'बुध', 'गुरु', 'शुक्र', 'शनि', 'रवि']
        : (widget.lang.isIndonesian
            ? const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']
            : const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']);

    final fullDayLabels = widget.lang.isHindi
        ? const [
            'सोमवार',
            'मंगलवार',
            'बुधवार',
            'गुरुवार',
            'शुक्रवार',
            'शनिवार',
            'रविवार',
          ]
        : (widget.lang.isIndonesian
            ? const [
                'Senin',
                'Selasa',
                'Rabu',
                'Kamis',
                'Jumat',
                'Sabtu',
                'Minggu',
              ]
            : const [
                'Monday',
                'Tuesday',
                'Wednesday',
                'Thursday',
                'Friday',
                'Saturday',
                'Sunday',
              ]);

    final maxVal = widget.weeklyMinutes.fold<int>(
      1,
      (prev, el) => math.max(prev, el),
    );

    final hasFocus = _focusedDayIndex != null;
    final focusedMins = hasFocus && _focusedDayIndex! < widget.weeklyMinutes.length
        ? widget.weeklyMinutes[_focusedDayIndex!]
        : 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasFocus
              ? AppColors.primary.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.s.tr(
                        'Aktivitas Mingguan',
                        'Weekly Activity',
                        'साप्ताहिक गतिविधि',
                      ),
                      style: GoogleFonts.outfit(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasFocus
                          ? widget.s.tr(
                              'Ketuk lagi untuk melihat semua hari',
                              'Tap again to view all days',
                              'सभी दिन देखने के लिए फिर से टैप करें',
                            )
                          : widget.s.tr(
                              'Sentuh grafik hari untuk melihat detail',
                              'Tap any day bar to focus & inspect',
                              'विवरण देखने के लिए किसी भी दिन पर टैप करें',
                            ),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasFocus)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: GestureDetector(
                    key: ValueKey(_focusedDayIndex),
                    onTap: () => setState(() => _focusedDayIndex = null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        '${fullDayLabels[_focusedDayIndex!]} • ${_formatDayMinutes(focusedMins)}',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 112,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (idx) {
                final rawMins = idx < widget.weeklyMinutes.length
                    ? widget.weeklyMinutes[idx]
                    : 0;
                final animatedMins =
                    (rawMins * widget.entranceProgress).round();
                final targetRatio =
                    maxVal > 0 ? (rawMins / maxVal).clamp(0.10, 1.0) : 0.10;
                final animatedRatio =
                    (targetRatio * widget.entranceProgress).clamp(0.08, 1.0);

                final isFocused = _focusedDayIndex == idx;
                final isPeak = !hasFocus && rawMins > 0 && rawMins == maxVal;
                final isHighlighted = isFocused || isPeak;
                final isDimmed = hasFocus && !isFocused;

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _focusedDayIndex = isFocused ? null : idx;
                      });
                    },
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isDimmed ? 0.32 : 1.0,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            rawMins > 0 ? _formatDayMinutes(animatedMins) : '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: isFocused ? 10.5 : 9.5,
                              fontWeight: isHighlighted
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isHighlighted
                                  ? AppColors.primaryLight
                                  : AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            width: isFocused ? 26 : 20,
                            height: 64 * animatedRatio,
                            decoration: BoxDecoration(
                              gradient: isHighlighted
                                  ? const LinearGradient(
                                      colors: [
                                        AppColors.primaryLight,
                                        AppColors.primary,
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    )
                                  : null,
                              color: isHighlighted
                                  ? null
                                  : Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(7),
                              boxShadow: isFocused
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.45),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            shortDayLabels[idx],
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: isHighlighted
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isHighlighted
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
