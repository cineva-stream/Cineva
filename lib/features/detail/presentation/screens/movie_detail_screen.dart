import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../watchlist/data/watchlist_repository.dart';
import '../../../download/presentation/widgets/download_options_modal.dart';

// ── Detail Providers ──

final movieDetailProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, movieId) async {
  final dio = DioClient.createTmdbClient();
  final response = await dio.get('/movie/$movieId', queryParameters: {
    'language': 'id-ID',
    'append_to_response': 'credits,external_ids,similar',
  });
  return response.data;
});

/// Movie detail screen displaying full backdrop, info, cast, and play button.
class MovieDetailScreen extends ConsumerWidget {
  final int movieId;
  const MovieDetailScreen({super.key, required this.movieId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(movieDetailProvider(movieId));

    return Scaffold(
      body: detail.when(
        data: (data) => _DetailContent(data: data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Iconsax.warning_2, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text('Gagal memuat detail', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(movieDetailProvider(movieId)),
                child: const Text('Coba Lagi'),
              ),
            ],
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

    // Cast
    final castList = (data['credits']?['cast'] as List<dynamic>?)?.take(10).toList() ?? [];

    // Similar movies
    final similarList = (data['similar']?['results'] as List<dynamic>?)?.take(10).toList() ?? [];

    return CustomScrollView(
      slivers: [
        // ── Hero Backdrop ──
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: AppColors.background,
          leading: IconButton(
            onPressed: () => context.pop(),
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
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.background.withValues(alpha: 0.5),
                        AppColors.background,
                      ],
                      stops: const [0.0, 0.6, 1.0],
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
                // ── Poster + Info Row ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Poster
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: CachedNetworkImage(
                        imageUrl: ApiConstants.imageUrl(posterPath),
                        width: 120,
                        height: 180,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => Container(
                          width: 120, height: 180,
                          color: AppColors.surfaceVariant,
                        ),
                      ),
                    ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                    const SizedBox(width: 16),

                    // Title & meta
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.headlineLarge,
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
                                  '${runtime ~/ 60}j ${runtime % 60}m',
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
                              border: Border.all(color: AppColors.surfaceElevated),
                            ),
                            child: Text(g, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ),
                        )
                        .toList(),
                  ),

                const SizedBox(height: 20),

                // ── Watch Now Button ──
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // Navigate to player with magnet resolution
                      await context.push('/player', extra: {
                        'title': title,
                        'imdbId': imdbId,
                        'tmdbId': data['id'] as int?,
                        'mediaType': 'movie',
                        'posterPath': data['poster_path'] as String?,
                        'backdropPath': data['backdrop_path'] as String?,
                        'magnetLink': '', // Will be resolved in player screen
                      });
                      SystemChrome.setPreferredOrientations([
                        DeviceOrientation.portraitUp,
                        DeviceOrientation.portraitDown,
                      ]);
                      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 28),
                    label: const Text('Tonton Sekarang', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 12),

                // ── Watchlist Button ──
                SizedBox(
                  width: double.infinity,
                  child: Builder(
                    builder: (context) {
                      final isInWatchlist = ref.watch(watchlistProvider.notifier).isInWatchlist(
                        data['id'] as int? ?? 0,
                        'movie',
                      );
                      return OutlinedButton.icon(
                        onPressed: () async {
                          final item = WatchlistItem(
                            id: data['id'] as int? ?? 0,
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
                                content: Text(added ? 'Ditambahkan ke Watchlist' : 'Dihapus dari Watchlist'),
                                backgroundColor: AppColors.surfaceVariant,
                              ),
                            );
                          }
                        },
                        icon: Icon(
                          isInWatchlist ? Iconsax.bookmark : Iconsax.bookmark,
                          size: 20,
                          color: isInWatchlist ? AppColors.primary : AppColors.textSecondary,
                        ),
                        label: Text(
                          isInWatchlist ? 'Tersimpan' : 'Simpan ke Watchlist',
                          style: TextStyle(
                            fontSize: 14,
                            color: isInWatchlist ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          side: BorderSide(
                            color: isInWatchlist ? AppColors.primary : AppColors.surfaceElevated,
                          ),
                        ),
                      );
                    },
                  ),
                ),

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
                    icon: const Icon(Iconsax.document_download, size: 20, color: AppColors.primary),
                    label: const Text(
                      'Unduh Film',
                      style: TextStyle(
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
                Text('Sinopsis', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  overview.isNotEmpty ? overview : 'Belum ada sinopsis.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
                ),

                // ── Cast ──
                if (castList.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Pemeran', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 130,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: castList.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final cast = castList[index];
                        final profilePath = cast['profile_path'] as String?;
                        return SizedBox(
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
                        );
                      },
                    ),
                  ),
                ],

                // ── Similar Movies ──
                if (similarList.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Film Serupa', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
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
                        return GestureDetector(
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
