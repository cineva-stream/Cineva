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

/// Personal Watch Statistics (Cineva Insights / Wrapped) & Shareable KTP / ATM Member Card Studio.
///
/// Features a responsive layout:
/// - **Mobile (< 840px)**: Clean single-column vertical flow (Card Studio -> Humorous Caption & Share -> Bento Analytics -> 7-Day Activity -> DNA & Top Titles).
/// - **Tablet, Windows Desktop & Android TV (>= 840px)**: Professional 2-Column Split Dashboard.
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
          content: Row(
            children: [
              Icon(
                ok ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                color: ok ? AppColors.success : AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ok
                      ? s.tr(
                          'Kartu Member siap dibagikan! Caption lucu juga telah disalin ke clipboard.',
                          'Member Card ready to share! Humorous caption also copied to clipboard.',
                          'मेंबर कार्ड साझा करने के लिए तैयार है! कैप्शन क्लिपबोर्ड पर भी कॉपी हो गया है।',
                        )
                      : s.insightsCaptionCopied,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
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
          content: Row(
            children: [
              const Icon(
                Icons.download_done_rounded,
                color: AppColors.success,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${s.insightsCardSaved}\n($savedPath)',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
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
        content: Row(
          children: [
            const Icon(
              Icons.copy_all_rounded,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                s.insightsCaptionCopied,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Iconsax.chart_21,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                s.insightsScreenTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 18.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TvFocusable(
              focusedScale: 1.05,
              borderRadius: BorderRadius.circular(12),
              onTap: () => _handleShareCard(
                caption: activeCaption,
                username: profile.username,
                s: s,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFFFF8F00)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.share_rounded,
                      size: 15,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      s.tr('Bagikan', 'Share', 'साझा करें'),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSplitWide = constraints.maxWidth >= 860;

            final cardStudioSection = _buildCardStudioPanel(
              context: context,
              s: s,
              lang: lang,
              profile: profile,
              insights: insights,
              cardStyle: cardStyle,
              activeCaption: activeCaption,
              captionIndex: safeCaptionIdx,
              totalCaptions: captions.length,
            );

            final analyticsBentoSection = _buildAnalyticsBentoPanel(
              context: context,
              s: s,
              lang: lang,
              insights: insights,
            );

            if (isSplitWide) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 48),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 47,
                          child: cardStudioSection,
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 53,
                          child: analyticsBentoSection,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      cardStudioSection,
                      const SizedBox(height: 24),
                      analyticsBentoSection,
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
  // LEFT / TOP PANEL: KTP & ATM MEMBER CARD STUDIO + HUMOROUS CAPTION SHARER
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildCardStudioPanel({
    required BuildContext context,
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
        // ── 1. Mode Switcher (KTP Sinema vs Kartu ATM VIP) ──
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _CardModeTabButton(
                  icon: Icons.badge_rounded,
                  label: s.insightsCardModeKtp,
                  isSelected: cardStyle == MemberCardStyle.ktp,
                  onTap: () => ref
                      .read(memberCardStyleProvider.notifier)
                      .state = MemberCardStyle.ktp,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _CardModeTabButton(
                  icon: Icons.credit_card_rounded,
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

        const SizedBox(height: 14),

        // ── 2. Live KTP / ATM Card Preview (1.586:1 ISO/IEC 7810 ID-1) ──
        CinevaMemberCardWidget(
          profile: profile,
          insights: insights,
          language: lang,
          style: cardStyle,
          repaintBoundaryKey: _cardBoundaryKey,
        )
            .animate(key: ValueKey(cardStyle))
            .fadeIn(duration: 300.ms)
            .scale(
              begin: const Offset(0.97, 0.97),
              end: const Offset(1, 1),
              duration: 300.ms,
              curve: Curves.easeOutCubic,
            ),

        const SizedBox(height: 10),

        // Proportion note pill
        Center(
          child: Text(
            s.tr(
              'Ukuran Standar KTP / ATM Internasional (ISO 7810 • 85.6 × 54 mm • HD 3x)',
              'Standard International ID / ATM Card Ratio (ISO 7810 • 85.6 × 54 mm • 3x HD)',
              'अंतर्राष्ट्रीय ID / ATM कार्ड आकार (ISO 7810 • 85.6 × 54 mm • 3x HD)',
            ),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── 3. Primary Share & Save HD Buttons ──
        Row(
          children: [
            Expanded(
              flex: 6,
              child: TvFocusable(
                focusedScale: 1.03,
                borderRadius: BorderRadius.circular(14),
                onTap: () => _handleShareCard(
                  caption: activeCaption,
                  username: profile.username,
                  s: s,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFFFF8F00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSharing)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.black,
                          ),
                        )
                      else
                        const Icon(
                          Icons.share_rounded,
                          color: Colors.black,
                          size: 19,
                        ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          s.insightsShareCardBtn,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
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
                focusedScale: 1.03,
                borderRadius: BorderRadius.circular(14),
                onTap: () => _handleSaveCard(
                  username: profile.username,
                  s: s,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSaving)
                        const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      else
                        const Icon(
                          Icons.download_rounded,
                          color: AppColors.primaryLight,
                          size: 18,
                        ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          s.insightsSaveCardBtn,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── 4. Humorous Default Caption Generator Box ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.tr(
                            'Caption Humor & Ajakan Download',
                            'Witty Social Caption & App Invite',
                            'मज़ेदार सोशल कैप्शन और ऐप आमंत्रण',
                          ),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          s.tr(
                            'Otomatis dilampirkan & disalin saat Anda membagikan kartu',
                            'Automatically attached & copied when you share your card',
                            'कार्ड साझा करते समय स्वतः संलग्न और कॉपी किया जाता है',
                          ),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${captionIndex + 1}/$totalCaptions',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: SelectableText(
                  activeCaption,
                  style: GoogleFonts.inter(
                    fontSize: 12.2,
                    height: 1.48,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TvFocusable(
                      focusedScale: 1.03,
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        ref.read(humorousCaptionIndexProvider.notifier).state =
                            (captionIndex + 1) % totalCaptions;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.casino_rounded,
                              size: 16,
                              color: AppColors.primaryLight,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              s.insightsShuffleCaptionBtn,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TvFocusable(
                    focusedScale: 1.03,
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _handleCopyCaption(
                      caption: activeCaption,
                      s: s,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.copy_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            s.insightsCopyCaptionBtn,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // RIGHT / BOTTOM PANEL: BENTO ANALYTICS DASHBOARD (CINEVA INSIGHTS)
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildAnalyticsBentoPanel({
    required BuildContext context,
    required AppStrings s,
    required AppLanguage lang,
    required WatchInsights insights,
  }) {
    final persona = insights.personaTitle(lang);
    final tagline = insights.personaTagline(lang);
    final nextPersona = insights.nextPersonaTitle(lang);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 1. Persona Rank & Level Progression Card ──
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.18),
                const Color(0xFF141422),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'LEVEL ${insights.personaLevel} / 5',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.tr(
                        'PANGKAT REBAHAN RESMI',
                        'OFFICIAL CINEMA PERSONA',
                        'आधिकारिक सिनेमा रैंक',
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.9,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ),
                  const Icon(
                    Iconsax.crown_1,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                persona,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
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
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: insights.levelProgress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${insights.formattedDurationCompact(lang)} / ${insights.nextLevelTargetHours}h',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      insights.personaLevel < 5
                          ? '${s.tr('Berikutnya:', 'Next Rank:', 'अगला पद:')} $nextPersona'
                          : nextPersona,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── 2. 2×2 Bento Grid of Core Metrics ──
        Row(
          children: [
            Expanded(
              child: _BentoStatCard(
                icon: Iconsax.timer_1,
                accentColor: AppColors.primary,
                title: s.tr('Total Jam Nonton', 'Total Watch Time', 'कुल देखने का समय'),
                mainValue: insights.formattedDurationCompact(lang),
                subtitle: s.tr(
                  'Hemat ~${insights.estimatedTicketsSaved} tiket bioskop',
                  'Saved ~${insights.estimatedTicketsSaved} cinema tickets',
                  '~${insights.estimatedTicketsSaved} सिनेमा टिकटों की बचत',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BentoStatCard(
                icon: Iconsax.video_play,
                accentColor: const Color(0xFF00E5FF),
                title: s.tr('Film & Episode', 'Movies & Episodes', 'फ़िल्में और एपिसोड'),
                mainValue:
                    '${insights.moviesWatchedCount}F • ${insights.episodesWatchedCount}EP',
                subtitle: s.tr(
                  '${insights.tvSeriesWatchedCount} Serial TV dijelajahi',
                  '${insights.tvSeriesWatchedCount} TV Series explored',
                  '${insights.tvSeriesWatchedCount} टीवी सीरीज़ देखी गईं',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _BentoStatCard(
                icon: Iconsax.tick_circle,
                accentColor: AppColors.success,
                title: s.tr('Tingkat Penyelesaian', 'Completion Rate', 'पूर्णता दर'),
                mainValue: '${insights.completionRatePercent}%',
                subtitle: s.tr(
                  '${insights.completedTitlesCount} tontonan ditamatkan',
                  '${insights.completedTitlesCount} titles finished',
                  '${insights.completedTitlesCount} शीर्षक पूरे किए',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BentoStatCard(
                icon: Iconsax.star_1,
                accentColor: const Color(0xFFFF7597),
                title: s.tr('Selera & Koleksi', 'Taste & Watchlist', 'पसंद और वॉचलिस्ट'),
                mainValue: '${insights.averageRating.toStringAsFixed(1)} ⭐',
                subtitle: s.tr(
                  '${insights.watchlistCount} disimpan • ${insights.activeDaysCount} hari aktif',
                  '${insights.watchlistCount} saved • ${insights.activeDaysCount} active days',
                  '${insights.watchlistCount} सहेजे • ${insights.activeDaysCount} सक्रिय दिन',
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── 3. Weekly Watch Activity Bar Chart (Mon - Sun) ──
        _WeeklyActivityChartCard(
          s: s,
          lang: lang,
          weeklyMinutes: insights.weeklyMinutesByWeekday,
          streak: insights.activeDaysStreak,
        ),

        const SizedBox(height: 16),

        // ── 4. Content DNA / Watch Flavor Breakdown ──
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Iconsax.magic_star,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s.tr(
                      'DNA Sinema & Karakter Tontonan',
                      'Cinema DNA & Viewing Profile',
                      'सिनेमा DNA और देखने की प्रोफ़ाइल',
                    ),
                    style: GoogleFonts.outfit(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...insights.topFlavors.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              item.localizedLabel(lang),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '${(item.percentage * 100).round()}%',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: item.percentage,
                          minHeight: 6.5,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.07),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── 5. Top Watched Titles Highlight ──
        if (insights.topWatchedItems.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Iconsax.cup,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      s.tr(
                        'Tontonan Teratas Anda',
                        'Your Top Watched Titles',
                        'आपके सबसे ज़्यादा देखे गए शीर्षक',
                      ),
                      style: GoogleFonts.outfit(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...insights.topWatchedItems.take(4).map((item) {
                  final mins = math.max(1, (item.positionMs / 60000).round());
                  final isTv = item.mediaType == 'tv';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TvFocusable(
                      focusedScale: 1.02,
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => context.push(
                        isTv ? '/tv/${item.id}' : '/movie/${item.id}',
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
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
                                      width: 42,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, _, _) => Container(
                                        width: 42,
                                        height: 60,
                                        color: AppColors.surface,
                                        child: const Icon(
                                          Icons.movie_rounded,
                                          color: AppColors.textMuted,
                                          size: 20,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      width: 42,
                                      height: 60,
                                      color: AppColors.surface,
                                      child: const Icon(
                                        Icons.movie_rounded,
                                        color: AppColors.textMuted,
                                        size: 20,
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
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    isTv &&
                                            item.season != null &&
                                            item.episode != null
                                        ? 'S${item.season} • E${item.episode} • $mins ${s.tr('menit', 'mins', 'मिनट')}'
                                        : '$mins ${s.tr('menit ditonton', 'mins watched', 'मिनट देखा गया')}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${(item.progressPercent * 100).round()}%',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CardModeTabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CardModeTabButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      focusedScale: 1.02,
      borderRadius: BorderRadius.circular(11),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.black : AppColors.textSecondary,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.black : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BentoStatCard extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String mainValue;
  final String subtitle;

  const _BentoStatCard({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.mainValue,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 17),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            mainValue,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyActivityChartCard extends StatelessWidget {
  final AppStrings s;
  final AppLanguage lang;
  final List<int> weeklyMinutes;
  final int streak;

  const _WeeklyActivityChartCard({
    required this.s,
    required this.lang,
    required this.weeklyMinutes,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final dayLabels = lang.isHindi
        ? const ['सोम', 'मंगल', 'बुध', 'गुरु', 'शुक्र', 'शनि', 'रवि']
        : (lang.isIndonesian
            ? const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']
            : const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']);

    final maxVal = weeklyMinutes.fold<int>(
      1,
      (prev, el) => math.max(prev, el),
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Iconsax.activity,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.tr(
                    'Ritme Menonton Mingguan',
                    'Weekly Viewing Rhythm',
                    'साप्ताहिक देखने की लय',
                  ),
                  style: GoogleFonts.outfit(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$streak ${s.tr('Hari Streak', 'Day Streak', 'दिन स्ट्रीक')}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ],
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
                final mins = idx < weeklyMinutes.length ? weeklyMinutes[idx] : 0;
                final ratio = maxVal > 0 ? (mins / maxVal).clamp(0.08, 1.0) : 0.08;
                final isPeak = mins > 0 && mins == maxVal;

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        mins > 0 ? '${mins}m' : '-',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9.5,
                          fontWeight:
                              isPeak ? FontWeight.w800 : FontWeight.w500,
                          color: isPeak
                              ? AppColors.primaryLight
                              : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 22,
                        height: 64 * ratio,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isPeak
                                ? [AppColors.primary, const Color(0xFFFF8F00)]
                                : [
                                    Colors.white.withValues(alpha: 0.22),
                                    Colors.white.withValues(alpha: 0.10),
                                  ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dayLabels[idx],
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight:
                              isPeak ? FontWeight.w700 : FontWeight.w500,
                          color: isPeak
                              ? AppColors.primaryLight
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
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
