import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../data/models/movie_collection_model.dart';
import '../providers/collection_providers.dart';

class CollectionDetailScreen extends ConsumerWidget {
  final int collectionId;
  final String? fallbackPoster;
  final String? fallbackBackdrop;

  const CollectionDetailScreen({
    super.key,
    required this.collectionId,
    this.fallbackPoster,
    this.fallbackBackdrop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final collectionAsync = ref.watch(collectionDetailProvider(collectionId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: collectionAsync.when(
        data: (collection) => _buildContent(context, collection, s),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Iconsax.warning_2, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text(
                s.isIndonesian ? 'Gagal memuat data koleksi' : 'Failed to load collection data',
                style: GoogleFonts.inter(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(collectionDetailProvider(collectionId)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                ),
                child: Text(s.detailRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _resolveHeaderImage(MovieCollectionModel collection) {
    if (collection.backdropPath != null && collection.backdropPath!.trim().isNotEmpty) {
      return collection.backdropPath;
    }
    if (fallbackBackdrop != null && fallbackBackdrop!.trim().isNotEmpty) {
      return fallbackBackdrop;
    }
    for (final part in collection.parts) {
      if (part.backdropPath != null && part.backdropPath!.trim().isNotEmpty) {
        return part.backdropPath;
      }
    }
    if (collection.posterPath != null && collection.posterPath!.trim().isNotEmpty) {
      return collection.posterPath;
    }
    if (fallbackPoster != null && fallbackPoster!.trim().isNotEmpty) {
      return fallbackPoster;
    }
    for (final part in collection.parts) {
      if (part.posterPath != null && part.posterPath!.trim().isNotEmpty) {
        return part.posterPath;
      }
    }
    return null;
  }

  Widget _buildHeaderImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E1610),
              Color(0xFF121218),
              Color(0xFF000000),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.movie_filter_rounded,
            size: 64,
            color: AppColors.primary.withValues(alpha: 0.15),
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 1: Ambient background image with blur (ensures full coverage even if vertical poster)
        CachedNetworkImage(
          imageUrl: ApiConstants.imageUrl(
            imagePath,
            size: ApiConstants.backdropMedium,
          ),
          fit: BoxFit.cover,
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              color: Colors.black.withValues(alpha: 0.25),
            ),
          ),
        ),
        // Layer 2: Main sharp image
        CachedNetworkImage(
          imageUrl: ApiConstants.imageUrl(
            imagePath,
            size: ApiConstants.backdropLarge,
          ),
          fit: BoxFit.cover,
        ),
        // Layer 3: Cinema OLED gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.35),
                Colors.transparent,
                AppColors.background.withValues(alpha: 0.7),
                AppColors.background,
              ],
              stops: const [0.0, 0.35, 0.75, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    MovieCollectionModel collection,
    AppStrings s,
  ) {
    final headerImage = _resolveHeaderImage(collection);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Backdrop Sliver AppBar ──
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: _buildHeaderImage(headerImage),
          ),
        ),

        // ── Franchise Details Header ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        s.collectionPartOf.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      s.collectionCountMovies(collection.parts.length),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  collection.name,
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (collection.overview.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    collection.overview,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(Iconsax.sort, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      s.collectionTimeline,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),

        // ── Chronological Parts Timeline ──
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.separated(
            itemCount: collection.parts.length,
            separatorBuilder: (_, _) => Divider(
              color: Colors.white.withValues(alpha: 0.08),
              height: 1,
              thickness: 0.8,
            ),
            itemBuilder: (context, index) {
              final part = collection.parts[index];
              return _CollectionPartListItem(
                part: part,
                partNumber: index + 1,
                totalParts: collection.parts.length,
                s: s,
              );
            },
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}

class _CollectionPartListItem extends StatelessWidget {
  final CollectionPartModel part;
  final int partNumber;
  final int totalParts;
  final AppStrings s;

  const _CollectionPartListItem({
    required this.part,
    required this.partNumber,
    required this.totalParts,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => context.push('/movie/${part.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chronological Index Badge
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 10, top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.15),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  '$partNumber',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),

            // Poster
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: part.posterPath != null
                  ? CachedNetworkImage(
                      imageUrl: ApiConstants.imageUrl(
                        part.posterPath,
                        size: ApiConstants.posterSmall,
                      ),
                      width: 68,
                      height: 98,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        width: 68,
                        height: 98,
                        color: AppColors.surfaceVariant,
                      ),
                    )
                  : Container(
                      width: 68,
                      height: 98,
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.movie, color: AppColors.textMuted),
                    ),
            ),
            const SizedBox(width: 12),

            // Info & Action
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (part.year.isNotEmpty) ...[
                        Text(
                          part.year,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const Text(
                          ' • ',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ],
                      const Icon(Icons.star_rounded, size: 14, color: AppColors.star),
                      const SizedBox(width: 2),
                      Text(
                        part.voteAverage > 0
                            ? part.voteAverage.toStringAsFixed(1)
                            : 'N/A',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    part.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    part.overview.isNotEmpty
                        ? part.overview
                        : 'No synopsis available.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Iconsax.play_circle, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        s.collectionWatchNow,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppColors.textMuted),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: (partNumber.clamp(0, 10)) * 25))
        .slideY(begin: 0.04, end: 0);
  }
}

