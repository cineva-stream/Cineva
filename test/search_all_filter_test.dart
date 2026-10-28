import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cineva/core/constants/app_constants.dart';
import 'package:cineva/core/localization/app_language.dart';
import 'package:cineva/core/localization/app_strings.dart';
import 'package:cineva/features/home/domain/entities/movie.dart';
import 'package:cineva/features/home/domain/entities/tv_series.dart';
import 'package:cineva/features/search/presentation/screens/search_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_search_all_test_');
    Hive.init(tempDir.path);
    await Hive.openBox(AppConstants.settingsBox);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Search All Tab Filter Tests', () {
    test('Default search tab is 0 (All)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(searchTabProvider), 0);

      container.read(searchTabProvider.notifier).state = 1;
      expect(container.read(searchTabProvider), 1);

      container.read(searchTabProvider.notifier).state = 2;
      expect(container.read(searchTabProvider), 2);
    });

    test('AppStrings provides correct translations for searchTabAll', () {
      final idStrings = AppStrings(AppLanguage.id);
      expect(idStrings.searchTabAll, 'Semua');
      expect(idStrings.searchTabMovies, 'Film');
      expect(idStrings.searchTabTv, 'Serial TV');

      final enStrings = AppStrings(AppLanguage.en);
      expect(enStrings.searchTabAll, 'All');
      expect(enStrings.searchTabMovies, 'Movies');
      expect(enStrings.searchTabTv, 'TV Shows');
    });

    testWidgets('SearchScreen displays All, Movies, and TV Shows filter chips when query is active', (tester) async {
      const mockMovie = Movie(
        id: 101,
        title: 'Avengers Secret Wars',
        overview: 'Action superhero movie',
        posterPath: '/avengers.jpg',
        backdropPath: '/avengers_bg.jpg',
        voteAverage: 9.1,
        releaseDate: '2026-05-01',
        genreIds: [28, 12],
      );

      const mockTv = TvSeries(
        id: 202,
        name: 'Daredevil Born Again',
        overview: 'Action superhero series',
        posterPath: '/daredevil.jpg',
        backdropPath: '/daredevil_bg.jpg',
        voteAverage: 8.9,
        firstAirDate: '2025-03-01',
        genreIds: [28, 80],
      );

      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            searchQueryProvider.overrideWith((ref) => 'Avengers'),
            searchTabProvider.overrideWith((ref) => 0),
            searchMovieResultsProvider.overrideWith((ref) => Future.value([mockMovie])),
            searchTvResultsProvider.overrideWith((ref) => Future.value([mockTv])),
          ],
          child: const MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that "Semua", "Film", and "Serial TV" filter chips are present
      expect(find.text('Semua'), findsWidgets);
      expect(find.text('Film'), findsWidgets);
      expect(find.text('Serial TV'), findsWidgets);

      // In "All" tab (index 0), both movies and tv series section items appear
      expect(find.text('Avengers Secret Wars'), findsOneWidget);
      expect(find.text('Daredevil Born Again'), findsOneWidget);

      // Tap "Film" filter chip
      await tester.tap(find.text('Film').first);
      await tester.pumpAndSettle();

      // Only movies shown
      expect(find.text('Avengers Secret Wars'), findsOneWidget);
      expect(find.text('Daredevil Born Again'), findsNothing);

      // Tap "Serial TV" filter chip
      await tester.tap(find.text('Serial TV').first);
      await tester.pumpAndSettle();

      // Only TV series shown
      expect(find.text('Avengers Secret Wars'), findsNothing);
      expect(find.text('Daredevil Born Again'), findsOneWidget);
    });
  });
}
