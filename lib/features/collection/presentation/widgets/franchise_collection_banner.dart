import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/localization/app_language_provider.dart';

class FranchiseCollectionBanner extends ConsumerWidget {
  final Map<String, dynamic> collection;

  const FranchiseCollectionBanner({super.key, required this.collection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final id = collection['id'] as int? ?? 0;
    final name = collection['name'] as String? ?? 'Franchise';
    final posterPath = collection['poster_path'] as String?;
    final backdropPath = collection['backdrop_path'] as String?;

    if (id == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: GestureDetector(
        onTap: () => context.push('/collection/$id'),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColors.surface,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 1.2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Subtle backdrop image
              if (backdropPath != null)
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.15,
                    child: CachedNetworkImage(
                      imageUrl: ApiConstants.imageUrl(
                        backdropPath,
                        size: ApiConstants.backdropMedium,
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Collection Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: posterPath != null
                          ? CachedNetworkImage(
                              imageUrl: ApiConstants.imageUrl(
                                posterPath,
                                size: ApiConstants.posterSmall,
                              ),
                              width: 50,
                              height: 72,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => Container(
                                width: 50,
                                height: 72,
                                color: AppColors.surfaceVariant,
                              ),
                            )
                          : Container(
                              width: 50,
                              height: 72,
                              color: AppColors.surfaceVariant,
                              child: const Icon(Icons.movie_rounded, color: AppColors.textMuted),
                            ),
                    ),
                    const SizedBox(width: 12),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  s.collectionPartOf.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.collectionViewFull,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.04, end: 0);
  }
}

