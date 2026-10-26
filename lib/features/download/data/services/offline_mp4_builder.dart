import 'dart:io';

import 'package:flutter/foundation.dart';

import 'native_media_muxer.dart';

/// Shared helper that concatenates offline HLS `.ts` segments (v_XXXX.ts / a_XXXX.ts)
/// and remuxes them into a single, validated `video.mp4`.
///
/// Source segments are only deleted when the resulting MP4 has been validated by the
/// native side. On any failure the partial MP4 is removed and the HLS bundle
/// (master.m3u8 + segments) is preserved as a playable fallback.
class OfflineMp4Builder {
  static const String mp4Name = 'video.mp4';

  static String _baseName(FileSystemEntity f) => f.path.split(RegExp(r'[\\/]')).last;

  /// Lists segment files in [dir] whose name starts with [prefix] and ends with `.ts`, sorted.
  static Future<List<File>> listSegments(Directory dir, String prefix) async {
    final files = <File>[];
    await for (final e in dir.list()) {
      if (e is File) {
        final name = _baseName(e);
        if (name.startsWith(prefix) && name.endsWith('.ts')) files.add(e);
      }
    }
    files.sort((a, b) => _baseName(a).compareTo(_baseName(b)));
    return files;
  }

  /// Sums `#EXTINF` durations of an m3u8 file in microseconds. Returns null if unavailable.
  static Future<int?> expectedDurationUsFromPlaylist(File playlist) async {
    try {
      if (!await playlist.exists()) return null;
      final lines = await playlist.readAsLines();
      double total = 0;
      for (final l in lines) {
        final m = RegExp(r'^#EXTINF:([0-9.]+)').firstMatch(l.trim());
        if (m != null) total += double.tryParse(m.group(1)!) ?? 0;
      }
      return total > 0 ? (total * 1000000).round() : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _concat(List<File> parts, File target) async {
    final sink = target.openWrite();
    try {
      for (final f in parts) {
        await sink.addStream(f.openRead());
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
  }

  /// Builds `video.mp4` inside [dir]. Returns true only if a validated MP4 was produced.
  ///
  /// When a mux fails, a `.mux_failed` marker is written. Callers that run lazily at playback
  /// time pass [respectFailureMarker] = true so a known-bad conversion is not retried each time.
  static Future<bool> build({
    required Directory dir,
    int? expectedDurationUs,
    bool deleteSegmentsOnSuccess = true,
    bool respectFailureMarker = false,
  }) async {
    if (!Platform.isAndroid) return false;

    final marker = File('${dir.path}/.mux_failed');
    if (respectFailureMarker && await marker.exists()) return false;
    try {
      if (await marker.exists()) await marker.delete();
    } catch (_) {}

    final videoSegments = await listSegments(dir, 'v_');
    if (videoSegments.isEmpty) return false;
    final audioSegments = await listSegments(dir, 'a_');

    final videoTemp = File('${dir.path}/temp_video.ts');
    final audioTemp = File('${dir.path}/temp_audio.ts');
    final mp4 = File('${dir.path}/$mp4Name');

    try {
      await _concat(videoSegments, videoTemp);

      String? audioTempPath;
      if (audioSegments.isNotEmpty) {
        await _concat(audioSegments, audioTemp);
        if (await audioTemp.exists() && (await audioTemp.length()) > 1000) {
          audioTempPath = audioTemp.path;
        }
      }

      final ok = await NativeMediaMuxer.muxToMp4(
        videoPath: videoTemp.path,
        audioPath: audioTempPath,
        outputPath: mp4.path,
        expectedDurationUs: expectedDurationUs,
      );

      if (ok && await mp4.exists() && (await mp4.length()) > 50000) {
        if (deleteSegmentsOnSuccess) {
          for (final f in [...videoSegments, ...audioSegments]) {
            try {
              await f.delete();
            } catch (_) {}
          }
        }
        debugPrint('[OfflineMp4Builder] Validated MP4 created: ${mp4.path}');
        return true;
      }

      debugPrint('[OfflineMp4Builder] Mux failed validation; keeping HLS fallback.');
      try {
        if (await mp4.exists()) await mp4.delete();
        await marker.writeAsString('failed');
      } catch (_) {}
      return false;
    } catch (e) {
      debugPrint('[OfflineMp4Builder] Error: $e');
      try {
        if (await mp4.exists()) await mp4.delete();
        await marker.writeAsString('failed');
      } catch (_) {}
      return false;
    } finally {
      try {
        if (await videoTemp.exists()) await videoTemp.delete();
        if (await audioTemp.exists()) await audioTemp.delete();
      } catch (_) {}
    }
  }

  /// Returns true if [mp4] exists and is a valid, playable MP4 (native probe on Android).
  /// On non-Android platforms (no probe available) only the size is checked.
  static Future<bool> isValidMp4(File mp4) async {
    try {
      if (!await mp4.exists() || (await mp4.length()) <= 50000) return false;
      if (!Platform.isAndroid) return true;
      final probe = await NativeMediaMuxer.probe(mp4.path);
      return probe != null && probe.isPlayable;
    } catch (_) {
      return false;
    }
  }
}
