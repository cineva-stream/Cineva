import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

import 'app/app.dart';
import 'core/constants/app_constants.dart';
import 'core/platform/smooth_mouse_scroll.dart';

Future<void> main() async {
  CinevaWidgetsBinding.ensureInitialized();

  // Initialize frameless window on desktop (Windows, macOS, Linux) with hidden native titlebar
  if (!kIsWeb &&
      !Platform.environment.containsKey('FLUTTER_TEST') &&
      (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    try {
      await windowManager.ensureInitialized();
      const windowOptions = WindowOptions(
        size: Size(1280, 720),
        minimumSize: Size(960, 540),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.hidden,
      );
      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
        await windowManager.maximize();
      });
    } catch (e) {
      debugPrint('[main] Non-fatal error initializing windowManager: $e');
    }
  }

  // Lock to portrait on phones; allow landscape on player screen
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Enable edge-to-edge: draw content behind both system bars
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarContrastEnforced: false,
  ));

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Hive for local storage
  await Hive.initFlutter();
  await Hive.openBox(AppConstants.watchlistBox);
  await Hive.openBox(AppConstants.historyBox);
  await Hive.openBox(AppConstants.settingsBox);
  await Hive.openBox(AppConstants.downloadsBox);

  // Initialize media_kit for video playback
  MediaKit.ensureInitialized();

  // Optimize image cache to eliminate GC pauses and memory spikes on 4GB RAM devices
  PaintingBinding.instance.imageCache.maximumSize = 100;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 60 * 1024 * 1024; // 60 MB


  runApp(
    const ProviderScope(
      child: CinevaApp(),
    ),
  );
}
