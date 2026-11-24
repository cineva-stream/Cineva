import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/content_preference.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../../core/platform/device_form_factor.dart';
import '../../../../shared/widgets/modern_flag_badge.dart';
import '../../../../shared/widgets/tv_focusable.dart';
import '../../../backup/data/backup_restore_service.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../data/settings_service.dart';
import '../../data/subtitle_languages.dart';
import '../../../player/presentation/providers/player_providers.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../profile/presentation/providers/watch_insights_provider.dart';
import '../../../profile/presentation/widgets/avatar_display.dart';

/// Modern, informative, and interactive Settings screen for Cineva.
///
/// Features:
/// - Grouped modern obsidian cards with Cinema Amber accents
/// - Content preference (Indonesia, Anime, Hollywood, Korea, etc.)
/// - Real-time interactive toggles and selection modals
/// - Cache cleaner with live feedback
/// - Hardware acceleration & smooth playback settings
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _contentPreference = 'all';
  String _defaultSubtitleLang = 'id';
  bool _autoTranslate = true;
  String _defaultQuality = 'Auto';
  String _subtitleFontSize = 'Sedang';
  String _subtitleBg = 'Transparan';
  bool _hwAcceleration = true;
  bool _autoPlayNextEpisode = true;
  double _cacheSizeMb = 38.4;
  String _appVersion = AppConstants.appVersion;
  String _buildNumber = AppConstants.appBuildNumber;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          if (info.version.isNotEmpty) _appVersion = info.version;
          if (info.buildNumber.isNotEmpty) {
            _buildNumber = AppConstants.normalizeBuildNumber(info.buildNumber);
          }
        });
      }
    } catch (_) {
      // Keep defaults
    }
  }

  void _loadSettings() {
    setState(() {
      _contentPreference = SettingsService.getContentPreference();
      _defaultSubtitleLang = SettingsService.getDefaultSubtitleLang();
      _autoTranslate = SettingsService.getAutoTranslate();
      _defaultQuality = SettingsService.getDefaultQuality();
      _subtitleFontSize = SettingsService.getSubtitleFontSize();
      _subtitleBg = SettingsService.getSubtitleBackground();
      _hwAcceleration = SettingsService.getHardwareAcceleration();
      _autoPlayNextEpisode = SettingsService.getAutoPlayNextEpisode();
    });
  }

  String _localizedFontSize(String size, AppStrings s) {
    switch (size.toLowerCase()) {
      case 'kecil':
        return s.tr('Kecil', 'Small', 'छोटा');
      case 'sedang':
        return s.tr('Sedang', 'Medium', 'मध्यम');
      case 'besar':
        return s.tr('Besar', 'Large', 'बड़ा');
      default:
        return size;
    }
  }

  String _localizedSubtitleBg(String bg, AppStrings s) {
    final lower = bg.toLowerCase();
    if (lower.contains('transparan') && !lower.contains('semi')) {
      return s.tr('Transparan', 'Transparent', 'पारदर्शी');
    } else if (lower.contains('semi')) {
      return s.tr('Semi-Transparan', 'Semi-Transparent', 'अर्ध-पारदर्शी');
    } else if (lower.contains('hitam') || lower.contains('gelap')) {
      return s.tr('Hitam Pekat', 'Solid Black', 'गहरा काला');
    }
    return bg;
  }

  // ── Unified Scrollable Root Modal Bottom Sheet ──

  void _showModalSheet({
    required Widget header,
    required List<Widget> children,
    String? subtitle,
  }) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 560),
      backgroundColor: AppColors.surface,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).padding.bottom;
        return SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle pill
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 42,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                // Header & Subtitle
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      header,
                      if (subtitle != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(color: Color(0x15FFFFFF), height: 1),
                // Scrollable content list
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(20, 14, 20, 24 + bottomInset),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: children,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showContentPreferenceSheet(AppStrings s) {
    final preferences = ContentPreference.values;

    _showModalSheet(
      header: Row(
        children: [
          const Icon(Iconsax.category_2, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Text(
            s.settingsContentPref,
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
      subtitle: s.settingsContentPrefDesc,
      children: preferences.map((pref) {
        final isSelected = _contentPreference == pref.code;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.05),
              width: isSelected ? 1.2 : 0.6,
            ),
          ),
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(pref.icon, color: isSelected ? AppColors.primary : AppColors.textMuted, size: 18),
            ),
            title: Text(
              pref.getLocalizedLabel(s.isIndonesian, s.language),
              style: GoogleFonts.inter(
                color: isSelected ? AppColors.primary : Colors.white,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              pref.getLocalizedDescription(s.isIndonesian, s.language),
              style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11),
            ),
            trailing: isSelected
                ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                : null,
            onTap: () async {
              Navigator.of(context, rootNavigator: true).pop();
              await ref.read(contentPreferenceProvider.notifier).setPreference(pref);
              _loadSettings();

              if (mounted) {
                final prefLabel = pref.getLocalizedLabel(s.isIndonesian, s.language);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.surfaceElevated,
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s.tr(
                              'Preferensi diubah ke $prefLabel. Beranda & Pencarian otomatis disesuaikan.',
                              'Preference changed to $prefLabel. Home & Search updated.',
                              'वरीयता $prefLabel में बदल दी गई। होम और खोज अपडेट हो गए।',
                            ),
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
        );
      }).toList(),
    );
  }

  void _showQualitySheet(AppStrings s) {
    final options = [
      {
        'val': 'Auto',
        'label': 'Auto (Adaptif FHD)',
        'desc': s.tr(
          'Menyesuaikan kecepatan jaringan secara dinamis',
          'Dynamically adapts to network speed',
          'नेटवर्क गति के अनुसार गतिशील रूप से अनुकूलित होता है',
        ),
      },
      {
        'val': '1080p',
        'label': '1080p Full HD',
        'desc': s.tr(
          'Kualitas gambar terbaik, jernih & tajam',
          'Best picture quality, crystal clear & sharp',
          'सर्वश्रेष्ठ चित्र गुणवत्ता, बिल्कुल स्पष्ट और शार्प',
        ),
      },
      {
        'val': '720p',
        'label': '720p HD',
        'desc': s.tr(
          'Hemat kuota dengan resolusi tetap tajam',
          'Data saving with crisp resolution',
          'शार्प रेज़ोल्यूशन के साथ डेटा की बचत',
        ),
      },
      {
        'val': '480p',
        'label': '480p SD',
        'desc': s.tr(
          'Koneksi lambat & paling hemat kuota',
          'For slow connections & lowest data usage',
          'धीमे कनेक्शन और सबसे कम डेटा उपयोग के लिए',
        ),
      },
    ];

    _showModalSheet(
      header: Row(
        children: [
          const Icon(Iconsax.video_play, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Text(
            s.settingsDefaultQuality,
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
      subtitle: s.tr(
        'Pilih resolusi pemutaran video yang disukai.',
        'Choose preferred video playback resolution.',
        'पसंदीदा वीडियो प्लेबैक रेज़ोल्यूशन चुनें।',
      ),
      children: options.map((opt) {
        final val = opt['val']!;
        final isSelected = _defaultQuality == val;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.05),
              width: isSelected ? 1.2 : 0.6,
            ),
          ),
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: Text(opt['label']!,
                style: GoogleFonts.inter(
                  color: isSelected ? AppColors.primary : Colors.white,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                )),
            subtitle: Text(opt['desc']!,
                style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
            trailing: isSelected
                ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                : null,
            onTap: () async {
              Navigator.of(context, rootNavigator: true).pop();
              await SettingsService.setDefaultQuality(val);
              _loadSettings();
            },
          ),
        );
      }).toList(),
    );
  }

  void _showAppLanguageSheet(AppStrings s) {
    final currentLang = ref.read(appLanguageProvider);
    _showModalSheet(
      header: Row(
        children: [
          const Icon(Icons.language_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Text(
            s.settingsAppLanguage,
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
      subtitle: s.settingsAppLanguageDesc,
      children: AppLanguage.values.map((lang) {
        final isSelected = currentLang == lang;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.05),
              width: isSelected ? 1.2 : 0.6,
            ),
          ),
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            leading: ModernFlagBadge(
              countryCode: lang.flagCountryCode,
              width: 30,
              height: 20,
              borderRadius: 4.5,
            ),
            title: Text(
              lang.localizedDisplayName(currentLang),
              style: GoogleFonts.inter(
                color: isSelected ? AppColors.primary : Colors.white,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              lang.localizedLabel(currentLang),
              style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11.5),
            ),
            trailing: isSelected
                ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                : null,
            onTap: () async {
              Navigator.of(context, rootNavigator: true).pop();
              await ref.read(appLanguageProvider.notifier).setLanguage(lang);
            },
          ),
        );
      }).toList(),
    );
  }

  void _showSubtitleLangSheet(AppStrings s) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 560),
      backgroundColor: AppColors.surface,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _SubtitleLanguagePickerSheet(
          selectedCode: _defaultSubtitleLang,
          strings: s,
          onSelect: (code) async {
            await SettingsService.setDefaultSubtitleLang(code);
            _loadSettings();
          },
        );
      },
    );
  }

  void _showFontSizeSheet(AppStrings s) {
    final is1080pDesktopOrTv = is1080pOrHigherDesktopOrTv(context, isTv: gIsTv);
    final sizes = [
      {
        'val': 'Kecil',
        'label': s.tr('Kecil', 'Small', 'छोटा'),
        'desc': is1080pDesktopOrTv
            ? s.tr(
                'Ukuran teks 24pt (Skala 1080p+ ringkas)',
                '24pt font size (1080p+ compact scale)',
                '24pt फ़ॉन्ट आकार (1080p+ कॉम्पैक्ट स्केल)',
              )
            : s.tr(
                'Ukuran teks 16pt (Cocok untuk layar landscape luas)',
                '16pt font size (Best for wide landscape screens)',
                '16pt फ़ॉन्ट आकार (चौड़ी लैंडस्केप स्क्रीन के लिए उपयुक्त)',
              ),
      },
      {
        'val': 'Sedang',
        'label': s.tr('Sedang', 'Medium', 'मध्यम'),
        'desc': is1080pDesktopOrTv
            ? s.tr(
                'Ukuran teks 30pt (Standar ideal jarak sofa 1080p+)',
                '30pt font size (Ideal couch distance for 1080p+)',
                '30pt फ़ॉन्ट आकार (1080p+ टीवी दूरी के लिए आदर्श)',
              )
            : s.tr(
                'Ukuran teks 20pt (Standar nyaman untuk semua layar)',
                '20pt font size (Standard comfortable size for all screens)',
                '20pt फ़ॉन्ट आकार (सभी स्क्रीन के लिए आरामदायक मानक)',
              ),
      },
      {
        'val': 'Besar',
        'label': s.tr('Besar', 'Large', 'बड़ा'),
        'desc': is1080pDesktopOrTv
            ? s.tr(
                'Ukuran teks 36pt (Besar dan sangat jelas jarak jauh)',
                '36pt font size (Large and ultra clear from distance)',
                '36pt फ़ॉन्ट आकार (दूर से भी बड़ा और अत्यंत स्पष्ट)',
              )
            : s.tr(
                'Ukuran teks 24pt (Terlihat jelas dan mudah dibaca)',
                '24pt font size (Clear and easily readable)',
                '24pt फ़ॉन्ट आकार (स्पष्ट और आसानी से पढ़ने योग्य)',
              ),
      },
    ];

    _showModalSheet(
      header: Row(
        children: [
          const Icon(Iconsax.text, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Text(
            s.settingsSubFontSize,
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
      subtitle: s.tr(
        'Sesuaikan ukuran teks subtitle agar nyaman dibaca.',
        'Adjust subtitle text size for comfortable reading.',
        'आरामदायक पढ़ने के लिए सबटाइटल टेक्स्ट का आकार समायोजित करें।',
      ),
      children: sizes.map((item) {
        final isSelected = _subtitleFontSize == item['val'];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.05),
              width: isSelected ? 1.2 : 0.6,
            ),
          ),
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: Text(item['label']!,
                style: GoogleFonts.inter(
                  color: isSelected ? AppColors.primary : Colors.white,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                )),
            subtitle: Text(item['desc']!,
                style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
            trailing: isSelected
                ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                : null,
            onTap: () async {
              Navigator.of(context, rootNavigator: true).pop();
              await SettingsService.setSubtitleFontSize(item['val']!);
              ref.read(subtitleStyleProvider.notifier).reloadFromSettings();
              _loadSettings();
            },
          ),
        );
      }).toList(),
    );
  }

  void _showSubtitleBgSheet(AppStrings s) {
    final backgrounds = [
      {
        'val': 'Transparan',
        'label': s.tr('Transparan', 'Transparent', 'पारदर्शी'),
        'desc': s.tr(
          'Teks dengan bayangan halus tanpa kotak latar',
          'Text with soft shadow without background box',
          'बिना बैकग्राउंड बॉक्स के हल्की छाया वाला टेक्स्ट',
        ),
      },
      {
        'val': 'Semi-Transparan',
        'label': s.tr('Semi-Transparan', 'Semi-Transparent', 'अर्ध-पारदर्शी'),
        'desc': s.tr(
          'Latar hitam transparan 50% untuk kontras tinggi',
          '50% transparent black background for high contrast',
          'उच्च कंट्रास्ट के लिए 50% पारदर्शी काला बैकग्राउंड',
        ),
      },
      {
        'val': 'Hitam Pekat',
        'label': s.tr('Hitam Pekat', 'Solid Black', 'गहरा काला'),
        'desc': s.tr(
          'Latar hitam solid untuk keterbacaan maksimal',
          'Solid black background for maximum readability',
          'अधिकतम पठनीयता के लिए गहरा काला बैकग्राउंड',
        ),
      },
    ];

    _showModalSheet(
      header: Row(
        children: [
          const Icon(Icons.format_paint_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Text(
            s.settingsSubBg,
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
      subtitle: s.tr(
        'Sesuaikan kontras latar belakang subtitle terhadap gambar video.',
        'Adjust subtitle background contrast against video content.',
        'वीडियो सामग्री के अनुसार सबटाइटल बैकग्राउंड कंट्रास्ट समायोजित करें।',
      ),
      children: backgrounds.map((bg) {
        final isSelected = _subtitleBg == bg['val'];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.05),
              width: isSelected ? 1.2 : 0.6,
            ),
          ),
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: Text(bg['label']!,
                style: GoogleFonts.inter(
                  color: isSelected ? AppColors.primary : Colors.white,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                )),
            subtitle: Text(bg['desc']!,
                style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
            trailing: isSelected
                ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                : null,
            onTap: () async {
              Navigator.of(context, rootNavigator: true).pop();
              await SettingsService.setSubtitleBackground(bg['val']!);
              ref.read(subtitleStyleProvider.notifier).reloadFromSettings();
              _loadSettings();
            },
          ),
        );
      }).toList(),
    );
  }

  void _showLegalDocsSheet(AppStrings s) {
    final docs = [
      {
        'title': s.settingsPrivacyPolicyTitle,
        'desc': s.settingsPrivacyPolicySubtitle,
        'icon': Icons.privacy_tip_outlined,
        'route': '/settings/privacy-policy',
      },
      {
        'title': s.settingsTermsTitle,
        'desc': s.settingsTermsSubtitle,
        'icon': Icons.gavel_rounded,
        'route': '/settings/terms',
      },
      {
        'title': s.settingsDisclaimerMenuTitle,
        'desc': s.settingsDisclaimerSubtitle,
        'icon': Icons.warning_amber_rounded,
        'route': '/settings/disclaimer',
      },
    ];

    _showModalSheet(
      header: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            s.tr('Kebijakan & Lisensi Legal', 'Legal & Policies', 'कानूनी नीतियां और लाइसेंस'),
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
      subtitle: s.tr(
        'Dokumentasi kepatuhan hukum, privasi pengguna, dan batasan lisensi Cineva',
        'Legal compliance documentation, user privacy, and Cineva licenses',
        'कानूनी अनुपालन दस्तावेज़, उपयोगकर्ता गोपनीयता और Cineva लाइसेंस',
      ),
      children: docs.map((doc) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
              width: 0.6,
            ),
          ),
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(doc['icon'] as IconData, color: AppColors.primaryLight, size: 18),
            ),
            title: Text(
              doc['title'] as String,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              doc['desc'] as String,
              style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 13),
            onTap: () {
              Navigator.of(context, rootNavigator: true).pop();
              context.push(doc['route'] as String);
            },
          ),
        );
      }).toList(),
    );
  }

  void _clearCacheAction(AppStrings s) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          s.settingsClearCache,
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          s.tr(
            'Tindakan ini akan menghapus ${_cacheSizeMb.toStringAsFixed(1)} MB file poster sementara dan data buffering yang tersimpan di perangkat.',
            'This will remove ${_cacheSizeMb.toStringAsFixed(1)} MB of cached posters and temporary buffering data on this device.',
            'यह इस डिवाइस पर संग्रहीत ${_cacheSizeMb.toStringAsFixed(1)} MB कैश्ड पोस्टर और अस्थायी बफरिंग डेटा को हटा देगा।',
          ),
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.dialogCancel, style: GoogleFonts.inter(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              PaintingBinding.instance.imageCache.clear();
              PaintingBinding.instance.imageCache.clearLiveImages();
              setState(() => _cacheSizeMb = 0.0);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.surfaceElevated,
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        '${s.dialogCacheCleaned} (0.0 MB)',
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(s.dialogClear),
          ),
        ],
      ),
    );
  }

  void _clearHistoryAction(AppStrings s) {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          s.settingsClearHistory,
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          s.settingsClearHistoryDesc,
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.dialogCancel, style: GoogleFonts.inter(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await SettingsService.clearWatchHistory();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.surfaceElevated,
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          s.dialogHistoryCleared,
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(s.dialogDelete),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExportBackup(AppStrings s) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Text(s.backupCreating,
                style: GoogleFonts.inter(color: Colors.white)),
          ],
        ),
      ),
    );

    final result = await BackupRestoreService.exportBackupToFile(ref);
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${s.backupExportSuccess} (${result.watchlistCount} watchlist, ${result.historyCount} riwayat)',
                  style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (result.errorMessage != null &&
        !result.errorMessage!.contains('dibatalkan')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          content: Text(result.errorMessage ?? s.backupExportFailed,
              style: GoogleFonts.inter(color: Colors.white)),
        ),
      );
    }
  }

  Future<void> _handleRestoreBackup(AppStrings s) async {
    final result = await BackupRestoreService.pickAndRestoreBackupFile(ref);
    if (!mounted) return;

    if (result.success) {
      _loadSettings();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.backupImportSuccessSummary(
                      result.watchlistCount, result.historyCount),
                  style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      );
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
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final currentAppLang = ref.watch(appLanguageProvider);
    final currentSubLang = SubtitleLanguageCatalog.findByCode(_defaultSubtitleLang);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                0,
                16,
                0,
                MediaQuery.of(context).padding.bottom + 76,
              ),
              children: [
                // Page Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 3.5,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        s.settingsTitle,
                        style: GoogleFonts.outfit(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── SECTION: ACCOUNT (Profile, View Stats, QR Scan) ──
                _buildSectionHeader(s.settingsAccountSection, Iconsax.user),
                Consumer(
                  builder: (context, ref, _) {
                    final profile = ref.watch(userProfileProvider);
                    final insights = ref.watch(watchInsightsProvider);
                    final isTv = ref.watch(isTvProvider);
                    final isDesktop = ref.watch(isDesktopProvider);
                    final showQrScan = !isTv && !isDesktop;
                    final durationCompact = insights.formattedDurationCompact(
                      currentAppLang,
                    );

                    return _buildSettingsCard([
                      // 1. Profile (Edit Profile)
                      TvFocusable(
                        onTap: () => context.push('/edit-profile'),
                        borderRadius: BorderRadius.circular(12),
                        scaleOnFocus: 1.0,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              AvatarDisplay(
                                avatarId: profile.avatarId,
                                customAvatarPath: profile.customAvatarPath,
                                size: 46,
                                showGlow: false,
                                borderWidth: 1.5,
                                borderColor: AppColors.primary,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      profile.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '@${profile.username} • ${s.settingsAccountProfileDesc}',
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
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: AppColors.textMuted,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                      _buildCardDivider(),
                      // 2. View Stats
                      _SettingsTileItem(
                        icon: Iconsax.chart_21,
                        title: s.settingsAccountViewStatsTitle,
                        subtitle: s.settingsAccountViewStatsDesc,
                        trailingText: durationCompact,
                        onTap: () => context.push('/profile/insights'),
                      ),
                      // 3. QR Scan (Mobile & Tablet only)
                      if (showQrScan) ...[
                        _buildCardDivider(),
                        _SettingsTileItem(
                          icon: Icons.qr_code_scanner_rounded,
                          title: s.settingsAccountQrScanTitle,
                          subtitle: s.settingsAccountQrScanDesc,
                          onTap: () => context.push('/tv-pairing-scanner'),
                        ),
                      ],
                    ]);
                  },
                ),

                const SizedBox(height: 20),

                // ── SECTION 0: PREFERENSI UMUM (Bahasa Aplikasi & Konten) ──
            _buildSectionHeader(s.settingsGeneralSection, Iconsax.setting_2),
            _buildSettingsCard([
              _SettingsTileItem(
                icon: Icons.language_rounded,
                title: s.settingsAppLanguage,
                subtitle: s.settingsAppLanguageDesc,
                trailingWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ModernFlagBadge(
                      countryCode: currentAppLang.flagCountryCode,
                      width: 26,
                      height: 18,
                      borderRadius: 4,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currentAppLang.localizedLabel(currentAppLang),
                      style: GoogleFonts.inter(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 13),
                  ],
                ),
                onTap: () => _showAppLanguageSheet(s),
              ),
              _buildCardDivider(),
              _SettingsTileItem(
                icon: Iconsax.discover,
                title: s.settingsContentPref,
                subtitle: '${s.settingsContentPrefDesc} (${ContentPreference.fromCode(_contentPreference).getLocalizedLabel(s.isIndonesian, s.language)})',
                trailingWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ContentPreference.fromCode(_contentPreference).getLocalizedLabel(s.isIndonesian, s.language).split(' ').first,
                        style: GoogleFonts.inter(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 13),
                  ],
                ),
                onTap: () => _showContentPreferenceSheet(s),
              ),
            ]),

            const SizedBox(height: 20),

            // ── SECTION 1: PEMUTARAN & KUALITAS VIDEO ──
            _buildSectionHeader(s.settingsVideoSection, Iconsax.video_circle),
            _buildSettingsCard([
              _SettingsTileItem(
                icon: Iconsax.video_play,
                title: s.settingsDefaultQuality,
                subtitle: _defaultQuality == 'Auto' ? 'Auto (Adaptif FHD)' : '$_defaultQuality Full HD',
                trailingText: _defaultQuality,
                onTap: () => _showQualitySheet(s),
              ),
              _buildCardDivider(),
              _SettingsToggleItem(
                icon: Icons.speed_rounded,
                title: s.settingsHwAccel,
                subtitle: s.settingsHwAccelDesc,
                value: _hwAcceleration,
                onChanged: (v) async {
                  await SettingsService.setHardwareAcceleration(v);
                  _loadSettings();
                },
              ),
              _buildCardDivider(),
              _SettingsToggleItem(
                icon: Icons.skip_next_rounded,
                title: s.settingsAutoPlayNextEpisode,
                subtitle: s.settingsAutoPlayNextEpisodeDesc,
                value: _autoPlayNextEpisode,
                onChanged: (v) async {
                  await SettingsService.setAutoPlayNextEpisode(v);
                  _loadSettings();
                },
              ),
            ]),

            const SizedBox(height: 20),

            // ── SECTION 2: SUBTITLE & BAHASA ──
            _buildSectionHeader(s.settingsSubSection, Iconsax.subtitle),
            _buildSettingsCard([
              _SettingsTileItem(
                icon: Iconsax.translate,
                title: s.settingsSubLanguage,
                subtitle: currentSubLang.displayName,
                trailingWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!currentSubLang.isOff) ...[
                      ModernFlagBadge(
                        countryCode: currentSubLang.countryCode,
                        width: 26,
                        height: 18,
                        borderRadius: 4,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      currentSubLang.code.toUpperCase(),
                      style: GoogleFonts.inter(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 13),
                  ],
                ),
                onTap: () => _showSubtitleLangSheet(s),
              ),
              _buildCardDivider(),
              _SettingsToggleItem(
                icon: Icons.auto_awesome_rounded,
                title: s.settingsAutoTranslateTo(currentSubLang.name),
                subtitle: s.settingsAutoTranslateDesc,
                value: _autoTranslate,
                onChanged: (v) async {
                  await SettingsService.setAutoTranslate(v);
                  _loadSettings();
                },
              ),
              _buildCardDivider(),
              _SettingsTileItem(
                icon: Iconsax.text,
                title: s.settingsSubFontSize,
                subtitle: _localizedFontSize(_subtitleFontSize, s),
                trailingText: _localizedFontSize(_subtitleFontSize, s),
                onTap: () => _showFontSizeSheet(s),
              ),
              _buildCardDivider(),
              _SettingsTileItem(
                icon: Icons.format_paint_rounded,
                title: s.settingsSubBg,
                subtitle: _localizedSubtitleBg(_subtitleBg, s),
                trailingText: _localizedSubtitleBg(_subtitleBg, s),
                onTap: () => _showSubtitleBgSheet(s),
              ),
            ]),

            const SizedBox(height: 20),

            // ── SECTION 3: PENYIMPANAN & PEMELIHARAAN ──
            _buildSectionHeader(s.settingsStorageSection, Iconsax.folder),
            _buildSettingsCard([
              _SettingsTileItem(
                icon: Iconsax.trash,
                title: s.settingsClearCache,
                subtitle: s.settingsClearCacheDesc,
                trailingWidget: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_cacheSizeMb.toStringAsFixed(1)} MB',
                    style: GoogleFonts.inter(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                onTap: () => _clearCacheAction(s),
              ),
              _buildCardDivider(),
              _SettingsTileItem(
                icon: Iconsax.clock,
                title: s.settingsClearHistory,
                subtitle: s.settingsClearHistoryDesc,
                onTap: () => _clearHistoryAction(s),
              ),
            ]),

            const SizedBox(height: 20),

            // ── SECTION 3.5: CADANGAN & PEMULIHAN ──
            _buildSectionHeader(s.backupSectionTitle, Iconsax.cloud_connection),
            _buildSettingsCard([
              // 1. Cadangkan Data (Backup to File)
              _SettingsTileItem(
                icon: Iconsax.export_3,
                title: s.backupExportTitle,
                subtitle: s.backupExportDesc,
                trailingWidget: const Icon(Icons.file_download_outlined,
                    color: AppColors.primary, size: 18),
                onTap: () => _handleExportBackup(s),
              ),
              _buildCardDivider(),
              // 2. Pulihkan Data (Restore from File)
              _SettingsTileItem(
                icon: Iconsax.import_1,
                title: s.backupImportTitle,
                subtitle: s.backupImportDesc,
                trailingWidget: const Icon(Icons.file_upload_outlined,
                    color: AppColors.primary, size: 18),
                onTap: () => _handleRestoreBackup(s),
              ),
            ]),

            const SizedBox(height: 20),

            // ── SECTION 4: TENTANG & LISENSI ──
            _buildSectionHeader(s.settingsAboutSection, Iconsax.info_circle),
            _buildSettingsCard([
              _SettingsTileItem(
                icon: Iconsax.message_favorite,
                title: s.feedbackMenuTitle,
                subtitle: s.feedbackMenuSubtitle,
                trailingWidget: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
                onTap: () => context.push('/feedback'),
              ),
              _buildCardDivider(),
              _SettingsTileItem(
                icon: Icons.info_outline_rounded,
                title: s.settingsInfoTitle,
                subtitle: '$_appVersion ($_buildNumber) • ${s.settingsInfoSubtitle}',
                trailingWidget: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
                onTap: () => context.push('/settings/info'),
              ),
              _buildCardDivider(),
              _SettingsTileItem(
                icon: Icons.shield_outlined,
                title: s.tr('Kebijakan & Lisensi Legal', 'Legal & Compliance', 'कानूनी नीतियां और लाइसेंस'),
                subtitle: s.tr(
                  'Kebijakan Privasi, Syarat Ketentuan, & Penafian',
                  'Privacy Policy, Terms of Service, & Disclaimer',
                  'गोपनीयता नीति, सेवा की शर्तें और अस्वीकरण',
                ),
                trailingWidget: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
                onTap: () => _showLegalDocsSheet(s),
              ),
            ]),

            const SizedBox(height: 4),
          ],
        ),
      ),
    ),
  ),
);
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    final isWide = MediaQuery.sizeOf(context).width >= 700;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: isWide ? 20 : 0),
      decoration: BoxDecoration(
        color: isWide
            ? AppColors.surface.withValues(alpha: 0.65)
            : AppColors.background,
        borderRadius: isWide ? BorderRadius.circular(16) : null,
        border: isWide
            ? Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              )
            : Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 0.8,
                ),
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 0.8,
                ),
              ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildCardDivider() {
    return Divider(
      color: Colors.white.withValues(alpha: 0.07),
      height: 1,
      thickness: 0.8,
      indent: 72,
      endIndent: 20,
    );
  }
}

