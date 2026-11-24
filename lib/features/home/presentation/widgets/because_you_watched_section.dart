import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/genre_constants.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../domain/entities/movie.dart';
import '../providers/home_providers.dart';
import '../screens/home_screen.dart';
import 'movie_card.dart';

/// Displays up to 2 personalized recommendation rows on the Home Screen
/// ("Karena Anda Menonton {Judul}" / "Because You Watched {Title}")
/// dynamically generated from the user's watch history or watchlist.
class BecauseYouWatchedSection extends ConsumerWidget {
  const BecauseYouWatchedSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final activeGenre = ref.watch(selectedHomeGenreProvider);
    final activeFilter = ref.watch(homeFilterProvider);
    final asyncGroups = ref.watch(becauseYouWatchedProvider);

    return asyncGroups.when(
      data: (groups) {
        if (groups.isEmpty) return const SizedBox.shrink();

        final renderedRows = <Widget>[];

        for (final group in groups) {
          // Filter by active category tab if needed
          if (activeFilter == HomeCategoryFilter.movies && group.isTv) {
            continue;
          }
          if (activeFilter == HomeCategoryFilter.tv && !group.isTv) {
            continue;
          }

          if (group.isTv) {
            final filteredTv = activeGenre.id == 'all'
                ? group.tvShows
                : group.tvShows
                    .where((t) => activeGenre.matchesTv(t))
                    .toList();
            if (filteredTv.isEmpty) continue;

            final adaptedMovies = filteredTv
                .map(
                  (tv) => Movie(
                    id: tv.id,
                    title: tv.name,
                    overview: tv.overview,
                    posterPath: tv.posterPath,
                    backdropPath: tv.backdropPath,
                    voteAverage: tv.voteAverage,
                    releaseDate: tv.firstAirDate,
                    genreIds: tv.genreIds,
                    originalLanguage: tv.originalLanguage,
                    originCountry: tv.originCountry,
                  ),
                )
                .toList();

            renderedRows.add(
              _PersonalizedRowBlock(
                group: group,
                headerTitle: group.isFromWatchlist
                    ? s.homeBecauseYouSaved(group.seedTitle)
                    : s.homeBecauseYouWatched(group.seedTitle),
                items: adaptedMovies,
                isTv: true,
              ),
            );
          } else {
            final filteredMovies = activeGenre.id == 'all'
                ? group.movies
                : group.movies
                    .where((m) => activeGenre.matchesMovie(m))
                    .toList();
            if (filteredMovies.isEmpty) continue;

            renderedRows.add(
              _PersonalizedRowBlock(
                group: group,
                headerTitle: group.isFromWatchlist
                    ? s.homeBecauseYouSaved(group.seedTitle)
                    : s.homeBecauseYouWatched(group.seedTitle),
                items: filteredMovies,
                isTv: false,
              ),
            );
          }
        }

        if (renderedRows.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: renderedRows,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _PersonalizedRowBlock extends StatelessWidget {
  final PersonalizedRecommendationGroup group;
  final String headerTitle;
  final List<Movie> items;
  final bool isTv;

  const _PersonalizedRowBlock({
    required this.group,
    required this.headerTitle,
    required this.items,
    required this.isTv,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Accent indicator bar
              Container(
                width: 3.5,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Iconsax.magic_star,
                size: 19,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => context.push(
                      isTv
                          ? '/tv/${group.seedId}'
                          : '/movie/${group.seedId}',
                    ),
                    child: Text(
                      headerTitle,
                      textAlign: TextAlign.left,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        RepaintBoundary(
          child: SizedBox(
            height: 255,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return MovieCard(
                      movie: item,
                      isTv: isTv,
                      onTap: isTv
                          ? () => context.push('/tv/${item.id}')
                          : null,
                    )
                    .animate()
                    .fadeIn(delay: (35 * index).ms, duration: 320.ms)
                    .slideX(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
              },
            ),
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}
