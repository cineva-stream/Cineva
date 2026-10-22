import 'package:flutter_test/flutter_test.dart';
import 'package:cineva/core/constants/content_preference.dart';
import 'package:cineva/features/home/domain/entities/movie.dart';
import 'package:cineva/features/home/domain/entities/tv_series.dart';

void main() {
  group('ContentPreference enum & fromCode tests', () {
    test('Correctly decodes from code strings', () {
      expect(ContentPreference.fromCode('all'), equals(ContentPreference.all));
      expect(ContentPreference.fromCode('indonesia'), equals(ContentPreference.indonesia));
      expect(ContentPreference.fromCode('anime'), equals(ContentPreference.anime));
      expect(ContentPreference.fromCode('hollywood'), equals(ContentPreference.hollywood));
      expect(ContentPreference.fromCode('korea'), equals(ContentPreference.korea));
      expect(ContentPreference.fromCode('japan'), equals(ContentPreference.japan));
      expect(ContentPreference.fromCode('bollywood'), equals(ContentPreference.bollywood));
      expect(ContentPreference.fromCode('unknown_code'), equals(ContentPreference.all));
      expect(ContentPreference.fromCode(null), equals(ContentPreference.all));
    });
  });

  group('ContentPreference matching logic tests', () {
    const indonesianMovie = Movie(
      id: 1,
      title: 'Agak Laen',
      overview: 'Empat sekawan penjaga rumah hantu...',
      voteAverage: 8.2,
      releaseDate: '2024-02-01',
      originalLanguage: 'id',
      originCountry: ['ID'],
    );

    const animeMovie = Movie(
      id: 2,
      title: 'Suzume',
      overview: 'Petualangan fantasi Suzume...',
      voteAverage: 8.0,
      releaseDate: '2022-11-11',
      originalLanguage: 'ja',
      genreIds: [16, 14], // 16 = Animation
      originCountry: ['JP'],
    );

    const hollywoodMovie = Movie(
      id: 3,
      title: 'Deadpool & Wolverine',
      overview: 'Wade Wilson and Logan...',
      voteAverage: 7.8,
      releaseDate: '2024-07-26',
      originalLanguage: 'en',
      originCountry: ['US'],
    );

    const koreanMovie = Movie(
      id: 4,
      title: 'Parasite',
      overview: 'Keluarga Kim yang miskin...',
      voteAverage: 8.5,
      releaseDate: '2019-05-30',
      originalLanguage: 'ko',
      originCountry: ['KR'],
    );

    test('Indonesia preference matches Indonesian movies and excludes others', () {
      final pref = ContentPreference.indonesia;
      expect(pref.matchesMovie(indonesianMovie), isTrue);
      expect(pref.matchesMovie(animeMovie), isFalse);
      expect(pref.matchesMovie(hollywoodMovie), isFalse);
      expect(pref.matchesMovie(koreanMovie), isFalse);
    });

    test('Anime preference matches Japanese animation movies and excludes non-anime', () {
      final pref = ContentPreference.anime;
      expect(pref.matchesMovie(animeMovie), isTrue);
      expect(pref.matchesMovie(indonesianMovie), isFalse);
      expect(pref.matchesMovie(hollywoodMovie), isFalse);
    });

    test('Korea preference matches Korean titles', () {
      final pref = ContentPreference.korea;
      expect(pref.matchesMovie(koreanMovie), isTrue);
      expect(pref.matchesMovie(indonesianMovie), isFalse);
    });

    test('All preference returns false for matchesMovie (no filter reordering)', () {
      final pref = ContentPreference.all;
      expect(pref.matchesMovie(indonesianMovie), isFalse);
      expect(pref.matchesMovie(animeMovie), isFalse);
    });
  });

  group('ContentPreference Search Priority Reordering', () {
    const movieA = Movie(
      id: 10,
      title: 'Avatar: The Way of Water',
      overview: 'Jake Sully lives with his family...',
      voteAverage: 7.6,
      releaseDate: '2022-12-16',
      originalLanguage: 'en',
    );

    const movieB = Movie(
      id: 20,
      title: 'Pengabdi Setan 2: Communion',
      overview: 'Keluarga Rini pindah ke rusun...',
      voteAverage: 7.3,
      releaseDate: '2022-08-04',
      originalLanguage: 'id',
    );

    const movieC = Movie(
      id: 30,
      title: 'Demon Slayer: Mugen Train',
      overview: 'Tanjiro and the Demon Slayer Corps...',
      voteAverage: 8.3,
      releaseDate: '2020-10-16',
      originalLanguage: 'ja',
      genreIds: [16, 28],
    );

    final rawResults = [movieA, movieB, movieC];

    test('Prioritizes Indonesian movies to the top when Indonesia preference is active', () {
      final pref = ContentPreference.indonesia;
      final matches = rawResults.where((m) => pref.matchesMovie(m)).toList();
      final others = rawResults.where((m) => !pref.matchesMovie(m)).toList();
      final sorted = [...matches, ...others];

      expect(sorted.first.id, equals(movieB.id));
      expect(sorted.first.title, equals('Pengabdi Setan 2: Communion'));
      expect(sorted.length, equals(3));
    });

    test('Prioritizes Anime movies to the top when Anime preference is active', () {
      final pref = ContentPreference.anime;
      final matches = rawResults.where((m) => pref.matchesMovie(m)).toList();
      final others = rawResults.where((m) => !pref.matchesMovie(m)).toList();
      final sorted = [...matches, ...others];

      expect(sorted.first.id, equals(movieC.id));
      expect(sorted.first.title, equals('Demon Slayer: Mugen Train'));
      expect(sorted.length, equals(3));
    });

    test('Preserves original order when preference is all', () {
      final pref = ContentPreference.all;
      List<Movie> results;
      if (pref == ContentPreference.all) {
        results = rawResults;
      } else {
        final matches = rawResults.where((m) => pref.matchesMovie(m)).toList();
        final others = rawResults.where((m) => !pref.matchesMovie(m)).toList();
        results = [...matches, ...others];
      }

      expect(results[0].id, equals(movieA.id));
      expect(results[1].id, equals(movieB.id));
      expect(results[2].id, equals(movieC.id));
    });

    test('TV Series matching correctly identifies Anime and Indonesian series', () {
      const animeTv = TvSeries(
        id: 101,
        name: 'Attack on Titan',
        overview: 'Humans vs Titans...',
        voteAverage: 9.0,
        firstAirDate: '2013-04-07',
        originalLanguage: 'ja',
        genreIds: [16, 10759],
        originCountry: ['JP'],
      );

      const indoTv = TvSeries(
        id: 102,
        name: 'Gadis Kretek',
        overview: 'Pencarian Jeng Yah...',
        voteAverage: 8.1,
        firstAirDate: '2023-11-02',
        originalLanguage: 'id',
        originCountry: ['ID'],
      );

      expect(ContentPreference.anime.matchesTv(animeTv), isTrue);
      expect(ContentPreference.anime.matchesTv(indoTv), isFalse);

      expect(ContentPreference.indonesia.matchesTv(indoTv), isTrue);
      expect(ContentPreference.indonesia.matchesTv(animeTv), isFalse);
    });
  });
}
