import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../history/data/models/watch_history_item.dart';
import '../../../history/data/repositories/watch_history_repository.dart';
import '../../../watchlist/data/watchlist_repository.dart';
import '../../domain/entities/watch_insights.dart';
import '../../domain/models/user_profile.dart';
import 'profile_provider.dart';

/// Currently selected card design mode (Member ID vs Metal Card).
final memberCardStyleProvider = StateProvider<MemberCardStyle>(
  (ref) => MemberCardStyle.idCard,
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

/// Default estimated duration per TV episode (42 minutes) when prior episodes in earlier
/// seasons were not individually retained in local storage.
const int _kDefaultTvEpisodeDurationMs = 42 * 60 * 1000;

/// Conservative minimum episodes per completed prior season of a multi-season TV series.
const int _kEstimatedEpisodesPerPriorSeason = 10;

/// Pure function to compute [WatchInsights] with accurate TV Series episode aggregation
/// and multi-season cumulative watch time calculation.
WatchInsights computeWatchInsights({
  required List<WatchHistoryItem> history,
  required List<WatchlistItem> watchlist,
  required UserProfile profile,
}) {
  final distinctMovieIds = <int>{};
  final distinctTvIds = <int>{};
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

  // Group history items by title key ('movie_<id>' or 'tv_<id>')
  final movieGroups = <int, List<WatchHistoryItem>>{};
  final tvGroups = <int, List<WatchHistoryItem>>{};

  for (final item in history) {
    final posMs = _effectiveWatchedMs(item);

    if (item.mediaType == 'tv') {
      if (item.id > 0) {
        distinctTvIds.add(item.id);
        tvGroups.putIfAbsent(item.id, () => []).add(item);
      }
    } else {
      if (item.id > 0) {
        distinctMovieIds.add(item.id);
        movieGroups.putIfAbsent(item.id, () => []).add(item);
      }
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

  // Build aggregated TopWatchedTitleItem list and compute accurate total watch time & episode counts
  final aggregatedTitles = <TopWatchedTitleItem>[];
  int totalWatchTimeMs = 0;
  int totalEpisodesWatched = 0;

  // 1. Aggregate Movies
  for (final entry in movieGroups.entries) {
    final items = entry.value;
    final latest = items.first;
    int movieWatchedMs = 0;
    for (final m in items) {
      movieWatchedMs = math.max(movieWatchedMs, _effectiveWatchedMs(m));
    }
    totalWatchTimeMs += movieWatchedMs;

    aggregatedTitles.add(
      TopWatchedTitleItem(
        id: entry.key,
        mediaType: 'movie',
        title: latest.title,
        posterPath: latest.posterPath,
        totalWatchedMs: movieWatchedMs,
        episodesCount: 1,
      ),
    );
  }

  // 2. Aggregate TV Series (Summing all episodes + multi-season cumulative progression)
  for (final entry in tvGroups.entries) {
    final episodes = entry.value;
    final latest = episodes.first;

    int summedRecordedMs = 0;
    int durationSampleSum = 0;
    int durationSampleCount = 0;
    int maxSeason = 1;
    int maxEpInMaxSeason = 1;
    bool latestEpIsCompleted = false;
    final maxEpPerSeason = <int, int>{};

    for (final ep in episodes) {
      final watchedMs = _effectiveWatchedMs(ep);
      summedRecordedMs += watchedMs;

      final epDur = ep.durationMs >= 10 * 60 * 1000
          ? ep.durationMs
          : (watchedMs >= 15 * 60 * 1000 ? watchedMs : 0);
      if (epDur > 0) {
        durationSampleSum += epDur;
        durationSampleCount++;
      }

      final s = ep.season ?? 1;
      final e = ep.episode ?? 1;
      final prevMaxE = maxEpPerSeason[s] ?? 0;
      if (e > prevMaxE) {
        maxEpPerSeason[s] = e;
      }

      if (s > maxSeason || (s == maxSeason && e >= maxEpInMaxSeason)) {
        maxSeason = s;
        maxEpInMaxSeason = e;
        latestEpIsCompleted = ep.isCompleted || ep.progressPercent >= 0.85;
      }
    }

    final avgEpisodeDurationMs = durationSampleCount > 0
        ? (durationSampleSum ~/ durationSampleCount)
        : _kDefaultTvEpisodeDurationMs;

    // Calculate cumulative episodes implied by reaching (maxSeason, maxEpInMaxSeason).
    // Example: If a user watched The Rookie from Season 1 and is currently on Season 4 Episode 3,
    // prior seasons (S1..S3) represent at least 3 * 10 = 30 episodes + 2 completed in S4 = 32+ episodes.
    int impliedCumulativeEpisodes = 0;
    if (maxSeason > 1) {
      for (int s = 1; s < maxSeason; s++) {
        final int recordedMaxInSeason = maxEpPerSeason[s] ?? 0;
        impliedCumulativeEpisodes += math.max<int>(
          _kEstimatedEpisodesPerPriorSeason,
          recordedMaxInSeason,
        );
      }
    }
    final int completedInMaxSeason =
        math.max<int>(0, maxEpInMaxSeason - 1) + (latestEpIsCompleted ? 1 : 0);
    final int activeInMaxSeason = math.max<int>(1, maxEpInMaxSeason);
    final int totalImpliedEpisodes =
        impliedCumulativeEpisodes +
        math.max<int>(completedInMaxSeason, activeInMaxSeason);

    final int recordedCount = episodes.length;
    final int effectiveEpisodeCount = math.max<int>(
      recordedCount,
      totalImpliedEpisodes,
    );

    // If earlier seasons/episodes were not individually retained as separate keys in Hive,
    // add their estimated watch duration so multi-season series accurately reflect total hours watched.
    final int unrecordedPriorEpisodes = math.max<int>(
      0,
      (impliedCumulativeEpisodes + math.max<int>(0, maxEpInMaxSeason - 1)) -
          (recordedCount - 1),
    );
    final int seriesTotalWatchedMs =
        summedRecordedMs + (unrecordedPriorEpisodes * avgEpisodeDurationMs);

    totalWatchTimeMs += seriesTotalWatchedMs;
    totalEpisodesWatched += effectiveEpisodeCount;

    // Also attribute unrecorded prior episode minutes to the latest watched weekday
    // so the weekly chart remains proportional
    if (unrecordedPriorEpisodes > 0) {
      final int latestWeekday = (latest.lastWatchedAt.weekday - 1).clamp(0, 6);
      final int extraMins =
          ((unrecordedPriorEpisodes * avgEpisodeDurationMs) / 60000).round();
      if (weeklyMinutes[latestWeekday] < 180) {
        weeklyMinutes[latestWeekday] += math.min<int>(extraMins, 240);
      }
    }

    if (latestEpIsCompleted && unrecordedPriorEpisodes > 0) {
      completedCount += unrecordedPriorEpisodes;
    }

    aggregatedTitles.add(
      TopWatchedTitleItem(
        id: entry.key,
        mediaType: 'tv',
        title: latest.title,
        posterPath: latest.posterPath,
        totalWatchedMs: seriesTotalWatchedMs,
        episodesCount: effectiveEpisodeCount,
        latestSeason: maxSeason,
        latestEpisode: maxEpInMaxSeason,
      ),
    );
  }

  // Sort aggregated titles by totalWatchedMs descending!
  aggregatedTitles.sort(
    (a, b) => b.totalWatchedMs.compareTo(a.totalWatchedMs),
  );
  final topWatchedTitles = aggregatedTitles.take(5).toList();

  // Keep legacy topWatchedItems aligned with topWatchedTitles order
  final topWatchedItems = <WatchHistoryItem>[];
  for (final top in topWatchedTitles) {
    final match = history.cast<WatchHistoryItem?>().firstWhere(
          (h) => h != null && h.mediaType == top.mediaType && h.id == top.id,
          orElse: () => null,
        );
    if (match != null) {
      topWatchedItems.add(match);
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
      (((seedHash ~/ 13) + moviesWatchedCount * 7 + totalEpisodesWatched * 3) %
                  9000 +
              1000)
          .toString();

  final idCardNumber = '3273 • $earliestYear • $block3 • $block4';
  final atmCardNumber = '8842  $earliestYear  $block3  $block4';

  final topFlavors = _computeContentDna(
    history: history,
    watchlist: watchlist,
    moviesCount: moviesWatchedCount,
    episodesCount: totalEpisodesWatched,
    completedCount: completedCount,
  );

  return WatchInsights(
    totalWatchTimeMs: totalWatchTimeMs,
    moviesWatchedCount: moviesWatchedCount,
    episodesWatchedCount: totalEpisodesWatched,
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
    idCardNumber: idCardNumber,
    atmCardNumber: atmCardNumber,
    memberSinceYear: earliestYear.toString(),
    topFlavors: topFlavors,
    topWatchedItems: topWatchedItems,
    topWatchedTitles: topWatchedTitles,
  );
}

int _effectiveWatchedMs(WatchHistoryItem item) {
  if (item.isCompleted && item.durationMs > item.positionMs) {
    return item.durationMs;
  }
  if (item.positionMs > 0) {
    return item.positionMs;
  }
  if (item.isCompleted) {
    return item.mediaType == 'tv'
        ? _kDefaultTvEpisodeDurationMs
        : 90 * 60 * 1000;
  }
  return 0;
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
