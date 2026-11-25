import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../watchlist/data/watchlist_repository.dart';
import '../../../download/presentation/widgets/download_options_modal.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../shared/widgets/tv_focusable.dart';
import '../widgets/in_app_trailer_modal.dart';
import '../../data/models/trailer_video_model.dart';
import '../../../tv_universe/presentation/widgets/tv_universe_banner.dart';
import '../../../../core/platform/device_form_factor.dart';
import '../../../watch_party/domain/models/watch_party_room.dart';
import '../../../watch_party/presentation/widgets/watch_party_modal.dart';
import '../../../player/data/services/provider_loader_service.dart';
import '../../data/services/media_share_service.dart';

// ── TV Detail Provider ──

final tvDetailProvider = FutureProvider.family<Map<String, dynamic>, int>((
  ref,
  tvId,
) async {
  final lang = ref.watch(appLanguageProvider);
  final tmdbLang = lang.tmdbLanguageCode;
  final dio = DioClient.createTmdbClient();
  final response = await dio.get(
    '/tv/$tvId',
    queryParameters: {
      'language': tmdbLang,
      'append_to_response': 'credits,external_ids,similar,videos',
    },
  );
  final data = Map<String, dynamic>.from(response.data as Map);
  final overview = (data['overview'] as String? ?? '').trim();
  if (overview.isEmpty) {
    try {
      final fallbackLang = tmdbLang == 'en-US' ? 'id-ID' : 'en-US';
      final fbResponse = await dio.get(
        '/tv/$tvId',
        queryParameters: {'language': fallbackLang},
      );
      final fbOverview = (fbResponse.data['overview'] as String? ?? '').trim();
      if (fbOverview.isNotEmpty) {
        data['overview'] = fbOverview;
      }
    } catch (_) {}
  }

  // Ensure videos are available (fallback to en-US if primary language has none)
  final rawVideos = (data['videos']?['results'] as List<dynamic>?) ?? [];
  if (rawVideos.isEmpty && tmdbLang != 'en-US') {
    try {
      final vResponse = await dio.get(
        '/tv/$tvId/videos',
        queryParameters: {'language': 'en-US'},
      );
      data['videos'] = vResponse.data;
    } catch (_) {}
  }

  return data;
});

// ── TV Season Episodes Provider ──

final tvSeasonEpisodesProvider =
    FutureProvider.family<
      List<Map<String, dynamic>>,
      ({int tvId, int seasonNumber})
    >((ref, arg) async {
      final lang = ref.watch(appLanguageProvider);
      final tmdbLang = lang.tmdbLanguageCode;
      final dio = DioClient.createTmdbClient();
      final genericTitlePattern = RegExp(
        r'^(?:episode|episod|ep|एपिसोड)\s*\d+$',
        caseSensitive: false,
      );

      bool isGenericTitle(String? name) {
        final clean = (name ?? '').trim();
        return clean.isEmpty || genericTitlePattern.hasMatch(clean);
      }

      try {
        final response = await dio.get(
          '/tv/${arg.tvId}/season/${arg.seasonNumber}',
          queryParameters: {'language': tmdbLang},
        );
        final rawEpisodes = response.data['episodes'] as List<dynamic>? ?? [];
        final episodes = rawEpisodes
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        // TMDB frequently lacks localized (id-ID / hi-IN) episode titles and synopses (`overview`),
        // returning empty `overview: ""` and generic `name: "Episode 1"`.
        // Automatically enrich missing titles and synopses from `en-US` so every episode displays its title & synopsis.
        final needsEnFallback =
            tmdbLang != 'en-US' &&
            episodes.any(
              (ep) =>
                  (ep['overview'] as String? ?? '').trim().isEmpty ||
                  isGenericTitle(ep['name'] as String?),
            );

        if (needsEnFallback) {
          try {
            final enResponse = await dio.get(
              '/tv/${arg.tvId}/season/${arg.seasonNumber}',
              queryParameters: {'language': 'en-US'},
            );
            final enRaw = enResponse.data['episodes'] as List<dynamic>? ?? [];
            final enByEpNum = <int, Map<String, dynamic>>{};
            for (final item in enRaw) {
              if (item is Map) {
                final map = Map<String, dynamic>.from(item);
                final num = map['episode_number'] as int?;
                if (num != null) {
                  enByEpNum[num] = map;
                }
              }
            }

            for (final ep in episodes) {
              final epNum = ep['episode_number'] as int?;
              final enEp = epNum != null ? enByEpNum[epNum] : null;
              if (enEp == null) continue;

              final curOverview = (ep['overview'] as String? ?? '').trim();
              final enOverview = (enEp['overview'] as String? ?? '').trim();
              if (curOverview.isEmpty && enOverview.isNotEmpty) {
                ep['overview'] = enOverview;
              }

              final curName = (ep['name'] as String? ?? '').trim();
              final enName = (enEp['name'] as String? ?? '').trim();
              if (isGenericTitle(curName) && enName.isNotEmpty) {
                ep['name'] = enName;
              }
            }
          } catch (_) {}
        }

        return episodes;
      } catch (e) {
        // Fallback to en-US if primary language request fails
        try {
          final fallbackLang = tmdbLang == 'en-US' ? 'id-ID' : 'en-US';
          final response = await dio.get(
            '/tv/${arg.tvId}/season/${arg.seasonNumber}',
            queryParameters: {'language': fallbackLang},
          );
          final rawEpisodes = response.data['episodes'] as List<dynamic>? ?? [];
          return rawEpisodes
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        } catch (_) {
          return [];
        }
      }
    });

