import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../history/data/models/watch_history_item.dart';
import '../../../history/data/repositories/watch_history_repository.dart';
import '../../../watchlist/data/watchlist_repository.dart';
import '../../domain/entities/watch_insights.dart';
import '../../domain/models/user_profile.dart';
import 'profile_provider.dart';

/// Currently selected card design mode (KTP Sinema vs VIP Black ATM Card).
final memberCardStyleProvider = StateProvider<MemberCardStyle>(
  (ref) => MemberCardStyle.ktp,
);

/// Currently selected humorous caption index (0..5).
final humorousCaptionIndexProvider = StateProvider<int>((ref) => 0);

/// Computes comprehensive [WatchInsights] reactively from [watchHistoryProvider],
/// [watchlistProvider], and [userProfileProvider].
final watchInsightsProvider = Provider<WatchInsights>((ref) {
  final history = ref.watch(watchHistoryProvider);
  final watchlist = ref.watch(watchlistProvider);
  final profile = ref.watch(userProfileProvider);

  return computeWatchInsights(
    history: history,
    watchlist: watchlist,
    profile: profile,
  );
});

/// Pure function to compute [WatchInsights] (also easily testable in unit tests).
WatchInsights computeWatchInsights({
  required List<WatchHistoryItem> history,
  required List<WatchlistItem> watchlist,
  required UserProfile profile,
}) {
  int totalWatchTimeMs = 0;
  final distinctMovieIds = <int>{};
  final distinctTvIds = <int>{};
  int episodesWatchedCount = 0;
  int completedCount = 0;
  double ratingSum = 0.0;
  int ratedItemsCount = 0;
  double progressSum = 0.0;
  int progressItemsCount = 0;

  // Mon (0) .. Sun (6)
  final weeklyMinutes = List<int>.filled(7, 0);
  final activeDateKeys = <String>{};
  final sortedDates = <DateTime>[];

  int earliestYear = DateTime.now().year;

  for (final item in history) {
    final posMs = item.positionMs > 0
        ? item.positionMs
        : (item.isCompleted && item.durationMs > 0 ? item.durationMs : 0);
    totalWatchTimeMs += posMs;

    if (item.mediaType == 'tv') {
      if (item.id > 0) distinctTvIds.add(item.id);
      episodesWatchedCount++;
    } else {
      if (item.id > 0) distinctMovieIds.add(item.id);
    }

    final isDone = item.isCompleted || item.progressPercent >= 0.85;
    if (isDone) {
      completedCount++;
      progressSum += 1.0;
      progressItemsCount++;
    } else if (item.durationMs > 0 && item.positionMs > 0) {
      progressSum += item.progressPercent.clamp(0.05, 1.0);
      progressItemsCount++;
    }

    if (item.voteAverage > 0) {
      ratingSum += item.voteAverage;
      ratedItemsCount++;
    }

    final dt = item.lastWatchedAt;
    if (dt.year >= 2020 && dt.year < earliestYear) {
      earliestYear = dt.year;
    }

    final weekdayIndex = (dt.weekday - 1).clamp(0, 6);
    final int itemMinutes = math.max<int>(1, (posMs / 60000).round());
    if (posMs > 0) {
      weeklyMinutes[weekdayIndex] += itemMinutes;
    }

    final dateKey =
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    if (activeDateKeys.add(dateKey)) {
      sortedDates.add(DateTime(dt.year, dt.month, dt.day));
    }
  }

  for (final w in watchlist) {
    if (w.voteAverage > 0) {
      ratingSum += w.voteAverage;
      ratedItemsCount++;
    }
    if (w.addedAt.year >= 2020 && w.addedAt.year < earliestYear) {
      earliestYear = w.addedAt.year;
    }
  }

  final moviesWatchedCount = distinctMovieIds.length;
  final tvSeriesWatchedCount = distinctTvIds.length;

  final completionRatePercent = progressItemsCount > 0
      ? ((progressSum / progressItemsCount) * 100).round().clamp(0, 100)
      : 0;

  final averageRating = ratedItemsCount > 0
      ? double.parse((ratingSum / ratedItemsCount).toStringAsFixed(1))
      : 8.5;

  // Calculate active days streak
  sortedDates.sort((a, b) => b.compareTo(a));
  int streak = 0;
  if (sortedDates.isNotEmpty) {
    streak = 1;
    for (int i = 0; i < sortedDates.length - 1; i++) {
      final diffDays = sortedDates[i].difference(sortedDates[i + 1]).inDays;
      if (diffDays == 1) {
        streak++;
      } else if (diffDays > 1) {
        break;
      }
    }
  }

  // Persona level calculation based on total hours
  final hoursDecimal = totalWatchTimeMs / 3600000.0;
  int personaLevel;
  int nextLevelTargetHours;
  double levelProgress;

  if (hoursDecimal < 2.0) {
    personaLevel = 1;
    nextLevelTargetHours = 2;
    levelProgress = (hoursDecimal / 2.0).clamp(0.08, 1.0);
  } else if (hoursDecimal < 10.0) {
    personaLevel = 2;
    nextLevelTargetHours = 10;
    levelProgress = ((hoursDecimal - 2.0) / 8.0).clamp(0.05, 1.0);
  } else if (hoursDecimal < 30.0) {
    personaLevel = 3;
    nextLevelTargetHours = 30;
    levelProgress = ((hoursDecimal - 10.0) / 20.0).clamp(0.05, 1.0);
  } else if (hoursDecimal < 75.0) {
    personaLevel = 4;
    nextLevelTargetHours = 75;
    levelProgress = ((hoursDecimal - 30.0) / 45.0).clamp(0.05, 1.0);
  } else {
    personaLevel = 5;
    nextLevelTargetHours = 150;
    levelProgress = ((hoursDecimal - 75.0) / 75.0).clamp(0.25, 1.0);
  }

  // Deterministic 16-digit NIK & ATM Card numbers based on username + stats
  final seedHash = _stableNumericHash('${profile.username}_${profile.name}');
  final block3 = ((seedHash % 9000) + 1000).toString();
  final block4 =
      (((seedHash ~/ 13) + moviesWatchedCount * 7 + episodesWatchedCount * 3) %
                  9000 +
              1000)
          .toString();

  final ktpNikNumber = '3273 • $earliestYear • $block3 • $block4';
  final atmCardNumber = '8842  $earliestYear  $block3  $block4';

  // Build Content DNA / Format & Category Distribution
  final topFlavors = _computeContentDna(
    history: history,
    watchlist: watchlist,
    moviesCount: moviesWatchedCount,
    episodesCount: episodesWatchedCount,
    completedCount: completedCount,
  );

  // Top watched items sorted by watch duration descending
  final sortedByWatchTime = [...history]
    ..sort((a, b) => b.positionMs.compareTo(a.positionMs));
  final seenTopKeys = <String>{};
  final topWatchedItems = <WatchHistoryItem>[];
  for (final item in sortedByWatchTime) {
    if (topWatchedItems.length >= 5) break;
    final key = '${item.mediaType}_${item.id}';
    if (seenTopKeys.add(key)) {
      topWatchedItems.add(item);
    }
  }

  return WatchInsights(
    totalWatchTimeMs: totalWatchTimeMs,
    moviesWatchedCount: moviesWatchedCount,
    episodesWatchedCount: episodesWatchedCount,
    tvSeriesWatchedCount: tvSeriesWatchedCount,
    completedTitlesCount: completedCount,
    watchlistCount: watchlist.length,
    completionRatePercent: completionRatePercent,
    averageRating: averageRating,
    activeDaysCount: activeDateKeys.length,
    activeDaysStreak: streak,
    weeklyMinutesByWeekday: weeklyMinutes,
    personaLevel: personaLevel,
    nextLevelTargetHours: nextLevelTargetHours,
    levelProgress: levelProgress,
    ktpNikNumber: ktpNikNumber,
    atmCardNumber: atmCardNumber,
    memberSinceYear: earliestYear.toString(),
    topFlavors: topFlavors,
    topWatchedItems: topWatchedItems,
  );
}

