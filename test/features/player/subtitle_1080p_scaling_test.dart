import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cineva/core/platform/device_form_factor.dart';
import 'package:cineva/features/player/data/models/subtitle_cue.dart';
import 'package:cineva/features/player/data/models/subtitle_style_settings.dart';
import 'package:cineva/features/player/presentation/widgets/custom_subtitle_overlay.dart';

void main() {
  group('is1080pOrHigherDesktopOrTv Detection Tests', () {
    testWidgets('Returns true on Windows with 1080p physical display (1920x1080, 1.0 DPR)', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late bool result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = is1080pOrHigherDesktopOrTv(context, isWindows: true, isTv: false);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(result, isTrue);
    });

    testWidgets('Returns true on Windows with 125% DPI scale on 1080p display (1536x864 logical)', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.25; // 1536 x 864 logical
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late bool result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = is1080pOrHigherDesktopOrTv(context, isWindows: true, isTv: false);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(result, isTrue);
    });

    testWidgets('Returns true on Windows with 4K UHD display (3840x2160)', (tester) async {
      tester.view.physicalSize = const Size(3840, 2160);
      tester.view.devicePixelRatio = 2.0; // 1920 x 1080 logical
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late bool result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = is1080pOrHigherDesktopOrTv(context, isWindows: true, isTv: false);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(result, isTrue);
    });

    testWidgets('Returns false on Windows with 720p display (1280x720)', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late bool result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = is1080pOrHigherDesktopOrTv(context, isWindows: true, isTv: false);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(result, isFalse);
    });

    testWidgets('Returns true on Android TV with 1080p display (1920x1080)', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.5; // 1280 x 720 logical
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late bool result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = is1080pOrHigherDesktopOrTv(context, isWindows: false, isTv: true);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(result, isTrue);
    });

    testWidgets('Returns false on Android TV with 720p display (1280x720)', (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late bool result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = is1080pOrHigherDesktopOrTv(context, isWindows: false, isTv: true);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(result, isFalse);
    });

    testWidgets('Returns false on Android Mobile even with high-res screen (2400x1080)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0; // 360 x 800 logical
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late bool result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = is1080pOrHigherDesktopOrTv(context, isWindows: false, isTv: false);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(result, isFalse);
    });

    testWidgets('Returns false on Tablet even with large screen (2560x1600)', (tester) async {
      tester.view.physicalSize = const Size(2560, 1600);
      tester.view.devicePixelRatio = 2.0; // 1280 x 800 logical
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late bool result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = is1080pOrHigherDesktopOrTv(context, isWindows: false, isTv: false);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(result, isFalse);
    });
  });

  group('CustomSubtitleOverlay 1080p+ Scaling Widget Tests', () {
    final sampleCue = SubtitleCue(
      start: Duration.zero,
      end: const Duration(seconds: 10),
      text: 'Halo, ini adalah subtitle pengujian Cineva!',
    );

    testWidgets('Renders base font size (20pt) on Mobile and Tablet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                CustomSubtitleOverlay(
                  cues: [sampleCue],
                  currentPosition: const Duration(seconds: 1),
                  settings: const SubtitleStyleSettings(fontSize: 20.0),
                  is1080pDesktopOrTvOverride: false,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final textWidgets = tester.widgetList<Text>(find.text(sampleCue.text)).toList();
      expect(textWidgets.isNotEmpty, isTrue);

      // Check fill text layer font size is 20.0
      final fillText = textWidgets.last;
      expect(fillText.style?.fontSize, equals(20.0));

      // Check positioned bottom offset is 32.0 (default unscaled)
      final positioned = tester.widget<Positioned>(find.byType(Positioned));
      expect(positioned.bottom, equals(32.0));
    });

    testWidgets('Renders enhanced font size (30pt) and elevated bottom offset on 1080p+ Windows/TV', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                CustomSubtitleOverlay(
                  cues: [sampleCue],
                  currentPosition: const Duration(seconds: 1),
                  settings: const SubtitleStyleSettings(fontSize: 20.0, strokeWidth: 2.5),
                  is1080pDesktopOrTvOverride: true,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final textWidgets = tester.widgetList<Text>(find.text(sampleCue.text)).toList();
      expect(textWidgets.length, equals(2)); // Stroke + Fill text

      // Fill text font size should be 20.0 * 1.5 = 30.0 pt
      final fillText = textWidgets.last;
      expect(fillText.style?.fontSize, equals(30.0));

      // Stroke text should have bolder stroke (2.5 * 1.3 * 2 = 6.5)
      final strokeText = textWidgets.first;
      expect(strokeText.style?.foreground?.strokeWidth, closeTo(6.5, 0.01));

      // Elevated bottom offset (32.0 + 12.0 = 44.0)
      final positioned = tester.widget<Positioned>(find.byType(Positioned));
      expect(positioned.bottom, equals(44.0));
    });

    testWidgets('Maintains comfortable scaling on long dialog text cues for 1080p+ sofa viewing', (tester) async {
      final longCue = SubtitleCue(
        start: Duration.zero,
        end: const Duration(seconds: 10),
        text: 'Ini adalah kalimat dialog yang cukup panjang lebih dari enam puluh karakter agar memicu adaptasi panjang.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                CustomSubtitleOverlay(
                  cues: [longCue],
                  currentPosition: const Duration(seconds: 1),
                  settings: const SubtitleStyleSettings(fontSize: 20.0),
                  is1080pDesktopOrTvOverride: true,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final textWidgets = tester.widgetList<Text>(find.text(longCue.text)).toList();
      final fillText = textWidgets.last;

      // 30.0 * 0.88 = 26.4 pt, comfortably well above mobile's 17.0 - 24.0 clamp
      expect(fillText.style?.fontSize, greaterThan(25.0));
      expect(fillText.style?.fontSize, lessThanOrEqualTo(30.0));
    });
  });
}
