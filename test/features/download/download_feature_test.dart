import 'package:flutter_test/flutter_test.dart';
import 'package:cineva/features/download/domain/models/download_item.dart';
import 'package:cineva/features/download/data/services/download_file_namer.dart';
import 'package:cineva/features/download/data/services/download_subtitle_pipeline.dart';
import 'package:cineva/features/player/data/models/subtitle_cue.dart';

void main() {
  group('DownloadFileNamer Tests', () {
    test('formatMovieFileName should strictly match "{Movie Name} - {Release Year}.mp4"', () {
      final name = DownloadFileNamer.formatMovieFileName(
        'SpiderMan Brand New Day',
        '2026',
      );
      expect(name, 'SpiderMan Brand New Day - 2026.mp4');
    });

    test('formatTvFileName should strictly match "{TV Series Name} - S{Season} E{Episode}.mp4"', () {
      final ep1 = DownloadFileNamer.formatTvFileName('The Originals', 1, 1);
      expect(ep1, 'The Originals - S1 E01.mp4');

      final ep12 = DownloadFileNamer.formatTvFileName('The Originals', 3, 12);
      expect(ep12, 'The Originals - S3 E12.mp4');
    });

    test('formatSubtitleFileName should replace .mp4 with .srt', () {
      final movieSub = DownloadFileNamer.formatSubtitleFileName(
        'SpiderMan Brand New Day - 2026.mp4',
      );
      expect(movieSub, 'SpiderMan Brand New Day - 2026.srt');

      final tvSub = DownloadFileNamer.formatSubtitleFileName(
        'The Originals - S1 E01.mp4',
      );
      expect(tvSub, 'The Originals - S1 E01.srt');
    });

    test('sanitizeFileName should remove illegal characters for device storage', () {
      final sanitized = DownloadFileNamer.sanitizeFileName('Film: Subtitle / Part 1 * "Special"? <Test> | Win');
      expect(sanitized, 'Film Subtitle Part 1 Special Test Win');
    });
  });

  group('DownloadItem Model Tests', () {
    test('toJson and fromJson should preserve all fields correctly', () {
      final now = DateTime.now();
      final item = DownloadItem(
        id: 'movie_76600',
        tmdbId: 76600,
        title: 'SpiderMan Brand New Day',
        mediaType: 'movie',
        releaseYear: '2026',
        resolution: '1080p',
        estimatedSizeBytes: 1800000000,
        downloadedBytes: 900000000,
        totalBytes: 1800000000,
        status: DownloadStatus.downloading,
        progress: 0.5,
        speed: '3.2 MB/s',
        videoFileName: 'SpiderMan Brand New Day - 2026.mp4',
        subtitleFileName: 'SpiderMan Brand New Day - 2026.srt',
        videoPath: '/storage/emulated/0/Download/Cineva/SpiderMan Brand New Day - 2026.mp4',
        subtitlePath: '/storage/emulated/0/Download/Cineva/SpiderMan Brand New Day - 2026.srt',
        selectedSubtitleLang: 'id',
        subtitleStatus: 'translated',
        createdAt: now,
      );

      final json = item.toJson();
      final restored = DownloadItem.fromJson(json);

      expect(restored.id, item.id);
      expect(restored.title, item.title);
      expect(restored.videoFileName, 'SpiderMan Brand New Day - 2026.mp4');
      expect(restored.subtitleFileName, 'SpiderMan Brand New Day - 2026.srt');
      expect(restored.status, DownloadStatus.downloading);
      expect(restored.progress, 0.5);
      expect(restored.speed, '3.2 MB/s');
      expect(restored.subtitleStatus, 'translated');
    });

    test('size formatters should format GB and MB correctly', () {
      final itemGb = DownloadItem(
        id: 'test_1',
        tmdbId: 1,
        title: 'Test',
        mediaType: 'movie',
        totalBytes: 2147483648, // 2 GB
        downloadedBytes: 1073741824, // 1 GB
        videoFileName: 'Test - 2024.mp4',
        subtitleFileName: 'Test - 2024.srt',
        videoPath: '',
        createdAt: DateTime.now(),
      );

      expect(itemGb.formattedTotalSize, '2.00 GB');
      expect(itemGb.formattedDownloadedSize, '1.00 GB');
    });
  });

  group('DownloadSubtitlePipeline SRT Conversion Tests', () {
    test('cuesToSrt should convert SubtitleCue list to valid SRT string', () {
      final cues = [
        const SubtitleCue(
          start: Duration(seconds: 1, milliseconds: 500),
          end: Duration(seconds: 4, milliseconds: 200),
          text: 'Halo, apa kabar?',
        ),
        const SubtitleCue(
          start: Duration(minutes: 1, seconds: 10),
          end: Duration(minutes: 1, seconds: 15),
          text: 'Aku sedang menonton Cineva.',
        ),
      ];

      final srt = DownloadSubtitlePipeline.cuesToSrt(cues);
      expect(srt, contains('1\n00:00:01,500 --> 00:00:04,200\nHalo, apa kabar?'));
      expect(srt, contains('2\n00:01:10,000 --> 00:01:15,000\nAku sedang menonton Cineva.'));
    });
  });
}