/// TV series detail screen with seasons, episodes selector, and cast.
class TvDetailScreen extends ConsumerWidget {
  final int tvId;
  const TvDetailScreen({super.key, required this.tvId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final detail = ref.watch(tvDetailProvider(tvId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      },
      child: Scaffold(
        body: detail.when(
          data: (data) => _TvDetailContent(data: data),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Iconsax.warning_2,
                  size: 48,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 16),
                Text(
                  s.detailFailed,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(tvDetailProvider(tvId)),
                  child: Text(s.detailRetry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TvDetailContent extends ConsumerStatefulWidget {
  final Map<String, dynamic> data;
  const _TvDetailContent({required this.data});

  @override
  ConsumerState<_TvDetailContent> createState() => _TvDetailContentState();
}

class _TvDetailContentState extends ConsumerState<_TvDetailContent> {
  int _selectedSeasonNumber = 1;

  @override
  void initState() {
    super.initState();
    final seasons = widget.data['seasons'] as List<dynamic>? ?? [];
    // Default to the first regular season (season_number >= 1) or first available
    final regular = seasons
        .where((s) => (s['season_number'] as int? ?? 0) >= 1)
        .firstOrNull;
    if (regular != null) {
      _selectedSeasonNumber = regular['season_number'] as int? ?? 1;
    } else if (seasons.isNotEmpty) {
      _selectedSeasonNumber = seasons.first['season_number'] as int? ?? 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final data = widget.data;
    final name = data['name'] ?? '';
    final overview = data['overview'] ?? '';
    final backdropPath = data['backdrop_path'] as String?;
    final posterPath = data['poster_path'] as String?;
    final voteAverage = (data['vote_average'] as num?)?.toDouble() ?? 0.0;
    final firstAirDate = data['first_air_date'] as String? ?? '';
    final genres =
        (data['genres'] as List<dynamic>?)
            ?.map((g) => g['name'] as String)
            .toList() ??
        [];
    final tagline = data['tagline'] as String? ?? '';
    final seasons = (data['seasons'] as List<dynamic>?) ?? [];
    final numberOfSeasons = data['number_of_seasons'] as int? ?? 0;
    final numberOfEpisodes = data['number_of_episodes'] as int? ?? 0;
    final castList =
        (data['credits']?['cast'] as List<dynamic>?)?.take(10).toList() ?? [];
    final imdbId = data['external_ids']?['imdb_id'] as String?;
    final tvId = data['id'] as int? ?? 0;
    final trailer = TrailerVideoModel.findBestTrailer(data['videos']);
    final status = data['status'] as String?;

    final unreleasedByMeta = MediaReleaseGuard.isUnreleasedByMetadata(
      releaseDate: firstAirDate,
      status: status,
    );
    final serverAvailableOverride = unreleasedByMeta && tvId > 0
        ? (ref
                  .watch(
                    streamAvailabilityProbeProvider((
                      tmdbId: tvId,
                      season: _selectedSeasonNumber,
                      episode: 1,
                    )),
                  )
                  .valueOrNull ??
              false)
        : true;
    final isComingSoon = unreleasedByMeta && !serverAvailableOverride;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTv = ref.watch(isTvProvider);
    final isWide = isWideScreenLayout(context, isTv: isTv);
    final useDesktopHero = (isWide && screenWidth >= 800) || isTv;
    final isCompact = screenWidth < 360;

    if (useDesktopHero) {
      return _buildDesktopLayout(
        context,
        ref: ref,
        s: s,
        data: data,
        name: name,
        tagline: tagline,
        overview: overview,
        posterPath: posterPath,
        backdropPath: backdropPath,
        voteAverage: voteAverage,
        genres: genres,
        firstAirDate: firstAirDate,
        seasons: seasons,
        numberOfSeasons: numberOfSeasons,
        numberOfEpisodes: numberOfEpisodes,
        castList: castList,
        imdbId: imdbId,
        tvId: tvId,
        trailer: trailer,
        isComingSoon: isComingSoon,
      );
    }

    return _buildMobileLayout(
      context,
      ref: ref,
      s: s,
      data: data,
      name: name,
      tagline: tagline,
      overview: overview,
      posterPath: posterPath,
      backdropPath: backdropPath,
      voteAverage: voteAverage,
      genres: genres,
      firstAirDate: firstAirDate,
      seasons: seasons,
      numberOfSeasons: numberOfSeasons,
      numberOfEpisodes: numberOfEpisodes,
      castList: castList,
      imdbId: imdbId,
      tvId: tvId,
      trailer: trailer,
      isCompact: isCompact,
      isComingSoon: isComingSoon,
    );
  }

  static Future<void> _playTvEpisode(
    BuildContext context, {
    required String name,
    required String episodeTitle,
    required String? imdbId,
    required int season,
    required int episode,
    required int tvId,
    required String? posterPath,
    required String? backdropPath,
    required String overview,
  }) async {
    await context.push(
      '/player',
      extra: {
        'title': name,
        'episodeTitle': episodeTitle,
        'imdbId': imdbId,
        'season': season,
        'episode': episode,
        'tmdbId': tvId,
        'mediaType': 'tv',
        'posterPath': posterPath,
        'backdropPath': backdropPath,
        'overview': overview,
        'magnetLink': '',
      },
    );
    await restoreSystemUiAndOrientations(isTv: gIsTv);
  }

  Widget _buildDesktopLayout(
    BuildContext context, {
    required WidgetRef ref,
    required AppStrings s,
    required Map<String, dynamic> data,
    required String name,
    required String tagline,
    required String overview,
    required String? posterPath,
    required String? backdropPath,
    required double voteAverage,
    required List<String> genres,
    required String firstAirDate,
    required List<dynamic> seasons,
    required int numberOfSeasons,
    required int numberOfEpisodes,
    required List<dynamic> castList,
    required String? imdbId,
    required int tvId,
    required TrailerVideoModel? trailer,
    required bool isComingSoon,
  }) {
    final firstAirYear = firstAirDate.length >= 4
        ? firstAirDate.substring(0, 4)
        : '';

    return CustomScrollView(
      slivers: [
        // ── Widescreen Cinematic Header Canvas ──
        SliverToBoxAdapter(
          child: SizedBox(
            height: 480,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // High-Res Backdrop
                if (backdropPath != null || posterPath != null)
                  CachedNetworkImage(
                    imageUrl: ApiConstants.imageUrl(
                      backdropPath ?? posterPath,
                      size: ApiConstants.backdropOriginal,
                    ),
                    memCacheWidth: 1920,
                    fit: BoxFit.cover,
                  ),

                // Left-to-Right Dark Vignette
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      stops: const [0.0, 0.40, 0.70, 1.0],
                      colors: [
                        Colors.black.withValues(alpha: 0.95),
                        Colors.black.withValues(alpha: 0.82),
                        Colors.black.withValues(alpha: 0.25),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // Bottom Vignette blending into page background
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: const [0.0, 0.35, 1.0],
                      colors: [
                        AppColors.background,
                        AppColors.background.withValues(alpha: 0.75),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // Top Vignette for Back Button
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.25],
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // Back Button
                Positioned(
                  top: 24,
                  left: 36,
                  child: TvFocusable(
                    focusedScale: 1.1,
                    borderRadius: BorderRadius.circular(24),
                    onTap: () =>
                        context.canPop() ? context.pop() : context.go('/'),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),

                // Header Content Row (Poster Card + Desktop Info)
                Positioned(
                  left: 36,
                  right: 36,
                  bottom: 32,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1300),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Large Floating Poster Card (non-interactive)
                          Container(
                            width: 210,
                            height: 315,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  blurRadius: 28,
                                  offset: const Offset(0, 10),
                                ),
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.15,
                                  ),
                                  blurRadius: 36,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 1.2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: CachedNetworkImage(
                                imageUrl: ApiConstants.imageUrl(posterPath),
                                fit: BoxFit.cover,
                                placeholder: (_, _) =>
                                    Container(color: AppColors.surfaceVariant),
                              ),
                            ),
                          ),

                          const SizedBox(width: 32),

                          // Metadata & Action Buttons Column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Title
                                Text(
                                  name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.15,
                                    letterSpacing: -0.6,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                if (tagline.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    tagline,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.primaryLight,
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 12),

                                // Badges Row: Rating, Seasons/Episodes, Year, 4K
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.star.withValues(
                                          alpha: 0.18,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.star.withValues(
                                            alpha: 0.4,
                                          ),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.star_rounded,
                                            color: AppColors.star,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            voteAverage.toStringAsFixed(1),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const Text(
                                            ' / 10',
                                            style: TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        s.detailSeasonEpisodes(
                                          numberOfSeasons,
                                          numberOfEpisodes,
                                        ),
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (firstAirYear.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          firstAirYear,
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: const Text(
                                        '4K UHD',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // Genres
                                if (genres.isNotEmpty)
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: genres
                                        .map(
                                          (g) => Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceVariant
                                                  .withValues(alpha: 0.7),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: Colors.white.withValues(
                                                  alpha: 0.1,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              g,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),

                                const SizedBox(height: 18),

                                // Action Buttons Row (Widescreen wrap for safety)
                                // Action Buttons: 2-Row Layout
                                // Row 1: Watch Now + Watchlist (icon-only)
                                // Row 2: Trailer, Watch Party, Download, Share (all icon-only)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Watch Now (or Disabled "Segera Hadir" if unreleased)
                                        if (isComingSoon)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 14,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(
                                                alpha: 0.10,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: Colors.white.withValues(
                                                  alpha: 0.16,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.schedule_rounded,
                                                  color: AppColors.textMuted,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  s.detailComingSoon,
                                                  style:
                                                      GoogleFonts.plusJakartaSans(
                                                        color:
                                                            AppColors.textMuted,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        fontSize: 14,
                                                        letterSpacing: 0.2,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          )
                                        else
                                          TvFocusable(
                                            autofocus: true,
                                            focusedScale: 1.04,
                                            glowBlurRadius: 16,
                                            glowColor: AppColors.primary,
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            onTap: () => _playTvEpisode(
                                              context,
                                              name: name,
                                              episodeTitle:
                                                  'Season $_selectedSeasonNumber Episode 1',
                                              imdbId: imdbId,
                                              season: _selectedSeasonNumber,
                                              episode: 1,
                                              tvId: tvId,
                                              posterPath: posterPath,
                                              backdropPath: backdropPath,
                                              overview: overview,
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                    vertical: 14,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors.primary
                                                        .withValues(alpha: 0.4),
                                                    blurRadius: 18,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.play_arrow_rounded,
                                                    color: Colors.black,
                                                    size: 24,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    s.detailWatchTv(
                                                      _selectedSeasonNumber,
                                                      1,
                                                    ),
                                                    style:
                                                        GoogleFonts.plusJakartaSans(
                                                          color: Colors.black,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          fontSize: 14,
                                                          letterSpacing: 0.2,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        const SizedBox(width: 10),
                                        // Watchlist Icon-Only Button
                                        Consumer(
                                          builder: (context, ref, _) {
                                            final isInWatchlist = ref.watch(
                                              isInWatchlistProvider((
                                                id: tvId,
                                                type: 'tv',
                                              )),
                                            );
                                            return Tooltip(
                                              message: isInWatchlist
                                                  ? s.detailWatchlistRemoveTooltip
                                                  : s.detailWatchlistAddTooltip,
                                              child: TvFocusable(
                                                focusedScale: 1.04,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                onTap: () async {
                                                  final item = WatchlistItem(
                                                    id: tvId,
                                                    title: name,
                                                    posterPath: posterPath,
                                                    voteAverage: voteAverage,
                                                    type: 'tv',
                                                    addedAt: DateTime.now(),
                                                  );
                                                  final added = await ref
                                                      .read(
                                                        watchlistProvider
                                                            .notifier,
                                                      )
                                                      .toggle(item);
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          added
                                                              ? s.detailAddedToWatchlist
                                                              : s.detailRemovedFromWatchlist,
                                                        ),
                                                        backgroundColor:
                                                            AppColors
                                                                .surfaceVariant,
                                                        duration:
                                                            const Duration(
                                                              seconds: 2,
                                                            ),
                                                      ),
                                                    );
                                                  }
                                                },
                                                child: Container(
                                                  width: 48,
                                                  height: 48,
                                                  decoration: BoxDecoration(
                                                    color: isInWatchlist
                                                        ? AppColors.primary
                                                              .withValues(
                                                                alpha: 0.15,
                                                              )
                                                        : Colors.white
                                                              .withValues(
                                                                alpha: 0.12,
                                                              ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    border: Border.all(
                                                      color: isInWatchlist
                                                          ? AppColors.primary
                                                                .withValues(
                                                                  alpha: 0.6,
                                                                )
                                                          : Colors.white
                                                                .withValues(
                                                                  alpha: 0.2,
                                                                ),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Icon(
                                                    isInWatchlist
                                                        ? Icons.bookmark_rounded
                                                        : Icons
                                                              .bookmark_border_rounded,
                                                    color: isInWatchlist
                                                        ? AppColors.primary
                                                        : Colors.white,
                                                    size: 22,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    // Row 2: Secondary Icon-Only Buttons (Trailer, Watch Party, Download, Share)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (trailer != null) ...[
                                          Tooltip(
                                            message: s.trailerTitle,
                                            child: TvFocusable(
                                              focusedScale: 1.04,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              onTap: () {
                                                InAppTrailerModal.show(
                                                  context,
                                                  trailer: trailer,
                                                  title: name,
                                                  onWatchNow: () => _playTvEpisode(
                                                    context,
                                                    name: name,
                                                    episodeTitle:
                                                        'Season $_selectedSeasonNumber Episode 1',
                                                    imdbId: imdbId,
                                                    season:
                                                        _selectedSeasonNumber,
                                                    episode: 1,
                                                    tvId: tvId,
                                                    posterPath: posterPath,
                                                    backdropPath: backdropPath,
                                                    overview: overview,
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                width: 48,
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Colors.redAccent
                                                        .withValues(alpha: 0.5),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: const Icon(
                                                  Icons.smart_display_rounded,
                                                  color: Colors.redAccent,
                                                  size: 22,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                        ],
                                        // Watch Party Icon-Only
                                        Tooltip(
                                          message: s.watchPartyTitle,
                                          child: TvFocusable(
                                            focusedScale: 1.04,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            onTap: () {
                                              WatchPartyModal.show(
                                                context,
                                                media: WatchPartyMedia(
                                                  title: name,
                                                  mediaType: 'tv',
                                                  tmdbId: tvId,
                                                  imdbId: imdbId,
                                                  season: _selectedSeasonNumber,
                                                  episode: 1,
                                                  episodeTitle:
                                                      'Season $_selectedSeasonNumber Episode 1',
                                                  posterPath: posterPath,
                                                  backdropPath: backdropPath,
                                                ),
                                              );
                                            },
                                            child: Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(
                                                  alpha: 0.12,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: AppColors.primary
                                                      .withValues(alpha: 0.5),
                                                  width: 1,
                                                ),
                                              ),
                                              child: const Icon(
                                                Iconsax.people,
                                                color: AppColors.primary,
                                                size: 21,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (!isComingSoon) ...[
                                          const SizedBox(width: 10),
                                          Tooltip(
                                            message: s.navDownloads,
                                            child: TvFocusable(
                                              focusedScale: 1.04,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              onTap: () {
                                                DownloadOptionsModal.show(
                                                  context,
                                                  tmdbId: tvId,
                                                  mediaType: 'tv',
                                                  title: name,
                                                  releaseYear: firstAirYear,
                                                  season: _selectedSeasonNumber,
                                                  episode: 1,
                                                  posterPath: posterPath,
                                                  backdropPath: backdropPath,
                                                  imdbId: imdbId,
                                                  runtimeMinutes: 45,
                                                );
                                              },
                                              child: Container(
                                                width: 48,
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.2),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: const Icon(
                                                  Icons.download_rounded,
                                                  color: Colors.white,
                                                  size: 22,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(width: 10),
                                        // Share Deep-Link Icon-Only Button
                                        Tooltip(
                                          message: s.detailShareTooltip,
                                          child: TvFocusable(
                                            focusedScale: 1.04,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            onTap: () =>
                                                MediaShareService.shareMedia(
                                                  context,
                                                  mediaType: 'tv',
                                                  tmdbId: tvId,
                                                  title: name,
                                                  year: firstAirYear,
                                                  rating: voteAverage,
                                                  posterPath: posterPath,
                                                  overview: overview,
                                                  s: s,
                                                ),
                                            child: Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(
                                                  alpha: 0.12,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.2),
                                                  width: 1,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.share_rounded,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
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
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Below Header Sections (Constrained to 1300 max width) ──
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1300),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Synopsis
                    Text(
                      s.detailSynopsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Text(
                        overview.isNotEmpty ? overview : s.detailNoSynopsis,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          height: 1.6,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),

                    // TV Universe Banner
                    const SizedBox(height: 24),
                    TvUniverseBanner(
                      tvId: tvId,
                      posterPath: posterPath,
                      backdropPath: backdropPath,
                    ),

                    const SizedBox(height: 28),

                    // Season Selector
                    Text(
                      'Episode',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (seasons.isNotEmpty)
                      SizedBox(
                        height: 42,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: seasons.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final seasonItem = seasons[index];
                            final sNum =
                                seasonItem['season_number'] as int? ??
                                (index + 1);
                            final sTitle =
                                seasonItem['name'] as String? ?? 'Season $sNum';
                            final isSelected = sNum == _selectedSeasonNumber;

                            return TvFocusable(
                              focusedScale: 1.05,
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                setState(() => _selectedSeasonNumber = sNum);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.surfaceElevated,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    sTitle,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.black
                                          : Colors.white,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Widescreen 2-Column Episode Cards Grid
                    Consumer(
                      builder: (context, ref, _) {
                        final epAsync = ref.watch(
                          tvSeasonEpisodesProvider((
                            tvId: tvId,
                            seasonNumber: _selectedSeasonNumber,
                          )),
                        );

                        return epAsync.when(
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          error: (err, _) => Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Iconsax.info_circle,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    s.detailEpisodesUnavailable,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => ref.invalidate(
                                    tvSeasonEpisodesProvider((
                                      tvId: tvId,
                                      seasonNumber: _selectedSeasonNumber,
                                    )),
                                  ),
                                  child: Text(s.detailRetry),
                                ),
                              ],
                            ),
                          ),
                          data: (episodes) {
                            if (episodes.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(24),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  s.detailNoEpisodesInSeason(
                                    _selectedSeasonNumber,
                                  ),
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              );
                            }

                            return LayoutBuilder(
                              builder: (context, constraints) {
                                final cardWidth =
                                    (constraints.maxWidth - 20) / 2;
                                return Wrap(
                                  spacing: 20,
                                  runSpacing: 16,
                                  children: episodes.map((ep) {
                                    final epNum =
                                        ep['episode_number'] as int? ?? 1;
                                    final epName =
                                        ep['name'] as String? ??
                                        'Episode $epNum';
                                    final epStill = ep['still_path'] as String?;
                                    final epOverview =
                                        (ep['overview'] as String? ?? '')
                                            .trim();
                                    final epRuntime = ep['runtime'] as int?;
                                    final epAirDate =
                                        ep['air_date'] as String? ?? '';
                                    final isEpComingSoon =
                                        isComingSoon ||
                                        (epAirDate.isNotEmpty &&
                                            MediaReleaseGuard.isUnreleasedByMetadata(
                                              releaseDate: epAirDate,
                                            ));

                                    return SizedBox(
                                      width: cardWidth,
                                      child: TvFocusable(
                                        focusedScale: 1.02,
                                        glowBlurRadius: 12,
                                        borderRadius: BorderRadius.circular(14),
                                        onTap: isEpComingSoon
                                            ? null
                                            : () => _playTvEpisode(
                                                context,
                                                name: name,
                                                episodeTitle:
                                                    'S$_selectedSeasonNumber:E$epNum $epName',
                                                imdbId: imdbId,
                                                season: _selectedSeasonNumber,
                                                episode: epNum,
                                                tvId: tvId,
                                                posterPath: posterPath,
                                                backdropPath:
                                                    epStill ?? backdropPath,
                                                overview: epOverview.isNotEmpty
                                                    ? epOverview
                                                    : overview,
                                              ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceVariant
                                                .withValues(alpha: 0.55),
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.08,
                                              ),
                                              width: 1,
                                            ),
                                          ),
                                          padding: const EdgeInsets.all(10),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Episode Still Thumbnail
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    CachedNetworkImage(
                                                      imageUrl:
                                                          ApiConstants.imageUrl(
                                                            epStill,
                                                            size: ApiConstants
                                                                .backdropSmall,
                                                          ),
                                                      width: 140,
                                                      height: 80,
                                                      fit: BoxFit.cover,
                                                      placeholder: (_, _) =>
                                                          Container(
                                                            width: 140,
                                                            height: 80,
                                                            color: AppColors
                                                                .surfaceElevated,
                                                          ),
                                                      errorWidget: (_, _, _) =>
                                                          Container(
                                                            width: 140,
                                                            height: 80,
                                                            color: AppColors
                                                                .surfaceElevated,
                                                            child: const Icon(
                                                              Icons
                                                                  .movie_outlined,
                                                              color: AppColors
                                                                  .textMuted,
                                                              size: 28,
                                                            ),
                                                          ),
                                                    ),
                                                    Container(
                                                      width: 34,
                                                      height: 34,
                                                      decoration: BoxDecoration(
                                                        color: Colors.black
                                                            .withValues(
                                                              alpha: 0.65,
                                                            ),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(
                                                        Icons
                                                            .play_arrow_rounded,
                                                        color:
                                                            AppColors.primary,
                                                        size: 22,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              // Episode Info
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'E$epNum • $epName',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: GoogleFonts.inter(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        if (epRuntime != null &&
                                                            epRuntime > 0) ...[
                                                          Text(
                                                            '${epRuntime}m',
                                                            style: const TextStyle(
                                                              color: AppColors
                                                                  .primaryLight,
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                          const Text(
                                                            '  •  ',
                                                            style: TextStyle(
                                                              color: AppColors
                                                                  .textMuted,
                                                              fontSize: 10,
                                                            ),
                                                          ),
                                                        ],
                                                        if (epAirDate
                                                            .isNotEmpty)
                                                          Text(
                                                            epAirDate,
                                                            style: const TextStyle(
                                                              color: AppColors
                                                                  .textMuted,
                                                              fontSize: 11,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      epOverview.isNotEmpty
                                                          ? epOverview
                                                          : (overview.isNotEmpty
                                                                ? overview
                                                                : s.detailNoSynopsis),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        color: AppColors
                                                            .textSecondary,
                                                        fontSize: 11,
                                                        height: 1.3,
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
                                  }).toList(),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),

                    // Cast Section
                    if (castList.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      Text(
                        s.detailCast,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 152,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: castList.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            final cast = castList[index];
                            final profilePath = cast['profile_path'] as String?;
                            final castId = cast['id'] as int?;
                            return TvFocusable(
                              borderRadius: BorderRadius.circular(12),
                              scaleOnFocus: 1.06,
                              onTap: () {
                                if (castId != null) {
                                  context.push(
                                    '/person/$castId',
                                    extra: cast['name'] as String?,
                                  );
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: SizedBox(
                                  width: 88,
                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 36,
                                        backgroundColor:
                                            AppColors.surfaceVariant,
                                        backgroundImage: profilePath != null
                                            ? CachedNetworkImageProvider(
                                                ApiConstants.imageUrl(
                                                  profilePath,
                                                  size:
                                                      ApiConstants.posterSmall,
                                                ),
                                              )
                                            : null,
                                        child: profilePath == null
                                            ? const Icon(
                                                Icons.person,
                                                color: AppColors.textMuted,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        cast['name'] ?? '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        cast['character'] ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    BuildContext context, {
    required WidgetRef ref,
    required AppStrings s,
    required Map<String, dynamic> data,
    required String name,
    required String tagline,
    required String overview,
    required String? posterPath,
    required String? backdropPath,
    required double voteAverage,
    required List<String> genres,
    required String firstAirDate,
    required List<dynamic> seasons,
    required int numberOfSeasons,
    required int numberOfEpisodes,
    required List<dynamic> castList,
    required String? imdbId,
    required int tvId,
    required TrailerVideoModel? trailer,
    required bool isCompact,
    required bool isComingSoon,
  }) {
    final posterWidth = isCompact ? 100.0 : 120.0;
    final posterHeight = isCompact ? 150.0 : 180.0;

    return CustomScrollView(
      slivers: [
        // ── Hero Backdrop with Cinematic Gradient ──
        SliverAppBar(
          expandedHeight: isCompact ? 240 : 280,
          pinned: true,
          backgroundColor: AppColors.background,
          leading: IconButton(
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (backdropPath != null)
                  CachedNetworkImage(
                    imageUrl: ApiConstants.imageUrl(
                      backdropPath,
                      size: ApiConstants.backdropLarge,
                    ),
                    fit: BoxFit.cover,
                  ),
                // Seamless gradient fade to pure black background
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        AppColors.background.withValues(alpha: 0.65),
                        AppColors.background,
                      ],
                      stops: const [0.0, 0.35, 0.72, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Poster + Info Row with Elevated Shadow ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.65),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: ApiConstants.imageUrl(posterPath),
                          width: posterWidth,
                          height: posterHeight,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(
                            width: posterWidth,
                            height: posterHeight,
                            color: AppColors.surfaceVariant,
                          ),
                        ),
                      ),
                    ).animate().fadeIn().slideY(begin: 0.1),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(
                                  fontSize: isCompact ? 21 : 24,
                                  letterSpacing: -0.3,
                                ),
                            maxLines: 3,
                          ),
                          if (tagline.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              tagline,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.primary,
                                  ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: AppColors.star,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                voteAverage.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const Text(
                                ' / 10',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            s.detailSeasonEpisodes(
                              numberOfSeasons,
                              numberOfEpisodes,
                            ),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          if (firstAirDate.length >= 4) ...[
                            const SizedBox(height: 4),
                            Text(
                              firstAirDate.substring(0, 4),
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Genres ──
                if (genres.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: genres
                        .map(
                          (g) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Text(
                              g,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),

                const SizedBox(height: 20),

                // ── Action Rows (2-Row Layout):
                // Row 1: Watch Now (or Disabled "Segera Hadir") + Watchlist (Icon-Only)
                // Row 2: Trailer, Watch Party, Download, Share (All Icon-Only) ──
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isComingSoon
                            ? null
                            : () => _playTvEpisode(
                                context,
                                name: name,
                                episodeTitle:
                                    'Season $_selectedSeasonNumber Episode 1',
                                imdbId: imdbId,
                                season: _selectedSeasonNumber,
                                episode: 1,
                                tvId: tvId,
                                posterPath: posterPath,
                                backdropPath: backdropPath,
                                overview: overview,
                              ),
                        icon: Icon(
                          isComingSoon
                              ? Icons.schedule_rounded
                              : Icons.play_arrow_rounded,
                          size: isComingSoon ? 22 : 28,
                          color: isComingSoon
                              ? AppColors.textMuted
                              : Colors.black,
                        ),
                        label: Text(
                          isComingSoon
                              ? s.detailComingSoon
                              : s.detailWatchTv(_selectedSeasonNumber, 1),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isComingSoon
                                ? AppColors.textMuted
                                : Colors.black,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.surfaceVariant,
                          disabledForegroundColor: AppColors.textMuted,
                          elevation: isComingSoon ? 0 : 6,
                          shadowColor: AppColors.primary.withValues(alpha: 0.4),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Watchlist Icon-Only Button
                    Consumer(
                      builder: (context, ref, _) {
                        final mediaId = data['id'] as int? ?? 0;
                        final isInWatchlist = ref.watch(
                          isInWatchlistProvider((id: mediaId, type: 'tv')),
                        );
                        return Tooltip(
                          message: isInWatchlist
                              ? s.detailWatchlistRemoveTooltip
                              : s.detailWatchlistAddTooltip,
                          child: InkWell(
                            onTap: () async {
                              final item = WatchlistItem(
                                id: mediaId,
                                title: name,
                                posterPath: posterPath,
                                voteAverage: voteAverage,
                                type: 'tv',
                                addedAt: DateTime.now(),
                              );
                              final added = await ref
                                  .read(watchlistProvider.notifier)
                                  .toggle(item);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      added
                                          ? s.detailAddedToWatchlist
                                          : s.detailRemovedFromWatchlist,
                                    ),
                                    backgroundColor: AppColors.surfaceVariant,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant.withValues(
                                  alpha: 0.6,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isInWatchlist
                                      ? AppColors.primary.withValues(alpha: 0.6)
                                      : Colors.white.withValues(alpha: 0.12),
                                  width: 1.5,
                                ),
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                transitionBuilder: (child, anim) =>
                                    ScaleTransition(scale: anim, child: child),
                                child: Icon(
                                  isInWatchlist
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_border_rounded,
                                  key: ValueKey(isInWatchlist),
                                  color: isInWatchlist
                                      ? AppColors.primary
                                      : Colors.white,
                                  size: 26,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                const SizedBox(height: 10),

                // ── Row 2: Secondary Icon-Only Buttons (Trailer, Watch Party, Download, Share) ──
                Row(
                  children: [
                    if (trailer != null) ...[
                      Expanded(
                        child: Tooltip(
                          message: s.trailerTitle,
                          child: InkWell(
                            onTap: () {
                              InAppTrailerModal.show(
                                context,
                                trailer: trailer,
                                title: name,
                                onWatchNow: () => _playTvEpisode(
                                  context,
                                  name: name,
                                  episodeTitle:
                                      'Season $_selectedSeasonNumber Episode 1',
                                  imdbId: imdbId,
                                  season: _selectedSeasonNumber,
                                  episode: 1,
                                  tvId: tvId,
                                  posterPath: posterPath,
                                  backdropPath: backdropPath,
                                  overview: overview,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant.withValues(
                                  alpha: 0.6,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.redAccent.withValues(
                                    alpha: 0.5,
                                  ),
                                  width: 1.2,
                                ),
                              ),
                              child: const Icon(
                                Icons.smart_display_rounded,
                                color: Colors.redAccent,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    // Watch Party Icon-Only Button
                    Expanded(
                      child: Tooltip(
                        message: s.watchPartyTitle,
                        child: InkWell(
                          onTap: () {
                            WatchPartyModal.show(
                              context,
                              media: WatchPartyMedia(
                                title: name,
                                mediaType: 'tv',
                                tmdbId: tvId,
                                imdbId: imdbId,
                                season: _selectedSeasonNumber,
                                episode: 1,
                                episodeTitle:
                                    'Season $_selectedSeasonNumber Episode 1',
                                posterPath: posterPath,
                                backdropPath: backdropPath,
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant.withValues(
                                alpha: 0.6,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.14),
                                width: 1.2,
                              ),
                            ),
                            child: const Icon(
                              Iconsax.people,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (!isComingSoon) ...[
                      const SizedBox(width: 10),
                      // Download Icon-Only Button
                      Expanded(
                        child: Tooltip(
                          message: s.navDownloads,
                          child: InkWell(
                            onTap: () {
                              final firstAirYear = firstAirDate.length >= 4
                                  ? firstAirDate.substring(0, 4)
                                  : '';
                              DownloadOptionsModal.show(
                                context,
                                tmdbId: tvId,
                                mediaType: 'tv',
                                title: name,
                                releaseYear: firstAirYear,
                                season: _selectedSeasonNumber,
                                episode: 1,
                                posterPath: posterPath,
                                backdropPath: backdropPath,
                                imdbId: imdbId,
                                runtimeMinutes: 45,
                              );
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant.withValues(
                                  alpha: 0.6,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  width: 1.2,
                                ),
                              ),
                              child: const Icon(
                                Icons.download_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 10),
                    // Share Deep-Link Icon-Only Button
                    Expanded(
                      child: Tooltip(
                        message: s.detailShareTooltip,
                        child: InkWell(
                          onTap: () {
                            final firstAirYear = firstAirDate.length >= 4
                                ? firstAirDate.substring(0, 4)
                                : '';
                            MediaShareService.shareMedia(
                              context,
                              mediaType: 'tv',
                              tmdbId: tvId,
                              title: name,
                              year: firstAirYear,
                              rating: voteAverage,
                              posterPath: posterPath,
                              overview: overview,
                              s: s,
                            );
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant.withValues(
                                alpha: 0.6,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.14),
                                width: 1.2,
                              ),
                            ),
                            child: const Icon(
                              Icons.share_rounded,
                              color: Colors.white,
                              size: 21,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 240.ms).slideY(begin: 0.1),

                const SizedBox(height: 24),

                // ── Synopsis ──
                Text(
                  s.detailSynopsis,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  overview.isNotEmpty ? overview : s.detailNoSynopsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.6),
                ),

                // ── TV Universe / Watch Order Hub ──
                TvUniverseBanner(
                  tvId: tvId,
                  posterPath: posterPath,
                  backdropPath: backdropPath,
                ),

                // ── Interactive Episode Selector Section ──
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Iconsax.video_play,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          s.detailSelectEpisode,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                    Text(
                      '${s.detailSeason} $_selectedSeasonNumber',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Season Selector Tabs / Chips
                if (seasons.isNotEmpty)
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: seasons.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final s = seasons[index];
                        final sNum = s['season_number'] as int? ?? (index + 1);
                        final sTitle = s['name'] as String? ?? 'Season $sNum';
                        final isSelected = sNum == _selectedSeasonNumber;

                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedSeasonNumber = sNum);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.surfaceElevated,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                sTitle,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.white,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 16),

                // Episodes List for Selected Season
                Consumer(
                  builder: (context, ref, _) {
                    final epAsync = ref.watch(
                      tvSeasonEpisodesProvider((
                        tvId: tvId,
                        seasonNumber: _selectedSeasonNumber,
                      )),
                    );

                    return epAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      error: (err, _) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Iconsax.info_circle,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                s.detailEpisodesUnavailable,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => ref.invalidate(
                                tvSeasonEpisodesProvider((
                                  tvId: tvId,
                                  seasonNumber: _selectedSeasonNumber,
                                )),
                              ),
                              child: Text(s.detailRetry),
                            ),
                          ],
                        ),
                      ),
                      data: (episodes) {
                        if (episodes.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(20),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              s.detailNoEpisodesInSeason(_selectedSeasonNumber),
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: episodes.length,
                          separatorBuilder: (_, _) => Divider(
                            color: Colors.white.withValues(alpha: 0.08),
                            height: 1,
                            thickness: 0.8,
                          ),
                          itemBuilder: (context, epIdx) {
                            final ep = episodes[epIdx];
                            final epNum =
                                ep['episode_number'] as int? ?? (epIdx + 1);
                            final epName =
                                ep['name'] as String? ?? 'Episode $epNum';
                            final epStill = ep['still_path'] as String?;
                            final epOverview = (ep['overview'] as String? ?? '')
                                .trim();
                            final epRuntime = ep['runtime'] as int?;
                            final epAirDate = ep['air_date'] as String? ?? '';
                            final isEpComingSoon =
                                isComingSoon ||
                                (epAirDate.isNotEmpty &&
                                    MediaReleaseGuard.isUnreleasedByMetadata(
                                      releaseDate: epAirDate,
                                    ));

                            return TvFocusable(
                              borderRadius: BorderRadius.circular(8),
                              scaleOnFocus: 1.01,
                              onTap: isEpComingSoon
                                  ? null
                                  : () => _playTvEpisode(
                                      context,
                                      name: name,
                                      episodeTitle:
                                          'S$_selectedSeasonNumber:E$epNum $epName',
                                      imdbId: imdbId,
                                      season: _selectedSeasonNumber,
                                      episode: epNum,
                                      tvId: tvId,
                                      posterPath: posterPath,
                                      backdropPath:
                                          (ep['still_path'] as String?) ??
                                          backdropPath,
                                      overview: epOverview.isNotEmpty
                                          ? epOverview
                                          : overview,
                                    ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 4,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Clean Episode Thumbnail with subtle badge
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Stack(
                                        children: [
                                          CachedNetworkImage(
                                            imageUrl: ApiConstants.imageUrl(
                                              epStill,
                                              size: ApiConstants.backdropSmall,
                                            ),
                                            width: 116,
                                            height: 74,
                                            fit: BoxFit.cover,
                                            placeholder: (_, _) => Container(
                                              width: 116,
                                              height: 74,
                                              color: AppColors.surface,
                                            ),
                                            errorWidget: (_, _, _) => Container(
                                              width: 116,
                                              height: 74,
                                              color: AppColors.surface,
                                              child: const Icon(
                                                Icons.tv_rounded,
                                                color: AppColors.textMuted,
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                          Positioned.fill(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Colors.transparent,
                                                    Colors.black.withValues(
                                                      alpha: 0.65,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 4,
                                            left: 6,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(
                                                  alpha: 0.8,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: AppColors.primary
                                                      .withValues(alpha: 0.5),
                                                  width: 0.6,
                                                ),
                                              ),
                                              child: Text(
                                                'EP $epNum',
                                                style: const TextStyle(
                                                  color: AppColors.primary,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    // Episode Details & Synopsis
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$epNum. $epName',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              if (epRuntime != null &&
                                                  epRuntime > 0)
                                                Text(
                                                  '$epRuntime ${s.isIndonesian ? 'mnt' : 'min'}',
                                                  style: const TextStyle(
                                                    color:
                                                        AppColors.textSecondary,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              if (epRuntime != null &&
                                                  epRuntime > 0 &&
                                                  epAirDate.isNotEmpty)
                                                const Text(
                                                  ' • ',
                                                  style: TextStyle(
                                                    color: AppColors.textMuted,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              if (epAirDate.isNotEmpty)
                                                Text(
                                                  epAirDate,
                                                  style: const TextStyle(
                                                    color: AppColors.textMuted,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            epOverview.isNotEmpty
                                                ? epOverview
                                                : (overview.isNotEmpty
                                                      ? overview
                                                      : s.detailNoSynopsis),
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.65,
                                              ),
                                              fontSize: 12,
                                              height: 1.35,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    // Episode Action Buttons: Download & Play (or Disabled "Segera Hadir" badge)
                                    if (isEpComingSoon)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.08,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.14,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          s.detailComingSoon,
                                          style: GoogleFonts.inter(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      )
                                    else
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                            visualDensity:
                                                VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(
                                              minWidth: 32,
                                              minHeight: 32,
                                            ),
                                            onPressed: () {
                                              DownloadOptionsModal.show(
                                                context,
                                                tmdbId: tvId,
                                                mediaType: 'tv',
                                                title: name,
                                                season: _selectedSeasonNumber,
                                                episode: epNum,
                                                episodeTitle: epName,
                                                posterPath: posterPath,
                                                episodeStillPath: epStill,
                                                backdropPath: backdropPath,
                                                imdbId: imdbId,
                                                runtimeMinutes: epRuntime ?? 45,
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.download_rounded,
                                              size: 20,
                                              color: AppColors.primary,
                                            ),
                                            tooltip: s.detailDownloadEpisode(
                                              epNum,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.15),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.4),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.play_arrow_rounded,
                                              color: AppColors.primary,
                                              size: 18,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),

                // ── Cast ──
                if (castList.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Text(
                    s.detailCast,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 142,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: castList.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final cast = castList[index];
                        final profilePath = cast['profile_path'] as String?;
                        final castId = cast['id'] as int?;
                        return TvFocusable(
                          borderRadius: BorderRadius.circular(12),
                          scaleOnFocus: 1.06,
                          onTap: () {
                            if (castId != null) {
                              context.push(
                                '/person/$castId',
                                extra: cast['name'] as String?,
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: SizedBox(
                              width: 80,
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 35,
                                    backgroundColor: AppColors.surfaceVariant,
                                    backgroundImage: profilePath != null
                                        ? CachedNetworkImageProvider(
                                            ApiConstants.imageUrl(
                                              profilePath,
                                              size: ApiConstants.posterSmall,
                                            ),
                                          )
                                        : null,
                                    child: profilePath == null
                                        ? const Icon(
                                            Icons.person,
                                            color: AppColors.textMuted,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    cast['name'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    cast['character'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
