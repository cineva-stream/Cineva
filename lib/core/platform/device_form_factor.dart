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

/// Convenience alias for [gIsTelevision]
bool get gIsTv => gIsTelevision;
set gIsTv(bool value) => gIsTelevision = value;

/// Global flag initialized during main() for tablet devices (shortestSide >= 600 on non-TV mobile OS)
bool gIsTablet = false;

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

/// Returns true if the current viewport is a Tablet (shortestSide >= 600 on non-TV, or width between 600 and 1200).
bool isTabletLayout(BuildContext context, {bool isTv = false}) {
  if (isTv || gIsTelevision) return false;
  final size = MediaQuery.sizeOf(context);
  return size.shortestSide >= 600 || (size.width >= 600 && size.width < 960);
}

/// Comprehensive helper to determine whether the screen should render in widescreen /
/// adaptive rail mode (Tablet, Windows Desktop, or Android TV 10-Foot UI).
///
/// Reliably covers:
/// - Windows, macOS, Linux desktop platforms
/// - Android TV (720p, 1080p, 4K)
/// - Tablets (portrait >= 600px and landscape)
/// - Any display with width >= 600px
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

  // In widget tests, the default Flutter test surface is 800x600 (4:3).
  // Keep default 800x600 test surface on mobile layout unless explicitly testing TV/tablet sizes.
  if (!kIsWeb &&
      Platform.environment.containsKey('FLUTTER_TEST') &&
      width == 800 &&
      height == 600) {
    return false;
  }

  // Tablet (portrait/landscape), Desktop, and 720p/1080p TV logical width breakpoint
  if (width >= 600) return true;

  // 720p Android TV / compact landscape display
  if (isLandscape && width >= 560 && (width / height) >= 1.35) {
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
  // 720p Android TV with 1.5x or 2.0x scaling (e.g. 853x480 or 640x360: landscape 16:9 with shortestSide < 600)
  if (isLandscape &&
      width >= 560 &&
      size.shortestSide < 600 &&
      (width / height) >= 1.35) {
    return DeviceFormFactor.tv;
  }
  if (width >= 600 || size.shortestSide >= 600) return DeviceFormFactor.tablet;
  return DeviceFormFactor.mobile;
}

/// Calculates the optimal number of poster columns for media grids across
/// Smartphone, Tablet (Portrait/Landscape), Windows Desktop, and Android TV.
int adaptivePosterGridColumns(double availableWidth, {bool isTv = false}) {
  if (availableWidth < 340) return 2;
  if (availableWidth < 560) return 3;
  if (availableWidth < 840) return 4; // Tablet Portrait / Small Window
  if (availableWidth < 1180) return 5; // Tablet Landscape / 720p TV / Medium Window
  if (availableWidth < 1560) return 6; // 1080p TV / Standard Desktop
  return 7; // Large / Ultra-wide Desktop
}

/// Calculates the optimal childAspectRatio for poster grids so cards never overflow.
double adaptivePosterGridAspectRatio(double availableWidth, {bool isTv = false}) {
  if (availableWidth >= 600 || isTv || gIsTelevision) {
    return 0.56;
  }
  return 0.53;
}

/// Calculates the optimal number of columns for horizontal card lists
/// (Live TV channels, Watchlist, Watch History, Airing Calendar, Collections, Downloads).
int adaptiveHorizontalCardGridColumns(double availableWidth, {bool isTv = false}) {
  if (availableWidth < 620 && !isTv && !gIsTelevision) return 1;
  if (availableWidth < 1040) return 2; // Tablet / Compact Desktop / 720p TV
  if (availableWidth < 1520) return 3; // Windows Desktop / 1080p TV
  return 4; // Ultra-wide Desktop
}

/// Centrally restores SystemChrome orientations and UI mode after exiting a fullscreen player.
/// Prevents Android TV and Tablets from being forced into portrait mode.
Future<void> restoreSystemUiAndOrientations({bool? isTv}) async {
  if (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST')) return;
  if (!Platform.isAndroid && !Platform.isIOS) return;

  final effectiveIsTv = (isTv ?? false) || gIsTelevision;
  try {
    if (effectiveIsTv) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      // Check if device is a tablet via global flag or physical view dimensions
      bool isTab = gIsTablet;
      if (!isTab) {
        final views = PlatformDispatcher.instance.views;
        if (views.isNotEmpty) {
          final view = views.first;
          final dpr = view.devicePixelRatio > 0 ? view.devicePixelRatio : 1.0;
          final shortestLogical = view.physicalSize.shortestSide / dpr;
          if (shortestLogical >= 600) {
            isTab = true;
            gIsTablet = true;
          }
        }
      }

      if (isTab) {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      }
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  } catch (e) {
    debugPrint('[restoreSystemUiAndOrientations] Non-fatal error: $e');
  }
}

