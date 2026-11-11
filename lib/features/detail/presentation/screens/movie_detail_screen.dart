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
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../shared/widgets/tv_focusable.dart';
import '../widgets/in_app_trailer_modal.dart';
import '../../data/models/trailer_video_model.dart';
import '../../../collection/presentation/widgets/franchise_collection_banner.dart';
import '../../../../core/platform/device_form_factor.dart';

// ── Detail Providers ──

final movieDetailProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, movieId) async {
  final lang = ref.watch(appLanguageProvider);
  final tmdbLang = lang == AppLanguage.en ? 'en-US' : 'id-ID';
  final dio = DioClient.createTmdbClient();
  final response = await dio.get('/movie/$movieId', queryParameters: {
    'language': tmdbLang,
    'append_to_response': 'credits,external_ids,similar,videos',
  });
  final data = Map<String, dynamic>.from(response.data as Map);
  final overview = (data['overview'] as String? ?? '').trim();
  if (overview.isEmpty) {
    try {
      final fallbackLang = tmdbLang == 'id-ID' ? 'en-US' : 'id-ID';
      final fbResponse = await dio.get('/movie/$movieId', queryParameters: {
        'language': fallbackLang,
      });
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
      final vResponse = await dio.get('/movie/$movieId/videos', queryParameters: {
        'language': 'en-US',
      });
      data['videos'] = vResponse.data;
    } catch (_) {}
  }

  return data;
});

