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
  });
}
