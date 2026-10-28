import 'package:flutter_test/flutter_test.dart';
import 'package:cineva/features/history/data/models/watch_history_item.dart';

void main() {
  group('WatchHistoryItem model tests', () {
    test('Calculates progress ratio and in-progress/completed states correctly', () {
      final inProgress = WatchHistoryItem(
        id: 123,
        imdbId: 'tt1234567',
        title: 'Interstellar',
        mediaType: 'movie',
        positionMs: 60 * 60 * 1000, // 1 hour
        durationMs: 2 * 60 * 60 * 1000, // 2 hours
        lastWatchedAt: DateTime.now(),
      );

      expect(inProgress.progress, closeTo(0.5, 0.01));
      expect(inProgress.progressPercent, 50);
      expect(inProgress.isInProgress, isTrue);
      expect(inProgress.isCompleted, isFalse);
      expect(inProgress.progressSubtitle, 'Sisa 1j 0m');
    });

    test('Identifies completed media when flag is set or progress exceeds 95%', () {
      final completed = WatchHistoryItem(
        id: 999,
        imdbId: 'tt9999999',
        title: 'Inception',
        mediaType: 'movie',
        positionMs: 96,
        durationMs: 100,
        lastWatchedAt: DateTime.now(),
      );

      expect(completed.progress, 0.96);
      expect(completed.isInProgress, isFalse); // > 95% is considered completed/watched
    });

    test('Json serialization and deserialization roundtrip', () {
      final now = DateTime(2026, 10, 22, 12, 0, 0);
      final item = WatchHistoryItem(
        id: 500,
        imdbId: 'tt500500',
        title: 'Breaking Bad',
        mediaType: 'tv',
        posterPath: '/poster.jpg',
        backdropPath: '/backdrop.jpg',
        season: 1,
        episode: 3,
        episodeTitle: '...And the Bag\'s in the River',
        positionMs: 1500000,
        durationMs: 3000000,
        lastWatchedAt: now,
      );

      final json = item.toJson();
      final restored = WatchHistoryItem.fromJson(json);

      expect(restored.id, item.id);
      expect(restored.title, item.title);
      expect(restored.mediaType, 'tv');
      expect(restored.season, 1);
      expect(restored.episode, 3);
      expect(restored.episodeTitle, '...And the Bag\'s in the River');
      expect(restored.positionMs, 1500000);
      expect(restored.durationMs, 3000000);
      expect(restored.lastWatchedAt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });

    test('Generates episode-specific key for TV series so episodes are not overwritten', () {
      final ep1 = WatchHistoryItem(
        id: 1399,
        mediaType: 'tv',
        title: 'Game of Thrones',
        season: 1,
        episode: 1,
        positionMs: 3600000,
        durationMs: 3600000,
        lastWatchedAt: DateTime.now(),
        isCompleted: true,
      );

      final ep2 = WatchHistoryItem(
        id: 1399,
        mediaType: 'tv',
        title: 'Game of Thrones',
        season: 1,
        episode: 2,
        positionMs: 120000,
        durationMs: 3600000,
        lastWatchedAt: DateTime.now(),
        isCompleted: false,
      );

      final movie = WatchHistoryItem(
        id: 550,
        mediaType: 'movie',
        title: 'Fight Club',
        positionMs: 5000000,
        durationMs: 8000000,
        lastWatchedAt: DateTime.now(),
      );

      expect(ep1.key, 'tv_1399_s1_e1');
      expect(ep2.key, 'tv_1399_s1_e2');
      expect(ep1.key, isNot(equals(ep2.key)));
      expect(ep1.isCompleted, isTrue);
      expect(movie.key, 'movie_550');
    });

    test('Ensures movie marked Belum (< 95% clamped) appears in Continue Watching', () {
      // Total duration 100 min, user was at 98 min (2 min remaining <= 12 min)
      // Clamped to 94%
      final durMs = 100 * 60 * 1000;
      final clampedPosMs = (durMs * 0.94).toInt();
      final movieNotYet = WatchHistoryItem(
        id: 888,
        mediaType: 'movie',
        title: 'Dune',
        positionMs: clampedPosMs,
        durationMs: durMs,
        lastWatchedAt: DateTime.now(),
        isCompleted: false,
      );

      expect(movieNotYet.progress, closeTo(0.94, 0.001));
      expect(movieNotYet.isInProgress, isTrue); // Appears in Continue Watching!
      expect(movieNotYet.isCompleted, isFalse);

      final movieDone = WatchHistoryItem(
        id: 888,
        mediaType: 'movie',
        title: 'Dune',
        positionMs: durMs,
        durationMs: durMs,
        lastWatchedAt: DateTime.now(),
        isCompleted: true,
      );

      expect(movieDone.isCompleted, isTrue); // Appears in Completed!
      expect(movieDone.isInProgress, isFalse);
    });
  });
}
