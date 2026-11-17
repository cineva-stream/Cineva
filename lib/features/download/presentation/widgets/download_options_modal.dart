import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../player/data/services/smart_stream_service.dart';
import '../../../player/data/services/subtitle_service.dart';
import '../../../settings/data/settings_service.dart';
import '../../../settings/data/subtitle_languages.dart';
import '../providers/download_provider.dart';
import '../../data/services/video_download_service.dart';

/// Compact, content-hugging two-step modal bottom sheet with smooth horizontal slide animation:
/// Step 1: Select Quality with Estimated File Size + [Cancel] & [Next] buttons.
/// Step 2: Select Available Subtitle + Auto-Translate Toggle to Primary Subtitle + [Download] button.
class DownloadOptionsModal extends ConsumerStatefulWidget {
  final int tmdbId;
  final String mediaType; // 'movie' or 'tv'
  final String title;
  final String releaseYear;
  final int? season;
  final int? episode;
  final String? episodeTitle;
  final String? posterPath;
  final String? backdropPath;
  final String? imdbId;
  final int runtimeMinutes;

  const DownloadOptionsModal({
    super.key,
    required this.tmdbId,
    required this.mediaType,
    required this.title,
    this.releaseYear = '',
    this.season,
    this.episode,
    this.episodeTitle,
    this.posterPath,
    this.backdropPath,
    this.imdbId,
    this.runtimeMinutes = 100,
  });

  static Future<void> show(
    BuildContext context, {
    required int tmdbId,
    required String mediaType,
    required String title,
    String releaseYear = '',
    int? season,
    int? episode,
    String? episodeTitle,
    String? posterPath,
    String? backdropPath,
    String? imdbId,
    int runtimeMinutes = 100,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: false,
      backgroundColor: AppColors.background,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (_) => DownloadOptionsModal(
        tmdbId: tmdbId,
        mediaType: mediaType,
        title: title,
        releaseYear: releaseYear,
        season: season,
        episode: episode,
        episodeTitle: episodeTitle,
        posterPath: posterPath,
        backdropPath: backdropPath,
        imdbId: imdbId,
        runtimeMinutes: runtimeMinutes,
      ),
    );
  }

  @override
  ConsumerState<DownloadOptionsModal> createState() =>
      _DownloadOptionsModalState();
}

class _DownloadOptionsModalState extends ConsumerState<DownloadOptionsModal> {
  final _videoService = VideoDownloadService();
  final _subtitleService = SubtitleService();

  int _currentStep = 0; // 0 = Quality, 1 = Subtitle
  bool _slidingForward = true;

  bool _isLoadingResolutions = true;
  bool _isLoadingSubtitles = true;

  List<ResolutionOption> _resolutions = [];
  String _selectedResolution = '1080p';

  List<SubtitleInfo> _availableSubtitles = [];
  SubtitleInfo? _selectedSubtitle;
  bool _noSubtitleSelected = false;
  late bool _autoTranslate;

  @override
  void initState() {
    super.initState();
    _autoTranslate = SettingsService.getAutoTranslate();
    _loadData();
  }

  @override
  void dispose() {
    _subtitleService.dispose();
    super.dispose();
  }

  String _getPrimarySubtitleLangCode() {
    final pref = SettingsService.getDefaultSubtitleLang();
    if (pref.isNotEmpty && pref != 'off') {
      return pref.toLowerCase();
    }
    final appLang = ref.read(appLanguageProvider);
    return appLang == AppLanguage.en ? 'en' : 'id';
  }

  Future<void> _loadData() async {
    final resolutionsFuture = _loadResolutions();
    final openSubsFuture = _fetchOpenSubtitles();
    await Future.wait([resolutionsFuture, openSubsFuture]);
  }

