import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../data/datasources/live_tv_channels_data.dart';
import '../../domain/entities/live_tv_channel.dart';
import '../providers/live_tv_providers.dart';

/// TV Live Channel Catalog Screen.
///
/// Provides a spacious, full-page channel exploration experience:
/// - Instant channel browsing with zero player overhead
/// - Instant search and horizontal category chips
/// - Tapping any channel opens [LiveTvPlayerScreen] with a smooth horizontal slide transition
class LiveTvScreen extends ConsumerStatefulWidget {
  const LiveTvScreen({super.key});

  @override
  ConsumerState<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends ConsumerState<LiveTvScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        ref.read(liveTvIsPlayingProvider.notifier).state = false;
        ref.read(liveTvFullscreenProvider.notifier).state = false;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onChannelSelected(LiveTvChannel channel) async {
    ref.read(liveTvIsPlayingProvider.notifier).state = true;
    await context.push('/live-tv/player', extra: channel);
    if (mounted) {
      ref.read(liveTvIsPlayingProvider.notifier).state = false;
      ref.read(liveTvFullscreenProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final selectedCategory = ref.watch(liveTvCategoryProvider);
    final channels = ref.watch(filteredLiveTvChannelsProvider);
    final favorites = ref.watch(liveTvFavoritesProvider);
    final favoritesNotifier = ref.read(liveTvFavoritesProvider.notifier);
    final bottomPadding = MediaQuery.of(context).padding.bottom + 80;

    final categories = [
      ...LiveTvChannelsData.categories,
      'Favorit',
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.live_tv_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.liveTvTitle,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${channels.length} ${s.isIndonesian ? "Saluran Siaran Langsung" : "Live Channels"}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Search Bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                  onChanged: (val) {
                    ref.read(liveTvSearchQueryProvider.notifier).state = val;
                  },
                  decoration: InputDecoration(
                    hintText: s.liveTvSearchHint,
                    hintStyle: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textMuted,
                      size: 18,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                color: AppColors.textMuted, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(liveTvSearchQueryProvider.notifier).state = '';
                              setState(() {});
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),

            // ── Category Filter Chips ──
            SizedBox(
              height: 38,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = cat == selectedCategory;
                  return FilterChip(
                    selected: isSelected,
                    label: Text(
                      cat,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.black : Colors.white70,
                      ),
                    ),
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.white.withValues(alpha: 0.08),
                        width: 0.8,
                      ),
                    ),
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                    onSelected: (_) {
                      ref.read(liveTvCategoryProvider.notifier).state = cat;
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // ── Channel Grid / List View ──
            Expanded(
              child: channels.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.tv_off_rounded,
                              size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            s.liveTvNoChannels,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(0, 4, 0, bottomPadding),
                      itemCount: channels.length,
                      itemBuilder: (context, index) {
                        final channel = channels[index];
                        final isFavorite = favorites.contains(channel.id);
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.white.withValues(alpha: 0.08),
                                width: 0.8,
                              ),
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _onChannelSelected(channel),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    // Logo (clean, without container background)
                                    SizedBox(
                                      width: 44,
                                      height: 44,
                                      child: channel.logoUrl != null && channel.logoUrl!.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: channel.logoUrl!,
                                              httpHeaders: const {
                                                'User-Agent':
                                                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
                                              },
                                              fit: BoxFit.contain,
                                              errorWidget: (_, _, _) => const Icon(
                                                Icons.tv_rounded,
                                                color: Colors.white70,
                                                size: 24,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.tv_rounded,
                                              color: Colors.white70,
                                              size: 24,
                                            ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Name and Category
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            channel.name,
                                            style: GoogleFonts.outfit(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            channel.category,
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Favorite Button
                                    IconButton(
                                      onPressed: () {
                                        favoritesNotifier.toggleFavorite(channel.id);
                                      },
                                      icon: Icon(
                                        isFavorite
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        color: isFavorite ? Colors.redAccent : Colors.white54,
                                        size: 20,
                                      ),
                                      tooltip: isFavorite
                                          ? 'Hapus dari Favorit'
                                          : 'Simpan ke Favorit',
                                    ),

                                    // Play icon pill
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.primary.withValues(alpha: 0.4),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.play_arrow_rounded,
                                            color: AppColors.primary,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            s.isIndonesian ? 'Tonton' : 'Watch',
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
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
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
