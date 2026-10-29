import 'package:flutter_test/flutter_test.dart';
import 'package:cineva/features/download/data/services/hls_url_resolver.dart';
import 'package:cineva/features/download/data/services/ts_segment_utils.dart';

void main() {
  group('HlsUrlResolver Tests', () {
    const masterWithTokens =
        'https://vixsrc.to/playlist/m3u8/abc123.m3u8?token=SECRET_XYZ&expires=1730000000&h=1&lang=en';

    test('inherits query parameters for relative child m3u8 playlists', () {
      final resolved = HlsUrlResolver.resolve('video_1080p.m3u8', masterWithTokens);
      expect(resolved, contains('https://vixsrc.to/playlist/m3u8/video_1080p.m3u8'));
      expect(resolved, contains('token=SECRET_XYZ'));
      expect(resolved, contains('expires=1730000000'));
      expect(resolved, contains('h=1'));
      expect(resolved, contains('lang=en'));
    });

    test('inherits query parameters for root-relative key URI', () {
      final resolved = HlsUrlResolver.resolve('/storage/enc.key', masterWithTokens);
      expect(resolved, contains('https://vixsrc.to/storage/enc.key'));
      expect(resolved, contains('token=SECRET_XYZ'));
      expect(resolved, contains('expires=1730000000'));
    });

    test('inherits query parameters for relative TS segments', () {
      final resolved = HlsUrlResolver.resolve('seg_0001.ts', masterWithTokens);
      expect(resolved, contains('https://vixsrc.to/playlist/m3u8/seg_0001.ts'));
      expect(resolved, contains('token=SECRET_XYZ'));
    });

    test('preserves child URL own query parameters if already present', () {
      const childWithParam = 'https://cdn.another.com/segment_0001.ts?sig=CUSTOM_SIG';
      final resolved = HlsUrlResolver.resolve(childWithParam, masterWithTokens);
      expect(resolved, equals(childWithParam));
      expect(resolved, contains('sig=CUSTOM_SIG'));
      expect(resolved, isNot(contains('SECRET_XYZ')));
    });

    test('handles empty input gracefully', () {
      expect(HlsUrlResolver.resolve('', masterWithTokens), equals(masterWithTokens));
      expect(HlsUrlResolver.resolve('   ', masterWithTokens), equals(masterWithTokens));
    });
  });

  group('TsSegmentUtils Disguised Segment Tests', () {
    test('unwraps disguised segments with fake image headers', () {
      // Create a disguised segment: 16 bytes of fake PNG header followed by 188-byte TS packet
      final fakeHeader = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52];
      final tsPacket = List<int>.filled(188, 0x00)..[0] = 0x47;
      final disguised = [...fakeHeader, ...tsPacket];

      final unwrapped = TsSegmentUtils.unwrapDisguisedSegment(disguised);
      expect(unwrapped.first, equals(0x47));
      expect(unwrapped.length, equals(188));
    });

    test('leaves already clean TS segment untouched', () {
      final tsPacket = List<int>.filled(188, 0xAA)..[0] = 0x47;
      final unwrapped = TsSegmentUtils.unwrapDisguisedSegment(tsPacket);
      expect(unwrapped, equals(tsPacket));
    });
  });
}

