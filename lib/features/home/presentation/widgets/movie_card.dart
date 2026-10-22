import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/tmdb_genres.dart';
import '../../domain/entities/movie.dart';

/// Modern, informative movie poster card for horizontal lists.
///
/// Features:
/// - 4K / HD resolution badge
/// - Glassmorphic rating pill
/// - Subtle bottom metadata (title, year, primary genre)
/// - Polished border and shadow effects
class MovieCard extends StatelessWidget {
  final Movie movie;
  final double width;
  final double height;
  final bool showBadge;

  const MovieCard({
    super.key,
    required this.movie,
    this.width = 135,
    this.height = 205,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final primaryGenre = TmdbGenres.getPrimaryGenre(movie.genreIds);
    final isHighRating = movie.voteAverage >= 7.5;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () => context.push('/movie/${movie.id}'),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 0.8,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Poster Image ──
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
                  child: const Center(
                    child: Icon(Icons.movie_outlined, color: AppColors.textMuted, size: 30),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.surfaceVariant,
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined, color: AppColors.textMuted, size: 30),
                  ),
                ),
              ),

              // ── Bottom Multi-Stop Dark Vignette ──
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.45, 0.70, 1.0],
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                        Colors.black.withValues(alpha: 0.95),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Top-Left: Resolution Badge (4K / HD) ──
              if (showBadge)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: isHighRating
                            ? AppColors.primary.withValues(alpha: 0.6)
                            : Colors.white.withValues(alpha: 0.2),
                        width: 0.6,
                      ),
                    ),
                    child: Text(
                      isHighRating ? '4K' : 'HD',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: isHighRating ? AppColors.primaryLight : Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),

              // ── Top-Right: Rating Badge ──
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 0.6,
                    ),
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

              // ── Bottom: Title & Year + Genre ──
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      movie.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (movie.year.isNotEmpty) ...[
                          Text(
                            movie.year,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
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
                              fontSize: 10,
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
            ],
          ),
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
    return GestureDetector(
      onTap: () => context.push('/movie/${movie.id}'),
      child: SizedBox(
        width: 175,
        height: 205,
        child: Stack(
          alignment: Alignment.bottomLeft,
          children: [
            // Giant Rank Number in the background/left
            Positioned(
              left: 0,
              bottom: -14,
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
                height: 205,
                showBadge: false,
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
      ),
    );
  }
}
