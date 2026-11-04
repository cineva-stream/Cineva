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
import '../../data/models/person_detail_model.dart';
import '../providers/person_providers.dart';

class PersonDetailScreen extends ConsumerStatefulWidget {
  final int personId;
  final String? initialName;

  const PersonDetailScreen({
    super.key,
    required this.personId,
    this.initialName,
  });

  @override
  ConsumerState<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends ConsumerState<PersonDetailScreen> {
  bool _isBioExpanded = false;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final detailAsync = ref.watch(personDetailProvider(widget.personId));
    final filter = ref.watch(personFilmographyFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: detailAsync.when(
        data: (person) => _buildContent(context, person, filter, s),
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
                s.isIndonesian ? 'Gagal memuat profil pemeran' : 'Failed to load actor profile',
                style: GoogleFonts.inter(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(personDetailProvider(widget.personId)),
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

  Widget _buildContent(
    BuildContext context,
    PersonDetailModel person,
    String activeFilter,
    AppStrings s,
  ) {
    final filteredCredits = person.credits.where((c) {
      if (activeFilter == 'movie') return c.mediaType == 'movie';
      if (activeFilter == 'tv') return c.mediaType == 'tv';
      return true;
    }).toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Sliver App Bar ──
        SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.background.withValues(alpha: 0.95),
          elevation: 0,
          leading: IconButton(
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          title: Text(
            person.name,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),

        // ── Actor Header Info ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                // Avatar with Amber Glow
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.primary,
                      width: 2.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 54,
                    backgroundColor: AppColors.surfaceVariant,
                    backgroundImage: person.profilePath != null
                        ? CachedNetworkImageProvider(
                            ApiConstants.imageUrl(
                              person.profilePath,
                              size: ApiConstants.posterMedium,
                            ),
                          )
                        : null,
                    child: person.profilePath == null
                        ? const Icon(Icons.person, size: 54, color: AppColors.textMuted)
                        : null,
                  ),
                ).animate().scale(
                      duration: 400.ms,
                      curve: Curves.easeOutCubic,
                    ),

                const SizedBox(height: 14),

                // Name
                Text(
                  person.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 4),

                // Department / Known For
                Text(
                  person.knownForDepartment == 'Directing'
                      ? s.personDirecting
                      : s.personActing,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 12),

                // Metadata Chips (Birthday, Age, Birthplace)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (person.birthday != null)
                      _buildMetaChip(
                        icon: Iconsax.calendar_1,
                        label: person.age != null
                            ? '${person.birthday} (${person.age} ${s.personAgeYears})'
                            : person.birthday!,
                      ),
                    if (person.placeOfBirth != null)
                      _buildMetaChip(
                        icon: Iconsax.location,
                        label: person.placeOfBirth!,
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Biography Section ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.personBiography,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedCrossFade(
                        firstChild: Text(
                          person.biography.isNotEmpty
                              ? person.biography
                              : s.personNoBiography,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                        secondChild: Text(
                          person.biography.isNotEmpty
                              ? person.biography
                              : s.personNoBiography,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                        crossFadeState: _isBioExpanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 250),
                      ),
                      if (person.biography.length > 200) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isBioExpanded = !_isBioExpanded;
                            });
                          },
                          child: Text(
                            _isBioExpanded ? s.personReadLess : s.personReadMore,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Filmography Section Header ──
                Row(
                  children: [
                    Text(
                      s.personFilmography,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${filteredCredits.length}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Filter Chips ──
                Row(
                  children: [
                    _buildFilterChip(
                      label: s.personAllCredits,
                      isSelected: activeFilter == 'all',
                      onTap: () => ref
                          .read(personFilmographyFilterProvider.notifier)
                          .state = 'all',
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: s.personMoviesOnly,
                      isSelected: activeFilter == 'movie',
                      onTap: () => ref
                          .read(personFilmographyFilterProvider.notifier)
                          .state = 'movie',
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      label: s.personTvOnly,
                      isSelected: activeFilter == 'tv',
                      onTap: () => ref
                          .read(personFilmographyFilterProvider.notifier)
                          .state = 'tv',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Filmography Grid ──
        if (filteredCredits.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  s.personNoCredits,
                  style: GoogleFonts.inter(color: AppColors.textMuted),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.52,
                crossAxisSpacing: 12,
                mainAxisSpacing: 14,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = filteredCredits[index];
                  return _FilmographyCard(credit: item, index: index);
                },
                childCount: filteredCredits.length,
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Widget _buildMetaChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.black : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _FilmographyCard extends StatelessWidget {
  final PersonCreditModel credit;
  final int index;

  const _FilmographyCard({required this.credit, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (credit.mediaType == 'tv') {
          context.push('/tv/${credit.id}');
        } else {
          context.push('/movie/${credit.id}');
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster Frame
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: ApiConstants.imageUrl(
                      credit.posterPath,
                      size: ApiConstants.posterSmall,
                    ),
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(color: AppColors.surfaceVariant),
                    errorWidget: (_, _, _) => Container(
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.movie, color: AppColors.textMuted),
                    ),
                  ),
                  // Rating Badge
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 12, color: AppColors.star),
                          const SizedBox(width: 2),
                          Text(
                            credit.voteAverage > 0
                                ? credit.voteAverage.toStringAsFixed(1)
                                : '—',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Title
          Text(
            credit.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          // Character & Year
          if (credit.character != null && credit.character!.isNotEmpty)
            Text(
              credit.character!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
          if (credit.year.isNotEmpty)
            Text(
              credit.year,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: (index.clamp(0, 15)) * 25))
        .slideY(begin: 0.05, end: 0);
  }
}