  Future<void> _loadResolutions() async {
    try {
      final res = await _videoService.resolveResolutionOptions(
        tmdbId: widget.tmdbId,
        imdbId: widget.imdbId,
        season: widget.season,
        episode: widget.episode,
        runtimeMinutes: widget.runtimeMinutes,
      );
      if (!mounted) return;
      setState(() {
        _resolutions = res;
        _isLoadingResolutions = false;
        if (res.isNotEmpty) {
          _selectedResolution = res.first.label;
          if (res.first.streamSubtitles.isNotEmpty) {
            _mergeAndSelectSubtitles(res.first.streamSubtitles);
          }
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingResolutions = false);
      }
    }
  }

  Future<void> _fetchOpenSubtitles() async {
    try {
      String? resolvedImdb = widget.imdbId;
      if ((resolvedImdb == null || resolvedImdb.isEmpty) && widget.tmdbId > 0) {
        try {
          final ids = await SmartStreamService.resolveIds(
            tmdbId: widget.tmdbId,
            imdbId: widget.imdbId,
            isTv: widget.season != null,
          );
          if (ids.imdbId != null && ids.imdbId!.isNotEmpty) {
            resolvedImdb = ids.imdbId;
          }
        } catch (_) {}
      }

      final primaryLang = _getPrimarySubtitleLangCode();
      final queryLangs = <String>{primaryLang, 'id', 'en'}.join(',');

      List<SubtitleInfo> openSubs = [];
      if (resolvedImdb != null && resolvedImdb.isNotEmpty) {
        openSubs = await _subtitleService.searchByImdbId(
          resolvedImdb,
          language: queryLangs,
          seasonNumber: widget.season,
          episodeNumber: widget.episode,
        );
      }
      if (openSubs.isEmpty && widget.title.isNotEmpty) {
        openSubs = await _subtitleService.searchByQuery(
          widget.title,
          language: queryLangs,
          seasonNumber: widget.season,
          episodeNumber: widget.episode,
        );
      }

      if (!mounted) return;
      setState(() {
        _mergeAndSelectSubtitles(openSubs);
        _isLoadingSubtitles = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingSubtitles = false);
      }
    }
  }

  void _mergeAndSelectSubtitles(List<SubtitleInfo> incoming) {
    final combined = <SubtitleInfo>[..._availableSubtitles, ...incoming];
    final seenKeys = <String>{};
    final deduped = <SubtitleInfo>[];
    final langCounts = <String, int>{};

    for (final sub in combined) {
      final lang = sub.language.toLowerCase().trim();
      final isStream = sub.languageName.toLowerCase().contains('stream') ||
          (sub.downloadUrl != null && sub.downloadUrl!.isNotEmpty);
      final key = '${lang}_${isStream ? 'stream' : sub.id}';
      if (!seenKeys.add(key)) continue;

      final countKey = '${lang}_${isStream ? 's' : 'o'}';
      final currentCount = langCounts[countKey] ?? 0;
      if (isStream && currentCount >= 1) continue;
      if (!isStream && currentCount >= 2) continue;
      langCounts[countKey] = currentCount + 1;

      deduped.add(sub);
    }

    final primaryLang = _getPrimarySubtitleLangCode();
    deduped.sort((a, b) {
      int score(SubtitleInfo item) {
        final l = item.language.toLowerCase();
        final isStream = item.languageName.toLowerCase().contains('stream') ||
            (item.downloadUrl != null && item.downloadUrl!.isNotEmpty);
        int s = 0;
        if (l == primaryLang) {
          s += 100;
        } else if (l == 'id') {
          s += 80;
        } else if (l == 'en') {
          s += 60;
        }
        if (isStream) s += 10;
        return s;
      }

      return score(b).compareTo(score(a));
    });

    _availableSubtitles = deduped;

    if (_selectedSubtitle == null &&
        !_noSubtitleSelected &&
        _availableSubtitles.isNotEmpty) {
      _selectedSubtitle = _availableSubtitles.first;
    }
  }

  void _nextPage() {
    setState(() {
      _slidingForward = true;
      _currentStep = 1;
    });
  }

  void _prevPage() {
    setState(() {
      _slidingForward = false;
      _currentStep = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    // Respect Android gesture navigation bar inset accurately in edge-to-edge mode
    final bottomInset = math.max(
      MediaQuery.viewPaddingOf(context).bottom,
      MediaQuery.paddingOf(context).bottom,
    );

    final selectedOption = _resolutions.firstWhere(
      (r) => r.label == _selectedResolution,
      orElse: () => ResolutionOption(
        label: '1080p',
        title: '1080p Full HD',
        description: s.downloadQualityDesc('1080p'),
        estimatedSizeBytes: 1800000000,
        formattedSize: '~1.8 GB',
        streamUrl: '',
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Simple Drag Handle
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // Content-hugging smooth slide transition between Step 1 and Step 2
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final isIncoming = child.key == ValueKey<int>(_currentStep);
              final beginOffset = isIncoming
                  ? Offset(_slidingForward ? 1.0 : -1.0, 0.0)
                  : Offset(_slidingForward ? -0.35 : 0.35, 0.0);
              return ClipRect(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: beginOffset,
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
              );
            },
            child: _currentStep == 0
                ? KeyedSubtree(
                    key: const ValueKey<int>(0),
                    child: _buildQualityStep(
                      context,
                      selectedOption,
                      bottomInset,
                      s,
                    ),
                  )
                : KeyedSubtree(
                    key: const ValueKey<int>(1),
                    child: _buildSubtitleStep(
                      context,
                      selectedOption,
                      bottomInset,
                      s,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  /// Step 1: Title, Quality List with Estimated File Size, Cancel & Next Buttons
  Widget _buildQualityStep(
    BuildContext context,
    ResolutionOption selectedOption,
    double bottomInset,
    AppStrings s,
  ) {
    final isMovie = widget.mediaType == 'movie';
    final mediaSubtitle = isMovie
        ? (widget.releaseYear.isNotEmpty
            ? '${widget.title} (${widget.releaseYear})'
            : widget.title)
        : '${widget.title} • S${widget.season ?? 1}:E${widget.episode ?? 1}${widget.episodeTitle != null && widget.episodeTitle!.isNotEmpty ? ' - ${widget.episodeTitle}' : ''}';

    final maxListHeight = MediaQuery.sizeOf(context).height * 0.42;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Bottom Sheet Title
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.downloadSheetQualityTitle,
                style: GoogleFonts.outfit(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                mediaSubtitle,
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

        const Divider(color: Color(0x15FFFFFF), height: 1),

        // Quality List with Estimated File Sizes (shrink-wrapped to content)
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxListHeight),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
            child: _isLoadingResolutions
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            s.downloadModalConnecting,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : _resolutions.isEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 22,
                        ),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.cloud_off_rounded,
                              color: AppColors.textMuted,
                              size: 30,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              s.isIndonesian
                                  ? 'Tautan unduhan belum tersedia untuk judul ini'
                                  : 'Download stream not available for this title',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _resolutions.map((res) {
                          final isSelected = _selectedResolution == res.label;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () =>
                                  setState(() => _selectedResolution = res.label),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.withValues(alpha: 0.12)
                                      : AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.surfaceElevated,
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected
                                          ? Icons.radio_button_checked_rounded
                                          : Icons.radio_button_off_rounded,
                                      size: 20,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            res.label,
                                            style: GoogleFonts.outfit(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w700,
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            s.downloadQualityDesc(res.label),
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primary.withValues(
                                                alpha: 0.18,
                                              )
                                            : AppColors.surfaceElevated,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        res.formattedSize,
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
          ),
        ),

        // Bottom Buttons: [Batal / Cancel] and [Lanjut / Next]
        Container(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 12 + bottomInset),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    s.downloadSheetCancel,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: (_isLoadingResolutions ||
                          _resolutions.isEmpty ||
                          selectedOption.streamUrl.isEmpty)
                      ? null
                      : _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        s.downloadSheetNext,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, size: 17),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Step 2: Title, Available Subtitles List, Auto-Translate Toggle, Download Button
  Widget _buildSubtitleStep(
    BuildContext context,
    ResolutionOption selectedOption,
    double bottomInset,
    AppStrings s,
  ) {
    final primaryLangCode = _getPrimarySubtitleLangCode();
    final primaryLangObj = SubtitleLanguageCatalog.findByCode(primaryLangCode);
    final maxListHeight = MediaQuery.sizeOf(context).height * 0.36;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Bottom Sheet Title with Back Arrow
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 20, 10),
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _prevPage,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceElevated,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
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
                      s.downloadSheetSubtitleTitle,
                      style: GoogleFonts.outfit(
                        fontSize: 17.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${selectedOption.label} • ${selectedOption.formattedSize}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(color: Color(0x15FFFFFF), height: 1),

        // Available Subtitles List (shrink-wrapped to content)
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxListHeight),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoadingSubtitles && _availableSubtitles.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          s.downloadSheetLoadingSubtitles,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Available Subtitle Items for this Movie / Episode
                for (final sub in _availableSubtitles)
                  _buildAvailableSubtitleTile(sub, s),

                // Fallback default language option if OpenSubtitles & Stream returned empty
                if (!_isLoadingSubtitles && _availableSubtitles.isEmpty)
                  _buildFallbackPrimarySubtitleTile(primaryLangObj, s),

                // No Subtitle Option
                _buildNoSubtitleTile(s),
              ],
            ),
          ),
        ),

        // Auto-Translate Toggle + Download Button Footer
        Container(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 12 + bottomInset),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Toggle: Auto-Translate to Primary Subtitle
              Opacity(
                opacity: _noSubtitleSelected ? 0.45 : 1.0,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceElevated),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.translate_rounded,
                        color: AppColors.primary,
                        size: 19,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.downloadSheetAutoTranslateTitle(
                                primaryLangObj.name,
                              ),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              s.downloadSheetAutoTranslateDesc(
                                primaryLangObj.name,
                              ),
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: !_noSubtitleSelected && _autoTranslate,
                        activeThumbColor: AppColors.primary,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: _noSubtitleSelected
                            ? null
                            : (val) {
                                setState(() => _autoTranslate = val);
                              },
                      ),
                    ],
                  ),
                ),
              ),

              // Download Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _startDownload(selectedOption, s),
                  icon: const Icon(Icons.download_rounded, size: 19),
                  label: Text(
                    '${s.downloadSheetDownloadBtn} (${selectedOption.formattedSize})',
                    style: GoogleFonts.outfit(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableSubtitleTile(SubtitleInfo sub, AppStrings s) {
    final isSelected =
        !_noSubtitleSelected && _selectedSubtitle?.id == sub.id;
    final langObj = SubtitleLanguageCatalog.findByCode(sub.language);
    final isStream = sub.languageName.toLowerCase().contains('stream') ||
        (sub.downloadUrl != null && sub.downloadUrl!.isNotEmpty);
    final sourceLabel = isStream
        ? s.downloadSheetSubSourceStream
        : s.downloadSheetSubSourceOpenSub;
    final detailText = sub.fileName.isNotEmpty && sub.fileName != sub.languageName
        ? '$sourceLabel • ${sub.fileName}'
        : sourceLabel;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _noSubtitleSelected = false;
            _selectedSubtitle = sub;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected ? AppColors.primary : AppColors.surfaceElevated,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      langObj.displayName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppColors.primary : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      detailText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textMuted,
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

  Widget _buildFallbackPrimarySubtitleTile(
    SubtitleLanguage primaryLangObj,
    AppStrings s,
  ) {
    final isSelected = !_noSubtitleSelected;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _noSubtitleSelected = false;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected ? AppColors.primary : AppColors.surfaceElevated,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      primaryLangObj.displayName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppColors.primary : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      s.downloadModalIndonesianPriorityDesc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textMuted,
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

  Widget _buildNoSubtitleTile(AppStrings s) {
    final isSelected = _noSubtitleSelected;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _noSubtitleSelected = true;
            _selectedSubtitle = null;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected ? AppColors.primary : AppColors.surfaceElevated,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.downloadModalNoSub,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppColors.primary : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      s.downloadModalNoSubDesc,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textMuted,
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

  Future<void> _startDownload(
    ResolutionOption selectedOption,
    AppStrings s,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final downloadNotifier = ref.read(downloadManagerProvider.notifier);
    final primaryLangCode = _getPrimarySubtitleLangCode();

    final effectiveSubLang = _noSubtitleSelected
        ? 'none'
        : (_autoTranslate
            ? primaryLangCode
            : (_selectedSubtitle?.language ?? primaryLangCode));

    Navigator.of(context, rootNavigator: true).pop();

    await downloadNotifier.startDownload(
          tmdbId: widget.tmdbId,
          mediaType: widget.mediaType,
          title: widget.title,
          releaseYear: widget.releaseYear,
          season: widget.season,
          episode: widget.episode,
          episodeTitle: widget.episodeTitle,
          posterPath: widget.posterPath,
          backdropPath: widget.backdropPath,
          imdbId: widget.imdbId,
          resolution: _selectedResolution,
          streamUrl: selectedOption.streamUrl,
          masterPlaylistUrl: selectedOption.masterPlaylistUrl,
          headers: selectedOption.headers,
          estimatedSizeBytes: selectedOption.estimatedSizeBytes,
          preferredSubtitleLang: effectiveSubLang,
          selectedSubtitle: _noSubtitleSelected ? null : _selectedSubtitle,
          autoTranslate: !_noSubtitleSelected && _autoTranslate,
          targetTranslateLang: primaryLangCode,
          runtimeMinutes: widget.runtimeMinutes,
        );

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Row(
          children: [
            const Icon(
              Icons.download_rounded,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                s.downloadModalStartedToast,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: s.downloadModalViewToast,
          textColor: AppColors.primary,
          onPressed: () {
            messenger.hideCurrentSnackBar();
            router.push('/downloads');
          },
        ),
      ),
    );
  }
}
