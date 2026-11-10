import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

import 'app/app.dart';
import 'app/routes/app_router.dart';
import 'app/theme/app_colors.dart';
import 'core/constants/app_constants.dart';
import 'core/platform/device_form_factor.dart';
import 'core/platform/smooth_mouse_scroll.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

Future<void> main() async {
  CinevaWidgetsBinding.ensureInitialized();

  // Initialize Firebase & Analytics safely on supported platforms (Android / iOS)
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      await Firebase.initializeApp();
      final analytics = FirebaseAnalytics.instance;
      await analytics.setAnalyticsCollectionEnabled(true);
      await analytics.logAppOpen();

      // Reliable GoRouter screen tracking immune to Dart AOT code obfuscation
      String? lastTrackedScreen;
      appRouter.routerDelegate.addListener(() {
        try {
          final location =
              appRouter.routerDelegate.currentConfiguration.uri.toString();
          if (location.isNotEmpty && location != lastTrackedScreen) {
            lastTrackedScreen = location;
            analytics.logScreenView(
              screenName: location,
              screenClass: location,
            );
          }
        } catch (_) {}
      });
      debugPrint('[Firebase] Initialized successfully with Analytics.');
    } catch (e) {
      debugPrint('[Firebase] Initialization error: $e');
    }
  }

  // Prevent release mode blank screen on unhandled widget exceptions
  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint('[ErrorWidget] Caught build error: ${details.exception}');
    return Material(
      color: AppColors.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.primary,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Terjadi Kesalahan Tampilan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                details.exceptionAsString(),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  };

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
        backgroundColor: AppColors.background,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.hidden,
      );
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
        await windowManager.maximize();
      });
    } catch (e) {
      debugPrint('[main] Non-fatal error initializing windowManager: $e');
    }
  }

  // Orientation and System UI setup
  bool isTv = false;
  if (!kIsWeb && Platform.isAndroid) {
    try {
      const channel = MethodChannel('com.primadev.cineva/device');
      isTv = await channel.invokeMethod<bool>('isTelevision') ?? false;
      gIsTelevision = isTv;
    } catch (e) {
      debugPrint('[main] Non-fatal error detecting TV: $e');
    }
  }

  if (!kIsWeb && Platform.isAndroid) {
    try {
      if (isTv) {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        // Android TV 10-Foot UI: immersive sticky mode prevents system UI overlay crashes
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        // Smartphone UI: edge-to-edge transparent bars
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.light,
            systemNavigationBarContrastEnforced: false,
          ),
        );
      }
    } catch (e) {
      debugPrint('[main] Non-fatal error configuring Android SystemChrome: $e');
    }
  }

  // Initialize Hive for local storage safely
  try {
    await Hive.initFlutter();
    await Hive.openBox(AppConstants.watchlistBox);
    await Hive.openBox(AppConstants.historyBox);
    await Hive.openBox(AppConstants.settingsBox);
    await Hive.openBox(AppConstants.downloadsBox);
  } catch (e) {
    debugPrint('[main] Error initializing Hive: $e');
  }

  // Initialize media_kit for video playback
  try {
    MediaKit.ensureInitialized();
  } catch (e) {
    debugPrint('[main] Non-fatal error initializing MediaKit: $e');
  }

  // Optimize image cache to eliminate GC pauses and memory spikes on 4GB RAM devices
  PaintingBinding.instance.imageCache.maximumSize = 100;
  PaintingBinding.instance.imageCache.maximumSizeBytes =
      60 * 1024 * 1024; // 60 MB

  runApp(const ProviderScope(child: CinevaApp()));
}