int _stableNumericHash(String input) {
  int hash = 5381;
  for (int i = 0; i < input.length; i++) {
    hash = ((hash << 5) + hash) ^ input.codeUnitAt(i);
  }
  return hash.abs();
}

List<GenreDistributionItem> _computeContentDna({
  required List<WatchHistoryItem> history,
  required List<WatchlistItem> watchlist,
  required int moviesCount,
  required int episodesCount,
  required int completedCount,
}) {
  final movieScore =
      moviesCount + watchlist.where((w) => w.type != 'tv').length;
  final tvScore =
      episodesCount + watchlist.where((w) => w.type == 'tv').length;
  final highRatedScore =
      history.where((h) => h.voteAverage >= 7.5).length +
      watchlist.where((w) => w.voteAverage >= 7.5).length;
  final finisherScore = completedCount + watchlist.length;

  final rawEntries = [
    (
      id: 'Film Bioskop & Blockbuster',
      en: 'Feature Films & Blockbusters',
      hi: 'फ़ीचर फ़िल्में और ब्लॉकबस्टर',
      val: math.max(1, movieScore),
    ),
    (
      id: 'Serial TV, Drakor & Anime',
      en: 'TV Series, K-Drama & Anime',
      hi: 'टीवी सीरीज़, के-ड्रामा और एनीमे',
      val: math.max(1, tvScore),
    ),
    (
      id: 'Kurasi Rating Tinggi (7.5+ ⭐)',
      en: 'Critically Acclaimed (7.5+ ⭐)',
      hi: 'उच्च रेटेड क्लासिक्स (7.5+ ⭐)',
      val: math.max(1, highRatedScore),
    ),
    (
      id: 'Kolektor & Penamat Setia',
      en: 'Dedicated Finisher & Collector',
      hi: 'समर्पित कलेक्टर और फ़िनिशर',
      val: math.max(1, finisherScore),
    ),
  ];

  final maxVal = rawEntries
      .map((e) => e.val)
      .fold<int>(1, (prev, el) => math.max(prev, el));

  return rawEntries
      .map(
        (e) => GenreDistributionItem(
          labelId: e.id,
          labelEn: e.en,
          labelHi: e.hi,
          count: e.val,
          percentage: (e.val / maxVal).clamp(0.18, 1.0),
        ),
      )
      .toList();
}
