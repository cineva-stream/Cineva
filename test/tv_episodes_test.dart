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

    test('Next Episode timing thresholds correctly show manual button and trigger auto next', () {
      const totalDuration = Duration(minutes: 45); // 2700s

      bool shouldShowButton(Duration pos) {
        final remaining = (totalDuration - pos).inSeconds;
        return remaining <= 60 && remaining > 5;
      }

      bool shouldAutoPlayNext(Duration pos) {
        final remaining = (totalDuration - pos).inSeconds;
        return remaining <= 5 && remaining >= 0;
      }

      // At 44:00 (60 seconds remaining) -> Button visible
      expect(shouldShowButton(const Duration(minutes: 44)), isTrue);
      expect(shouldAutoPlayNext(const Duration(minutes: 44)), isFalse);

      // At 44:30 (30 seconds remaining) -> Button visible
      expect(shouldShowButton(const Duration(minutes: 44, seconds: 30)), isTrue);
      expect(shouldAutoPlayNext(const Duration(minutes: 44, seconds: 30)), isFalse);

      // At 43:00 (120 seconds remaining) -> Button hidden
      expect(shouldShowButton(const Duration(minutes: 43)), isFalse);
      expect(shouldAutoPlayNext(const Duration(minutes: 43)), isFalse);

      // At 44:56 (4 seconds remaining) -> Button hidden, auto next triggers
      expect(shouldShowButton(const Duration(minutes: 44, seconds: 56)), isFalse);
      expect(shouldAutoPlayNext(const Duration(minutes: 44, seconds: 56)), isTrue);
    });

    test('In-place episode advance stops previous audio and resets timeline cleanly', () {
      int currentEpisode = 1;
      double volume = 100.0;
      bool isPlaying = true;
      Duration position = const Duration(minutes: 44, seconds: 50);

      // Simulate _playNextEpisode cleanup & state change
      void playNextEpisode() {
        // 1. Immediately mute and stop previous audio
        volume = 0.0;
        isPlaying = false;

        // 2. Advance episode and reset position
        currentEpisode += 1;
        position = Duration.zero;

        // 3. Restore volume for new episode
        volume = 100.0;
      }

      playNextEpisode();

      expect(currentEpisode, equals(2));
      expect(position, equals(Duration.zero));
      expect(volume, equals(100.0));
      expect(isPlaying, isFalse);
    });
  });
}
