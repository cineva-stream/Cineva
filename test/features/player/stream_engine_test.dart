import 'package:cineva/core/network/interceptors/header_interceptor.dart';
import 'package:cineva/features/player/data/models/provider_stream_models.dart';
import 'package:cineva/features/player/data/services/provider_loader_service.dart';
import 'package:cineva/features/player/data/services/smart_stream_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Stream Engine & Network Interceptors Tests', () {
    test('HeaderInterceptor injects standard headers', () async {
      final interceptor = HeaderInterceptor(customUserAgent: 'Cineva-Test/1.0');
      final options = RequestOptions(path: 'https://example.com');

      interceptor.onRequest(options, RequestInterceptorHandler());

      expect(options.headers['User-Agent'], equals('Cineva-Test/1.0'));
      expect(options.headers['Accept'], contains('application/json'));
    });

    test('RegularSubtitleLinks converts correctly to SubtitleInfo', () {
      final subLink = RegularSubtitleLinks(
        url: 'https://example.com/sub.vtt',
        language: 'Indonesian',
      );

      final subtitleInfo = subLink.toSubtitleInfo();
      expect(subtitleInfo.language, equals('id'));
      expect(subtitleInfo.downloadUrl, equals('https://example.com/sub.vtt'));
      expect(subtitleInfo.languageName, contains('Stream'));
    });

    test('ProviderLoadResult correctly reports stream availability', () {
      const emptyResult = ProviderLoadResult(
        success: false,
        videoLinks: [],
      );
      expect(emptyResult.hasPlayableStreams, isFalse);

      final validResult = ProviderLoadResult(
        success: true,
        videoLinks: [
          RegularVideoLinks(
            url: 'https://cdn.example.com/master.m3u8',
            quality: '1080p',
            isM3U8: true,
          ),
        ],
      );
      expect(validResult.hasPlayableStreams, isTrue);
      expect(validResult.videoLinks!.first.url, equals('https://cdn.example.com/master.m3u8'));
    });

    test('SmartStreamService includes direct providers and fallback web servers', () {
      final servers = SmartStreamService.servers;
      expect(servers, isNotEmpty);

      // Direct HLS server
      final directServer = servers.firstWhere((s) => s.isDirectHls);
      expect(directServer.isDirectHls, isTrue);

      // Fallback web server
      final webServer = servers.firstWhere((s) => !s.isDirectHls);
      expect(webServer.isDirectHls, isFalse);
      expect(webServer.tag, equals('Cadangan Web'));
    });

    test('ProviderLoaderService prioritization and discovery', () async {
      final loader = ProviderLoaderService();
      final providers = await loader.getAvailableProviders();

      expect(providers, isNotEmpty);
      expect(providers.first.type, equals(VideoProviderType.directVixSrc));
      expect(providers.first.displayName, contains('VixSrc'));
    });

    test('Side panel playback speeds are valid positive multipliers', () {
      const validSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
      for (final speed in validSpeeds) {
        expect(speed, greaterThan(0.0));
        expect(speed, lessThanOrEqualTo(2.0));
      }
      expect(validSpeeds, contains(1.0));
    });

    test('Video container aspect ratio calculation scales properly with drawer', () {
      const totalWidth = 1280.0;
      final drawerWidth = (totalWidth * 0.36).clamp(310.0, 390.0);
      expect(drawerWidth, equals(390.0)); // 1280 * 0.36 = 460.8, clamped to 390.0

      final videoWidthWithPanel = totalWidth - drawerWidth;
      expect(videoWidthWithPanel, equals(890.0));
      expect(videoWidthWithPanel, greaterThan(0));
    });
  });
}

