import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../data/models/airing_show_model.dart';
import '../../data/datasources/calendar_remote_datasource.dart';

final calendarRemoteDataSourceProvider = Provider<CalendarRemoteDataSource>((ref) {
  return CalendarRemoteDataSource();
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

