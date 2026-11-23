import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../../core/utils/tmdb_genres.dart';
import '../../../../shared/widgets/tv_focusable.dart';
import '../../domain/entities/movie.dart';

/// Clean, modern movie poster card with metadata below the poster.
///
/// Features:
/// - 100% pure poster image without dark vignette or gradient overlays
/// - Minimalist TMDb rating badge on the poster (semi-transparent black, borderless)
/// - Movie title and genre/year positioned cleanly below the poster
class MovieCard extends ConsumerWidget {
  final Movie movie;
  final double width;
  final double? height;
  final bool showBadge; // Kept for backwards compatibility
  final bool showRating;
  final bool isTv;
  final VoidCallback? onTap;

  const MovieCard({
    super.key,
    required this.movie,
    this.width = 135,
    this.height = 245,
    this.showBadge = true,
    this.showRating = true,
    this.isTv = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final primaryGenre = TmdbGenres.getPrimaryGenre(
      movie.genreIds,
      fallback: isTv
          ? (movie.originCountry.contains('JP')
                ? s.tr('Anime', 'Anime', 'एनीमे')
                : s.tr('Serial TV', 'TV Show', 'टीवी शो'))
          : s.tr('Film', 'Movie', 'फ़िल्म'),
      isIndonesian: s.isIndonesian,
      language: s.language,
    );

    return RepaintBoundary(
      child: TvFocusable(
        focusedScale: 1.08,
        borderRadius: BorderRadius.circular(14),
        onTap: onTap ??
            () {
              if (isTv) {
                context.push('/tv/${movie.id}');
              } else {
                context.push('/movie/${movie.id}');
              }
            },
        child: SizedBox(
          width: width,
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Pure Poster Image Container ──
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // ── Pure Poster Image (No gradient / vignette) ──
                        CachedNetworkImage(
                          imageUrl: ApiConstants.imageUrl(
                            movie.posterPath,
                            size: ApiConstants.posterMedium,
                          ),
                          memCacheWidth: 270,
                          memCacheHeight: 410,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppColors.surfaceVariant,
                            child: Center(
                              child: Icon(
                                isTv ? Icons.tv_rounded : Icons.movie_outlined,
                                color: AppColors.textMuted,
                                size: 28,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.surfaceVariant,
                            child: Center(
                              child: Icon(
                                isTv ? Icons.tv_off_outlined : Icons.broken_image_outlined,
                                color: AppColors.textMuted,
                                size: 28,
                              ),
                            ),
                          ),
                        ),

                        // ── TMDb Rating Badge (Clean, semi-transparent black, borderless) ──
                        if (showRating && movie.voteAverage > 0)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, color: AppColors.star, size: 12),
                                  const SizedBox(width: 3),
                                  Text(
                                    movie.voteAverage.toStringAsFixed(1),
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // ── Title Below Poster ──
              Text(
                movie.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),

              const SizedBox(height: 2),

              // ── Year & Genre Below Title ──
              Row(
                children: [
                  if (movie.year.isNotEmpty) ...[
                    Text(
                      movie.year,
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 2.5,
                      height: 2.5,
                      decoration: const BoxDecoration(
                        color: AppColors.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      primaryGenre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Netflix-style Top 10 Card featuring giant rank numbers beside the poster.
class Top10MovieCard extends StatelessWidget {
  final Movie movie;
  final int rank;

  const Top10MovieCard({
    super.key,
    required this.movie,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 175,
      height: 245,
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          // Giant Rank Number in the background/left
          Positioned(
            left: 0,
            bottom: 22,
            child: Text(
              '$rank',
              style: GoogleFonts.outfit(
                fontSize: 100,
                fontWeight: FontWeight.w900,
                letterSpacing: -6.0,
                color: AppColors.surfaceElevated.withValues(alpha: 0.8),
                shadows: [
                  Shadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),

          // Overlaid Movie Card offset to the right
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: MovieCard(
              movie: movie,
              width: 130,
              height: 245,
              showBadge: false,
              showRating: false,
            ),
          ),

          // Top Rank Badge on the poster
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9500), Color(0xFFFF5E3A)],
                ),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Text(
                'TOP $rank',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
