import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../settings/data/legal_content.dart';
import '../../../settings/data/settings_service.dart';
import '../providers/profile_provider.dart';

/// Full Legal Agreement Onboarding Screen for Cineva.
///
/// Features:
/// - Displays all legal policies (Terms & Conditions, Privacy Policy, and DMCA Disclaimer)
///   with 100% identical styling to the existing settings legal screen.
/// - ScrollController detection: "Setuju" / "Agree" button is disabled until
///   the user scrolls completely to the bottom.
/// - Dynamic real-time reading progress bar under the AppBar.
/// - Quick scroll-to-bottom action to assist users.
/// - Persists acceptance via [SettingsService.setLegalAccepted] and completes profile onboarding.
class LegalAgreementScreen extends ConsumerStatefulWidget {
  const LegalAgreementScreen({super.key});

  @override
  ConsumerState<LegalAgreementScreen> createState() =>
      _LegalAgreementScreenState();
}

class _LegalAgreementScreenState extends ConsumerState<LegalAgreementScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;
  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (_scrollController.position.maxScrollExtent <= 20) {
          setState(() {
            _hasScrolledToBottom = true;
            _scrollProgress = 1.0;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;

    if (max > 0) {
      final progress = (current / max).clamp(0.0, 1.0);
      if ((progress - _scrollProgress).abs() > 0.005) {
        setState(() {
          _scrollProgress = progress;
        });
      }
    }

    if (!_hasScrolledToBottom) {
      if (max <= 20 || current >= max - 40) {
        setState(() {
          _hasScrolledToBottom = true;
          _scrollProgress = 1.0;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _agreeAndProceed() async {
    if (!_hasScrolledToBottom) return;

    await SettingsService.setLegalAccepted(true);
    await ref.read(userProfileProvider.notifier).completeOnboarding();

    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(appLanguageProvider);
    final s = AppStrings(language);

    final termsDoc = LegalContentRepository.getDocument(
      LegalDocType.termsAndConditions,
      s.isIndonesian,
    );
    final privacyDoc = LegalContentRepository.getDocument(
      LegalDocType.privacyPolicy,
      s.isIndonesian,
    );
    final disclaimerDoc = LegalContentRepository.getDocument(
      LegalDocType.disclaimer,
      s.isIndonesian,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.pushReplacement('/onboarding-profile');
            }
          },
          tooltip: s.isIndonesian ? 'Kembali' : 'Back',
        ),
        title: Text(
          s.legalAgreementTitle,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.5),
          child: Stack(
            children: [
              Container(
                height: 2.5,
                color: Colors.white.withValues(alpha: 0.08),
              ),
              FractionallySizedBox(
                widthFactor: _scrollProgress,
                child: Container(
                  height: 2.5,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Document 1: Terms & Conditions ──
            _buildLegalDocumentView(termsDoc, s, 1, 3),

            _buildDocumentDivider(),

            // ── Document 2: Privacy Policy ──
            _buildLegalDocumentView(privacyDoc, s, 2, 3),

            _buildDocumentDivider(),

            // ── Document 3: DMCA & Content Disclaimer ──
            _buildLegalDocumentView(disclaimerDoc, s, 3, 3),

            const SizedBox(height: 28),

            // ── Confirmation Status Card ──
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: _hasScrolledToBottom
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.surfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _hasScrolledToBottom
                      ? AppColors.primary.withValues(alpha: 0.45)
                      : Colors.white.withValues(alpha: 0.08),
                  width: _hasScrolledToBottom ? 1.2 : 0.8,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _hasScrolledToBottom
                        ? Icons.check_circle_rounded
                        : Icons.info_outline_rounded,
                    color: _hasScrolledToBottom
                        ? AppColors.primary
                        : AppColors.textMuted,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _hasScrolledToBottom
                          ? (s.isIndonesian
                              ? 'Anda telah mencapai akhir dokumen. Silakan tekan tombol Setuju di bawah untuk melanjutkan.'
                              : 'You have reached the end of the document. Tap Agree below to proceed.')
                          : (s.isIndonesian
                              ? 'Harap gulir ke bawah hingga selesai untuk menyetujui.'
                              : 'Please scroll to the bottom to agree.'),
                      style: GoogleFonts.inter(
                        color: _hasScrolledToBottom
                            ? Colors.white
                            : AppColors.textMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 110),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(s),
    );
  }

  Widget _buildLegalDocumentView(
    LegalDocumentData doc,
    AppStrings s,
    int docIndex,
    int totalDocs,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Document Index Badge
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 0.8,
              ),
            ),
            child: Text(
              s.isIndonesian
                  ? 'DOKUMEN $docIndex DARI $totalDocs'
                  : 'DOCUMENT $docIndex OF $totalDocs',
              style: GoogleFonts.outfit(
                color: AppColors.primaryLight,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Document Main Title (H1 Style) ──
        Text(
          doc.title,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          doc.subtitle,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            height: 1.45,
          ),
        ),

        const SizedBox(height: 20),

        // ── Markdown-Style Callout Blockquote ──
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            border: const Border(
              left: BorderSide(
                color: AppColors.primary,
                width: 3.5,
              ),
            ),
          ),
          child: Text(
            doc.calloutSummary,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              height: 1.55,
            ),
          ),
        ),

        const SizedBox(height: 28),

        // ── Sections (H2 & Paragraphs, Full-Width) ──
        ...doc.sections.map((sec) => _buildLegalSection(sec)),

        const SizedBox(height: 10),

        // ── Concluding Notice & Jurisdiction ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
              width: 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.public_rounded,
                    color: AppColors.primaryLight,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.legalJurisdictionNotice,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                doc.concludingNotice,
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegalSection(LegalSection sec) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Heading (Markdown H2 style)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '§${sec.number}',
                style: GoogleFonts.outfit(
                  color: AppColors.primaryLight,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sec.title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 1,
            width: double.infinity,
            color: Colors.white.withValues(alpha: 0.06),
          ),
          const SizedBox(height: 12),

          // Section Body Paragraph
          Text(
            sec.body,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 13.5,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),

          // Bullet Points (if any)
          if (sec.bulletPoints.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...sec.bulletPoints.map(
              (point) => Padding(
                padding: const EdgeInsets.only(left: 6, bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        point,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.55,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 0.8,
                ),
              ),
              child: const Icon(
                Icons.shield_outlined,
                size: 16,
                color: AppColors.primary,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(AppStrings s) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding + 14),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hint Row
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _hasScrolledToBottom
                          ? Icons.check_circle_rounded
                          : Icons.arrow_downward_rounded,
                      size: 14,
                      color: _hasScrolledToBottom
                          ? AppColors.primaryLight
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _hasScrolledToBottom
                          ? s.legalFullyRead
                          : s.legalScrollHint,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: _hasScrolledToBottom
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: _hasScrolledToBottom
                            ? AppColors.primaryLight
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                if (!_hasScrolledToBottom)
                  GestureDetector(
                    onTap: _scrollToBottom,
                    child: Row(
                      children: [
                        Text(
                          s.legalScrollToBottom,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_double_arrow_down_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Main Action Button: Setuju / Agree
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: _hasScrolledToBottom ? AppColors.primaryGradient : null,
              color: _hasScrolledToBottom
                  ? null
                  : AppColors.surfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: _hasScrolledToBottom
                  ? null
                  : Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1,
                    ),
              boxShadow: _hasScrolledToBottom
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.45),
                        blurRadius: 18,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: ElevatedButton(
              onPressed: _hasScrolledToBottom ? _agreeAndProceed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                disabledForegroundColor: AppColors.textMuted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _hasScrolledToBottom
                        ? Icons.check_circle_rounded
                        : Icons.lock_outline_rounded,
                    color:
                        _hasScrolledToBottom ? Colors.black : AppColors.textMuted,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s.legalAgreeButton,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight:
                          _hasScrolledToBottom ? FontWeight.w800 : FontWeight.w600,
                      color:
                          _hasScrolledToBottom ? Colors.black : AppColors.textMuted,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
