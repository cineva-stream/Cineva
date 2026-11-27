import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/content_preference.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../../core/platform/device_form_factor.dart';
import '../../../../shared/widgets/modern_flag_badge.dart';
import '../../../home/presentation/providers/home_providers.dart';

/// Dedicated full-screen page for selecting the user's Content Preference.
///
/// Matches the minimalist flat-list aesthetic of [AppLanguageScreen]:
/// no cards, smooth 1px hairline borders, active item highlighted in
/// Cineva Orange ([AppColors.primary]) with a trailing checkmark icon.
class ContentPreferenceScreen extends ConsumerWidget {
  const ContentPreferenceScreen({super.key});

  String? _flagCodeForPreference(ContentPreference pref) {
    switch (pref) {
      case ContentPreference.all:
        return null;
      case ContentPreference.indonesia:
        return 'ID';
      case ContentPreference.anime:
        return 'JP';
      case ContentPreference.hollywood:
        return 'US';
      case ContentPreference.korea:
        return 'KR';
      case ContentPreference.japan:
        return 'JP';
      case ContentPreference.bollywood:
        return 'IN';
    }
  }

  Widget _buildLeadingBadge(ContentPreference pref, bool isSelected) {
    final flagCode = _flagCodeForPreference(pref);
    if (flagCode != null) {
      return ModernFlagBadge(
        countryCode: flagCode,
        width: 28,
        height: 19,
        borderRadius: 4,
      );
    }

    return Container(
      width: 28,
      height: 19,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2028),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.16),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        pref.icon,
        size: 13,
        color: isSelected ? AppColors.primary : Colors.white70,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPref = ref.watch(contentPreferenceProvider);
    final currentLang = ref.watch(appLanguageProvider);
    final s = ref.watch(appStringsProvider);
    final isTv = ref.watch(isTvProvider);
    final isDesktop = ref.watch(isDesktopProvider);
    final isWide = isTv || isDesktop;

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
          s.settingsContentPref,
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
                    s.settingsContentPrefDesc,
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
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: ContentPreference.values.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    itemBuilder: (context, index) {
                      final pref = ContentPreference.values[index];
                      final isSelected = currentPref == pref;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () async {
                              await ref
                                  .read(contentPreferenceProvider.notifier)
                                  .setPreference(pref);
                            },
                            splashColor: Colors.transparent,
                            highlightColor: Colors.white.withValues(
                              alpha: 0.03,
                            ),
                            hoverColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              child: Row(
                                children: [
                                  _buildLeadingBadge(pref, isSelected),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          pref.getLocalizedLabel(
                                            s.isIndonesian,
                                            currentLang,
                                          ),
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? AppColors.primary
                                                : Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          pref.getLocalizedDescription(
                                            s.isIndonesian,
                                            currentLang,
                                          ),
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: isSelected
                                                ? AppColors.primary.withValues(
                                                    alpha: 0.8,
                                                  )
                                                : AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_rounded,
                                      color: AppColors.primary,
                                      size: 22,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (index == ContentPreference.values.length - 1)
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                        ],
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
