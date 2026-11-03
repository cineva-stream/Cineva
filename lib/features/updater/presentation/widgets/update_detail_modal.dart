import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../domain/entities/app_update_info.dart';
import '../providers/app_update_provider.dart';
import 'install_permission_dialog.dart';

/// Modal dialog showing complete GitHub release body/changelog
/// with automatic language detection, translation support,
/// and direct update triggers.
class UpdateDetailModal extends ConsumerStatefulWidget {
  final AppUpdateInfo info;

  const UpdateDetailModal({super.key, required this.info});

  static Future<void> show(BuildContext context, {required AppUpdateInfo info}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (context) => UpdateDetailModal(info: info),
    );
  }

  @override
  ConsumerState<UpdateDetailModal> createState() => _UpdateDetailModalState();
}

class _UpdateDetailModalState extends ConsumerState<UpdateDetailModal> {
  bool _showTranslated = true;
  bool _isTranslating = false;
  String? _translatedText;
  late final String _originalText;
  late final String _targetLang;
  bool _needsTranslation = false;

  @override
  void initState() {
    super.initState();
    _originalText = widget.info.changelog.trim();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLanguageAdaptation();
    });
  }

  void _initLanguageAdaptation() {
    final s = ref.read(appStringsProvider);
    _targetLang = s.isIndonesian ? 'id' : 'en';

    // 1. Check if markdown already contains bilingual sections
    final sectionText = _extractLanguageSection(_originalText, s.isIndonesian);
    if (sectionText != null && sectionText.isNotEmpty) {
      if (mounted) {
        setState(() {
          _translatedText = sectionText;
          _showTranslated = true;
          _needsTranslation = false;
        });
      }
      return;
    }

    // 2. Check if original text already matches the app language
    final isIndo = _isIndonesianText(_originalText);
    final textLangMatches = (s.isIndonesian && isIndo) || (!s.isIndonesian && !isIndo);

    if (textLangMatches) {
      _needsTranslation = false;
      _showTranslated = false;
      return;
    }

    // 3. Needs translation to match app language
    _needsTranslation = true;
    _translateChangelog();
  }

  Future<void> _translateChangelog() async {
    if (_originalText.isEmpty) return;
    if (mounted) setState(() => _isTranslating = true);

    try {
      final translated = await _performTranslation(_originalText, _targetLang);
      if (mounted) {
        setState(() {
          _translatedText = translated;
          _isTranslating = false;
          _showTranslated = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isTranslating = false;
          _showTranslated = false;
        });
      }
    }
  }

  static Future<String> _performTranslation(String text, String targetLang) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'},
      ),
    );

    // 1. Try Google Translate endpoint first
    try {
      final res = await dio.get(
        'https://translate.googleapis.com/translate_a/single',
        queryParameters: {
          'client': 'gtx',
          'sl': 'auto',
          'tl': targetLang,
          'dt': 't',
          'q': text,
        },
      );
      if (res.statusCode == 200 && res.data is List && (res.data as List).isNotEmpty) {
        final list = res.data[0];
        if (list is List) {
          final buffer = StringBuffer();
          for (final item in list) {
            if (item is List && item.isNotEmpty && item[0] != null) {
              buffer.write(item[0].toString());
            }
          }
          if (buffer.isNotEmpty) return buffer.toString();
        }
      }
    } catch (_) {}

    // 2. Fallback to MyMemory open translation API
    try {
      final pair = targetLang == 'id' ? 'en|id' : 'id|en';
      final res = await dio.get(
        'https://api.mymemory.translated.net/get',
        queryParameters: {
          'q': text,
          'langpair': pair,
        },
      );
      if (res.statusCode == 200 && res.data is Map) {
        final data = res.data as Map<String, dynamic>;
        final translatedText = data['responseData']?['translatedText']?.toString();
        if (translatedText != null && translatedText.isNotEmpty) {
          return translatedText;
        }
      }
    } catch (_) {}

    return text;
  }

  static String? _extractLanguageSection(String markdown, bool isIndonesian) {
    if (markdown.isEmpty) return null;
    final idRegex = RegExp(
      r'(?:^|\n)#{1,4}\s*(?:🇮🇩|Bahasa Indonesia|Indonesian|ID|Catatan Rilis)[^\n]*\n([\s\S]*?)(?=\n#{1,4}\s*(?:🇬🇧|🇺🇸|English|EN|Changelog|What|Release)|$)',
      caseSensitive: false,
    );
    final enRegex = RegExp(
      r'(?:^|\n)#{1,4}\s*(?:🇬🇧|🇺🇸|English|EN|Changelog|What(?:\x27s|’s)?\s*New|Release Notes)[^\n]*\n([\s\S]*?)(?=\n#{1,4}\s*(?:🇮🇩|Bahasa Indonesia|Indonesian|ID)|$)',
      caseSensitive: false,
    );

    if (isIndonesian) {
      final match = idRegex.firstMatch(markdown);
      if (match != null && match.group(1)?.trim().isNotEmpty == true) {
        return match.group(1)!.trim();
      }
    } else {
      final match = enRegex.firstMatch(markdown);
      if (match != null && match.group(1)?.trim().isNotEmpty == true) {
        return match.group(1)!.trim();
      }
    }
    return null;
  }

  static bool _isIndonesianText(String text) {
    final lower = text.toLowerCase();
    const idKeywords = [
      'perbaikan',
      'pembaruan',
      'penambahan',
      'dukungan',
      'fitur',
      'dengan',
      'untuk',
      'pada',
      'telah',
      'yang',
      'dan',
      'tidak',
      'aplikasi',
      'unduh'
    ];
    const enKeywords = [
      'fix',
      'fixed',
      'feature',
      'features',
      'added',
      'support',
      'improved',
      'update',
      'with',
      'for',
      'and',
      'the',
      'release',
      'download'
    ];
    int idScore = 0;
    int enScore = 0;
    for (final k in idKeywords) {
      if (lower.contains(k)) idScore++;
    }
    for (final k in enKeywords) {
      if (lower.contains(k)) enScore++;
    }
    return idScore >= enScore;
  }

  static String _monthName(int month, bool isIndonesian) {
    const idMonths = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    const enMonths = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    if (month < 1 || month > 12) return '';
    return isIndonesian ? idMonths[month - 1] : enMonths[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final updateState = ref.watch(appUpdateProvider);
    final notifier = ref.read(appUpdateProvider.notifier);

    final info = widget.info;
    final isDownloading = updateState.status == AppUpdateStatus.downloading;
    final isReadyToInstall = updateState.status == AppUpdateStatus.readyToInstall ||
        updateState.status == AppUpdateStatus.installing;

    final displayText = (_showTranslated && _translatedText != null && _translatedText!.isNotEmpty)
        ? _translatedText!
        : (_originalText.isNotEmpty ? _originalText : s.updateNoChangelog);

    final size = MediaQuery.of(context).size;
    String? formattedDate;
    if (info.publishedAt != null) {
      final p = info.publishedAt!;
      formattedDate = '${p.day} ${_monthName(p.month, s.isIndonesian)} ${p.year}';
    }

    return Center(
      child: Container(
        width: size.width > 600 ? 540 : size.width * 0.92,
        constraints: BoxConstraints(
          maxHeight: size.height * 0.82,
        ),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.35),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.85),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header: Title, Version, Date & Close ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.system_update_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  s.updateChangelogTitle,
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.5),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  'v${info.latestVersion}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            formattedDate != null
                                ? '${info.releaseTitle} • $formattedDate'
                                : info.releaseTitle,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      tooltip: s.updateCloseModal,
                    ),
                  ],
                ),
              ),

              // ── Translation Control Pill Bar (if applicable) ──
              if (_needsTranslation || _translatedText != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.translate_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            _isTranslating
                                ? s.updateTranslatingChangelog
                                : (_showTranslated
                                    ? s.updateTranslatedText
                                    : s.updateOriginalText),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (!_isTranslating && _translatedText != null)
                        InkWell(
                          onTap: () => setState(() => _showTranslated = !_showTranslated),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white12, width: 0.8),
                            ),
                            child: Text(
                              _showTranslated ? s.updateOriginalText : s.updateTranslatedText,
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              const Divider(color: Colors.white12, height: 1),

              // ── Changelog Scrollable Body ──
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: _isTranslating
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  s.updateTranslatingChangelog,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _buildFormattedChangelog(displayText),
                ),
              ),

              const Divider(color: Colors.white12, height: 1),

              // ── Bottom Action Bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Target ABI & Size Badge
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          info.formattedSize,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (info.isArchitectureSpecific) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                                width: 0.6,
                              ),
                            ),
                            child: Text(
                              info.targetAbi,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Dynamic CTA Button
                    if (isDownloading)
                      Text(
                        '${(updateState.progress * 100).toInt()}% ${s.updateDownloading}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else if (isReadyToInstall)
                      ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          final allowed = await notifier.canRequestPackageInstalls();
                          if (!allowed && context.mounted) {
                            final granted = await InstallPermissionDialog.show(context);
                            if (granted == true) {
                              await notifier.triggerInstall();
                            }
                          } else {
                            await notifier.triggerInstall();
                          }
                        },
                        icon: const Icon(Icons.install_mobile_rounded, size: 16),
                        label: Text(s.updateInstallAction),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                          textStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          notifier.startDownload();
                        },
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: Text(s.updateAction),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                          textStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Parses markdown changelog lines into clean structured native UI elements.
  Widget _buildFormattedChangelog(String markdown) {
    final lines = markdown.split('\n');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      // Markdown Headers (e.g. ## What's Changed, ### New Features)
      if (line.startsWith('#')) {
        final cleanHeader = line.replaceFirst(RegExp(r'^#+\s*'), '');
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Text(
              cleanHeader,
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        );
      }
      // Bullet items (e.g. - Fix crash, * Added server)
      else if (line.startsWith('-') || line.startsWith('*') || line.startsWith('•')) {
        final cleanBullet = line.replaceFirst(RegExp(r'^[-*•]\s*'), '');
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6, right: 9),
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    cleanBullet,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      height: 1.5,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      // Horizontal dividers (--- or ***)
      else if (line.startsWith('---') || line.startsWith('***')) {
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Colors.white12, height: 1),
          ),
        );
      }
      // Regular paragraphs
      else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              line,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                height: 1.5,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
