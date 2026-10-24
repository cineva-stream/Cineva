import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../../core/localization/app_strings.dart';
import '../../data/legal_content.dart';

/// Full-width Markdown-style legal document viewer.
/// Renders structured international legal policies without cards or boxes.
class LegalDocumentScreen extends ConsumerWidget {
  final LegalDocType type;

  const LegalDocumentScreen({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(appLanguageProvider);
    final s = AppStrings(language);
    final doc = LegalContentRepository.getDocument(type, s.isIndonesian);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: s.isIndonesian ? 'Kembali' : 'Back',
        ),
        title: Text(
          doc.title,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withValues(alpha: 0.08),
            height: 0.8,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                      const Icon(Icons.public_rounded, color: AppColors.primaryLight, size: 16),
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

            const SizedBox(height: 36),
          ],
        ),
      ),
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
}
