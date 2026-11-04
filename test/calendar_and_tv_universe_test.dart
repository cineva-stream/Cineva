import 'package:flutter_test/flutter_test.dart';
import 'package:cineva/core/localization/app_language.dart';
import 'package:cineva/core/localization/app_strings.dart';
import 'package:cineva/features/calendar/data/models/upcoming_media_model.dart';
import 'package:cineva/features/tv_universe/data/tv_universe_registry.dart';
import 'package:cineva/features/tv_universe/domain/entities/tv_universe.dart';

void main() {
  group('UpcomingMediaModel Tests', () {
    test('Correctly parses upcoming movie JSON', () {
      final now = DateTime.now();
      final releaseDateStr =
          DateTime(now.year, now.month, now.day + 5).toIso8601String().split('T').first;

      final json = {
        'id': 1001,
        'title': 'Dune: Part Three',
        'overview': 'Paul Atreides continues his journey.',
        'poster_path': '/dune3.jpg',
        'backdrop_path': '/dune3_bg.jpg',
        'release_date': releaseDateStr,
        'vote_average': 8.9,
        'popularity': 350.0,
        'genre_ids': [878, 12],
      };

      final item = UpcomingMediaModel.fromJson(json, mediaType: 'movie');
      expect(item.id, 1001);
      expect(item.title, 'Dune: Part Three');
      expect(item.isMovie, isTrue);
      expect(item.isTv, isFalse);
      expect(item.releaseDate, releaseDateStr);
      expect(item.daysUntilRelease, 5);
      expect(item.mediaTypeBadge, 'MOVIE');

      const sId = AppStrings(AppLanguage.id);
      expect(item.countdownLabel(sId), '5 Hari Lagi');

      const sEn = AppStrings(AppLanguage.en);
      expect(item.countdownLabel(sEn), 'In 5 Days');
    });

    test('Correctly parses upcoming TV series JSON', () {
      final now = DateTime.now();
      final releaseDateStr =
          DateTime(now.year, now.month, now.day + 1).toIso8601String().split('T').first;

      final json = {
        'id': 2002,
        'name': 'The Last of Us Season 2',
        'overview': 'Five years later...',
        'poster_path': '/tlou2.jpg',
        'backdrop_path': '/tlou2_bg.jpg',
        'first_air_date': releaseDateStr,
        'vote_average': 9.1,
        'popularity': 520.0,
        'genre_ids': [18, 10759],
      };

      final item = UpcomingMediaModel.fromJson(json, mediaType: 'tv');
      expect(item.id, 2002);
      expect(item.title, 'The Last of Us Season 2');
      expect(item.isMovie, isFalse);
      expect(item.isTv, isTrue);
      expect(item.daysUntilRelease, 1);
      expect(item.mediaTypeBadge, 'TV');

      const sId = AppStrings(AppLanguage.id);
      expect(item.countdownLabel(sId), 'Rilis Besok');

      const sEn = AppStrings(AppLanguage.en);
      expect(item.countdownLabel(sEn), 'Releases Tomorrow');
    });

    test('Handles release date today', () {
      final now = DateTime.now();
      final releaseDateStr =
          DateTime(now.year, now.month, now.day).toIso8601String().split('T').first;

      final json = {
        'id': 3003,
        'title': 'Release Today Special',
        'release_date': releaseDateStr,
      };

      final item = UpcomingMediaModel.fromJson(json, mediaType: 'movie');
      expect(item.daysUntilRelease, 0);

      const sId = AppStrings(AppLanguage.id);
      expect(item.countdownLabel(sId), 'Rilis Hari Ini');

      const sEn = AppStrings(AppLanguage.en);
      expect(item.countdownLabel(sEn), 'Releases Today');
    });
  });

  group('TvUniverseRegistry Tests', () {
    test('Finds Game of Thrones universe for House of the Dragon (ID 94997)', () {
      final universe = TvUniverseRegistry.findUniverseByTvId(94997);
      expect(universe, isNotNull);
      expect(universe!.id, 'got-universe');
      expect(universe.name, 'Semesta Game of Thrones (Westeros)');
      expect(universe.entries.length, greaterThanOrEqualTo(2));

      final index = universe.indexOfShow(94997);
      expect(index, 1); // Prequel is #1 in story order

      final entry = universe.entries.firstWhere((e) => e.tmdbTvId == 94997);
      expect(entry.type, TvUniverseEntryType.prequel);
      expect(entry.title, 'House of the Dragon');
    });

    test('Finds Breaking Bad universe for Better Call Saul (ID 60059)', () {
      final universe = TvUniverseRegistry.findUniverseByTvId(60059);
      expect(universe, isNotNull);
      expect(universe!.id, 'breaking-bad-universe');
      expect(universe.name, 'Semesta Breaking Bad');

      final bcsIndex = universe.indexOfShow(60059);
      expect(bcsIndex, 1); // Better Call Saul is Prequel (#1 in story order)

      final bbIndex = universe.indexOfShow(1396);
      expect(bbIndex, 2); // Breaking Bad is Main Series (#2)
    });

    test('Finds Naruto universe for Naruto Shippūden (ID 31910)', () {
      final universe = TvUniverseRegistry.findUniverseByTvId(31910);
      expect(universe, isNotNull);
      expect(universe!.id, 'naruto-universe');
      expect(universe.entries.length, 3); // Naruto, Shippuden, Boruto

      final shippudenIndex = universe.indexOfShow(31910);
      expect(shippudenIndex, 2);

      final entry = universe.entries.firstWhere((e) => e.tmdbTvId == 31910);
      expect(entry.type, TvUniverseEntryType.sequel);
    });

    test('Returns null for unknown TV series ID', () {
      final universe = TvUniverseRegistry.findUniverseByTvId(99999999);
      expect(universe, isNull);
    });

    test('Registry contains all major requested universes', () {
      final all = TvUniverseRegistry.allUniverses;
      final ids = all.map((u) => u.id).toSet();

      expect(ids.contains('naruto-universe'), isTrue);
      expect(ids.contains('dragon-ball-universe'), isTrue);
      expect(ids.contains('breaking-bad-universe'), isTrue);
      expect(ids.contains('got-universe'), isTrue);
      expect(ids.contains('twd-universe'), isTrue);
      expect(ids.contains('the-boys-universe'), isTrue);
      expect(ids.contains('money-heist-universe'), isTrue);
      expect(ids.contains('yellowstone-universe'), isTrue);
    });

    test('Registry entries have valid poster paths and titles', () {
      final all = TvUniverseRegistry.allUniverses;
      for (final universe in all) {
        for (final entry in universe.entries) {
          expect(entry.title.isNotEmpty, isTrue);
          expect(entry.posterPath, isNotNull);
          expect(entry.posterPath!.startsWith('/'), isTrue);
        }
      }
    });

    test('Header image resolution handles missing backdrop using fallback poster', () {
      const universeNoBackdrop = TvUniverse(
        id: 'sample-no-bg',
        name: 'Sample Universe',
        description: 'Sample description',
        backdropPath: null,
        posterPath: null,
        entries: [],
      );

      // Verify that if both backdropPath and posterPath are null, fallbackPoster is used
      const fallbackPoster = '/fallback_poster.jpg';
      const fallbackBackdrop = '/fallback_backdrop.jpg';

      String? resolveHeaderImage(TvUniverse universe, {String? fbBackdrop, String? fbPoster}) {
        if (universe.backdropPath != null && universe.backdropPath!.trim().isNotEmpty) {
          return universe.backdropPath;
        }
        if (fbBackdrop != null && fbBackdrop.trim().isNotEmpty) {
          return fbBackdrop;
        }
        if (universe.posterPath != null && universe.posterPath!.trim().isNotEmpty) {
          return universe.posterPath;
        }
        if (fbPoster != null && fbPoster.trim().isNotEmpty) {
          return fbPoster;
        }
        return null;
      }

      // When backdrop is available on caller
      expect(
        resolveHeaderImage(universeNoBackdrop, fbBackdrop: fallbackBackdrop, fbPoster: fallbackPoster),
        '/fallback_backdrop.jpg',
      );

      // When only poster is available on caller (no backdrop anywhere)
      expect(
        resolveHeaderImage(universeNoBackdrop, fbPoster: fallbackPoster),
        '/fallback_poster.jpg',
      );
    });
  });
}

