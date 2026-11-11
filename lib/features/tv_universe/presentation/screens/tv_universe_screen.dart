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
import '../../../../shared/widgets/tv_focusable.dart';
import '../../data/tv_universe_registry.dart';
import '../../domain/entities/tv_universe.dart';
import '../../../detail/presentation/screens/tv_detail_screen.dart';

class TvUniverseScreen extends ConsumerWidget {
  final String universeId;
  final String? fallbackPoster;
  final String? fallbackBackdrop;

  const TvUniverseScreen({
    super.key,
    required this.universeId,
    this.fallbackPoster,
    this.fallbackBackdrop,
  });

  String? _resolveHeaderImage(TvUniverse universe, WidgetRef ref) {
    if (universe.backdropPath != null &&
        universe.backdropPath!.trim().isNotEmpty) {
      return universe.backdropPath;
    }
    if (fallbackBackdrop != null && fallbackBackdrop!.trim().isNotEmpty) {
      return fallbackBackdrop;
    }
    if (universe.entries.isNotEmpty) {
      final firstTv = ref
          .watch(tvDetailProvider(universe.entries.first.tmdbTvId))
          .valueOrNull;
      final dynamicBackdrop = firstTv?['backdrop_path'] as String?;
      if (dynamicBackdrop != null && dynamicBackdrop.isNotEmpty) {
        return dynamicBackdrop;
      }
    }
    if (universe.posterPath != null && universe.posterPath!.trim().isNotEmpty) {
      return universe.posterPath;
    }
    if (fallbackPoster != null && fallbackPoster!.trim().isNotEmpty) {
      return fallbackPoster;
    }
    for (final entry in universe.entries) {
      if (entry.posterPath != null && entry.posterPath!.trim().isNotEmpty) {
        return entry.posterPath;
      }
    }
    return null;
  }

  Widget _buildFallbackMesh() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1610), Color(0xFF121218), Color(0xFF000000)],
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

  Widget _buildHeaderImage(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return _buildFallbackMesh();
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
          errorWidget: (_, _, _) => _buildFallbackMesh(),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(color: Colors.black.withValues(alpha: 0.25)),
          ),
        ),
        // Layer 2: Main sharp image
        CachedNetworkImage(
          imageUrl: ApiConstants.imageUrl(
            imagePath,
            size: ApiConstants.backdropLarge,
          ),
          fit: BoxFit.cover,
          errorWidget: (_, _, _) => const SizedBox.shrink(),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final universe = TvUniverseRegistry.getUniverseById(universeId);

    if (universe == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: IconButton(
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
        body: Center(
          child: Text(
            'Universe not found',
            style: GoogleFonts.inter(color: AppColors.textMuted),
          ),
        ),
      );
    }

    final headerImage = _resolveHeaderImage(universe, ref);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Backdrop Sliver AppBar ──
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/'),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeaderImage(headerImage),
            ),
          ),

          // ── Universe Information Header ──
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.5),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              s.tvUniverseWatchOrder.toUpperCase(),
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
                            s.tvUniverseCountSeries(universe.entries.length),
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
                        universe.name,
                        style: GoogleFonts.outfit(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (universe.description.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          universe.description,
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
                          const Icon(
                            Iconsax.sort,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            s.tvUniverseChronologicalOrder,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Chronological Entries List ──
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isTwoCol = constraints.maxWidth >= 760;
                      if (isTwoCol) {
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisExtent: 138,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 12,
                              ),
                          itemCount: universe.entries.length,
                          itemBuilder: (context, index) {
                            final entry = universe.entries[index];
                            return _TvUniverseEntryItem(
                              entry: entry,
                              s: s,
                              index: index,
                              isCardStyle: true,
                            );
                          },
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: universe.entries.length,
                        separatorBuilder: (_, _) => Divider(
                          color: Colors.white.withValues(alpha: 0.08),
                          height: 1,
                          thickness: 0.8,
                        ),
                        itemBuilder: (context, index) {
                          final entry = universe.entries[index];
                          return _TvUniverseEntryItem(
                            entry: entry,
                            s: s,
                            index: index,
                            isCardStyle: false,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _TvUniverseEntryItem extends ConsumerWidget {
  final TvUniverseEntry entry;
  final AppStrings s;
  final int index;
  final bool isCardStyle;

  const _TvUniverseEntryItem({
    required this.entry,
    required this.s,
    required this.index,
    this.isCardStyle = false,
  });

  Color _typeBadgeColor(TvUniverseEntryType type) {
    switch (type) {
      case TvUniverseEntryType.mainSeries:
        return AppColors.primary;
      case TvUniverseEntryType.prequel:
        return const Color(0xFF38BDF8); // Sky blue
      case TvUniverseEntryType.sequel:
        return const Color(0xFF34D399); // Emerald
      case TvUniverseEntryType.spinoff:
        return const Color(0xFFA78BFA); // Purple
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgeColor = _typeBadgeColor(entry.type);
    final dynamicDetail = ref
        .watch(tvDetailProvider(entry.tmdbTvId))
        .valueOrNull;
    final effectivePoster =
        (entry.posterPath != null && entry.posterPath!.isNotEmpty)
        ? entry.posterPath
        : dynamicDetail?['poster_path'] as String?;

    return TvFocusable(
          borderRadius: BorderRadius.circular(12),
          scaleOnFocus: 1.02,
          onTap: () => context.push('/tv/${entry.tmdbTvId}'),
          child: Container(
            decoration: isCardStyle
                ? BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 0.8,
                    ),
                  )
                : null,
            padding: EdgeInsets.symmetric(
              vertical: 14,
              horizontal: isCardStyle ? 12 : 4,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Number Badge
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 10, top: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.15),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.6),
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${entry.orderIndex}',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),

                // TV Series Poster Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: effectivePoster != null && effectivePoster.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: ApiConstants.imageUrl(
                            effectivePoster,
                            size: ApiConstants.posterSmall,
                          ),
                          width: 68,
                          height: 98,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(
                            width: 68,
                            height: 98,
                            color: AppColors.surfaceVariant,
                            child: const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (_, _, _) => Container(
                            width: 68,
                            height: 98,
                            color: AppColors.surfaceVariant,
                            child: const Icon(
                              Icons.tv_rounded,
                              color: AppColors.textMuted,
                            ),
                          ),
                        )
                      : Container(
                          width: 68,
                          height: 98,
                          color: AppColors.surfaceVariant,
                          child: const Icon(
                            Icons.tv_rounded,
                            color: AppColors.textMuted,
                          ),
                        ),
                ),
                const SizedBox(width: 12),

                // Content Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Entry Type Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: badgeColor.withValues(alpha: 0.4),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              entry.type.localizedLabel(s),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: badgeColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            entry.yearRange,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        entry.title,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.note,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Iconsax.play_circle,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            s.tvUniverseViewSeries,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 11,
                            color: AppColors.textMuted,
                          ),
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
        .fadeIn(delay: Duration(milliseconds: (index.clamp(0, 10)) * 25))
        .slideY(begin: 0.04, end: 0);
  }
}
