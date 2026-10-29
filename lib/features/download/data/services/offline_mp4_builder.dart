import 'dart:io';

import 'package:flutter/foundation.dart';

import 'native_media_muxer.dart';

/// Shared helper that concatenates offline HLS `.ts` segments (v_XXXX.ts / a_XXXX.ts)
/// and remuxes them into a single, validated `video.mp4` via hardware muxer on Android.
///
/// Source segments are ONLY deleted when the resulting MP4 has been validated with a playable
/// video track. If MP4 remuxing is not supported or fails, the raw HLS bundle (master.m3u8 + segments)
/// is preserved 100% intact so LocalStreamServer plays it with complete quality and synced audio.
class OfflineMp4Builder {
  static const String mp4Name = 'video.mp4';
  static const String videoTsName = 'video.ts';
  static const String audioTsName = 'audio.ts';

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

  /// Builds `video.mp4` inside [dir].
  ///
  /// Steps:
  /// 1. Concatenates raw segments into temporary `video.ts` and `audio.ts`.
  /// 2. Remuxes them into `video.mp4` via Android MediaMuxer hardware engine.
  /// 3. If MP4 succeeds and is validated: deletes temporary TS and segment fragments.
  /// 4. If MP4 fails: cleans up temporary TS/MP4 files and preserves the raw HLS bundle
  ///    (master.m3u8 + segments) so LocalStreamServer plays it seamlessly offline!
  static Future<bool> build({
    required Directory dir,
    int? expectedDurationUs,
    bool deleteSegmentsOnSuccess = true,
    bool respectFailureMarker = false,
  }) async {
    final marker = File('${dir.path}/.mux_failed');
    if (respectFailureMarker && await marker.exists()) return false;
    try {
      if (await marker.exists()) await marker.delete();
    } catch (_) {}

    final videoSegments = await listSegments(dir, 'v_');
    final audioSegments = await listSegments(dir, 'a_');

    final mp4 = File('${dir.path}/$mp4Name');
    final videoTs = File('${dir.path}/$videoTsName');
    final audioTs = File('${dir.path}/$audioTsName');

    if (videoSegments.isEmpty) {
      if (await isValidMp4(mp4)) return true;
      if (await videoTs.exists() && (await videoTs.length()) > 50000) return true;
      return false;
    }

    try {
      // 1. Concatenate all video segments into temporary video.ts
      await _concat(videoSegments, videoTs);

      String? audioPath;
      if (audioSegments.isNotEmpty) {
        await _concat(audioSegments, audioTs);
        if (await audioTs.exists() && (await audioTs.length()) > 1000) {
          audioPath = audioTs.path;
        }
      }

      // 2. On Android, attempt native remux to MP4
      bool ok = false;
      if (Platform.isAndroid) {
        ok = await NativeMediaMuxer.muxToMp4(
          videoPath: videoTs.path,
          audioPath: audioPath,
          outputPath: mp4.path,
          expectedDurationUs: expectedDurationUs,
        );
      }

      final validMp4 = ok && await isValidMp4(mp4);
      if (validMp4) {
        if (deleteSegmentsOnSuccess) {
          for (final f in [...videoSegments, ...audioSegments]) {
            try { await f.delete(); } catch (_) {}
          }
        }
        try { if (await videoTs.exists()) await videoTs.delete(); } catch (_) {}
        try { if (await audioTs.exists()) await audioTs.delete(); } catch (_) {}
        debugPrint('[OfflineMp4Builder] Validated MP4 successfully built: ${mp4.path}');
        return true;
      }

      // 3. Fallback: MP4 did NOT validate or native mux failed.
      // Clean up temporary concat TS and invalid MP4 files so disk space is not wasted.
      // NEVER delete the raw HLS segments! The HLS bundle (master.m3u8 + segments)
      // is preserved intact so LocalStreamServer plays it with 100% reliability.
      try { if (await mp4.exists()) await mp4.delete(); } catch (_) {}
      try { if (await videoTs.exists()) await videoTs.delete(); } catch (_) {}
      try { if (await audioTs.exists()) await audioTs.delete(); } catch (_) {}
      await marker.writeAsString('mux_failed');
      debugPrint('[OfflineMp4Builder] Native remux failed or unvalidated; preserving raw HLS segments for LocalStreamServer.');
      return false;
    } catch (e) {
      debugPrint('[OfflineMp4Builder] Error during build: $e');
      try { if (await mp4.exists()) await mp4.delete(); } catch (_) {}
      try { if (await videoTs.exists()) await videoTs.delete(); } catch (_) {}
      try { if (await audioTs.exists()) await audioTs.delete(); } catch (_) {}
      return false;
    }
  }

  /// Returns true if [mp4] exists and has a validated video track (or substantial size).
  static Future<bool> isValidMp4(File mp4) async {
    try {
      if (!await mp4.exists()) return false;
      final len = await mp4.length();
      if (len <= 50000) return false;
      if (!Platform.isAndroid) return true;
      final probe = await NativeMediaMuxer.probe(mp4.path);
      if (probe == null) return len > 100000;
      return probe.hasVideo;
    } catch (_) {
      return false;
    }
  }

  /// Locates the best offline playable file in [dir] (MP4 -> TS fallback -> HLS playlist).
  static Future<File?> findPlayableOfflineFile(Directory dir) async {
    // 1. Standalone validated MP4
    final mp4 = File('${dir.path}/$mp4Name');
    if (await isValidMp4(mp4)) return mp4;

    // 2. Unified TS container if present (>50KB)
    final videoTs = File('${dir.path}/$videoTsName');
    if (await videoTs.exists() && (await videoTs.length()) > 50000) {
      return videoTs;
    }

    // 3. Complete offline HLS package
    final hls = File('${dir.path}/master.m3u8');
    if (await hls.exists()) {
      return hls;
    }

    final masterCineva = File('${dir.path}/master.cineva');
    if (await masterCineva.exists()) {
      return masterCineva;
    }

    final videoM3u8 = File('${dir.path}/video.m3u8');
    if (await videoM3u8.exists()) {
      return videoM3u8;
    }

    return null;
  }

  /// Returns the secondary audio file in [dir] if audio was stored separately.
  static Future<File?> getSecondaryAudioFile(Directory dir) async {
    final audioTs = File('${dir.path}/$audioTsName');
    if (await audioTs.exists() && (await audioTs.length()) > 1000) {
      return audioTs;
    }
    return null;
  }
}