class _SettingsTileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailingText;
  final Widget? trailingWidget;
  final VoidCallback onTap;

  const _SettingsTileItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailingText,
    this.trailingWidget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      scaleOnFocus: 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 19, color: AppColors.primaryLight),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (trailingWidget != null)
              trailingWidget!
            else if (trailingText != null) ...[
              Text(
                trailingText!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AppColors.textMuted,
              ),
            ] else
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AppColors.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingsToggleItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggleItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      scaleOnFocus: 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 19, color: AppColors.primaryLight),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: AppColors.primary,
              activeThumbColor: Colors.black,
              inactiveTrackColor: AppColors.surfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Minimalist, high-performance modal sheet for selecting a subtitle language with instant search.
class _SubtitleLanguagePickerSheet extends StatefulWidget {
  final String selectedCode;
  final AppStrings strings;
  final ValueChanged<String> onSelect;

  const _SubtitleLanguagePickerSheet({
    required this.selectedCode,
    required this.strings,
    required this.onSelect,
  });

  @override
  State<_SubtitleLanguagePickerSheet> createState() => _SubtitleLanguagePickerSheetState();
}

class _SubtitleLanguagePickerSheetState extends State<_SubtitleLanguagePickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<SubtitleLanguage> _filteredLanguages = SubtitleLanguageCatalog.languages;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _filteredLanguages = SubtitleLanguageCatalog.search(_searchCtrl.text);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle pill
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  const Icon(Iconsax.translate, color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.strings.settingsSubLanguage,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Modern Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 0.8,
                  ),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    hintText: widget.strings.settingsSearchLanguage,
                    hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Iconsax.search_normal, color: AppColors.primary, size: 18),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 16),
                            onPressed: () => _searchCtrl.clear(),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Minimalist Language List (Flags + Name only, no heavy description)
            Flexible(
              child: _filteredLanguages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          widget.strings.settingsNoLanguageFound,
                          style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(20, 6, 20, bottomPadding + bottomInset + 16),
                      itemCount: _filteredLanguages.length,
                      itemBuilder: (ctx, index) {
                        final lang = _filteredLanguages[index];
                        final isSelected = widget.selectedCode.toLowerCase() == lang.code.toLowerCase();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.05),
                              width: isSelected ? 1.2 : 0.6,
                            ),
                          ),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            leading: lang.isOff
                                ? Container(
                                    width: 28,
                                    height: 19,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.subtitles_off_rounded, color: AppColors.textMuted, size: 14),
                                  )
                                : ModernFlagBadge(
                                    countryCode: lang.countryCode,
                                    width: 28,
                                    height: 19,
                                    borderRadius: 4,
                                  ),
                            title: Text(
                              lang.displayName,
                              style: GoogleFonts.inter(
                                color: isSelected ? AppColors.primary : Colors.white,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                                : null,
                            onTap: () {
                              Navigator.of(context).pop();
                              widget.onSelect(lang.code);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
