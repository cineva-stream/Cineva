import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../data/datasources/live_tv_channels_data.dart';
import '../providers/live_tv_providers.dart';
import 'live_player_screen.dart';

/// Screen dedicated to browsing and streaming Live TV channels.
/// Features a pure smooth black aesthetic, live category filtering,
/// quick search, and direct playback via LivePlayerScreen.
class LiveTvScreen extends ConsumerStatefulWidget {
  const LiveTvScreen({super.key});

  @override
  ConsumerState<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends ConsumerState<LiveTvScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final selectedCategory = ref.watch(liveTvCategoryProvider);
    final channels = ref.watch(filteredLiveTvChannelsProvider);
    final favoritesNotifier = ref.read(liveTvFavoritesProvider.notifier);
    final favorites = ref.watch(liveTvFavoritesProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom + 80;

    final categories = [
      ...LiveTvChannelsData.categories,
      'Favorit',
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── 1. App Bar Header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Text(
                      s.liveTvTitle,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.6),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'LIVE',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.redAccent,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── 2. Search Bar ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 0.8,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      ref.read(liveTvSearchQueryProvider.notifier).state = val;
                    },
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: s.liveTvSearchHint,
                      hintStyle: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.textMuted),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(liveTvSearchQueryProvider.notifier).state = '';
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
            ),

            // ── 3. Category Filter Chips ──
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: categories.map((cat) {
                    final isSelected = selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          ref.read(liveTvCategoryProvider.notifier).state = cat;
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.white.withValues(alpha: 0.1),
                              width: isSelected ? 1.2 : 0.8,
                            ),
                          ),
                          child: Text(
                            cat,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 14),
            ),

            // ── 4. Channel List Items ──
            if (channels.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tv_off_rounded, size: 44, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        s.liveTvNoChannels,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final ch = channels[index];
                      final isFav = favorites.contains(ch.id);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => LivePlayerScreen(channel: ch),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Channel Logo Container
                                  Container(
                                    width: 48,
                                    height: 48,
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.08),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: ch.logoUrl != null && ch.logoUrl!.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: ch.logoUrl!,
                                            fit: BoxFit.contain,
                                            placeholder: (_, _) => Center(
                                              child: SizedBox(
                                                width: 14,
                                                height: 14,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 1.5,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                            errorWidget: (_, _, _) => Center(
                                              child: Icon(
                                                _getCategoryIcon(ch.category),
                                                color: AppColors.primary,
                                                size: 20,
                                              ),
                                            ),
                                          )
                                        : Center(
                                            child: Icon(
                                              _getCategoryIcon(ch.category),
                                              color: AppColors.primary,
                                              size: 20,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Name, Category & Country
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ch.name,
                                          style: GoogleFonts.outfit(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Text(
                                              ch.category,
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                            Text(
                                              ' • ${ch.country}',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Quality Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.07),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      ch.quality,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),

                                  // Favorite Button
                                  IconButton(
                                    onPressed: () => favoritesNotifier.toggleFavorite(ch.id),
                                    icon: Icon(
                                      isFav ? Icons.star_rounded : Icons.star_border_rounded,
                                      color: isFav ? AppColors.star : AppColors.textMuted,
                                      size: 20,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: (20 * index).ms, duration: 250.ms);
                    },
                    childCount: channels.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Olahraga':
        return Icons.sports_soccer_rounded;
      case 'Berita':
        return Icons.newspaper_rounded;
      case 'Film & Hiburan':
        return Icons.movie_filter_rounded;
      case 'Indonesia':
        return Icons.flag_rounded;
      case 'Anak & Animasi':
        return Icons.child_care_rounded;
      case 'Sains & Edukasi':
        return Icons.science_rounded;
      case 'Musik':
        return Icons.music_note_rounded;
      default:
        return Icons.live_tv_rounded;
    }
  }
}
