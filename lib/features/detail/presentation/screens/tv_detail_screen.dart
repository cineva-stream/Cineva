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

// ── TV Detail Provider ──

final tvDetailProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, tvId) async {
  final dio = DioClient.createTmdbClient();
  final response = await dio.get('/tv/$tvId', queryParameters: {
    'language': 'id-ID',
    'append_to_response': 'credits,external_ids,similar',
  });
  return response.data;
});

// ── TV Season Episodes Provider ──

final tvSeasonEpisodesProvider = FutureProvider.family<List<Map<String, dynamic>>, ({int tvId, int seasonNumber})>((ref, arg) async {
  final dio = DioClient.createTmdbClient();
  try {
    final response = await dio.get('/tv/${arg.tvId}/season/${arg.seasonNumber}', queryParameters: {
      'language': 'id-ID',
    });
    final episodes = response.data['episodes'] as List<dynamic>? ?? [];
    return episodes.cast<Map<String, dynamic>>();
  } catch (e) {
    // Fallback to English if Indonesian translation is not available
    try {
      final response = await dio.get('/tv/${arg.tvId}/season/${arg.seasonNumber}', queryParameters: {
        'language': 'en-US',
      });
      final episodes = response.data['episodes'] as List<dynamic>? ?? [];
      return episodes.cast<Map<String, dynamic>>();
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
    final detail = ref.watch(tvDetailProvider(tvId));

    return Scaffold(
      body: detail.when(
        data: (data) => _TvDetailContent(data: data),
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
                onPressed: () => ref.invalidate(tvDetailProvider(tvId)),
                child: const Text('Coba Lagi'),
              ),
            ],
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
    final regular = seasons.where((s) => (s['season_number'] as int? ?? 0) >= 1).firstOrNull;
    if (regular != null) {
      _selectedSeasonNumber = regular['season_number'] as int? ?? 1;
    } else if (seasons.isNotEmpty) {
      _selectedSeasonNumber = seasons.first['season_number'] as int? ?? 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final name = data['name'] ?? '';
    final overview = data['overview'] ?? '';
    final backdropPath = data['backdrop_path'] as String?;
    final posterPath = data['poster_path'] as String?;
    final voteAverage = (data['vote_average'] as num?)?.toDouble() ?? 0.0;
    final firstAirDate = data['first_air_date'] as String? ?? '';
    final genres = (data['genres'] as List<dynamic>?)?.map((g) => g['name'] as String).toList() ?? [];
    final tagline = data['tagline'] as String? ?? '';
    final seasons = (data['seasons'] as List<dynamic>?) ?? [];
    final numberOfSeasons = data['number_of_seasons'] as int? ?? 0;
    final numberOfEpisodes = data['number_of_episodes'] as int? ?? 0;
    final castList = (data['credits']?['cast'] as List<dynamic>?)?.take(10).toList() ?? [];
    final imdbId = data['external_ids']?['imdb_id'] as String?;
    final tvId = data['id'] as int? ?? 0;

    return CustomScrollView(
      slivers: [
        // ── Hero Backdrop ──
        SliverAppBar(
          expandedHeight: 280,
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
                // ── Poster + Info ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: CachedNetworkImage(
                        imageUrl: ApiConstants.imageUrl(posterPath),
                        width: 120,
                        height: 180,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => Container(width: 120, height: 180, color: AppColors.surfaceVariant),
                      ),
                    ).animate().fadeIn().slideY(begin: 0.1),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: Theme.of(context).textTheme.headlineLarge, maxLines: 3),
                          if (tagline.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(tagline, style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic, color: AppColors.primary,
                            )),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.star, color: AppColors.star, size: 18),
                              const SizedBox(width: 4),
                              Text(voteAverage.toStringAsFixed(1),
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                              const Text(' / 10', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$numberOfSeasons Season • $numberOfEpisodes Episode',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          ),
                          if (firstAirDate.length >= 4) ...[
                            const SizedBox(height: 4),
                            Text(firstAirDate.substring(0, 4),
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
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
                    spacing: 8, runSpacing: 6,
                    children: genres.map((g) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.surfaceElevated),
                      ),
                      child: Text(g, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    )).toList(),
                  ),

                const SizedBox(height: 20),

                // ── Watch Now (Starts S{selectedSeason}:E1) ──
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await context.push('/player', extra: {
                        'title': name,
                        'episodeTitle': 'Season $_selectedSeasonNumber Episode 1',
                        'imdbId': imdbId,
                        'season': _selectedSeasonNumber,
                        'episode': 1,
                        'tmdbId': tvId,
                        'mediaType': 'tv',
                        'posterPath': posterPath,
                        'backdropPath': backdropPath,
                        'magnetLink': '',
                      });
                      SystemChrome.setPreferredOrientations([
                        DeviceOrientation.portraitUp,
                        DeviceOrientation.portraitDown,
                      ]);
                      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 28),
                    label: Text(
                      'Tonton Season $_selectedSeasonNumber Episode 1',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                const SizedBox(height: 12),

                // ── Watchlist Button ──
                SizedBox(
                  width: double.infinity,
                  child: Builder(
                    builder: (context) {
                      final isInWatchlist = ref.watch(watchlistProvider.notifier).isInWatchlist(
                        data['id'] as int? ?? 0,
                        'tv',
                      );
                      return OutlinedButton.icon(
                        onPressed: () async {
                          final item = WatchlistItem(
                            id: data['id'] as int? ?? 0,
                            title: name,
                            posterPath: posterPath,
                            voteAverage: voteAverage,
                            type: 'tv',
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
                          Iconsax.bookmark,
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

                const SizedBox(height: 24),

                // ── Synopsis ──
                Text('Sinopsis', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  overview.isNotEmpty ? overview : 'Belum ada sinopsis.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
                ),

                // ── Interactive Episode Selector Section ──
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Iconsax.video_play, color: AppColors.primary, size: 22),
                        const SizedBox(width: 8),
                        Text('Pilih Episode', style: Theme.of(context).textTheme.headlineMedium),
                      ],
                    ),
                    Text(
                      'Season $_selectedSeasonNumber',
                      style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.surfaceElevated,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                sTitle,
                                style: TextStyle(
                                  color: isSelected ? Colors.black : Colors.white,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
                    final epAsync = ref.watch(tvSeasonEpisodesProvider((
                      tvId: tvId,
                      seasonNumber: _selectedSeasonNumber,
                    )));

                    return epAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(color: AppColors.primary),
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
                            const Icon(Iconsax.info_circle, color: AppColors.textMuted),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Daftar episode tidak tersedia saat ini.',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ),
                            TextButton(
                              onPressed: () => ref.invalidate(tvSeasonEpisodesProvider((
                                tvId: tvId,
                                seasonNumber: _selectedSeasonNumber,
                              ))),
                              child: const Text('Coba Lagi'),
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
                              'Belum ada episode di Season $_selectedSeasonNumber',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: episodes.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, epIdx) {
                            final ep = episodes[epIdx];
                            final epNum = ep['episode_number'] as int? ?? (epIdx + 1);
                            final epName = ep['name'] as String? ?? 'Episode $epNum';
                            final epStill = ep['still_path'] as String?;
                            final epOverview = ep['overview'] as String? ?? '';
                            final epRuntime = ep['runtime'] as int?;
                            final epAirDate = ep['air_date'] as String? ?? '';

                            return InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () async {
                                await context.push('/player', extra: {
                                  'title': name,
                                  'episodeTitle': 'S$_selectedSeasonNumber:E$epNum $epName',
                                  'imdbId': imdbId,
                                  'season': _selectedSeasonNumber,
                                  'episode': epNum,
                                  'tmdbId': tvId,
                                  'mediaType': 'tv',
                                  'posterPath': posterPath,
                                  'backdropPath': (ep['still_path'] as String?) ?? backdropPath,
                                  'magnetLink': '',
                                });
                                SystemChrome.setPreferredOrientations([
                                  DeviceOrientation.portraitUp,
                                  DeviceOrientation.portraitDown,
                                ]);
                                SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.surfaceElevated),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Thumbnail with Episode Badge
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Stack(
                                        children: [
                                          CachedNetworkImage(
                                            imageUrl: ApiConstants.imageUrl(epStill, size: ApiConstants.backdropSmall),
                                            width: 110,
                                            height: 72,
                                            fit: BoxFit.cover,
                                            placeholder: (_, _) => Container(
                                              width: 110, height: 72, color: AppColors.surface,
                                            ),
                                            errorWidget: (_, _, _) => Container(
                                              width: 110, height: 72, color: AppColors.surface,
                                              child: const Icon(Icons.tv, color: AppColors.textMuted),
                                            ),
                                          ),
                                          Positioned(
                                            top: 4,
                                            left: 4,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(alpha: 0.75),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'EPS $epNum',
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

                                    // Episode Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              if (epRuntime != null && epRuntime > 0)
                                                Text(
                                                  '$epRuntime mnt',
                                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                                ),
                                              if (epRuntime != null && epRuntime > 0 && epAirDate.isNotEmpty)
                                                const Text(' • ', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                              if (epAirDate.isNotEmpty)
                                                Text(
                                                  epAirDate,
                                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                                ),
                                            ],
                                          ),
                                          if (epOverview.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              epOverview,
                                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    // Episode Action Buttons: Download & Play
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          onPressed: () {
                                            DownloadOptionsModal.show(
                                              context,
                                              tmdbId: tvId,
                                              mediaType: 'tv',
                                              title: name,
                                              season: _selectedSeasonNumber,
                                              episode: epNum,
                                              episodeTitle: epName,
                                              posterPath: epStill ?? posterPath,
                                              backdropPath: backdropPath,
                                              imdbId: imdbId,
                                              runtimeMinutes: epRuntime ?? 45,
                                            );
                                          },
                                          icon: const Icon(
                                            Iconsax.document_download,
                                            size: 20,
                                            color: AppColors.primary,
                                          ),
                                          tooltip: 'Unduh Episode $epNum',
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.play_arrow_rounded,
                                            color: AppColors.primary,
                                            size: 20,
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
                                        ApiConstants.imageUrl(profilePath, size: ApiConstants.posterSmall))
                                    : null,
                                child: profilePath == null ? const Icon(Icons.person, color: AppColors.textMuted) : null,
                              ),
                              const SizedBox(height: 6),
                              Text(cast['name'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                              Text(cast['character'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                            ],
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
