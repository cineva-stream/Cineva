import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/platform/device_form_factor.dart';
import '../../data/release_notes_catalog.dart';

/// Dedicated full-screen page displaying Cineva's version history in a
/// minimalist vertical timeline with circular version dots, concise core
/// feature titles only (no long sentences), and scroll-triggered reveal
/// animations in 3 languages (Indonesian, English, and Hindi).
class ReleaseNotesScreen extends ConsumerWidget {
  const ReleaseNotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(appLanguageProvider);
    final s = ref.watch(appStringsProvider);
    final isTv = ref.watch(isTvProvider);
    final isDesktop = ref.watch(isDesktopProvider);
    final isWide = isTv || isDesktop;
    const entries = ReleaseNotesCatalog.entries;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 19,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/settings');
            }
          },
        ),
        title: Text(
          s.settingsReleaseNotesTitle,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWide ? 680 : double.infinity,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
                  child: Text(
                    s.settingsReleaseNotesSubtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    cacheExtent: 60,
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final isLatest = index == 0;
                      final isLast = index == entries.length - 1;
                      return _ReleaseTimelineNode(
                        key: ValueKey('${entry.version}_${currentLang.name}'),
                        entry: entry,
                        language: currentLang,
                        strings: s,
                        isLatest: isLatest,
                        isLast: isLast,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReleaseTimelineNode extends StatelessWidget {
  final ReleaseNoteEntry entry;
  final AppLanguage language;
  final AppStrings strings;
  final bool isLatest;
  final bool isLast;

  const _ReleaseTimelineNode({
    super.key,
    required this.entry,
    required this.language,
    required this.strings,
    required this.isLatest,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final features = entry.localizedFeatures(language);
    final dateText = entry.localizedDate(language);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Left Column: Vertical Line + Circular Dot ──
          SizedBox(
            width: 28,
            child: Column(
              children: [
                const SizedBox(height: 3),
                _buildVersionDot()
                    .animate()
                    .scale(
                      begin: const Offset(0.4, 0.4),
                      end: const Offset(1.0, 1.0),
                      duration: 260.ms,
                      curve: Curves.easeOutBack,
                    )
                    .fadeIn(duration: 220.ms),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // ── Right Column: Version Header & Staggered Core Feature List ──
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 8 : 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'v${entry.version}',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isLatest ? AppColors.primary : Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        dateText,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(duration: 240.ms)
                      .slideX(
                        begin: 0.03,
                        end: 0,
                        duration: 240.ms,
                        curve: Curves.easeOutCubic,
                      ),
                  const SizedBox(height: 10),
                  ...List.generate(features.length, (i) {
                    final featureText = features[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.only(top: 8, right: 10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isLatest
                                  ? AppColors.primary.withValues(alpha: 0.85)
                                  : Colors.white.withValues(alpha: 0.45),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              featureText,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.88),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(
                          duration: 260.ms,
                          delay: (50 + (i * 40)).ms,
                        )
                        .slideY(
                          begin: 0.14,
                          end: 0,
                          duration: 260.ms,
                          delay: (50 + (i * 40)).ms,
                          curve: Curves.easeOutCubic,
                        );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionDot() {
    if (isLatest) {
      return Container(
        width: 18,
        height: 18,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withValues(alpha: 0.20),
        ),
        child: Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
          ),
        ),
      );
    }

    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.background,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
    );
  }
}
