import 'package:flutter_test/flutter_test.dart';
import 'package:cineva/features/player/data/services/smart_stream_service.dart';

void main() {
  group('SmartStreamService Tests', () {
    test('Server configurations are defined and complete', () {
      expect(SmartStreamService.servers.length, greaterThanOrEqualTo(5));

      final directServer = SmartStreamService.servers.firstWhere((s) => s.id == 'cineva_direct');
      expect(directServer.isDirectHls, isTrue);

      final vidLink = SmartStreamService.servers.firstWhere((s) => s.id == 'vidlink');
      expect(vidLink.isDirectHls, isFalse);
      expect(vidLink.name, contains('VidLink'));

      final multiEmbed = SmartStreamService.servers.firstWhere((s) => s.id == 'multiembed');
      expect(multiEmbed.name, contains('MultiEmbed'));
    });

    test('URL Generation for Kimetsu No Yaiba (TMDB 85937) TV Series', () {
      final vidlink = SmartStreamService.servers.firstWhere((s) => s.id == 'vidlink');
      final url = vidlink.buildUrl(
        tmdbId: 85937,
        imdbId: 'tt9335498',
        season: 1,
        episode: 1,
      );
      expect(url, equals('https://vidlink.pro/tv/85937/1/1?autoplay=true&primaryColor=f59e0b'));

      final multiEmbed = SmartStreamService.servers.firstWhere((s) => s.id == 'multiembed');
      final multiUrl = multiEmbed.buildUrl(
        tmdbId: 85937,
        imdbId: 'tt9335498',
        season: 1,
        episode: 1,
      );
      expect(multiUrl, contains('tt9335498'));
      expect(multiUrl, contains('&s=1&e=1'));
    });

    test('URL Generation for Naruto 2002 (TMDB 46260) TV Series', () {
      final vidlink = SmartStreamService.servers.firstWhere((s) => s.id == 'vidlink');
      final url = vidlink.buildUrl(
        tmdbId: 46260,
        imdbId: 'tt0409591',
        season: 1,
        episode: 5,
      );
      expect(url, equals('https://vidlink.pro/tv/46260/1/5?autoplay=true&primaryColor=f59e0b'));
    });

    test('URL Generation for Released Movie without season/episode', () {
      final vidlink = SmartStreamService.servers.firstWhere((s) => s.id == 'vidlink');
      final url = vidlink.buildUrl(
        tmdbId: 533535, // Deadpool & Wolverine
        imdbId: 'tt6263850',
      );
      expect(url, equals('https://vidlink.pro/movie/533535?autoplay=true&primaryColor=f59e0b'));

      final multiEmbed = SmartStreamService.servers.firstWhere((s) => s.id == 'multiembed');
      final multiUrl = multiEmbed.buildUrl(
        tmdbId: 533535,
        imdbId: 'tt6263850',
      );
      expect(multiUrl, contains('tt6263850'));
    });

    test('Stream Sniffer JS contains CinevaStreamBridge and hooks', () {
      expect(SmartStreamService.streamSnifferJs, contains('CinevaStreamBridge'));
      expect(SmartStreamService.streamSnifferJs, contains('STREAM_FOUND'));
      expect(SmartStreamService.streamSnifferJs, contains('.m3u8'));
      expect(SmartStreamService.streamSnifferJs, contains('.mp4'));
    });

    test('Cinema Cleaner CSS removes common ad units and enforces clean viewport', () {
      expect(SmartStreamService.cinemaCleanerCss, contains('display: none !important;'));
      expect(SmartStreamService.cinemaCleanerCss, contains('iframe[src*="ad"]'));
      expect(SmartStreamService.cinemaCleanerCss, contains('background-color: #000000 !important;'));
    });
  });
}
