import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../providers/download_provider.dart';
import '../../data/services/download_file_namer.dart';
import '../../data/services/video_download_service.dart';

/// Modal bottom sheet with a smooth two-step slide transition:
/// Step 1: Video Resolution & File Size Selection
/// Step 2: Subtitle Preference & Auto-Translation Selection
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
      backgroundColor: AppColors.surface,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
  ConsumerState<DownloadOptionsModal> createState() => _DownloadOptionsModalState();
}

class _DownloadOptionsModalState extends ConsumerState<DownloadOptionsModal> {
  final _videoService = VideoDownloadService();
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoadingResolutions = true;
  List<ResolutionOption> _resolutions = [];
  String _selectedResolution = '1080p';
  String _selectedSubtitleLang = 'id';

  @override
  void initState() {
    super.initState();
    _loadResolutions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
      if (mounted) {
        setState(() {
          _resolutions = res;
          _isLoadingResolutions = false;
          if (res.isNotEmpty) {
            _selectedResolution = res.first.label;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingResolutions = false);
      }
    }
  }

  void _nextPage() {
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _prevPage() {
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isMovie = widget.mediaType == 'movie';

    final videoFileName = isMovie
        ? DownloadFileNamer.formatMovieFileName(widget.title, widget.releaseYear)
        : DownloadFileNamer.formatTvFileName(
            widget.title, widget.season ?? 1, widget.episode ?? 1);
    final subtitleFileName = DownloadFileNamer.formatSubtitleFileName(videoFileName);

    final selectedOption = _resolutions.firstWhere(
      (r) => r.label == _selectedResolution,
      orElse: () => ResolutionOption(
        label: '1080p',
        title: '1080p Full HD',
        description: 'Kualitas terbaik',
        estimatedSizeBytes: 1800000000,
        formattedSize: '~1.8 GB',
        streamUrl: '',
      ),
    );

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            // Header Media Preview with Step Dots
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: ApiConstants.imageUrl(
                        widget.posterPath,
                        size: ApiConstants.posterSmall,
                      ),
                      width: 48,
                      height: 72,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        width: 48,
                        height: 72,
                        color: AppColors.surfaceVariant,
                      ),
                      errorWidget: (_, _, _) => Container(
                        width: 48,
                        height: 72,
                        color: AppColors.surfaceVariant,
                        child: const Icon(Icons.movie, color: AppColors.textMuted),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isMovie
                              ? 'Film • ${widget.releaseYear.isNotEmpty ? widget.releaseYear : 'N/A'}'
                              : 'Serial TV • S${widget.season} E${widget.episode}${widget.episodeTitle != null ? ' - ${widget.episodeTitle}' : ''}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _currentPage == 0 ? 'Langkah 1/2: Resolusi' : 'Langkah 2/2: Subtitle',
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Smooth step indicator dots
                            Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  width: _currentPage == 0 ? 16 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _currentPage == 0 ? AppColors.primary : Colors.white24,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  width: _currentPage == 1 ? 16 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _currentPage == 1 ? AppColors.primary : Colors.white24,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0x15FFFFFF), height: 1),

            // Two-step PageView with smooth horizontal slide animation
            Flexible(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                children: [
                  // PAGE 1: Resolusi & Ukuran
                  _buildResolutionStep(context, selectedOption),

                  // PAGE 2: Subtitle Preference & Auto-Translation
                  _buildSubtitleStep(context, selectedOption, videoFileName, subtitleFileName, bottomInset),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Step 1: Video resolution & file size selection
  Widget _buildResolutionStep(BuildContext context, ResolutionOption selectedOption) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.hd_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Pilih Resolusi Video',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Pilih kualitas video sesuai ruang penyimpanan perangkat Anda',
                  style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textMuted),
                ),
                const SizedBox(height: 14),

                if (_isLoadingResolutions)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Menghubungkan stream & menghitung ukuran...',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: _resolutions.map((res) {
                      final isSelected = _selectedResolution == res.label;
                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          setState(() => _selectedResolution = res.label);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.surfaceElevated,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  res.label,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected ? Colors.black : Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      res.title,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected ? AppColors.primary : Colors.white,
                                      ),
                                    ),
                                    Text(
                                      res.description,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                res.formattedSize,
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                isSelected
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                                size: 20,
                                color: isSelected ? AppColors.primary : AppColors.textMuted,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),

        // Action Button: Lanjut ke Subtitle
        Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 14 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoadingResolutions ? null : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Lanjut ke Pilihan Subtitle (${selectedOption.label} • ${selectedOption.formattedSize})',
                    style: GoogleFonts.outfit(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Step 2: Subtitle preference selection with auto-translate option
  Widget _buildSubtitleStep(
    BuildContext context,
    ResolutionOption selectedOption,
    String videoFileName,
    String subtitleFileName,
    double bottomInset,
  ) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with back button
                Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _prevPage,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceElevated,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pilih Subtitle',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Kualitas terpilih: ${selectedOption.label} (${selectedOption.formattedSize})',
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                _buildSubtitleOption(
                  langCode: 'id',
                  title: 'Bahasa Indonesia (Prioritas)',
                  badge: 'Auto-Translate',
                  subtitle:
                      'Otomatis unduh teks Indonesia. Jika belum ada, sistem mengunduh teks English ke cache lalu otomatis menerjemahkannya secara gratis.',
                ),
                _buildSubtitleOption(
                  langCode: 'en',
                  title: 'English Subtitle',
                  badge: 'Original',
                  subtitle: 'Unduh teks subtitle resmi Bahasa Inggris asli.',
                ),
                _buildSubtitleOption(
                  langCode: 'none',
                  title: 'Tanpa Subtitle',
                  subtitle: 'Hanya mengunduh file video saja tanpa file subtitle terpisah.',
                ),

                const SizedBox(height: 14),

                // File location card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.folder_outlined, color: AppColors.textSecondary, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Lokasi Simpan di Perangkat:',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Penyimpanan Utama > Download > Cineva > $videoFileName',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          color: AppColors.primary,
                        ),
                      ),
                      if (_selectedSubtitleLang != 'none') ...[
                        const SizedBox(height: 2),
                        Text(
                          '+ Subtitle: $subtitleFileName',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom Action Button: Mulai Mengunduh
        Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 14 + bottomInset),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final router = GoRouter.of(context);

                Navigator.of(context, rootNavigator: true).pop();

                await ref.read(downloadManagerProvider.notifier).startDownload(
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
                      estimatedSizeBytes: selectedOption.estimatedSizeBytes,
                      preferredSubtitleLang: _selectedSubtitleLang,
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
                        const Icon(Icons.download_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Unduhan dimulai! Ketuk ikon Unduhan di AppBar untuk melihat proses.',
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
                      label: 'Lihat',
                      textColor: AppColors.primary,
                      onPressed: () {
                        messenger.hideCurrentSnackBar();
                        router.push('/downloads');
                      },
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.download_rounded, size: 20),
              label: Text(
                'Mulai Mengunduh (${selectedOption.formattedSize})',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitleOption({
    required String langCode,
    required String title,
    String? badge,
    required String subtitle,
  }) {
    final isSelected = _selectedSubtitleLang == langCode;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _selectedSubtitleLang = langCode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceElevated,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.primary : Colors.white,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      color: AppColors.textMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 20,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
