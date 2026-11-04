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
import '../../../watchlist/data/watchlist_repository.dart';
import '../../data/models/airing_show_model.dart';
import '../../data/models/upcoming_media_model.dart';
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
    final activeTab = ref.watch(calendarActiveTabProvider);
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    final selectedCategory = ref.watch(selectedCalendarCategoryProvider);
    final upcomingCategory = ref.watch(upcomingCategoryFilterProvider);
    final scheduleAsync = ref.watch(calendarScheduleProvider);
    final upcomingAsync = ref.watch(upcomingMediaListProvider);

    final isSelectedDateToday = selectedDate.year == _today.year &&
        selectedDate.month == _today.month &&
        selectedDate.day == _today.day;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Header Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                          activeTab == 0 ? s.calendarTitle : s.upcomingTitle,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          activeTab == 0
                              ? '${selectedDate.day} ${_getMonthName(selectedDate, s)} ${selectedDate.year}${isSelectedDateToday ? ' • ${s.calendarToday}' : ''}'
                              : s.upcomingSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (activeTab == 0 && !isSelectedDateToday)
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

            // ── Minimalist 2-Tab Switcher ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTopTabItem(
                        context,
                        ref,
                        index: 0,
                        icon: Iconsax.calendar_1,
                        label: s.calendarTabWeekly,
                        isActive: activeTab == 0,
                      ),
                    ),
                    Expanded(
                      child: _buildTopTabItem(
                        context,
                        ref,
                        index: 1,
                        icon: Iconsax.timer_1,
                        label: s.calendarTabUpcoming,
                        isActive: activeTab == 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ── TAB CONTENT ──
            if (activeTab == 0) ...[
              // ── TAB 1: WEEKLY AIRING SCHEDULE ──
              // Horizontal Date Ribbon
              SizedBox(
                height: 74,
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

              // Category Filter Chips
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

              const SizedBox(height: 8),

              // Airing Show List
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      physics: const BouncingScrollPhysics(),
                      itemCount: shows.length,
                      separatorBuilder: (_, _) => Divider(
                        color: Colors.white.withValues(alpha: 0.08),
                        height: 1,
                        thickness: 0.8,
                      ),
                      itemBuilder: (context, index) {
                        final show = shows[index];
                        return _AiringShowListItem(show: show, index: index, s: s);
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
            ] else ...[
              // ── TAB 2: COMING SOON / RELEASE RADAR ──
              // Upcoming Category Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildUpcomingChip(context, ref, id: 'all', label: s.upcomingFilterAll, isSelected: upcomingCategory == 'all'),
                    const SizedBox(width: 8),
                    _buildUpcomingChip(context, ref, id: 'movie', label: s.upcomingFilterMovies, isSelected: upcomingCategory == 'movie'),
                    const SizedBox(width: 8),
                    _buildUpcomingChip(context, ref, id: 'tv', label: s.upcomingFilterTv, isSelected: upcomingCategory == 'tv'),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Upcoming Media List
              Expanded(
                child: upcomingAsync.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Iconsax.clock, size: 56, color: AppColors.textMuted),
                              const SizedBox(height: 16),
                              Text(
                                s.upcomingNoMedia,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                s.upcomingNoMediaSub,
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      physics: const BouncingScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => Divider(
                        color: Colors.white.withValues(alpha: 0.08),
                        height: 1,
                        thickness: 0.8,
                      ),
                      itemBuilder: (context, index) {
                        final media = items[index];
                        return _UpcomingMediaListItem(media: media, index: index, s: s);
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
                          s.isIndonesian ? 'Gagal memuat daftar rilis mendatang' : 'Failed to load upcoming releases',
                          style: GoogleFonts.inter(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => ref.invalidate(upcomingMediaListProvider),
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
          ],
        ),
      ),
    );
  }

  Widget _buildTopTabItem(
    BuildContext context,
    WidgetRef ref, {
    required int index,
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () {
        ref.read(calendarActiveTabProvider.notifier).state = index;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? Colors.black : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                color: isActive ? Colors.black : AppColors.textPrimary,
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

  Widget _buildUpcomingChip(
    BuildContext context,
    WidgetRef ref, {
    required String id,
    required String label,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        ref.read(upcomingCategoryFilterProvider.notifier).state = id;
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

class _AiringShowListItem extends StatelessWidget {
  final AiringShowModel show;
  final int index;
  final AppStrings s;

  const _AiringShowListItem({
    required this.show,
    required this.index,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => context.push('/tv/${show.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: show.posterPath != null
                  ? CachedNetworkImage(
                      imageUrl: ApiConstants.imageUrl(
                        show.posterPath,
                        size: ApiConstants.posterSmall,
                      ),
                      width: 72,
                      height: 104,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        width: 72,
                        height: 104,
                        color: AppColors.surfaceVariant,
                      ),
                    )
                  : Container(
                      width: 72,
                      height: 104,
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.tv, color: AppColors.textMuted),
                    ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          show.regionBadge,
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.star_rounded, size: 15, color: AppColors.star),
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
                  const SizedBox(height: 5),
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
                  const SizedBox(height: 3),
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
                        s.isIndonesian ? 'Lihat Serial' : 'View Series',
                        style: GoogleFonts.inter(
                          fontSize: 11,
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
        .fadeIn(delay: Duration(milliseconds: (index.clamp(0, 10)) * 25))
        .slideY(begin: 0.04, end: 0);
  }
}

class _UpcomingMediaListItem extends ConsumerWidget {
  final UpcomingMediaModel media;
  final int index;
  final AppStrings s;

  const _UpcomingMediaListItem({
    required this.media,
    required this.index,
    required this.s,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMovie = media.mediaType == 'movie';

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        if (isMovie) {
          context.push('/movie/${media.id}');
        } else {
          context.push('/tv/${media.id}');
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: media.posterPath != null
                  ? CachedNetworkImage(
                      imageUrl: ApiConstants.imageUrl(
                        media.posterPath,
                        size: ApiConstants.posterSmall,
                      ),
                      width: 72,
                      height: 104,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        width: 72,
                        height: 104,
                        color: AppColors.surfaceVariant,
                      ),
                    )
                  : Container(
                      width: 72,
                      height: 104,
                      color: AppColors.surfaceVariant,
                      child: Icon(
                        isMovie ? Icons.movie : Icons.tv,
                        color: AppColors.textMuted,
                      ),
                    ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Countdown Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          media.countdownLabel(s),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Type tag (MOVIE / TV)
                      Text(
                        isMovie ? 'FILM' : 'SERIAL',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      // Watchlist Quick Bookmark Icon
                      Consumer(
                        builder: (context, ref, _) {
                          final isInWatchlist = ref.watch(
                            isInWatchlistProvider((
                              id: media.id,
                              type: media.mediaType,
                            )),
                          );
                          return GestureDetector(
                            onTap: () async {
                              final item = WatchlistItem(
                                id: media.id,
                                title: media.title,
                                posterPath: media.posterPath,
                                voteAverage: media.voteAverage,
                                type: media.mediaType,
                                addedAt: DateTime.now(),
                              );
                              final added = await ref
                                  .read(watchlistProvider.notifier)
                                  .toggle(item);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      added
                                          ? s.detailAddedToWatchlist
                                          : s.detailRemovedFromWatchlist,
                                    ),
                                    backgroundColor: AppColors.surfaceVariant,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            child: Icon(
                              isInWatchlist
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              color: isInWatchlist
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                              size: 20,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    media.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (media.formattedDate.isNotEmpty)
                    Text(
                      'Rilis: ${media.formattedDate}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  const SizedBox(height: 3),
                  Text(
                    media.overview.isNotEmpty
                        ? media.overview
                        : 'No synopsis available yet.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                      height: 1.35,
                    ),
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
