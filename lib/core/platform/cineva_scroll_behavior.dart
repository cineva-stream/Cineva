import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Global scroll behavior for Cineva:
/// - Enables mouse & trackpad dragging across desktop platforms.
/// - Returns [ClampingScrollPhysics] on desktop platforms to match native desktop expectations.
/// - Preserves native platform physics on mobile and Android TV.
class CinevaScrollBehavior extends MaterialScrollBehavior {
  const CinevaScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    if (!kIsWeb &&
        !Platform.environment.containsKey('FLUTTER_TEST') &&
        (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      return const ClampingScrollPhysics();
    }
    return super.getScrollPhysics(context);
  }
}

