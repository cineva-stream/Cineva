import 'package:flutter_test/flutter_test.dart';
import 'package:cineva/features/calendar/data/models/airing_show_model.dart';
import 'package:cineva/features/detail/data/models/trailer_video_model.dart';
import 'package:cineva/features/person/data/models/person_detail_model.dart';
import 'package:cineva/features/collection/data/models/movie_collection_model.dart';

void main() {
  group('Feature 1: Airing Calendar Models', () {
    test('AiringShowModel correctly parses anime show', () {
      final json = {
        'id': 12345,
        'name': 'Demon Slayer: Kimetsu no Yaiba',
        'overview': 'Tanjiro Kamado fights demons.',
        'poster_path': '/ds_poster.jpg',
        'backdrop_path': '/ds_backdrop.jpg',
        'vote_average': 8.7,
        'vote_count': 5400,
        'first_air_date': '2019-04-06',
        'original_language': 'ja',
        'origin_country': ['JP'],
        'genre_ids': [16, 10759, 10765],
        'popularity': 420.5,
      };

      final model = AiringShowModel.fromJson(json);

      expect(model.id, 12345);
      expect(model.name, 'Demon Slayer: Kimetsu no Yaiba');
      expect(model.isAnime, isTrue);
      expect(model.regionBadge, 'ANIME');
      expect(model.voteAverage, 8.7);
    });

    test('AiringShowModel correctly identifies K-Drama and other regions', () {
      final kdramaJson = {
        'id': 23456,
        'name': 'Crash Landing on You',
        'overview': 'South Korean heiress paraglides into North Korea.',
        'vote_average': 8.8,
        'vote_count': 850,
        'original_language': 'ko',
        'origin_country': ['KR'],
        'genre_ids': [18, 35],
        'popularity': 120.0,
      };

      final kdrama = AiringShowModel.fromJson(kdramaJson);
      expect(kdrama.isAnime, isFalse);
      expect(kdrama.regionBadge, 'K-DRAMA');

      final indoJson = {
        'id': 34567,
        'name': 'Gadis Kretek',
        'overview': 'Sejarah rokok kretek Indonesia.',
        'vote_average': 8.1,
        'vote_count': 230,
        'original_language': 'id',
        'origin_country': ['ID'],
        'genre_ids': [18],
        'popularity': 45.0,
      };

      final indo = AiringShowModel.fromJson(indoJson);
      expect(indo.regionBadge, 'INDONESIA');
    });
  });

  group('Feature 2: In-App Trailer Video Model', () {
    test('TrailerVideoModel prioritizes Official YouTube Trailer', () {
      final videosJson = [
        {
          'id': 'clip_1',
          'key': 'clip_key_123',
          'name': 'Teaser Clip',
          'site': 'YouTube',
          'type': 'Clip',
          'official': false,
        },
        {
          'id': 'trailer_unofficial',
          'key': 'unoff_key_456',
          'name': 'Fan Trailer',
          'site': 'YouTube',
          'type': 'Trailer',
          'official': false,
        },
        {
          'id': 'trailer_official',
          'key': 'official_key_789',
          'name': 'Main Official Trailer',
          'site': 'YouTube',
          'type': 'Trailer',
          'official': true,
        },
      ];

      final best = TrailerVideoModel.findBestTrailer(videosJson);
      expect(best, isNotNull);
      expect(best!.key, 'official_key_789');
      expect(best.name, 'Main Official Trailer');
      expect(best.official, isTrue);
      expect(best.youtubeUrl, 'https://www.youtube.com/watch?v=official_key_789');
      expect(
        best.embedUrl,
        contains('https://www.youtube-nocookie.com/embed/official_key_789'),
      );
    });

    test('TrailerVideoModel ignores non-YouTube sites and handles empty lists', () {
      final nonYoutube = [
        {
          'id': 'vimeo_1',
          'key': 'vimeo_123',
          'site': 'Vimeo',
          'type': 'Trailer',
          'official': true,
        }
      ];

      expect(TrailerVideoModel.findBestTrailer(nonYoutube), isNull);
      expect(TrailerVideoModel.findBestTrailer([]), isNull);
      expect(TrailerVideoModel.findBestTrailer(null), isNull);
    });
  });

  group('Feature 3: Person Detail & Filmography Model', () {
    test('PersonDetailModel parses profile and calculates age correctly', () {
      final json = {
        'id': 3223,
        'name': 'Robert Downey Jr.',
        'biography': 'Robert John Downey Jr. is an American actor.',
        'birthday': '1965-04-04',
        'place_of_birth': 'Manhattan, New York City, USA',
        'profile_path': '/rdj.jpg',
        'known_for_department': 'Acting',
        'popularity': 68.5,
        'external_ids': {'imdb_id': 'nm0000375'},
        'combined_credits': {
          'cast': [
            {
              'id': 1726,
              'title': 'Iron Man',
              'media_type': 'movie',
              'poster_path': '/ironman.jpg',
              'release_date': '2008-05-02',
              'character': 'Tony Stark / Iron Man',
              'vote_average': 7.6,
              'vote_count': 25000,
              'popularity': 150.0,
            },
            {
              'id': 299536,
              'title': 'Avengers: Infinity War',
              'media_type': 'movie',
              'poster_path': '/infinity_war.jpg',
              'release_date': '2018-04-27',
              'character': 'Tony Stark / Iron Man',
              'vote_average': 8.3,
              'vote_count': 29000,
              'popularity': 240.0,
            },
          ]
        }
      };

      final person = PersonDetailModel.fromJson(json);

      expect(person.id, 3223);
      expect(person.name, 'Robert Downey Jr.');
      expect(person.age, greaterThanOrEqualTo(58));
      expect(person.credits.length, 2);
      // Verify sorted by popularity descending
      expect(person.credits.first.title, 'Avengers: Infinity War');
      expect(person.credits.last.title, 'Iron Man');
      expect(person.credits.first.year, '2018');
    });
  });

  group('Feature 4: Franchise & Movie Collection Model', () {
    test('MovieCollectionModel sorts parts chronologically by release_date', () {
      final json = {
        'id': 1241,
        'name': 'Harry Potter Collection',
        'overview': 'The complete saga of Harry Potter.',
        'poster_path': '/hp_collection_poster.jpg',
        'backdrop_path': '/hp_collection_backdrop.jpg',
        'parts': [
          {
            'id': 672,
            'title': 'Harry Potter and the Chamber of Secrets',
            'overview': 'Second year at Hogwarts.',
            'poster_path': '/hp2.jpg',
            'release_date': '2002-11-15',
            'vote_average': 7.7,
            'vote_count': 18000,
            'popularity': 85.0,
          },
          {
            'id': 671,
            'title': 'Harry Potter and the Philosopher\'s Stone',
            'overview': 'First year at Hogwarts.',
            'poster_path': '/hp1.jpg',
            'release_date': '2001-11-16',
            'vote_average': 7.9,
            'vote_count': 23000,
            'popularity': 110.0,
          },
          {
            'id': 673,
            'title': 'Harry Potter and the Prisoner of Azkaban',
            'overview': 'Third year at Hogwarts.',
            'poster_path': '/hp3.jpg',
            'release_date': '2004-05-31',
            'vote_average': 8.0,
            'vote_count': 19000,
            'popularity': 90.0,
          },
        ]
      };

      final collection = MovieCollectionModel.fromJson(json);

      expect(collection.id, 1241);
      expect(collection.name, 'Harry Potter Collection');
      expect(collection.parts.length, 3);

      // Verify sorted chronologically
      expect(collection.parts[0].title, 'Harry Potter and the Philosopher\'s Stone');
      expect(collection.parts[0].year, '2001');

      expect(collection.parts[1].title, 'Harry Potter and the Chamber of Secrets');
      expect(collection.parts[1].year, '2002');

      expect(collection.parts[2].title, 'Harry Potter and the Prisoner of Azkaban');
      expect(collection.parts[2].year, '2004');
    });
  });
}

