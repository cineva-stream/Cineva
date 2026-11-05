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

/// StateNotifier that stores whether the app is running on a TV.
class TvModeNotifier extends StateNotifier<bool> {
  TvModeNotifier() : super(false) {
    _detectTv();
  }

  Future<void> _detectTv() async {
    if (kIsWeb) return;
    if (Platform.isAndroid) {
      try {
        final bool? isTv = await _deviceChannel.invokeMethod<bool>('isTelevision');
        if (isTv == true && mounted) {
          state = true;
        }
      } catch (e) {
        debugPrint('[TvModeNotifier] Non-fatal error detecting TV mode: $e');
      }
    }
  }

  /// Allows manual toggling (e.g. from Settings or developer options)
  void setTvMode(bool value) {
    state = value;
  }
}

final isTvProvider = StateNotifierProvider<TvModeNotifier, bool>((ref) {
  return TvModeNotifier();
});

/// Returns true if running on desktop (Windows, macOS, Linux).
final isDesktopProvider = Provider<bool>((ref) {
  if (kIsWeb) return false;
  return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
});

/// Context helper to resolve the effective form factor based on screen width & TV mode.
DeviceFormFactor resolveFormFactor(BuildContext context, {required bool isTv}) {
  if (isTv) return DeviceFormFactor.tv;
  final width = MediaQuery.sizeOf(context).width;
  if (width >= 960) return DeviceFormFactor.desktop;
  if (width >= 600) return DeviceFormFactor.tablet;
  return DeviceFormFactor.mobile;
}

