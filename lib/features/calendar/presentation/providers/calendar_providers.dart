import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../data/models/airing_show_model.dart';
import '../../data/models/upcoming_media_model.dart';
import '../../data/datasources/calendar_remote_datasource.dart';
import '../../data/datasources/upcoming_remote_datasource.dart';

final calendarRemoteDataSourceProvider = Provider<CalendarRemoteDataSource>((ref) {
  return CalendarRemoteDataSource();
});

final upcomingRemoteDataSourceProvider = Provider<UpcomingRemoteDataSource>((ref) {
  return UpcomingRemoteDataSource();
});

/// Active top tab on the Calendar Screen:
/// 0: Weekly Airing Schedule (Jadwal Episode Mingguan)
/// 1: Coming Soon (Segera Hadir / Release Radar)
final calendarActiveTabProvider = StateProvider<int>((ref) => 0);

/// Active filter category on Coming Soon: 'all', 'movie', 'tv'
final upcomingCategoryFilterProvider = StateProvider<String>((ref) => 'all');

/// Selected date filter on Coming Soon: null means "Semua Tanggal / All Dates"
final selectedUpcomingDateProvider = StateProvider<DateTime?>((ref) => null);

/// Upcoming movies and TV shows provider
final upcomingMediaListProvider = FutureProvider.autoDispose<List<UpcomingMediaModel>>((ref) async {
  final category = ref.watch(upcomingCategoryFilterProvider);
  final targetDate = ref.watch(selectedUpcomingDateProvider);
  final lang = ref.watch(appLanguageProvider);
  final tmdbLang = lang == AppLanguage.en ? 'en-US' : 'id-ID';

  final targetDateStr = targetDate != null
      ? '${targetDate.year.toString().padLeft(4, '0')}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}'
      : null;

  final dataSource = ref.watch(upcomingRemoteDataSourceProvider);
  return dataSource.getUpcomingMedia(
    category: category,
    language: tmdbLang,
    targetDate: targetDateStr,
  );
});

/// Selected date on the Airing Calendar (normalized to midnight)
final selectedCalendarDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Active filter category: 'all', 'anime', 'kdrama', 'western', 'indonesian'
final selectedCalendarCategoryProvider = StateProvider<String>((ref) => 'all');

/// Airing schedule provider reactively fetching shows based on date, category, and language
final calendarScheduleProvider = FutureProvider.autoDispose<List<AiringShowModel>>((ref) async {
  final date = ref.watch(selectedCalendarDateProvider);
  final category = ref.watch(selectedCalendarCategoryProvider);
  final lang = ref.watch(appLanguageProvider);
  final tmdbLang = lang == AppLanguage.en ? 'en-US' : 'id-ID';

  final dataSource = ref.watch(calendarRemoteDataSourceProvider);
  return dataSource.getAiringShowsForDate(
    date: date,
    category: category,
    language: tmdbLang,
  );
});

