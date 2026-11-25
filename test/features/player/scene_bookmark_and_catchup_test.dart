import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cineva/core/constants/app_constants.dart';
import 'package:cineva/core/localization/app_language.dart';
import 'package:cineva/core/localization/app_strings.dart';
import 'package:cineva/features/detail/data/services/media_share_service.dart';
import 'package:cineva/features/player/data/services/scene_bookmark_service.dart';
import 'package:cineva/features/player/presentation/screens/player_screen.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('cineva_bookmark_test_');
    Hive.init(tempDir.path);
    await Hive.openBox(AppConstants.settingsBox);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('MediaShareService Deep-Link URL Builder', () {
    test('builds rich movie and tv GitHub Pages deep-link URLs', () {
      final movieUrl = MediaShareService.buildShareUrl(
        mediaType: 'movie',
        tmdbId: 27205,
        title: 'Inception',
        year: '2010',
        rating: 8.8,
        posterPath: '/oYuLEt3zVCKq57qu2F8dT7NIa6f.jpg',
        overview: 'A thief who steals corporate secrets.',
      );

      expect(
        movieUrl,
        startsWith('https://cineva-stream.github.io/Cineva/movie/27205?'),
      );
      final parsed = Uri.parse(movieUrl);
      expect(parsed.queryParameters['title'], 'Inception');
      expect(parsed.queryParameters['year'], '2010');
      expect(parsed.queryParameters['rating'], '8.8');
      expect(
        parsed.queryParameters['poster'],
        '/oYuLEt3zVCKq57qu2F8dT7NIa6f.jpg',
      );
    });
  });

  group('SceneBookmarkService CRUD & Timestamp Formatting', () {
    test('formats duration milliseconds into MM:SS and HH:MM:SS', () {
      expect(SceneBookmark.formatDurationMs(65000), '01:05');
      expect(SceneBookmark.formatDurationMs(3661000), '01:01:01');
    });

    test('saves, sorts by timestamp, and deletes scene bookmarks in Hive', () async {
      final mediaKey = SceneBookmarkService.buildMediaKey(
        tmdbId: 1399,
        title: 'Game of Thrones',
        season: 1,
        episode: 1,
      );
      expect(mediaKey, 'tmdb_1399_s1_e1');

      await SceneBookmarkService.addBookmark(
        SceneBookmark(
          id: 'b2',
          mediaKey: mediaKey,
          title: 'Game of Thrones',
          episodeLabel: 'S01E01',
          positionMs: 180000,
          quoteText: 'Winter is coming.',
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      await SceneBookmarkService.addBookmark(
        SceneBookmark(
          id: 'b1',
          mediaKey: mediaKey,
          title: 'Game of Thrones',
          episodeLabel: 'S01E01',
          positionMs: 45000,
          quoteText: 'The things I do for love.',
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      final list = SceneBookmarkService.getBookmarks(mediaKey);
      expect(list.length, 2);
      // Sorted ascending by positionMs
      expect(list.first.id, 'b1');
      expect(list.first.formattedTimestamp, '00:45');
      expect(list.last.id, 'b2');
      expect(list.last.formattedTimestamp, '03:00');

      final afterDelete = await SceneBookmarkService.deleteBookmark(
        mediaKey,
        'b1',
      );
      expect(afterDelete.length, 1);
      expect(afterDelete.single.id, 'b2');
    });
  });

  group('Watch Party Smooth Micro-Speed Catch-Up (1.05x / 0.95x)', () {
    test('returns 1.05x when guest is 1.0s to 3.5s behind target', () {
      expect(PlayerScreen.computeWatchPartyCatchUpRate(0.4), 1.0);
      expect(PlayerScreen.computeWatchPartyCatchUpRate(1.0), 1.05);
      expect(PlayerScreen.computeWatchPartyCatchUpRate(2.2), 1.05);
      expect(PlayerScreen.computeWatchPartyCatchUpRate(3.5), 1.05);
      expect(PlayerScreen.computeWatchPartyCatchUpRate(4.0), 1.0);
    });

    test('returns 0.95x when guest is 1.0s to 3.0s ahead of target', () {
      expect(PlayerScreen.computeWatchPartyCatchUpRate(-0.5), 1.0);
      expect(PlayerScreen.computeWatchPartyCatchUpRate(-1.2), 0.95);
      expect(PlayerScreen.computeWatchPartyCatchUpRate(-3.0), 0.95);
      expect(PlayerScreen.computeWatchPartyCatchUpRate(-3.6), 1.0);
    });
  });

  group('3-Language Localization & ID Card Terminology', () {
    test('provides ID, EN, and HI translations with ID Card terminology', () {
      for (final lang in AppLanguage.values) {
        final s = AppStrings(lang);
        expect(s.insightsCardModeId, isNotEmpty);
        expect(s.insightsCardModeId.toUpperCase().contains('ID'), isTrue);
        expect(s.detailShareTooltip, isNotEmpty);
        expect(s.sceneBookmarkTitle, isNotEmpty);
        expect(s.sceneQuoteShareBtn, isNotEmpty);
      }
    });
  });
}
