import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cineva/core/utils/tmdb_genres.dart';
import 'package:cineva/features/home/domain/entities/movie.dart';
import 'package:cineva/features/home/presentation/widgets/movie_card.dart';
import 'package:cineva/features/home/presentation/widgets/section_header.dart';
import 'package:cineva/app/theme/app_colors.dart';

void main() {
  group('TmdbGenres utility tests', () {
    test('Correctly maps well-known movie genre IDs to Indonesian names', () {
      expect(TmdbGenres.getGenreName(28), equals('Aksi'));
      expect(TmdbGenres.getGenreName(12), equals('Petualangan'));
      expect(TmdbGenres.getGenreName(878), equals('Sci-Fi'));
      expect(TmdbGenres.getGenreName(18), equals('Drama'));
      expect(TmdbGenres.getGenreName(27), equals('Horor'));
      expect(TmdbGenres.getGenreName(99999), isEmpty);
    });

    test('Correctly formats multiple genres with separator', () {
      final formatted = TmdbGenres.getFormattedGenres([28, 878, 12], limit: 2);
      expect(formatted, equals('Aksi • Sci-Fi'));
    });

    test('Returns primary genre with fallback', () {
      expect(TmdbGenres.getPrimaryGenre([878, 28]), equals('Sci-Fi'));
      expect(TmdbGenres.getPrimaryGenre([], fallback: 'Film'), equals('Film'));
    });
  });

  group('AppColors launcher icon alignment tests', () {
    test('Primary color is Cinema Amber and background is Deep Obsidian', () {
      expect(AppColors.primary, equals(const Color(0xFFFF9500)));
      expect(AppColors.background, equals(const Color(0xFF0A0A0C)));
      expect(AppColors.surface, equals(const Color(0xFF121217)));
    });
  });

  group('SectionHeader widget tests', () {
    testWidgets('Renders title, indicator bar, and action button', (tester) async {
      bool seeAllTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: 'Film Populer',
              icon: Icons.local_fire_department,
              onSeeAll: () => seeAllTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Film Populer'), findsOneWidget);
      expect(find.text('Lihat Semua'), findsOneWidget);

      await tester.tap(find.text('Lihat Semua'));
      expect(seeAllTapped, isTrue);
    });
  });

  group('MovieCard and Top10MovieCard tests', () {
    const testMovie = Movie(
      id: 12345,
      title: 'Dune: Part Two',
      overview: 'Paul Atreides unites with Chani and the Fremen...',
      posterPath: '/8cdWjvZQUExUUTzyp4t6EDMubfO.jpg',
      backdropPath: '/xOMo8BRK7PfcJv9JCnx7s5200.jpg',
      voteAverage: 8.5,
      releaseDate: '2024-03-01',
      genreIds: [878, 12],
    );

    testWidgets('MovieCard renders title, rating, 4K badge, and genre', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MovieCard(movie: testMovie),
            ),
          ),
        ),
      );

      expect(find.text('Dune: Part Two'), findsOneWidget);
      expect(find.text('8.5'), findsOneWidget);
      expect(find.text('4K'), findsOneWidget);
      expect(find.text('Sci-Fi'), findsOneWidget);
    });

    testWidgets('Top10MovieCard displays rank badge and rank number', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Top10MovieCard(movie: testMovie, rank: 1),
            ),
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
      expect(find.text('TOP 1'), findsOneWidget);
      expect(find.text('Dune: Part Two'), findsOneWidget);
    });
  });
}
