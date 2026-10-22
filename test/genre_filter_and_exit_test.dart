import 'package:cineva/core/constants/genre_constants.dart';
import 'package:cineva/features/home/domain/entities/movie.dart';
import 'package:cineva/features/home/domain/entities/tv_series.dart';
import 'package:cineva/shared/widgets/exit_confirmation_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GenreConstants and GenreFilter Model Tests', () {
    test('Default all-genre filter matches everything', () {
      final allGenre = GenreConstants.filters.firstWhere((g) => g.id == 'all');
      expect(allGenre.id, 'all');

      const movie = Movie(
        id: 1,
        title: 'Action Movie',
        overview: 'Overview',
        posterPath: '/path.jpg',
        backdropPath: '/back.jpg',
        voteAverage: 8.5,
        releaseDate: '2025-01-01',
        genreIds: [28, 12],
      );

      const tv = TvSeries(
        id: 10,
        name: 'Action Series',
        overview: 'TV Overview',
        posterPath: '/tv.jpg',
        backdropPath: '/tv_back.jpg',
        voteAverage: 8.0,
        firstAirDate: '2024-05-01',
        genreIds: [10759],
      );

      expect(allGenre.matchesMovie(movie), isTrue);
      expect(allGenre.matchesTv(tv), isTrue);
    });

    test('Action genre correctly matches action movies and TV series', () {
      final actionGenre = GenreConstants.filters.firstWhere((g) => g.id == 'action');
      expect(actionGenre.label, 'Action');

      const actionMovie = Movie(
        id: 1,
        title: 'Action Movie',
        overview: 'Overview',
        posterPath: '/path.jpg',
        backdropPath: '/back.jpg',
        voteAverage: 8.5,
        releaseDate: '2025-01-01',
        genreIds: [28, 878],
      );

      const romanceMovie = Movie(
        id: 2,
        title: 'Romance Movie',
        overview: 'Overview',
        posterPath: '/path.jpg',
        backdropPath: '/back.jpg',
        voteAverage: 7.0,
        releaseDate: '2025-01-01',
        genreIds: [10749, 35],
      );

      const actionTv = TvSeries(
        id: 10,
        name: 'Action Series',
        overview: 'TV Overview',
        posterPath: '/tv.jpg',
        backdropPath: '/tv_back.jpg',
        voteAverage: 8.0,
        firstAirDate: '2024-05-01',
        genreIds: [10759, 18],
      );

      const comedyTv = TvSeries(
        id: 11,
        name: 'Comedy Series',
        overview: 'TV Overview',
        posterPath: '/tv.jpg',
        backdropPath: '/tv_back.jpg',
        voteAverage: 7.5,
        firstAirDate: '2024-05-01',
        genreIds: [35],
      );

      expect(actionGenre.matchesMovie(actionMovie), isTrue);
      expect(actionGenre.matchesMovie(romanceMovie), isFalse);
      expect(actionGenre.matchesTv(actionTv), isTrue);
      expect(actionGenre.matchesTv(comedyTv), isFalse);
    });

    test('Sci-Fi genre matches science fiction movies and TV series', () {
      final sciFiGenre = GenreConstants.filters.firstWhere((g) => g.id == 'scifi');
      expect(sciFiGenre.label, 'Sci-Fi');

      const sciFiMovie = Movie(
        id: 3,
        title: 'Sci-Fi Movie',
        overview: 'Overview',
        posterPath: '/path.jpg',
        backdropPath: '/back.jpg',
        voteAverage: 8.8,
        releaseDate: '2025-01-01',
        genreIds: [878],
      );

      const sciFiTv = TvSeries(
        id: 12,
        name: 'Sci-Fi TV',
        overview: 'TV Overview',
        posterPath: '/tv.jpg',
        backdropPath: '/tv_back.jpg',
        voteAverage: 8.1,
        firstAirDate: '2024-05-01',
        genreIds: [10765],
      );

      expect(sciFiGenre.matchesMovie(sciFiMovie), isTrue);
      expect(sciFiGenre.matchesTv(sciFiTv), isTrue);
    });

    test('All genres in filters have non-empty ID, label and valid fields', () {
      expect(GenreConstants.filters.length, greaterThanOrEqualTo(10));
      for (final genre in GenreConstants.filters) {
        expect(genre.id.isNotEmpty, isTrue);
        expect(genre.label.isNotEmpty, isTrue);
      }
    });
  });

  group('ExitConfirmationBottomSheet Widget Tests', () {
    testWidgets('Renders exit bottom sheet with Keluar and Batal buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ExitConfirmationBottomSheet.show(context),
                child: const Text('Show Sheet'),
              ),
            ),
          ),
        ),
      );

      // Tap button to open sheet
      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      // Check title and content
      expect(find.text('Keluar dari Cineva?'), findsOneWidget);
      expect(
        find.text('Apakah Anda yakin ingin menutup dan keluar dari aplikasi Cineva?'),
        findsOneWidget,
      );

      // Check actions
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Keluar'), findsOneWidget);

      // Tap 'Batal' to dismiss smoothly
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(find.text('Keluar dari Cineva?'), findsNothing);
    });
  });
}
