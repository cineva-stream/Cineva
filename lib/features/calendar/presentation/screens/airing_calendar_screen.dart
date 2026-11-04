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
import '../../data/models/airing_show_model.dart';
import '../providers/calendar_providers.dart';

class AiringCalendarScreen extends ConsumerStatefulWidget {
  const AiringCalendarScreen({super.key});

  @override
  ConsumerState<AiringCalendarScreen> createState() => _AiringCalendarScreenState();
}

class _AiringCalendarScreenState extends ConsumerState<AiringCalendarScreen> {
  final ScrollController _dateScrollController = ScrollController();

  // Generate 14 days around today: 3 days in the past, today, 10 days in future
  late final List<DateTime> _dates;
  late final DateTime _today;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _dates = List.generate(14, (i) {
      return _today.add(Duration(days: i - 3));
    });

    // Auto-scroll to today after layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_dateScrollController.hasClients) {
        // Approximate width of 3 items before today: 3 * (64 + 10) = ~222px
        _dateScrollController.animateTo(
          210.0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    super.dispose();
  }

  String _getDayName(DateTime date, AppStrings s) {
    const enDays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    const idDays = ['SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB', 'MIN'];
    final idx = date.weekday - 1;
    return s.isIndonesian ? idDays[idx] : enDays[idx];
  }

  String _getMonthName(DateTime date, AppStrings s) {
    const enMonths = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const idMonths = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final idx = date.month - 1;
    return s.isIndonesian ? idMonths[idx] : enMonths[idx];
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    final selectedCategory = ref.watch(selectedCalendarCategoryProvider);
    final scheduleAsync = ref.watch(calendarScheduleProvider);

    final isSelectedDateToday = selectedDate.year == _today.year &&
        selectedDate.month == _today.month &&
        selectedDate.day == _today.day;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Header ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.calendarTitle,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${selectedDate.day} ${_getMonthName(selectedDate, s)} ${selectedDate.year}${isSelectedDateToday ? ' • ${s.calendarToday}' : ''}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isSelectedDateToday)
                    TextButton.icon(
                      onPressed: () {
                        ref.read(selectedCalendarDateProvider.notifier).state = _today;
                        if (_dateScrollController.hasClients) {
                          _dateScrollController.animateTo(
                            210.0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                          );
                        }
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: AppColors.primary, width: 1),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      icon: const Icon(Iconsax.calendar_1, size: 14, color: AppColors.primary),
                      label: Text(
                        s.calendarToday,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Horizontal Date Ribbon ──
            SizedBox(
              height: 78,
              child: ListView.separated(
                controller: _dateScrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _dates.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final date = _dates[index];
                  final isSelected = date.year == selectedDate.year &&
                      date.month == selectedDate.month &&
                      date.day == selectedDate.day;
                  final isDateToday = date.year == _today.year &&
                      date.month == _today.month &&
                      date.day == _today.day;

                  return GestureDetector(
                    onTap: () {
                      ref.read(selectedCalendarDateProvider.notifier).state = date;
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      width: 58,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isDateToday
                                  ? AppColors.primary.withValues(alpha: 0.5)
                                  : Colors.white.withValues(alpha: 0.08)),
                          width: isSelected || isDateToday ? 1.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _getDayName(date, s),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected
                                  ? Colors.black
                                  : (isDateToday ? AppColors.primary : AppColors.textMuted),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            date.day.toString(),
                            style: GoogleFonts.outfit(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.black : AppColors.textPrimary,
                            ),
                          ),
                          if (isDateToday && !isSelected)
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // ── Category Filter Chips ──
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildCategoryChip(context, ref, id: 'all', label: s.calendarFilterAll, isSelected: selectedCategory == 'all'),
                  const SizedBox(width: 8),
                  _buildCategoryChip(context, ref, id: 'anime', label: s.calendarFilterAnime, isSelected: selectedCategory == 'anime'),
                  const SizedBox(width: 8),
                  _buildCategoryChip(context, ref, id: 'kdrama', label: s.calendarFilterKdrama, isSelected: selectedCategory == 'kdrama'),
                  const SizedBox(width: 8),
                  _buildCategoryChip(context, ref, id: 'western', label: s.calendarFilterWestern, isSelected: selectedCategory == 'western'),
                  const SizedBox(width: 8),
                  _buildCategoryChip(context, ref, id: 'indonesian', label: s.calendarFilterIndonesian, isSelected: selectedCategory == 'indonesian'),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Episode / Show List ──
            Expanded(
              child: scheduleAsync.when(
                data: (shows) {
                  if (shows.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Iconsax.calendar_remove, size: 56, color: AppColors.textMuted),
                            const SizedBox(height: 16),
                            Text(
                              s.calendarNoShows,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              s.calendarNoShowsSub,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    physics: const BouncingScrollPhysics(),
                    itemCount: shows.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final show = shows[index];
                      return _AiringShowCard(show: show, index: index);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Iconsax.warning_2, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        s.isIndonesian ? 'Gagal memuat jadwal tayang' : 'Failed to load schedule',
                        style: GoogleFonts.inter(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(calendarScheduleProvider),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
    BuildContext context,
    WidgetRef ref, {
    required String id,
    required String label,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        ref.read(selectedCalendarCategoryProvider.notifier).state = id;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.black : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _AiringShowCard extends StatelessWidget {
  final AiringShowModel show;
  final int index;

  const _AiringShowCard({required this.show, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/tv/${show.id}'),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: show.posterPath != null
                  ? CachedNetworkImage(
                      imageUrl: ApiConstants.imageUrl(
                        show.posterPath,
                        size: ApiConstants.posterSmall,
                      ),
                      width: 75,
                      height: 110,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        width: 75,
                        height: 110,
                        color: AppColors.surfaceVariant,
                      ),
                    )
                  : Container(
                      width: 75,
                      height: 110,
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.tv, color: AppColors.textMuted),
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          show.regionBadge,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.star_rounded, size: 16, color: AppColors.star),
                      const SizedBox(width: 3),
                      Text(
                        show.voteAverage > 0 ? show.voteAverage.toStringAsFixed(1) : 'N/A',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    show.name,
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
                    show.overview.isNotEmpty ? show.overview : 'No overview available.',
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
                        'Watch Series',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
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
        .fadeIn(delay: Duration(milliseconds: (index.clamp(0, 10)) * 30))
        .slideY(begin: 0.05, end: 0);
  }
}

