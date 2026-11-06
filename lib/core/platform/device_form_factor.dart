import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DeviceFormFactor {
  mobile,
  tablet,
  desktop,
  tv,
}

/// Native channel to query Android system features (e.g. Leanback / Television)
const MethodChannel _deviceChannel = MethodChannel('com.primadev.cineva/device');

/// Global flag initialized synchronously during main() for instant TV mode without initial frame delay
bool gIsTelevision = false;

/// StateNotifier that stores whether the app is running on a TV.
class TvModeNotifier extends StateNotifier<bool> {
  TvModeNotifier() : super(gIsTelevision) {
    _detectTv();
  }

  Future<void> _detectTv() async {
    if (kIsWeb) return;
    if (Platform.isAndroid) {
      try {
        final bool? isTv = await _deviceChannel.invokeMethod<bool>('isTelevision');
        if (isTv != null && isTv != state && mounted) {
          state = isTv;
          gIsTelevision = isTv;
        }
      } catch (e) {
        debugPrint('[TvModeNotifier] Non-fatal error detecting TV mode: $e');
      }
    }
  }

  /// Allows manual toggling (e.g. from Settings or developer options)
  void setTvMode(bool value) {
    state = value;
    gIsTelevision = value;
  }
}

final isTvProvider = StateNotifierProvider<TvModeNotifier, bool>((ref) {
  return TvModeNotifier();
});

/// Returns true if running on desktop (Windows, macOS, Linux).
final isDesktopProvider = Provider<bool>((ref) {
  if (kIsWeb) return false;
  if (Platform.environment.containsKey('FLUTTER_TEST')) return false;
  return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
});

/// Comprehensive helper to determine whether the screen should render in widescreen
/// mode (Desktop layout, Android TV 10-Foot UI, or landscape widescreen layout).
///
/// Reliably covers:
/// - Windows, macOS, Linux desktop platforms
/// - Android TV (720p, 1080p, 4K)
/// - 720p Android TV emulators / STB boxes (logical widths ~640px to ~853px in landscape)
/// - Any widescreen landscape display with width >= 960 or (width >= 640 and aspect ratio >= 1.35)
bool isWideScreenLayout(BuildContext context, {bool isTv = false}) {
  if (isTv || gIsTelevision) return true;
  if (!kIsWeb &&
      !Platform.environment.containsKey('FLUTTER_TEST') &&
      (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    return true;
  }

  final size = MediaQuery.sizeOf(context);
  final width = size.width;
  final height = size.height;
  final isLandscape = width > height;

  // Standard Desktop / 1080p TV logical width breakpoint
  if (width >= 960) return true;

  // 720p Android TV (typically 1280x720 physical pixels = 853px with 1.5x scale, or 640px with 2.0x scale)
  if (isLandscape && width >= 640 && (width / height) >= 1.35) {
    return true;
  }

  return false;
}

/// Context helper to resolve the effective form factor based on screen width & TV mode.
DeviceFormFactor resolveFormFactor(BuildContext context, {required bool isTv}) {
  if (isTv || gIsTelevision) return DeviceFormFactor.tv;
  if (!kIsWeb &&
      !Platform.environment.containsKey('FLUTTER_TEST') &&
      (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    return DeviceFormFactor.desktop;
  }

  final size = MediaQuery.sizeOf(context);
  final width = size.width;
  final height = size.height;
  final isLandscape = width > height;

  if (width >= 960) return DeviceFormFactor.desktop;
  if (isLandscape && width >= 640 && (width / height) >= 1.35) return DeviceFormFactor.tv;
  if (width >= 600) return DeviceFormFactor.tablet;
  return DeviceFormFactor.mobile;
}