/// Movie detail screen displaying full backdrop, info, cast, and play button.
class MovieDetailScreen extends ConsumerWidget {
  final int movieId;
  const MovieDetailScreen({super.key, required this.movieId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final detail = ref.watch(movieDetailProvider(movieId));

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
          data: (data) => _DetailContent(data: data),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.warning_2, size: 48, color: AppColors.textMuted),
                const SizedBox(height: 16),
                Text(s.detailFailed, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(movieDetailProvider(movieId)),
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

class _DetailContent extends ConsumerWidget {
  final Map<String, dynamic> data;
  const _DetailContent({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final title = data['title'] ?? '';
    final overview = data['overview'] ?? '';
    final backdropPath = data['backdrop_path'] as String?;
    final posterPath = data['poster_path'] as String?;
    final voteAverage = (data['vote_average'] as num?)?.toDouble() ?? 0.0;
    final releaseDate = data['release_date'] as String? ?? '';
    final runtime = data['runtime'] as int? ?? 0;
    final genres = (data['genres'] as List<dynamic>?)?.map((g) => g['name'] as String).toList() ?? [];
    final tagline = data['tagline'] as String? ?? '';
    final imdbId = data['external_ids']?['imdb_id'] as String?;
    final trailer = TrailerVideoModel.findBestTrailer(data['videos']);
    final belongsToCollection = data['belongs_to_collection'] as Map<String, dynamic>?;

    // Cast
    final castList = (data['credits']?['cast'] as List<dynamic>?)?.take(10).toList() ?? [];

    // Similar movies
    final similarList = (data['similar']?['results'] as List<dynamic>?)?.take(10).toList() ?? [];

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
        title: title,
        tagline: tagline,
        overview: overview,
        releaseDate: releaseDate,
        runtime: runtime,
        voteAverage: voteAverage,
        genres: genres,
        posterPath: posterPath,
        backdropPath: backdropPath,
        belongsToCollection: belongsToCollection,
        castList: castList,
        similarList: similarList,
        trailer: trailer,
        imdbId: imdbId,
      );
    }

    return _buildMobileLayout(
      context,
      ref: ref,
      s: s,
      data: data,
      title: title,
      tagline: tagline,
      overview: overview,
      releaseDate: releaseDate,
      runtime: runtime,
      voteAverage: voteAverage,
      genres: genres,
      posterPath: posterPath,
      backdropPath: backdropPath,
      belongsToCollection: belongsToCollection,
      castList: castList,
      similarList: similarList,
      trailer: trailer,
      imdbId: imdbId,
      isCompact: isCompact,
    );
  }

  static Future<void> _playMovie(
    BuildContext context, {
    required String title,
    required String? imdbId,
    required Map<String, dynamic> data,
    required String overview,
  }) async {
    await context.push('/player', extra: {
      'title': title,
      'imdbId': imdbId,
      'tmdbId': data['id'] as int?,
      'mediaType': 'movie',
      'posterPath': data['poster_path'] as String?,
      'backdropPath': data['backdrop_path'] as String?,
      'overview': overview,
      'magnetLink': '',
    });
    await restoreSystemUiAndOrientations(isTv: gIsTv);
  }

  Widget _buildDesktopLayout(
    BuildContext context, {
    required WidgetRef ref,
    required AppStrings s,
    required Map<String, dynamic> data,
    required String title,
    required String tagline,
    required String overview,
    required String releaseDate,
    required int runtime,
    required double voteAverage,
    required List<String> genres,
    required String? posterPath,
    required String? backdropPath,
    required Map<String, dynamic>? belongsToCollection,
    required List<dynamic> castList,
    required List<dynamic> similarList,
    required TrailerVideoModel? trailer,
    required String? imdbId,
  }) {
    final mediaId = data['id'] as int? ?? 0;
    final releaseYear = releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '';

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
                    onTap: () => context.canPop() ? context.pop() : context.go('/'),
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
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
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
                                  color: AppColors.primary.withValues(alpha: 0.15),
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
                                placeholder: (_, _) => Container(color: AppColors.surfaceVariant),
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
                                  title,
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

                                // Badges Row: Rating, Year, Duration, 4K
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.star.withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.star.withValues(alpha: 0.4),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star_rounded, color: AppColors.star, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            voteAverage.toStringAsFixed(1),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const Text(' / 10', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                    if (releaseYear.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          releaseYear,
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                    if (runtime > 0) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${runtime ~/ 60}${s.isIndonesian ? 'j' : 'h'} ${runtime % 60}m',
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 0.8),
                                      ),
                                      child: const Text('4K UHD', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
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
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceVariant.withValues(alpha: 0.7),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                            ),
                                            child: Text(g, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                          ),
                                        )
                                        .toList(),
                                  ),

                                const SizedBox(height: 18),

                                // Action Buttons Row (Widescreen wrap for safety)
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 10,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    // Watch Now
                                    TvFocusable(
                                      autofocus: true,
                                      focusedScale: 1.04,
                                      glowBlurRadius: 16,
                                      glowColor: AppColors.primary,
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: () => _playMovie(context, title: title, imdbId: imdbId, data: data, overview: overview),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(14),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primary.withValues(alpha: 0.4),
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
                                              s.detailWatchNow,
                                              style: GoogleFonts.plusJakartaSans(
                                                color: Colors.black,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    if (trailer != null)
                                      TvFocusable(
                                        focusedScale: 1.04,
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () {
                                          InAppTrailerModal.show(
                                            context,
                                            trailer: trailer,
                                            title: title,
                                            onWatchNow: () => _playMovie(context, title: title, imdbId: imdbId, data: data, overview: overview),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5), width: 1),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.smart_display_rounded, color: Colors.redAccent, size: 20),
                                              const SizedBox(width: 8),
                                              Text(
                                                s.trailerTitle,
                                                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                    // Watchlist Button
                                    Consumer(
                                      builder: (context, ref, _) {
                                        final isInWatchlist = ref.watch(
                                          isInWatchlistProvider((id: mediaId, type: 'movie')),
                                        );
                                        return TvFocusable(
                                          focusedScale: 1.04,
                                          borderRadius: BorderRadius.circular(12),
                                          onTap: () async {
                                            final item = WatchlistItem(
                                              id: mediaId,
                                              title: title,
                                              posterPath: posterPath,
                                              voteAverage: voteAverage,
                                              type: 'movie',
                                              addedAt: DateTime.now(),
                                            );
                                            final added = await ref.read(watchlistProvider.notifier).toggle(item);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(added ? s.detailAddedToWatchlist : s.detailRemovedFromWatchlist),
                                                  backgroundColor: AppColors.surfaceVariant,
                                                  duration: const Duration(seconds: 2),
                                                ),
                                              );
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                                            decoration: BoxDecoration(
                                              color: isInWatchlist
                                                  ? AppColors.primary.withValues(alpha: 0.15)
                                                  : Colors.white.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isInWatchlist
                                                    ? AppColors.primary.withValues(alpha: 0.6)
                                                    : Colors.white.withValues(alpha: 0.2),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isInWatchlist ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                                  color: isInWatchlist ? AppColors.primary : Colors.white,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Watchlist',
                                                  style: GoogleFonts.inter(
                                                    color: isInWatchlist ? AppColors.primary : Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),

                                    // Download Button
                                    TvFocusable(
                                      focusedScale: 1.04,
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () {
                                        DownloadOptionsModal.show(
                                          context,
                                          tmdbId: mediaId,
                                          mediaType: 'movie',
                                          title: title,
                                          releaseYear: releaseYear,
                                          posterPath: posterPath,
                                          backdropPath: backdropPath,
                                          imdbId: imdbId,
                                          runtimeMinutes: runtime > 0 ? runtime : 100,
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.download_rounded, color: Colors.white, size: 20),
                                            const SizedBox(width: 8),
                                            Text(
                                              s.detailDownloadMovie,
                                              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                            ),
                                          ],
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
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
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
                        style: GoogleFonts.inter(fontSize: 15, height: 1.6, color: AppColors.textSecondary),
                      ),
                    ),

                    // Franchise Collection Banner
                    if (belongsToCollection != null) ...[
                      const SizedBox(height: 24),
                      FranchiseCollectionBanner(
                        collection: belongsToCollection,
                        callerPosterPath: data['poster_path'] as String?,
                        callerBackdropPath: data['backdrop_path'] as String?,
                      ),
                    ],

                    // Cast Section
                    if (castList.isNotEmpty) ...[
                      const SizedBox(height: 28),
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
                                  context.push('/person/$castId', extra: cast['name'] as String?);
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
                                        backgroundColor: AppColors.surfaceVariant,
                                        backgroundImage: profilePath != null
                                            ? CachedNetworkImageProvider(
                                                ApiConstants.imageUrl(profilePath, size: ApiConstants.posterSmall),
                                              )
                                            : null,
                                        child: profilePath == null ? const Icon(Icons.person, color: AppColors.textMuted) : null,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        cast['name'] ?? '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                      ),
                                      Text(
                                        cast['character'] ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
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

                    // Similar Movies
                    if (similarList.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      Text(
                        s.detailSimilarMovies,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 220,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: similarList.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 14),
                          itemBuilder: (context, index) {
                            final similar = similarList[index];
                            final sId = similar['id'] as int;
                            final sPoster = similar['poster_path'] as String?;
                            final sTitle = similar['title'] as String? ?? '';
                            final sRating = (similar['vote_average'] as num?)?.toDouble() ?? 0.0;
                            return TvFocusable(
                              focusedScale: 1.11,
                              glowBlurRadius: 16,
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => context.push('/movie/$sId'),
                              child: SizedBox(
                                width: 130,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: CachedNetworkImage(
                                          imageUrl: ApiConstants.imageUrl(sPoster),
                                          fit: BoxFit.cover,
                                          width: 130,
                                          placeholder: (_, _) => Container(color: AppColors.surfaceVariant),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(sTitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, size: 12, color: AppColors.star),
                                        const SizedBox(width: 3),
                                        Text(sRating.toStringAsFixed(1),
                                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                      ],
                                    ),
                                  ],
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
    required String title,
    required String tagline,
    required String overview,
    required String releaseDate,
    required int runtime,
    required double voteAverage,
    required List<String> genres,
    required String? posterPath,
    required String? backdropPath,
    required Map<String, dynamic>? belongsToCollection,
    required List<dynamic> castList,
    required List<dynamic> similarList,
    required TrailerVideoModel? trailer,
    required String? imdbId,
    required bool isCompact,
  }) {
    final posterWidth = isCompact ? 100.0 : 120.0;
    final posterHeight = isCompact ? 150.0 : 180.0;

    return CustomScrollView(
      slivers: [
        // ── Hero Backdrop with Cinematic Gradient ──
        SliverAppBar(
          expandedHeight: isCompact ? 250 : 300,
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
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (backdropPath != null)
                  CachedNetworkImage(
                    imageUrl: ApiConstants.imageUrl(backdropPath, size: ApiConstants.backdropLarge),
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
                    // Poster with subtle ambient glow & shadow
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
                    ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                    const SizedBox(width: 14),

                    // Title & meta
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontSize: isCompact ? 21 : 24,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (tagline.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              tagline,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.primary,
                                  ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          // Rating
                          Row(
                            children: [
                              const Icon(Icons.star, color: AppColors.star, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                voteAverage.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Text(' / 10', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Year & Runtime
                          Row(
                            children: [
                              if (releaseDate.length >= 4)
                                Text(
                                  releaseDate.substring(0, 4),
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                ),
                              if (runtime > 0) ...[
                                const Text('  •  ', style: TextStyle(color: AppColors.textMuted)),
                                Text(
                                  '${runtime ~/ 60}${s.isIndonesian ? 'j' : 'h'} ${runtime % 60}m',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Genre Chips ──
                if (genres.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: genres
                        .map(
                          (g) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Text(g, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ),
                        )
                        .toList(),
                  ),

                const SizedBox(height: 20),

                // ── Action Row: Watch Now, Trailer & Watchlist ──
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _playMovie(
                          context,
                          title: title,
                          imdbId: imdbId,
                          data: data,
                          overview: overview,
                        ),
                        icon: const Icon(
                          Icons.play_arrow_rounded,
                          size: 28,
                          color: Colors.black,
                        ),
                        label: Text(
                          s.detailWatchNow,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                            letterSpacing: 0.2,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 6,
                          shadowColor: AppColors.primary.withValues(alpha: 0.4),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    if (trailer != null) ...[
                      const SizedBox(width: 10),
                      Tooltip(
                        message: s.trailerTitle,
                        child: InkWell(
                          onTap: () {
                            InAppTrailerModal.show(
                              context,
                              trailer: trailer,
                              title: title,
                              onWatchNow: () => _playMovie(
                                context,
                                title: title,
                                imdbId: imdbId,
                                data: data,
                                overview: overview,
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.redAccent.withValues(alpha: 0.6),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.smart_display_rounded,
                              color: Colors.redAccent,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 10),
                    // Watchlist Button (Outlined when not added, Filled icon when added)
                    Consumer(
                      builder: (context, ref, _) {
                        final mediaId = data['id'] as int? ?? 0;
                        final isInWatchlist = ref.watch(
                          isInWatchlistProvider((id: mediaId, type: 'movie')),
                        );
                        return Tooltip(
                          message: isInWatchlist ? s.detailWatchlistRemoveTooltip : s.detailWatchlistAddTooltip,
                          child: InkWell(
                            onTap: () async {
                              final item = WatchlistItem(
                                id: mediaId,
                                title: title,
                                posterPath: posterPath,
                                voteAverage: voteAverage,
                                type: 'movie',
                                addedAt: DateTime.now(),
                              );
                              final added = await ref.read(watchlistProvider.notifier).toggle(item);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(added ? s.detailAddedToWatchlist : s.detailRemovedFromWatchlist),
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
                                color: AppColors.surfaceVariant.withValues(alpha: 0.6),
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
                                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                                child: Icon(
                                  isInWatchlist ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                  key: ValueKey(isInWatchlist),
                                  color: isInWatchlist ? AppColors.primary : Colors.white,
                                  size: 26,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 12),

                // ── Download Button ──
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final releaseYear = releaseDate.length >= 4 ? releaseDate.substring(0, 4) : '';
                      DownloadOptionsModal.show(
                        context,
                        tmdbId: data['id'] as int? ?? 0,
                        mediaType: 'movie',
                        title: title,
                        releaseYear: releaseYear,
                        posterPath: posterPath,
                        backdropPath: backdropPath,
                        imdbId: imdbId,
                        runtimeMinutes: runtime > 0 ? runtime : 100,
                      );
                    },
                    icon: const Icon(Icons.download_rounded, size: 22, color: AppColors.primary),
                    label: Text(
                      s.detailDownloadMovie,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Synopsis ──
                Text(s.detailSynopsis, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  overview.isNotEmpty ? overview : s.detailNoSynopsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
                ),

                // ── Franchise / Collection Hub ──
                if (belongsToCollection != null)
                  FranchiseCollectionBanner(
                    collection: belongsToCollection,
                    callerPosterPath: data['poster_path'] as String?,
                    callerBackdropPath: data['backdrop_path'] as String?,
                  ),

                // ── Cast ──
                if (castList.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(s.detailCast, style: Theme.of(context).textTheme.headlineMedium),
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
                              context.push('/person/$castId', extra: cast['name'] as String?);
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
                                            ApiConstants.imageUrl(profilePath, size: ApiConstants.posterSmall),
                                          )
                                        : null,
                                    child: profilePath == null
                                        ? const Icon(Icons.person, color: AppColors.textMuted)
                                        : null,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    cast['name'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                                  ),
                                  Text(
                                    cast['character'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
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

                // ── Similar Movies ──
                if (similarList.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(s.detailSimilarMovies, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 205,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: similarList.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final similar = similarList[index];
                        final sId = similar['id'] as int;
                        final sPoster = similar['poster_path'] as String?;
                        final sTitle = similar['title'] as String? ?? '';
                        final sRating = (similar['vote_average'] as num?)?.toDouble() ?? 0.0;
                        return TvFocusable(
                          borderRadius: BorderRadius.circular(12),
                          scaleOnFocus: 1.05,
                          onTap: () => context.push('/movie/$sId'),
                          child: SizedBox(
                            width: 130,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: ApiConstants.imageUrl(sPoster),
                                      fit: BoxFit.cover,
                                      width: 130,
                                      placeholder: (_, _) => Container(color: AppColors.surfaceVariant),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(sTitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                                Row(
                                  children: [
                                    const Icon(Icons.star, size: 11, color: AppColors.star),
                                    const SizedBox(width: 2),
                                    Text(sRating.toStringAsFixed(1),
                                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                  ],
                                ),
                              ],
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
