import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../app/theme/app_colors.dart';
import '../../core/constants/genre_constants.dart';
import '../../core/localization/app_language_provider.dart';
import '../../core/localization/app_strings.dart';
import 'tv_focusable.dart';

/// Sorting options supported by SectionCatalogScreen ("See All") and SearchScreen.
enum MediaSortOption {
  latest(Icons.auto_awesome_rounded),
  popular(Iconsax.trend_up),
  topRated(Iconsax.star_1);

  final IconData icon;
  const MediaSortOption(this.icon);

  String localizedLabel(AppStrings s) {
    switch (this) {
      case MediaSortOption.latest:
        return s.filterSortLatest;
      case MediaSortOption.popular:
        return s.filterSortPopular;
      case MediaSortOption.topRated:
        return s.filterSortTopRated;
    }
  }
}

/// Result returned when the user applies or changes filters in [MediaFilterBottomSheet].
class MediaFilterSelection {
  final MediaSortOption sortOption;
  final int? releaseYear;
  final GenreFilter? genre;

  const MediaFilterSelection({
    required this.sortOption,
    required this.releaseYear,
    this.genre,
  });
}

/// Clean, unified bottom sheet for sorting (Latest / Popular / Top Rated),
/// filtering by Release Year (All Years / 2026..2013), and optionally filtering by Genre.
/// Styled with Cineva's pure black background (`AppColors.background`) and smooth borders.
class MediaFilterBottomSheet extends ConsumerStatefulWidget {
  final MediaSortOption initialSort;
  final int? initialYear;
  final GenreFilter? initialGenre;
  final bool showGenreFilter;
  final MediaSortOption defaultSort;
  final void Function(MediaFilterSelection selection) onApply;

  const MediaFilterBottomSheet({
    super.key,
    required this.initialSort,
    required this.initialYear,
    this.initialGenre,
    this.showGenreFilter = false,
    this.defaultSort = MediaSortOption.latest,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required MediaSortOption initialSort,
    required int? initialYear,
    GenreFilter? initialGenre,
    bool showGenreFilter = false,
    MediaSortOption defaultSort = MediaSortOption.latest,
    required void Function(MediaFilterSelection selection) onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      builder: (_) => MediaFilterBottomSheet(
        initialSort: initialSort,
        initialYear: initialYear,
        initialGenre: initialGenre,
        showGenreFilter: showGenreFilter,
        defaultSort: defaultSort,
        onApply: onApply,
      ),
    );
  }

  @override
  ConsumerState<MediaFilterBottomSheet> createState() =>
      _MediaFilterBottomSheetState();
}

class _MediaFilterBottomSheetState
    extends ConsumerState<MediaFilterBottomSheet> {
  late MediaSortOption _sort;
  late int? _year;
  late GenreFilter _genre;

  late final List<int> _years = List<int>.generate(
    14,
    (index) => DateTime.now().year - index,
  );

  @override
  void initState() {
    super.initState();
    _sort = widget.initialSort;
    _year = widget.initialYear;
    _genre = widget.initialGenre ?? GenreConstants.filters.first;
  }

  bool get _hasNonDefaultFilters =>
      _sort != widget.defaultSort ||
      _year != null ||
      (widget.showGenreFilter && _genre.id != 'all');

  void _handleReset() {
    setState(() {
      _sort = widget.defaultSort;
      _year = null;
      _genre = GenreConstants.filters.first;
    });
    widget.onApply(
      MediaFilterSelection(
        sortOption: _sort,
        releaseYear: _year,
        genre: _genre,
      ),
    );
    Navigator.of(context).pop();
  }

  void _handleApply() {
    widget.onApply(
      MediaFilterSelection(
        sortOption: _sort,
        releaseYear: _year,
        genre: _genre,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: MediaQuery.sizeOf(context).height * 0.84,
        ),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 18),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.14),
                width: 1.0,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 28,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Drag Handle ──
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Header ──
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.45),
                      ),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.primary,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.filterAndSortTitle,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          s.filterAndSortSubtitle,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_hasNonDefaultFilters)
                    TvFocusable(
                      focusedScale: 1.05,
                      borderRadius: BorderRadius.circular(14),
                      onTap: _handleReset,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          s.filterResetButton,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),

              // ── Scrollable Filter Sections ──
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Sort By Section
                      _buildSectionTitle(
                        icon: Icons.swap_vert_rounded,
                        title: s.filterSortByLabel,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: MediaSortOption.values.map((option) {
                          final isSelected = _sort == option;
                          return _buildChip(
                            label: option.localizedLabel(s),
                            icon: option.icon,
                            isSelected: isSelected,
                            onTap: () => setState(() => _sort = option),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),

                      // 2. Release Year Section
                      _buildSectionTitle(
                        icon: Iconsax.calendar_1,
                        title: s.catalogReleaseYearLabel,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildChip(
                            label: s.filterAllYears,
                            isSelected: _year == null,
                            onTap: () => setState(() => _year = null),
                          ),
                          for (final yr in _years)
                            _buildChip(
                              label: '$yr',
                              isSelected: _year == yr,
                              onTap: () => setState(() => _year = yr),
                            ),
                        ],
                      ),

                      // 3. Genre Section (When enabled, e.g. on SearchScreen)
                      if (widget.showGenreFilter) ...[
                        const SizedBox(height: 20),
                        _buildSectionTitle(
                          icon: Iconsax.category,
                          title: s.searchGenres,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: GenreConstants.filters.map((g) {
                            final isSelected = _genre.id == g.id;
                            return _buildChip(
                              label: g.getLocalizedLabel(
                                s.isIndonesian,
                                s.language,
                              ),
                              icon: g.icon,
                              isSelected: isSelected,
                              onTap: () => setState(() => _genre = g),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ── Apply Button ──
              SizedBox(
                width: double.infinity,
                child: TvFocusable(
                  focusedScale: 1.02,
                  borderRadius: BorderRadius.circular(16),
                  onTap: _handleApply,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      s.filterApplyButton,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.9),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return TvFocusable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      scaleOnFocus: 1.05,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.14),
            width: isSelected ? 1.3 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
