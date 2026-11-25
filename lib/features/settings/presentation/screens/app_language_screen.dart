import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../../core/platform/device_form_factor.dart';
import '../../../../shared/widgets/modern_flag_badge.dart';

/// Dedicated full-screen page for selecting the application interface language.
///
/// Renders a minimalist flat list without cards, separated only by smooth 1px
/// hairline borders. The active language displays its title in Cineva Orange
/// ([AppColors.primary]) along with a trailing checkmark icon.
class AppLanguageScreen extends ConsumerWidget {
  const AppLanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          s.settingsAppLanguage,
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
                    s.settingsAppLanguageDesc,
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
                    itemCount: AppLanguage.values.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    itemBuilder: (context, index) {
                      final lang = AppLanguage.values[index];
                      final isSelected = currentLang == lang;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () async {
                              await ref
                                  .read(appLanguageProvider.notifier)
                                  .setLanguage(lang);
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
                                  ModernFlagBadge(
                                    countryCode: lang.flagCountryCode,
                                    width: 28,
                                    height: 19,
                                    borderRadius: 4,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          lang.localizedDisplayName(
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
                                          lang.localizedLabel(currentLang),
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
                          if (index == AppLanguage.values.length - 1)
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
