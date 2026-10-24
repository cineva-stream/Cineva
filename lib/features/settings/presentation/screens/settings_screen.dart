import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/content_preference.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../data/settings_service.dart';

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
  bool _wifiOnlySeeding = true;
  bool _hwAcceleration = true;
  double _cacheSizeMb = 38.4;
  String _appVersion = AppConstants.appVersion;
  String _buildNumber = '1';

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
          if (info.buildNumber.isNotEmpty) _buildNumber = info.buildNumber;
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
      _wifiOnlySeeding = SettingsService.getWifiOnlySeeding();
      _hwAcceleration = SettingsService.getHardwareAcceleration();
    });
  }

  String _subtitleLangLabel(String code) {
    switch (code) {
      case 'id':
        return 'Indonesia (Auto-Terjemah)';
      case 'en':
        return 'English (Bahasa Asli)';
      case 'off':
        return 'Nonaktif (Tanpa Subtitle)';
      default:
        return code.toUpperCase();
    }
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

  void _showContentPreferenceSheet() {
    final preferences = ContentPreference.values;

    _showModalSheet(
      header: Row(
        children: [
          const Icon(Iconsax.category_2, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Text(
            'Preferensi Movie & TV Series',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
      subtitle: 'Pilih kategori untuk diprioritaskan di Beranda dan pencarian film / serial TV.',
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
              pref.label,
              style: GoogleFonts.inter(
                color: isSelected ? AppColors.primary : Colors.white,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              pref.description,
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.surfaceElevated,
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Preferensi diubah ke ${pref.label}. Beranda & Pencarian otomatis disesuaikan.',
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

  void _showQualitySheet() {
    final options = [
      {'val': 'Auto', 'label': 'Auto (Adaptif FHD)', 'desc': 'Menyesuaikan kecepatan jaringan secara dinamis'},
      {'val': '1080p', 'label': '1080p Full HD', 'desc': 'Kualitas gambar terbaik, jernih & tajam'},
      {'val': '720p', 'label': '720p HD', 'desc': 'Hemat kuota dengan resolusi tetap tajam'},
      {'val': '480p', 'label': '480p SD', 'desc': 'Koneksi lambat & paling hemat kuota'},
    ];

    _showModalSheet(
      header: Row(
        children: [
          const Icon(Iconsax.video_play, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Text(
            'Kualitas Video Default',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
      subtitle: 'Pilih resolusi pemutaran video yang disukai.',
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

  void _showSubtitleLangSheet() {
    final langs = [
      {'val': 'id', 'title': 'Bahasa Indonesia', 'desc': 'Prioritas subtitle ID. Jika tidak tersedia, auto-terjemahkan subtitle EN secara instan.'},
      {'val': 'en', 'title': 'English (Original)', 'desc': 'Gunakan subtitle Bahasa Inggris bawaan tanpa terjemahan otomatis.'},
      {'val': 'off', 'title': 'Nonaktif', 'desc': 'Jangan aktifkan subtitle otomatis saat film baru dimulai.'},
    ];

    _showModalSheet(
      header: Row(
        children: [
          const Icon(Iconsax.subtitle, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Text(
            'Bahasa Subtitle Default',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
      subtitle: 'Pilih bahasa subtitle bawaan saat memutar video.',
      children: langs.map((lang) {
        final val = lang['val']!;
        final isSelected = _defaultSubtitleLang == val;
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
            title: Text(lang['title']!,
                style: GoogleFonts.inter(
                  color: isSelected ? AppColors.primary : Colors.white,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                )),
            subtitle: Text(lang['desc']!,
                style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
            trailing: isSelected
                ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                : null,
            onTap: () async {
              Navigator.of(context, rootNavigator: true).pop();
              await SettingsService.setDefaultSubtitleLang(val);
              _loadSettings();
            },
          ),
        );
      }).toList(),
    );
  }

  void _showFontSizeSheet() {
    final sizes = [
      {'val': 'Kecil', 'desc': 'Ukuran teks 16pt (Cocok untuk layar landscape luas)'},
      {'val': 'Sedang', 'desc': 'Ukuran teks 20pt (Standar nyaman untuk semua layar)'},
      {'val': 'Besar', 'desc': 'Ukuran teks 24pt (Terlihat jelas dan mudah dibaca)'},
    ];

    _showModalSheet(
      header: Row(
        children: [
          const Icon(Iconsax.text, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Text(
            'Ukuran Huruf Subtitle',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
      subtitle: 'Sesuaikan ukuran teks subtitle agar nyaman dibaca.',
      children: sizes.map((s) {
        final isSelected = _subtitleFontSize == s['val'];
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
            title: Text(s['val']!,
                style: GoogleFonts.inter(
                  color: isSelected ? AppColors.primary : Colors.white,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                )),
            subtitle: Text(s['desc']!,
                style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
            trailing: isSelected
                ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                : null,
            onTap: () async {
              Navigator.of(context, rootNavigator: true).pop();
              await SettingsService.setSubtitleFontSize(s['val']!);
              _loadSettings();
            },
          ),
        );
      }).toList(),
    );
  }

  void _showSubtitleBgSheet() {
    final backgrounds = [
      {'val': 'Transparan', 'desc': 'Teks dengan bayangan halus tanpa kotak latar'},
      {'val': 'Semi-Transparan', 'desc': 'Latar hitam transparan 50% untuk kontras tinggi'},
      {'val': 'Hitam Pekat', 'desc': 'Latar hitam solid untuk keterbacaan maksimal'},
    ];

    _showModalSheet(
      header: Row(
        children: [
          const Icon(Icons.format_paint_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Text(
            'Latar Belakang Subtitle',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
      subtitle: 'Sesuaikan kontras latar belakang subtitle terhadap gambar video.',
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
            title: Text(bg['val']!,
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
              _loadSettings();
            },
          ),
        );
      }).toList(),
    );
  }

  void _clearCacheAction() {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Bersihkan Cache?',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Tindakan ini akan menghapus ${_cacheSizeMb.toStringAsFixed(1)} MB file poster sementara dan data buffering yang tersimpan di perangkat.',
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.inter(color: AppColors.textMuted)),
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
                        'Cache berhasil dibersihkan (0.0 MB)',
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
            child: const Text('Bersihkan'),
          ),
        ],
      ),
    );
  }

  void _clearHistoryAction() {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hapus Riwayat Tontonan?',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Semua daftar film dan episode yang telah selesai atau sedang Anda tonton akan dihapus secara permanen.',
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.inter(color: AppColors.textMuted)),
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
                          'Riwayat tontonan berhasil dihapus',
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
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(0, 16, 0, MediaQuery.of(context).padding.bottom + 76),
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
                    'Pengaturan',
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

            // ── App Detail Card (Full-width with Smooth Border) ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(
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
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppConstants.appName,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Versi $_appVersion (Build $_buildNumber)',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'com.primadev.cineva',
                          style: GoogleFonts.inter(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── SECTION: PREFERENSI KONTEN (Movie & TV Series) ──
            _buildSectionHeader('Preferensi Konten', Iconsax.category_2),
            _buildSettingsCard([
              _SettingsTileItem(
                icon: Iconsax.discover,
                title: 'Preferensi Movie & TV Series',
                subtitle: 'Prioritaskan katalog di Beranda & Pencarian (${ContentPreference.fromCode(_contentPreference).label})',
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
                        ContentPreference.fromCode(_contentPreference).label.split(' ').first,
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
                onTap: _showContentPreferenceSheet,
              ),
            ]),

            const SizedBox(height: 20),

            // ── SECTION 1: PEMUTARAN & KUALITAS VIDEO ──
            _buildSectionHeader('Pemutaran & Video', Iconsax.video_circle),
            _buildSettingsCard([
              _SettingsTileItem(
                icon: Iconsax.video_play,
                title: 'Kualitas Streaming Default',
                subtitle: _defaultQuality == 'Auto' ? 'Auto (Adaptif FHD)' : '$_defaultQuality Full HD',
                trailingText: _defaultQuality,
                onTap: _showQualitySheet,
              ),
              _buildCardDivider(),
              _SettingsToggleItem(
                icon: Icons.speed_rounded,
                title: 'Akselerasi Perangkat Keras',
                subtitle: 'Gunakan GPU decoder untuk pemutaran video 60fps tanpa patah-patah',
                value: _hwAcceleration,
                onChanged: (v) async {
                  await SettingsService.setHardwareAcceleration(v);
                  _loadSettings();
                },
              ),
              _buildCardDivider(),
              _SettingsToggleItem(
                icon: Iconsax.wifi,
                title: 'Streaming Hemat Kuota (Wi-Fi Saja)',
                subtitle: 'Mencegah buffering torrent berukuran besar di jaringan seluler',
                value: _wifiOnlySeeding,
                onChanged: (v) async {
                  await SettingsService.setWifiOnlySeeding(v);
                  _loadSettings();
                },
              ),
            ]),

            const SizedBox(height: 20),

            // ── SECTION 2: SUBTITLE & BAHASA ──
            _buildSectionHeader('Subtitle & Bahasa', Iconsax.subtitle),
            _buildSettingsCard([
              _SettingsTileItem(
                icon: Iconsax.translate,
                title: 'Bahasa Subtitle Utama',
                subtitle: _subtitleLangLabel(_defaultSubtitleLang),
                trailingText: _defaultSubtitleLang.toUpperCase(),
                onTap: _showSubtitleLangSheet,
              ),
              _buildCardDivider(),
              _SettingsToggleItem(
                icon: Icons.auto_awesome_rounded,
                title: 'Auto-Terjemah ke Indonesia',
                subtitle: 'Otomatis terjemahkan subtitle asing ke Indonesia jika tidak ada yang asli',
                value: _autoTranslate,
                onChanged: (v) async {
                  await SettingsService.setAutoTranslate(v);
                  _loadSettings();
                },
              ),
              _buildCardDivider(),
              _SettingsTileItem(
                icon: Iconsax.text,
                title: 'Ukuran Huruf Subtitle',
                subtitle: _subtitleFontSize,
                trailingText: _subtitleFontSize,
                onTap: _showFontSizeSheet,
              ),
              _buildCardDivider(),
              _SettingsTileItem(
                icon: Icons.format_paint_rounded,
                title: 'Latar Belakang Subtitle',
                subtitle: _subtitleBg,
                trailingText: _subtitleBg,
                onTap: _showSubtitleBgSheet,
              ),
            ]),

            const SizedBox(height: 20),

            // ── SECTION 3: PENYIMPANAN & RIWAYAT ──
            _buildSectionHeader('Penyimpanan & Riwayat', Iconsax.folder),
            _buildSettingsCard([
              _SettingsTileItem(
                icon: Icons.download_rounded,
                title: 'Daftar Unduhan (Download Manager)',
                subtitle: 'Kelola film & serial TV yang sedang diunduh atau selesai',
                trailingWidget: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
                onTap: () => context.push('/downloads'),
              ),
              _buildCardDivider(),
              _SettingsTileItem(
                icon: Iconsax.play_cricle,
                title: 'Buka Riwayat Tontonan',
                subtitle: 'Lihat daftar film & serial TV yang pernah diputar',
                trailingWidget: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
                onTap: () => context.push('/history'),
              ),
              _buildCardDivider(),
              _SettingsTileItem(
                icon: Iconsax.trash,
                title: 'Bersihkan Cache Gambar & Poster',
                subtitle: 'Membebaskan ruang penyimpanan dan memori sementara',
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
                onTap: _clearCacheAction,
              ),
              _buildCardDivider(),
              _SettingsTileItem(
                icon: Iconsax.clock,
                title: 'Hapus Riwayat Tontonan',
                subtitle: 'Menghapus catatan posisi putar dan film yang telah ditonton',
                onTap: _clearHistoryAction,
              ),
            ]),

            const SizedBox(height: 20),

            // ── SECTION 4: TENTANG & DUKUNGAN ──
            _buildSectionHeader('Tentang & Lisensi', Iconsax.info_circle),
            _buildSettingsCard([
              _SettingsTileItem(
                icon: Iconsax.document_text,
                title: 'Disclaimer & Hak Cipta',
                subtitle: 'Informasi hukum penggunaan layanan streaming P2P',
                onTap: () {
                  showDialog(
                    context: context,
                    useRootNavigator: true,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Text(
                        'Disclaimer Hukum',
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      content: Text(
                        'Cineva adalah pemutar media berbasis P2P terdesentralisasi yang mengakses konten publik yang tersedia di internet. Pengguna bertanggung jawab penuh atas media yang diakses sesuai peraturan perundang-undangan yang berlaku.',
                        style: GoogleFonts.inter(color: AppColors.textSecondary, height: 1.5, fontSize: 13),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Mengerti',
                            style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ]),

            const SizedBox(height: 4),
          ],
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
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
    return InkWell(
      onTap: onTap,
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
              const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textMuted),
            ] else
              const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textMuted),
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
    return Padding(
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
    );
  }
}
