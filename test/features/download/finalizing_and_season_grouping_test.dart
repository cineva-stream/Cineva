import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:cineva/core/constants/app_constants.dart';
import 'package:cineva/core/localization/app_language.dart';
import 'package:cineva/core/localization/app_language_provider.dart';
import 'package:cineva/features/download/data/repositories/download_repository.dart';
import 'package:cineva/features/download/data/services/offline_mp4_builder.dart';
import 'package:cineva/features/download/domain/models/download_item.dart';
import 'package:cineva/features/download/presentation/providers/download_provider.dart';
import 'package:cineva/features/download/presentation/screens/download_list_screen.dart';

class _TestLanguageNotifier extends AppLanguageNotifier {
  _TestLanguageNotifier(super.initialLanguage);

  @override
  Future<void> setLanguage(AppLanguage language) async {
    state = language;
  }
}

class _TestDownloadNotifier extends DownloadNotifier {
  _TestDownloadNotifier(super.repository, List<DownloadItem> initialItems) {
    state = initialItems;
  }
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('cineva_download_screen_test_');
    Hive.init(tempDir.path);
    await Hive.openBox(AppConstants.downloadsBox);
    await Hive.openBox(AppConstants.settingsBox);
  });

  group('DownloadStatus Finalizing & DownloadItem Tests', () {
    test('DownloadStatus contains finalizing and isFinalizing is true', () {
      final item = DownloadItem(
        id: 'tv_123_s1_e1',
        tmdbId: 123,
        title: 'Loki',
        mediaType: 'tv',
        seasonNumber: 1,
        episodeNumber: 1,
        posterPath: '/official_loki_poster.jpg',
        episodeStillPath: '/episode_still_1.jpg',
        status: DownloadStatus.finalizing,
        progress: 0.65,
        speed: 'Menyatukan segmen video 65/100',
        videoFileName: 'Loki - S1 E1.mp4',
        subtitleFileName: 'Loki - S1 E1.srt',
        videoPath: '/path/to/video',
        createdAt: DateTime.now(),
      );

      expect(item.status, DownloadStatus.finalizing);
      expect(item.isFinalizing, isTrue);
      expect(item.isDownloading, isTrue);
      expect(item.isCompleted, isFalse);
      expect(item.posterPath, '/official_loki_poster.jpg');
      expect(item.episodeStillPath, '/episode_still_1.jpg');

      final json = item.toJson();
      final restored = DownloadItem.fromJson(json);

      expect(restored.status, DownloadStatus.finalizing);
      expect(restored.isFinalizing, isTrue);
      expect(restored.isDownloading, isTrue);
      expect(restored.posterPath, '/official_loki_poster.jpg');
      expect(restored.episodeStillPath, '/episode_still_1.jpg');
      expect(restored.progress, 0.65);
      expect(restored.speed, 'Menyatukan segmen video 65/100');
    });
  });

  group('OfflineMp4Builder Real-Time Finalizing Progress Tests', () {
    test('OfflineMp4Builder.build emits real-time progress callbacks for segments', () async {
      final tempDir = await Directory.systemTemp.createTemp('cineva_finalize_test_');
      try {
        final bundleDir = Directory('${tempDir.path}/item');
        await bundleDir.create(recursive: true);

        // Write dummy TS segments
        for (int i = 0; i < 4; i++) {
          final seg = File('${bundleDir.path}/v_${i.toString().padLeft(4, '0')}.ts');
          await seg.writeAsBytes(List.filled(188 * 5, 0x47));
        }

        final progressList = <double>[];
        final messages = <String>[];

        await OfflineMp4Builder.build(
          dir: bundleDir,
          deleteSegmentsOnSuccess: false,
          onProgress: ({required double progress, required String statusMessage}) {
            progressList.add(progress);
            messages.add(statusMessage);
          },
        );

        expect(progressList, isNotEmpty);
        expect(messages, isNotEmpty);
        expect(messages.any((m) => m.contains('Menyatukan segmen video')), isTrue);
        expect(progressList.last, 1.0);
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('OfflineMp4Builder.build reuses pre-concatenated fMP4 video.mp4 and deletes segments in parallel', () async {
      final tempDir = await Directory.systemTemp.createTemp('cineva_preconcat_test_');
      try {
        final bundleDir = Directory('${tempDir.path}/item_fmp4');
        await bundleDir.create(recursive: true);

        final initFile = File('${bundleDir.path}/init_v.mp4');
        final initBytes = List<int>.filled(20000, 0x11);
        await initFile.writeAsBytes(initBytes);

        final segFiles = <File>[];
        final totalBytes = <int>[...initBytes];
        for (int i = 0; i < 5; i++) {
          final seg = File('${bundleDir.path}/v_${i.toString().padLeft(4, '0')}.m4s');
          final b = List<int>.filled(10000, i + 1);
          await seg.writeAsBytes(b);
          segFiles.add(seg);
          totalBytes.addAll(b);
        }

        // Simulate progressive track assembler having already built video.mp4 during download
        final mp4File = File('${bundleDir.path}/${OfflineMp4Builder.mp4Name}');
        await mp4File.writeAsBytes(totalBytes);

        final messages = <String>[];
        final ok = await OfflineMp4Builder.build(
          dir: bundleDir,
          deleteSegmentsOnSuccess: true,
          deleteSegmentsInBackground: false,
          onProgress: ({required double progress, required String statusMessage}) {
            messages.add(statusMessage);
          },
        );

        expect(ok, isTrue);
        // Should skip 'Menyatukan segmen' because video.mp4 was already pre-concatenated!
        expect(messages.any((m) => m.contains('Menyatukan segmen')), isFalse);
        expect(await mp4File.exists(), isTrue);
        expect(await initFile.exists(), isFalse);
        for (final seg in segFiles) {
          expect(await seg.exists(), isFalse);
        }
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('OfflineMp4Builder.deleteFilesFast deletes large batches of segment files in parallel', () async {
      final tempDir = await Directory.systemTemp.createTemp('cineva_fast_delete_test_');
      try {
        final files = <File>[];
        for (int i = 0; i < 150; i++) {
          final f = File('${tempDir.path}/v_${i.toString().padLeft(4, '0')}.ts');
          await f.writeAsBytes(const [0x47, 0x00, 0x01]);
          files.add(f);
        }

        await OfflineMp4Builder.deleteFilesFast(files, batchSize: 64);

        for (final f in files) {
          expect(await f.exists(), isFalse);
        }
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('OfflineMp4Builder.build instantaneously finalizes pre-assembled video.ts via .assembled marker', () async {
      final tempDir = await Directory.systemTemp.createTemp('cineva_instant_ts_finalize_');
      try {
        final bundleDir = Directory('${tempDir.path}/item_ts');
        await bundleDir.create(recursive: true);

        final segFiles = <File>[];
        final totalBytes = <int>[];
        for (int i = 0; i < 4; i++) {
          final seg = File('${bundleDir.path}/v_${i.toString().padLeft(4, '0')}.ts');
          final b = List<int>.filled(188 * 100, 0x47);
          await seg.writeAsBytes(b);
          segFiles.add(seg);
          totalBytes.addAll(b);
        }

        // Simulate _ProgressiveTrackAssembler having pre-assembled video.ts and its .assembled marker
        final videoTs = File('${bundleDir.path}/${OfflineMp4Builder.videoTsName}');
        await videoTs.writeAsBytes(totalBytes);
        final assembledMarker = File('${videoTs.path}.assembled');
        await assembledMarker.writeAsString('${segFiles.length}:${totalBytes.length}');

        final ok = await OfflineMp4Builder.build(
          dir: bundleDir,
          expectedDurationUs: 16000000,
          deleteSegmentsOnSuccess: true,
          deleteSegmentsInBackground: false,
        );

        expect(ok, isTrue);
        expect(await videoTs.exists(), isTrue);
        expect(await assembledMarker.exists(), isFalse);
        for (final seg in segFiles) {
          expect(await seg.exists(), isFalse);
        }

        // Unified manifests must exist and point to video.ts for 100% offline playback compatibility
        final videoM3u8 = File('${bundleDir.path}/video.m3u8');
        final masterM3u8 = File('${bundleDir.path}/master.m3u8');
        expect(await videoM3u8.exists(), isTrue);
        expect(await masterM3u8.exists(), isTrue);
        expect(await videoM3u8.readAsString(), contains('video.ts'));

        // findPlayableOfflineFile returns unified video.ts directly
        final playable = await OfflineMp4Builder.findPlayableOfflineFile(bundleDir);
        expect(playable?.path, equals(videoTs.path));
      } finally {
        await tempDir.delete(recursive: true);
      }
    });
  });

  group('Download List Screen Finalizing & Season Dropdown Widget Tests', () {
    Widget buildSubject({
      required List<DownloadItem> items,
      AppLanguage lang = AppLanguage.id,
    }) {
      return ProviderScope(
        overrides: [
          appLanguageProvider.overrideWith((ref) => _TestLanguageNotifier(lang)),
          downloadManagerProvider.overrideWith(
            (ref) => _TestDownloadNotifier(
              ref.watch(downloadRepositoryProvider),
              items,
            ),
          ),
        ],
        child: const MaterialApp(
          home: DownloadListScreen(),
        ),
      );
    }

    testWidgets('Renders Finalizing badge and progress message during finalizing', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final finalizingItem = DownloadItem(
        id: 'tv_456_s1_e2',
        tmdbId: 456,
        title: 'Stranger Things',
        mediaType: 'tv',
        seasonNumber: 1,
        episodeNumber: 2,
        episodeTitle: 'The Weirdo on Maple Street',
        posterPath: '/stranger_things_official.jpg',
        status: DownloadStatus.finalizing,
        progress: 0.42,
        speed: 'Menyatukan segmen video 42/100',
        videoFileName: 'Stranger Things - S1 E2.mp4',
        subtitleFileName: 'Stranger Things - S1 E2.srt',
        videoPath: '',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(buildSubject(items: [finalizingItem]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Finalizing UI elements
      expect(find.text('FINALIZING'), findsOneWidget);
      expect(find.text('Menyatukan segmen video 42/100'), findsOneWidget);
      expect(find.textContaining('Sedang menyatukan segmen offline'), findsOneWidget);
      expect(find.text('42%'), findsOneWidget);
    });

    testWidgets('Renders TV Series Season Dropdown when multiple seasons are downloaded', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final completedItems = [
        DownloadItem(
          id: 'tv_789_s1_e1',
          tmdbId: 789,
          title: 'Arcane',
          mediaType: 'tv',
          seasonNumber: 1,
          episodeNumber: 1,
          episodeTitle: 'Welcome to the Playground',
          posterPath: '/arcane_official.jpg',
          status: DownloadStatus.completed,
          progress: 1.0,
          speed: 'Selesai',
          videoFileName: 'Arcane - S1 E1.mp4',
          subtitleFileName: 'Arcane - S1 E1.srt',
          videoPath: '/path/to/arcane_s1_e1.mp4',
          createdAt: DateTime.now(),
        ),
        DownloadItem(
          id: 'tv_789_s2_e1',
          tmdbId: 789,
          title: 'Arcane',
          mediaType: 'tv',
          seasonNumber: 2,
          episodeNumber: 1,
          episodeTitle: 'Heavy Is the Crown',
          posterPath: '/arcane_official.jpg',
          status: DownloadStatus.completed,
          progress: 1.0,
          speed: 'Selesai',
          videoFileName: 'Arcane - S2 E1.mp4',
          subtitleFileName: 'Arcane - S2 E1.srt',
          videoPath: '/path/to/arcane_s2_e1.mp4',
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(buildSubject(items: completedItems));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Switch to Tersimpan Offline (Completed) tab
      await tester.tap(find.text('Tersimpan Offline'));
      await tester.pumpAndSettle();

      expect(find.text('Arcane'), findsOneWidget);
      expect(find.text('2 Season • 2 Episode'), findsOneWidget);

      // Tap on the TV Series card to expand
      await tester.tap(find.text('Arcane'));
      await tester.pumpAndSettle();

      // Season Dropdown selector appears
      expect(find.text('Pilih Season:'), findsOneWidget);
      expect(find.byType(DropdownButton<int>), findsOneWidget);
    });
  });
}
