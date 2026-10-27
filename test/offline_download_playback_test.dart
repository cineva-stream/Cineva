import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:cineva/features/download/data/services/offline_mp4_builder.dart';
import 'package:cineva/features/download/data/services/native_media_muxer.dart';

void main() {
  group('Offline Media & Playback Perfection Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('cineva_offline_test_');
    });

    tearDown(() async {
      try {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      } catch (_) {}
    });

    test('NativeMediaProbe isPlayable requires only hasVideo', () {
      const probeZeroDuration = NativeMediaProbe(
        durationMs: 0,
        hasVideo: true,
        hasAudio: true,
      );
      expect(probeZeroDuration.isPlayable, isTrue);

      const probeValid = NativeMediaProbe(
        durationMs: 7200000,
        hasVideo: true,
        hasAudio: true,
      );
      expect(probeValid.isPlayable, isTrue);

      const probeAudioOnly = NativeMediaProbe(
        durationMs: 50000,
        hasVideo: false,
        hasAudio: true,
      );
      expect(probeAudioOnly.isPlayable, isFalse);
    });

    test('OfflineMp4Builder.isValidMp4 rejects missing or tiny files', () async {
      final missingFile = File('${tempDir.path}/non_existent.mp4');
      expect(await OfflineMp4Builder.isValidMp4(missingFile), isFalse);

      final tinyFile = File('${tempDir.path}/tiny.mp4');
      await tinyFile.writeAsBytes(List.filled(100, 0));
      expect(await OfflineMp4Builder.isValidMp4(tinyFile), isFalse);
    });

    test('OfflineMp4Builder.findPlayableOfflineFile prioritizes video.mp4, then video.ts, then master.m3u8', () async {
      // 1. When empty, returns null
      expect(await OfflineMp4Builder.findPlayableOfflineFile(tempDir), isNull);

      // 2. When master.m3u8 exists
      final m3u8 = File('${tempDir.path}/master.m3u8');
      await m3u8.writeAsString('#EXTM3U\n');
      var playable = await OfflineMp4Builder.findPlayableOfflineFile(tempDir);
      expect(playable?.path, equals(m3u8.path));

      // 3. When video.ts exists with valid size (>50KB), it takes priority over master.m3u8
      final videoTs = File('${tempDir.path}/${OfflineMp4Builder.videoTsName}');
      await videoTs.writeAsBytes(List.filled(60000, 0x47)); // 0x47 is TS sync byte
      playable = await OfflineMp4Builder.findPlayableOfflineFile(tempDir);
      expect(playable?.path, equals(videoTs.path));

      // 4. Secondary audio detection
      expect(await OfflineMp4Builder.getSecondaryAudioFile(tempDir), isNull);
      final audioTs = File('${tempDir.path}/${OfflineMp4Builder.audioTsName}');
      await audioTs.writeAsBytes(List.filled(5000, 0x47));
      final detectedAudio = await OfflineMp4Builder.getSecondaryAudioFile(tempDir);
      expect(detectedAudio?.path, equals(audioTs.path));
    });

    test('expectedDurationUsFromPlaylist parses EXTINF correctly', () async {
      final playlist = File('${tempDir.path}/video.m3u8');
      await playlist.writeAsString('''
#EXTM3U
#EXT-X-VERSION:3
#EXTINF:6.000,
v_0000.ts
#EXTINF:6.000,
v_0001.ts
#EXTINF:4.500,
v_0002.ts
#EXT-X-ENDLIST
''');

      final durationUs = await OfflineMp4Builder.expectedDurationUsFromPlaylist(playlist);
      // 6.0 + 6.0 + 4.5 = 16.5 seconds = 16,500,000 microseconds
      expect(durationUs, equals(16500000));
    });
  });
}
