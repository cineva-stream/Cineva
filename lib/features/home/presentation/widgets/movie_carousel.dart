import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../../core/utils/tmdb_genres.dart';
import '../../../../core/platform/device_form_factor.dart';
import '../../../../shared/widgets/tv_focusable.dart';
import '../../domain/entities/movie.dart';

/// Top-tier Cinematic Hero Billboard Carousel showcasing featured/trending titles.
///
/// Features:
/// - Desktop (Widescreen) & Android TV responsive layout (up to 490px height)
/// - Left-to-right cinematic gradient vignette with rich overview and natural button widths
/// - Interactive desktop/TV chevron slide navigation buttons
/// - 5-second automated cinematic slide transition
/// - Cinema Amber trending badge & quality pills (4K Ultra HD, HDR10)
/// - Prominent dual CTA buttons ("Nonton Sekarang" & "Detail") with D-Pad focus & hover glow
/// - Smooth animated page indicator pills
class MovieCarousel extends ConsumerStatefulWidget {
  final List<Movie> movies;

  const MovieCarousel({super.key, required this.movies});

  @override
  ConsumerState<MovieCarousel> createState() => _MovieCarouselState();
}

class _MovieCarouselState extends ConsumerState<MovieCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final count = widget.movies.take(10).length;
      if (count <= 1) return;
      final nextPage = (_currentPage + 1) % count;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _goToPrevious(int count) {
    if (!_pageController.hasClients || count <= 1) return;
    final prevPage = (_currentPage - 1 + count) % count;
    _pageController.animateToPage(
      prevPage,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  void _goToNext(int count) {
    if (!_pageController.hasClients || count <= 1) return;
    final nextPage = (_currentPage + 1) % count;
    _pageController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final movies = widget.movies.take(10).toList();
    if (movies.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isTv = ref.watch(isTvProvider);
    final isWide = isWideScreenLayout(context, isTv: isTv);
    final isCompact = screenWidth < 360 || screenHeight < 700;
    final carouselHeight = isWide
        ? (screenHeight < 650 ? 400.0 : 490.0)
        : (isCompact ? 375.0 : 430.0);

    return Column(
      children: [
        SizedBox(
          height: carouselHeight,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                  _startAutoSlide();
                },
                itemCount: movies.length,
                itemBuilder: (context, index) {
                  final movie = movies[index];
                  final genreText = TmdbGenres.getFormattedGenres(movie.genreIds, limit: 3);

                  return AnimatedPadding(
                    duration: const Duration(milliseconds: 300),
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 0 : 5,
                      vertical: _currentPage == index ? 0 : (isWide ? 2 : 6),
                    ),
                    child: GestureDetector(
                      onTap: () => context.push(movie.mediaType == 'tv' ? '/tv/${movie.id}' : '/movie/${movie.id}'),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(isWide ? 28 : 22),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // ── High-Res Backdrop Image ──
                            CachedNetworkImage(
                              imageUrl: ApiConstants.imageUrl(
                                movie.backdropPath ?? movie.posterPath,
                                size: isWide ? ApiConstants.backdropOriginal : ApiConstants.backdropLarge,
                              ),
                              memCacheWidth: isWide ? 1920 : 800,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppColors.surfaceVariant,
                                child: const Center(
                                  child: Icon(Icons.movie, size: 48, color: AppColors.textMuted),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.surfaceVariant,
                                child: const Icon(Icons.movie, size: 48, color: AppColors.textMuted),
                              ),
                            ),

                            // ── Multi-Layer Cinematic Vignette ──
                            if (isWide) ...[
                              // Strong horizontal left vignette for widescreen readability
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    stops: const [0.0, 0.40, 0.70, 1.0],
                                    colors: [
                                      Colors.black.withValues(alpha: 0.94),
                                      Colors.black.withValues(alpha: 0.75),
                                      Colors.black.withValues(alpha: 0.20),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              // Bottom vignette
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    stops: const [0.0, 0.35, 1.0],
                                    colors: [
                                      AppColors.background,
                                      AppColors.background.withValues(alpha: 0.70),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ] else ...[
                              // Mobile vertical vignette
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    stops: const [0.0, 0.25, 0.55, 0.82, 1.0],
                                    colors: [
                                      Colors.black.withValues(alpha: 0.55),
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.4),
                                      AppColors.background.withValues(alpha: 0.92),
                                      AppColors.background,
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            // Top gradient shadow for contrast
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  stops: const [0.0, 0.22],
                                  colors: [
                                    Colors.black.withValues(alpha: 0.5),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),

                            // ── Billboard Content Overlay ──
                            Positioned(
                              bottom: isWide ? 40 : 20,
                              left: isWide ? 44 : 18,
                              right: isWide ? null : 18,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: isWide ? 640 : double.infinity,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Trending Rank & Quality Badges
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.22),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: AppColors.primary.withValues(alpha: 0.6),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.local_fire_department_rounded,
                                                  size: 14, color: AppColors.primary),
                                              const SizedBox(width: 4),
                                              Text(
                                                movie.mediaType == 'tv'
                                                    ? 'POPULER TV #${index + 1}'
                                                    : 'TRENDING #${index + 1}',
                                                style: GoogleFonts.inter(
                                                  color: AppColors.primaryLight,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // 4K UHD badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 0.25),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Text(
                                            '4K UHD',
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        // HDR badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'HDR',
                                            style: GoogleFonts.inter(
                                              color: AppColors.textSecondary,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: isWide ? 12 : 10),

                                    // Movie Title
                                    Text(
                                      movie.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        fontSize: isWide ? 38 : (isCompact ? 21 : 26),
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        height: 1.12,
                                        letterSpacing: -0.4,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withValues(alpha: 0.85),
                                            blurRadius: 14,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                    ),

                                    SizedBox(height: isWide ? 10 : 8),

                                    // Metadata Info Row (Rating, Year, Genres)
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded, color: AppColors.star, size: 17),
                                        const SizedBox(width: 4),
                                        Text(
                                          movie.voteAverage.toStringAsFixed(1),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                        if (movie.year.isNotEmpty) ...[
                                          _buildDotDivider(),
                                          Text(
                                            movie.year,
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                        if (genreText.isNotEmpty) ...[
                                          _buildDotDivider(),
                                          Flexible(
                                            child: Text(
                                              genreText,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),

                                    // Widescreen Synopsis Snippet
                                    if (isWide && movie.overview.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        movie.overview,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          height: 1.5,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w400,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black.withValues(alpha: 0.9),
                                              blurRadius: 8,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    SizedBox(height: isWide ? 22 : 16),

                                    // Action Buttons Row
                                    if (isWide) ...[
                                      // Widescreen Action Buttons (natural widths, D-Pad/Hover tactile)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TvFocusable(
                                            focusedScale: 1.05,
                                            glowBlurRadius: 14,
                                            borderRadius: BorderRadius.circular(14),
                                            onTap: () => context.push(movie.mediaType == 'tv' ? '/tv/${movie.id}' : '/movie/${movie.id}'),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                borderRadius: BorderRadius.circular(14),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors.primary.withValues(alpha: 0.35),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 24),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    s.homeWatchNow,
                                                    style: GoogleFonts.inter(
                                                      color: Colors.black,
                                                      fontWeight: FontWeight.w800,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          TvFocusable(
                                            focusedScale: 1.05,
                                            glowBlurRadius: 10,
                                            borderRadius: BorderRadius.circular(14),
                                            onTap: () => context.push(movie.mediaType == 'tv' ? '/tv/${movie.id}' : '/movie/${movie.id}'),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(14),
                                                border: Border.all(
                                                  color: Colors.white.withValues(alpha: 0.25),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    s.homeDetail,
                                                    style: GoogleFonts.inter(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ] else ...[
                                      // Mobile Action Buttons (Full width responsive)
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 6,
                                            child: ElevatedButton.icon(
                                              onPressed: () => context.push(movie.mediaType == 'tv' ? '/tv/${movie.id}' : '/movie/${movie.id}'),
                                              icon: Icon(Icons.play_arrow_rounded, color: Colors.black, size: isCompact ? 20 : 24),
                                              label: Text(
                                                s.homeWatchNow,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.inter(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: isCompact ? 12 : 14,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.primary,
                                                foregroundColor: Colors.black,
                                                padding: EdgeInsets.symmetric(vertical: isCompact ? 10 : 12),
                                                elevation: 6,
                                                shadowColor: AppColors.primary.withValues(alpha: 0.4),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 4,
                                            child: OutlinedButton.icon(
                                              onPressed: () => context.push(movie.mediaType == 'tv' ? '/tv/${movie.id}' : '/movie/${movie.id}'),
                                              icon: Icon(Icons.info_outline_rounded, color: Colors.white, size: isCompact ? 16 : 18),
                                              label: Text(
                                                s.homeDetail,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.inter(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: isCompact ? 12 : 14,
                                                ),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                backgroundColor: Colors.white.withValues(alpha: 0.12),
                                                side: BorderSide(
                                                  color: Colors.white.withValues(alpha: 0.25),
                                                  width: 1,
                                                ),
                                                padding: EdgeInsets.symmetric(vertical: isCompact ? 10 : 12),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Widescreen Side Navigation Chevrons
              if (isWide && movies.length > 1) ...[
                Positioned(
                  left: 20,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: TvFocusable(
                      focusedScale: 1.15,
                      glowBlurRadius: 12,
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => _goToPrevious(movies.length),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 20,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: TvFocusable(
                      focusedScale: 1.15,
                      glowBlurRadius: 12,
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => _goToNext(movies.length),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Page Indicator Capsule
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            movies.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentPage == index ? 22 : 6,
              height: 4,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? AppColors.primary
                    : AppColors.textMuted.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDotDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 3.5,
      height: 3.5,
      decoration: const BoxDecoration(
        color: AppColors.textMuted,
        shape: BoxShape.circle,
      ),
    );
  }
}
