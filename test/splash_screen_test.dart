import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:cineva/app/theme/app_colors.dart';
import 'package:cineva/core/constants/app_constants.dart';
import 'package:cineva/core/localization/app_language.dart';
import 'package:cineva/core/localization/app_language_provider.dart';
import 'package:cineva/features/splash/presentation/screens/splash_screen.dart';

class _InMemoryLanguageNotifier extends AppLanguageNotifier {
  _InMemoryLanguageNotifier(super.initialLanguage);

  @override
  Future<void> setLanguage(AppLanguage language) async {
    state = language;
  }
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('cineva_splash_test_');
    Hive.init(tempDir.path);
    await Hive.openBox(AppConstants.settingsBox);
    await Hive.openBox(AppConstants.watchlistBox);
    await Hive.openBox(AppConstants.historyBox);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Widget buildSubject({Size surfaceSize = const Size(390, 844)}) {
    return ProviderScope(
      overrides: [
        appLanguageProvider.overrideWith((ref) => _InMemoryLanguageNotifier(AppLanguage.id)),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: surfaceSize),
          child: const SplashScreen(),
        ),
      ),
    );
  }

  /// Advances past both flutter_animate intro delays (max ~950ms) and _navTimer (2000ms).
  Future<void> advancePastIntro(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 700));
  }

  group('SplashScreen Vertical Tilted Poster Wall & Onboarding Flow Tests', () {
    testWidgets('Renders full-screen left-tilted vertical poster columns & bottom-to-top pure black fade', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildSubject(surfaceSize: const Size(390, 844)));
      await tester.pump(const Duration(milliseconds: 100));

      // Verify left-tilted Transform.rotate ("\", negative ~ -0.16 radians) exists
      final rotatedFinder = find.byWidgetPredicate((widget) {
        if (widget is Transform) {
          // Z-rotation matrix element [0] == cos(angle), [1] == sin(angle)
          final storage = widget.transform.storage;
          final sinVal = storage[1];
          final cosVal = storage[0];
          final angle = math.atan2(sinVal, cosVal);
          return (angle + 0.16).abs() < 0.02;
        }
        return false;
      });
      expect(rotatedFinder, findsOneWidget);

      // Verify GPU-composited Flow poster wall is present inside the tilted Transform.rotate
      final flowInRotated = find.descendant(
        of: rotatedFinder,
        matching: find.byType(Flow),
      );
      expect(flowInRotated, findsOneWidget);

      // Multiple vertical cached RepaintBoundary 2-card Column chunks should be rendered
      final chunkColumnsInWall = find.descendant(
        of: flowInRotated,
        matching: find.byType(Column),
      );
      expect(chunkColumnsInWall.evaluate().length, greaterThanOrEqualTo(12));

      // Verify poster card size is slightly enlarged (136x202 on standard mobile) and spacing is tight (8px)
      final posterCards = find.descendant(
        of: chunkColumnsInWall.first,
        matching: find.byWidgetPredicate((w) =>
            w is Container &&
            w.constraints?.maxWidth == 136.0 &&
            w.constraints?.maxHeight == 202.0 &&
            w.margin == const EdgeInsets.only(bottom: 8.0)),
      );
      expect(posterCards, findsWidgets);

      // Verify bottom-to-top pure black gradient fading to transparent exists
      final bottomToTopGradientFinder = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final dec = widget.decoration as BoxDecoration;
          if (dec.gradient is LinearGradient) {
            final grad = dec.gradient as LinearGradient;
            return grad.begin == Alignment.bottomCenter &&
                grad.end == Alignment.topCenter &&
                grad.colors.first == AppColors.background &&
                grad.colors.last == Colors.transparent;
          }
        }
        return false;
      });
      expect(bottomToTopGradientFinder, findsOneWidget);

      // Complete pending intro/nav timers cleanly
      await advancePastIntro(tester);
    });

    testWidgets('Counter-scrolling columns animate in opposite vertical directions across frames', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildSubject(surfaceSize: const Size(390, 844)));
      await tester.pump(const Duration(milliseconds: 500));

      final rotatedFinder = find.byWidgetPredicate((widget) {
        if (widget is Transform) {
          final angle = math.atan2(widget.transform.storage[1], widget.transform.storage[0]);
          return (angle + 0.16).abs() < 0.02;
        }
        return false;
      });

      final flowFinder = find.descendant(
        of: rotatedFinder,
        matching: find.byType(Flow),
      );
      expect(flowFinder, findsOneWidget);

      final flowRenderObj = tester.renderObject(flowFinder);
      final chunkRenderObjects = find
          .descendant(of: flowFinder, matching: find.byType(Column))
          .evaluate()
          .map((e) => e.renderObject!)
          .toList();

      RenderObject? firstChunkAtX(double targetX) {
        for (final ro in chunkRenderObjects) {
          final m = ro.getTransformTo(flowRenderObj).storage;
          if ((m[12] - targetX).abs() < 1.0 && m[13].abs() > 0.01) {
            return ro;
          }
        }
        return null;
      }

      final col0Chunk = firstChunkAtX(0.0);
      final col1Chunk = firstChunkAtX(144.0);
      final col2Chunk = firstChunkAtX(288.0);
      expect(col0Chunk, isNotNull);
      expect(col1Chunk, isNotNull);
      expect(col2Chunk, isNotNull);

      final t1Y0 = col0Chunk!.getTransformTo(flowRenderObj).storage[13];
      final t1Y1 = col1Chunk!.getTransformTo(flowRenderObj).storage[13];
      final t1Y2 = col2Chunk!.getTransformTo(flowRenderObj).storage[13];

      // Advance 2 seconds
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 800));

      final t2Y0 = col0Chunk.getTransformTo(flowRenderObj).storage[13];
      final t2Y1 = col1Chunk.getTransformTo(flowRenderObj).storage[13];
      final t2Y2 = col2Chunk.getTransformTo(flowRenderObj).storage[13];

      // Column 0 (even) moves up (deltaY < 0), Column 1 (odd) moves down (deltaY > 0)
      expect(t2Y0 - t1Y0, lessThan(0));
      expect(t2Y1 - t1Y1, greaterThan(0));
      expect(t2Y2 - t1Y2, lessThan(0));

      await tester.pump(const Duration(milliseconds: 700));
    });

    testWidgets('Transitions from Splash Intro to Language Selection & Google Login cleanly with working language switch', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildSubject(surfaceSize: const Size(390, 844)));
      await advancePastIntro(tester);

      // Verify Indonesian labels after transition
      expect(find.text('Pilih Bahasa'), findsOneWidget);
      expect(find.text('Indonesia'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Masuk dengan Google'), findsOneWidget);
      expect(find.text('Pulihkan dari File Cadangan'), findsOneWidget);
      expect(find.text('Mulai Menonton (Tanpa Akun)'), findsOneWidget);

      // Switch to English and verify reactive UI update
      await tester.tap(find.text('English'));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Select Language'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(find.text('Restore from Backup File'), findsOneWidget);
      expect(find.text('Start Watching (Guest Mode)'), findsOneWidget);
    });

    testWidgets('Renders without layout overflow on compact mobile (320x568) and desktop/TV widescreen (1280x720)', (tester) async {
      // 1. Compact mobile
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(buildSubject(surfaceSize: const Size(320, 568)));
      await advancePastIntro(tester);
      expect(find.text('Pilih Bahasa'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 2. Widescreen 720p Desktop / Android TV
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(buildSubject(surfaceSize: const Size(1280, 720)));
      await advancePastIntro(tester);
      expect(find.text('Pilih Bahasa'), findsOneWidget);
      expect(tester.takeException(), isNull);

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });
  });
}

