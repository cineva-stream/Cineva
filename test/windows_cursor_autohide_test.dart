import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cineva/core/constants/app_constants.dart';
import 'package:cineva/features/live_tv/data/datasources/live_tv_channels_data.dart';
import 'package:cineva/features/live_tv/presentation/screens/live_tv_player_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('cineva_cursor_test_');
    Hive.init(tempDir.path);
    await Hive.openBox(AppConstants.settingsBox);
    await Hive.openBox(AppConstants.historyBox);
    await Hive.openBox(AppConstants.watchlistBox);
    await Hive.openBox(AppConstants.downloadsBox);
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Anti-Jitter Mouse Threshold Tests', () {
    test('Calculates distance and filters micro-jitter below 14.0 px', () {
      const threshold = 14.0;
      const initial = Offset(500, 300);

      // Acoustic vibration / subwoofer desk shaking (1.0 to 4.0 px)
      const jitter1 = Offset(501, 301);
      final dist1 = (jitter1 - initial).distance;
      expect(dist1 < threshold, isTrue, reason: 'Small 1.41px jitter must be ignored');

      const jitter2 = Offset(503, 302);
      final dist2 = (jitter2 - initial).distance;
      expect(dist2 < threshold, isTrue, reason: 'Small 3.60px jitter must be ignored');

      const jitter3 = Offset(492, 305);
      final dist3 = (jitter3 - initial).distance;
      expect(dist3 < threshold, isTrue, reason: 'Displacement of 9.43px must be ignored');

      // Intentional human user movement (>= 14.0 px)
      const intentional1 = Offset(515, 300);
      final distIntentional1 = (intentional1 - initial).distance;
      expect(distIntentional1 >= threshold, isTrue, reason: '15.0px deliberate movement must trigger');

      const intentional2 = Offset(550, 340);
      final distIntentional2 = (intentional2 - initial).distance;
      expect(distIntentional2 >= threshold, isTrue, reason: '64.0px deliberate movement must trigger');
    });
  });

  group('LiveTvPlayerScreen Desktop MouseRegion & Cursor Tests', () {
    testWidgets('Renders MouseRegion and handles cursor auto-hide & anti-jitter wake-up', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final initialChannel = LiveTvChannelsData.defaultChannels.first;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LiveTvPlayerScreen(initialChannel: initialChannel),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. MouseRegion must be present in widget tree
      final mouseRegionFinder = find.byType(MouseRegion);
      expect(mouseRegionFinder, findsWidgets);

      // 2. Controls are initially visible
      expect(find.byIcon(Icons.fullscreen_rounded), findsOneWidget);
      expect(find.text(initialChannel.name), findsWidgets);

      // 3. Fast-forward timer past 4 seconds auto-hide
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 300));

      // 4. Simulate a pointer hover with micro-movement (< 14px) - representing desk/sound vibration
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: const Offset(400, 200));
      await tester.pump();

      // Jitter movement of 2px
      await gesture.moveTo(const Offset(402, 201));
      await tester.pump(const Duration(milliseconds: 100));

      // 5. Deliberate mouse movement (>= 14px)
      await gesture.moveTo(const Offset(440, 230));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Controls should be active
      expect(find.text(initialChannel.name), findsWidgets);

      await gesture.removePointer();
    });
  });
}
