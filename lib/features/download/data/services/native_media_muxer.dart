import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service interfacing with native Android MediaMuxer to package H.264 video
/// and AAC audio into standard, hardware-accelerated .mp4 containers with zero stutter.
class NativeMediaMuxer {
  static const MethodChannel _channel = MethodChannel('com.primadev.cineva/muxer');

  /// Remuxes video TS and optional separate audio TS into a standard hardware-accelerated MP4 container.
  static Future<bool> muxToMp4({
    required String videoPath,
    String? audioPath,
    required String outputPath,
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
}
