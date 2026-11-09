import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cineva/core/constants/app_constants.dart';
import 'package:cineva/features/home/domain/entities/movie.dart';
import 'package:cineva/features/home/domain/entities/tv_series.dart';
import 'package:cineva/features/home/presentation/providers/home_providers.dart';
import 'package:cineva/features/home/presentation/screens/home_screen.dart';
import 'package:cineva/features/home/presentation/widgets/movie_carousel.dart';
import 'package:cineva/features/search/domain/entities/streaming_platform.dart';
import 'package:cineva/features/search/presentation/providers/platform_catalog_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('cineva_catalog_test_');
    Hive.init(tempDir.path);
    await Hive.openBox(AppConstants.settingsBox);
    await Hive.openBox(AppConstants.historyBox);
    await Hive.openBox(AppConstants.watchlistBox);
    await Hive.openBox(AppConstants.downloadsBox);
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('StreamingPlatform Enhanced Provider Query Tests', () {
    test('All platforms provide valid multi-channel TMDB provider queries', () {
      final max = StreamingPlatform.fromId('max');
      expect(max.providerId, 1899);
      expect(max.watchProviderQuery, '1899|1825');

      final paramount = StreamingPlatform.fromId('paramount');
      expect(paramount.providerId, 531);
      expect(paramount.watchProviderQuery, '582|2303|531');

      final peacock = StreamingPlatform.fromId('peacock');
      expect(peacock.providerId, 387);
      expect(peacock.watchProviderQuery, '386|387');

      final prime = StreamingPlatform.fromId('prime');
      expect(prime.providerId, 9);
      expect(prime.watchProviderQuery, '9|119');

      final netflix = StreamingPlatform.fromId('netflix');
      expect(netflix.watchProviderQuery, '8');

      final disney = StreamingPlatform.fromId('disney');
      expect(disney.watchProviderQuery, '337');
    });
  });

  group('TvSeries.toMovie Adaptation Tests', () {
    test('Properly converts TvSeries to Movie entity with mediaType tv', () {
      const tv = TvSeries(
        id: 999,
        name: 'Breaking Bad',
        overview: 'A chemistry teacher diagnosed with cancer...',
        firstAirDate: '2008-01-20',
        voteAverage: 9.5,
        genreIds: [18, 80],
        originCountry: ['US'],
      );

      final movie = tv.toMovie();
      expect(movie.id, 999);
      expect(movie.title, 'Breaking Bad');
      expect(movie.releaseDate, '2008-01-20');
      expect(movie.year, '2008');
      expect(movie.mediaType, 'tv');
      expect(movie.voteAverage, 9.5);
      expect(movie.genreIds, [18, 80]);
    });
  });

  group('MovieCarousel 8-10 Items & TV Badge Tests', () {
    testWidgets('MovieCarousel takes up to 10 items and formats TV badge', (tester) async {
      final testItems = List.generate(
        12,
        (i) => Movie(
          id: i + 1,
          title: 'Movie/TV Title $i',
          overview: 'Overview $i',
          releaseDate: '2026-01-0$i',
          voteAverage: 8.0,
          mediaType: i.isEven ? 'tv' : 'movie',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MovieCarousel(movies: testItems),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(MovieCarousel), findsOneWidget);
      // First item is TV (index 0 is even)
      expect(find.text('POPULER TV #1'), findsOneWidget);
    });
  });

  group('Platform Catalog Pagination Provider Tests', () {
    test('PaginatedPlatformState copyWith maintains or updates fields', () {
      const state = PaginatedPlatformState<Movie>(
        items: [],
        page: 1,
        isLoading: true,
        hasMore: true,
      );

      final updated = state.copyWith(
        items: const [
          Movie(id: 1, title: 'Test', overview: '', releaseDate: '', voteAverage: 7.0),
        ],
        page: 2,
        isLoading: false,
        isLoadingMore: false,
        hasMore: true,
      );

      expect(updated.items.length, 1);
      expect(updated.page, 2);
      expect(updated.isLoading, isFalse);
      expect(updated.hasMore, isTrue);
    });
  });

  group('HomeScreen Filter Switching Tests', () {
    testWidgets('Switching to Film shows Seluruh Film grid and hides horizontal sections', (tester) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const dummyMovie = Movie(
        id: 1,
        title: 'Cyberpunk Premiere',
        overview: 'Action futuristic journey',
        voteAverage: 8.5,
        releaseDate: '2026-05-10',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeFilterProvider.overrideWith((ref) => HomeCategoryFilter.movies),
            trendingMoviesProvider.overrideWith((ref) => Future.value([dummyMovie])),
            popularMoviesProvider.overrideWith((ref) => Future.value([dummyMovie])),
            paginatedPopularMoviesProvider.overrideWith((ref) {
              return PaginatedPopularMoviesNotifier(
                ref.watch(movieRepositoryProvider),
                ref.watch(contentPreferenceProvider),
              );
            }),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Seluruh Film'), findsOneWidget);
      // Top 10 horizontal list should be hidden in Film filter mode
      expect(find.text('Top 10 Hari Ini'), findsNothing);
    });

    testWidgets('Switching to Serial TV shows Seluruh Serial TV grid and MovieCarousel', (tester) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const dummyTv = TvSeries(
        id: 101,
        name: 'Arcane League',
        overview: 'Animation drama adventure',
        voteAverage: 9.2,
        firstAirDate: '2024-11-09',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeFilterProvider.overrideWith((ref) => HomeCategoryFilter.tv),
            popularTvProvider.overrideWith((ref) => Future.value([dummyTv])),
            paginatedPopularTvProvider.overrideWith((ref) {
              return PaginatedPopularTvNotifier(
                ref.watch(movieRepositoryProvider),
                ref.watch(contentPreferenceProvider),
              );
            }),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Seluruh Serial TV'), findsOneWidget);
      expect(find.byType(MovieCarousel), findsOneWidget);
      expect(find.text('Top 10 Hari Ini'), findsNothing);
    });
  });
}
