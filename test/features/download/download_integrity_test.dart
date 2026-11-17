import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:cineva/features/download/data/services/download_speed_meter.dart';
import 'package:cineva/features/download/data/services/offline_mp4_builder.dart';
import 'package:cineva/features/download/data/services/ts_segment_utils.dart';
import 'package:cineva/features/download/data/services/video_download_service.dart';

Uint8List _ts(int packets) {
  final data = Uint8List(packets * 188);
  for (int p = 0; p < packets; p++) {
    data[p * 188] = 0x47;
    for (int i = 1; i < 188; i++) {
      data[p * 188 + i] = (p * 13 + i * 5) & 0xFF;
    }
  }
  return data;
}

void main() {
  group('DownloadSpeedMeter', () {
    test('reports real wire speed, not a burst of already-stored bytes', () {
      var now = 1000;
      final meter = DownloadSpeedMeter(nowMs: () => now);

      // 2 MiB/s steady for 6 seconds.
      for (int i = 0; i < 60; i++) {
        now += 100;
        meter.add(209715);
      }
      final bps = meter.bytesPerSecond;
      expect(bps, closeTo(2 * 1048576, 0.1 * 1048576));
      expect(meter.formatted, startsWith('2.0 MB/s'));
    });

    test('is bounded when many workers finish at the same instant', () {
      var now = 5000;
      final meter = DownloadSpeedMeter(nowMs: () => now);
      // 12 segments of 1 MiB arriving "at once" 100ms after start must not read 120 MB/s.
      now += 100;
      for (int i = 0; i < 12; i++) {
        meter.add(1048576);
      }
      // Minimum 0.5 s assumed -> at most 24 MiB/s for this first burst, and it decays.
      expect(meter.bytesPerSecond, lessThanOrEqualTo(25 * 1048576));
      now += 10000;
      expect(meter.bytesPerSecond, 0);
    });

    test('format switches between KB/s and MB/s and shows Mbps', () {
      expect(DownloadSpeedMeter.format(512 * 1024), '512 KB/s (4.2 Mbps)');
      expect(DownloadSpeedMeter.format(5 * 1048576), '5.0 MB/s (41.9 Mbps)');
      expect(DownloadSpeedMeter.format(double.nan), '0 KB/s (0.0 Mbps)');
    });
  });

  group('TsSegmentUtils strict validation', () {
    test('accepts TS, fMP4 and raw audio; rejects garbage / error pages', () {
      expect(TsSegmentUtils.isValidMediaSegment(_ts(20)), isTrue);
      expect(
        TsSegmentUtils.isValidMediaSegment(
          Uint8List.fromList([0, 0, 0, 24, 0x6D, 0x6F, 0x6F, 0x66, ...List.filled(40, 1)]),
        ),
        isTrue,
      );
      final adts = Uint8List.fromList([0xFF, 0xF1, 0x50, 0x80, ...List.filled(50, 3)]);
      expect(TsSegmentUtils.isValidMediaSegment(adts), isFalse);
      expect(TsSegmentUtils.isValidMediaSegment(adts, allowRawAudio: true), isTrue);

      final rnd = Random(7);
      final garbage = Uint8List.fromList(List.generate(4096, (_) => rnd.nextInt(256)));
      garbage[0] = 0x00;
      expect(TsSegmentUtils.isValidMediaSegment(garbage), isFalse);
      expect(TsSegmentUtils.isValidMediaSegment(Uint8List(0)), isFalse);
    });

    test('random payload is never mis-detected as TS by the sync scan', () {
      // Large random buffers contain many 0x47..0x47 pairs 188 bytes apart; a run of
      // consecutive packets must be required, so no "TS" may be carved out of noise.
      final rnd = Random(1234);
      for (int round = 0; round < 20; round++) {
        final noise = Uint8List.fromList(
          List.generate(1024 * 1024, (_) => rnd.nextInt(256)),
        );
        noise[0] = 0x00;
        final out = TsSegmentUtils.unwrapDisguisedSegment(noise);
        expect(TsSegmentUtils.isValidMediaSegment(out), isFalse,
            reason: 'round $round produced a bogus TS slice');
      }
    });

    test('still finds TS after leading junk bytes', () {
      final ts = _ts(12);
      final wrapped = Uint8List.fromList([1, 2, 3, 4, 5, ...ts]);
      final out = TsSegmentUtils.unwrapDisguisedSegment(wrapped);
      expect(Uint8List.fromList(out), ts);
    });
  });

  group('Download workspace hygiene', () {
    test('stale segments from another/unknown download are purged, same download kept',
        () async {
      final dir = await Directory.systemTemp.createTemp('cineva_ws_test_');
      try {
        final seg = File('${dir.path}/v_0000.ts')..writeAsBytesSync(_ts(10));
        File('${dir.path}/video.mp4').writeAsBytesSync(Uint8List(60000));
        File('${dir.path}/.mux_failed').writeAsStringSync('x');
        File('${dir.path}/movie.srt').writeAsStringSync('1\n');
        File('${dir.path}/master.m3u8').writeAsStringSync('#EXTM3U');

        final sig = VideoDownloadService.buildDownloadSignature(
          quality: '720p',
          videoSegments: 10,
          audioSegments: 10,
          videoSeconds: 40,
          hasInit: false,
        );

        // No previous state -> leftover segment is untrusted and must go.
        await VideoDownloadService.prepareDownloadWorkspace(dir, signature: sig);
        expect(await seg.exists(), isFalse);
        expect(await File('${dir.path}/video.mp4').exists(), isFalse);
        expect(await File('${dir.path}/.mux_failed').exists(), isFalse);
        expect(await File('${dir.path}/master.m3u8').exists(), isFalse);
        expect(await File('${dir.path}/movie.srt').exists(), isTrue);

        // Same signature on resume -> valid segment is kept, partial files removed.
        seg.writeAsBytesSync(_ts(10));
        File('${dir.path}/v_0001.ts.part').writeAsBytesSync(Uint8List(100));
        await VideoDownloadService.prepareDownloadWorkspace(dir, signature: sig);
        expect(await seg.exists(), isTrue);
        expect(await File('${dir.path}/v_0001.ts.part').exists(), isFalse);

        // Different quality/segment layout -> segments dropped.
        final other = VideoDownloadService.buildDownloadSignature(
          quality: '1080p',
          videoSegments: 12,
          audioSegments: 12,
          videoSeconds: 48,
          hasInit: false,
        );
        await VideoDownloadService.prepareDownloadWorkspace(dir, signature: other);
        expect(await seg.exists(), isFalse);
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('isStoredSegmentUsable rejects junk and truncated placeholders', () async {
      final dir = await Directory.systemTemp.createTemp('cineva_seg_test_');
      try {
        final good = File('${dir.path}/v_0000.ts')..writeAsBytesSync(_ts(30));
        final junk = File('${dir.path}/v_0001.ts')
          ..writeAsBytesSync(Uint8List.fromList(List.filled(5000, 0x41)));
        final tiny = File('${dir.path}/v_0002.ts')..writeAsBytesSync(_ts(1));

        expect(
          await VideoDownloadService.isStoredSegmentUsable(good, allowRawAudio: false),
          isTrue,
        );
        expect(
          await VideoDownloadService.isStoredSegmentUsable(junk, allowRawAudio: false),
          isFalse,
        );
        expect(
          await VideoDownloadService.isStoredSegmentUsable(tiny, allowRawAudio: false),
          isFalse,
        );
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('verifyHlsBundle only accepts bundles made of real media segments', () async {
      final dir = await Directory.systemTemp.createTemp('cineva_bundle_verify_');
      try {
        File('${dir.path}/master.m3u8').writeAsStringSync('#EXTM3U\nvideo.m3u8');
        for (int i = 0; i < 4; i++) {
          File('${dir.path}/v_000$i.ts').writeAsBytesSync(_ts(40));
        }
        expect(await OfflineMp4Builder.verifyHlsBundle(dir), isTrue);

        File('${dir.path}/v_0003.ts')
            .writeAsBytesSync(Uint8List.fromList(List.filled(8000, 0x20)));
        expect(await OfflineMp4Builder.verifyHlsBundle(dir), isFalse);
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });
}

