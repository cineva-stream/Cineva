import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TV Series Episode Routing & Stream URL Tests', () {
    test('Correctly formats TV Series title and episode number', () {
      const showTitle = 'Game of Thrones';
      const season = 1;
      const episode = 1;
      const epName = 'Winter Is Coming';

      final formattedTitle = '$showTitle - S$season:E$episode $epName';
      expect(formattedTitle, equals('Game of Thrones - S1:E1 Winter Is Coming'));
    });

    test('Correctly constructs Torrentio TV Series endpoint URL', () {
      const imdbId = 'tt0944947';

      String buildEndpoint(int? season, int? episode) {
        return (season != null && episode != null)
            ? 'https://torrentio.strem.fun/stream/series/$imdbId:$season:$episode.json'
            : 'https://torrentio.strem.fun/stream/movie/$imdbId.json';
      }

      expect(buildEndpoint(2, 5), equals('https://torrentio.strem.fun/stream/series/tt0944947:2:5.json'));
      expect(buildEndpoint(null, null), equals('https://torrentio.strem.fun/stream/movie/tt0944947.json'));
    });

    test('Correctly constructs Movie vs TV Embed Stream URLs', () {
      // Movie URL test
      const movieImdb = 'tt1630029';
      final cleanMovieImdb = movieImdb.startsWith('tt') ? movieImdb : 'tt$movieImdb';
      final movieUrl = 'https://vidsrc.to/embed/movie/$cleanMovieImdb';
      expect(movieUrl, equals('https://vidsrc.to/embed/movie/tt1630029'));

      // TV Series Episode URL test
      const tvImdb = 'tt0944947';
      const season = 1;
      const episode = 3;
      final cleanTvImdb = tvImdb.startsWith('tt') ? tvImdb : 'tt$tvImdb';
      final tvUrl = 'https://vidsrc.to/embed/tv/$cleanTvImdb/$season/$episode';
      expect(tvUrl, equals('https://vidsrc.to/embed/tv/tt0944947/1/3'));
    });
  });
}
