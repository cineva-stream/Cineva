import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Result of probing a media file with the native Android MediaExtractor.
class NativeMediaProbe {
  final int durationMs;
  final bool hasVideo;
  final bool hasAudio;

  const NativeMediaProbe({
    required this.durationMs,
    required this.hasVideo,
    required this.hasAudio,
  });

  bool get isPlayable => hasVideo;
}

/// Service interfacing with native Android MediaMuxer to package H.264 video
/// and AAC audio into standard, hardware-accelerated .mp4 containers with zero stutter.
class NativeMediaMuxer {
  static const MethodChannel _channel = MethodChannel('com.primadev.cineva/muxer');

  /// Remuxes video TS and optional separate audio TS into a standard hardware-accelerated MP4 container.
  /// When [expectedDurationUs] is given, the native side validates the output duration and
  /// deletes the output (returning false) if it is significantly shorter than expected.
  static Future<bool> muxToMp4({
    required String videoPath,
    String? audioPath,
    required String outputPath,
    int? expectedDurationUs,
  }) async {
    if (!Platform.isAndroid) {
      debugPrint('[NativeMediaMuxer] Native muxing is only supported on Android.');
      return false;
    }

    try {
      final success = await _channel.invokeMethod<bool>('muxToMp4', {
        'videoPath': videoPath,
        'audioPath': audioPath,
        'outputPath': outputPath,
        'expectedDurationUs': expectedDurationUs,
      });
      return success ?? false;
    } on PlatformException catch (e) {
      debugPrint('[NativeMediaMuxer] PlatformException during mux: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[NativeMediaMuxer] Unexpected error during mux: $e');
      return false;
    }
  }

  /// Probes a media file. Returns null if unsupported or the file cannot be parsed.
  static Future<NativeMediaProbe?> probe(String path) async {
    if (!Platform.isAndroid) return null;
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>('probeMedia', {'path': path});
      if (res == null) return null;
      return NativeMediaProbe(
        durationMs: (res['durationMs'] as num?)?.toInt() ?? 0,
        hasVideo: res['hasVideo'] as bool? ?? false,
        hasAudio: res['hasAudio'] as bool? ?? false,
      );
    } on PlatformException catch (e) {
      debugPrint('[NativeMediaMuxer] probe failed: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[NativeMediaMuxer] probe error: $e');
      return null;
    }
  }
}
