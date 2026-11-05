import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineva/core/platform/cineva_scroll_behavior.dart';
import 'package:cineva/core/platform/smooth_mouse_scroll.dart';

void main() {
  group('SmoothMouseScrollHandler Tests', () {
    testWidgets('Interpolates vertical mouse wheel scroll over multiple frames via Ticker',
        (tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              controller: controller,
              itemCount: 100,
              itemExtent: 50,
              itemBuilder: (context, index) => Text('Item $index'),
            ),
          ),
        ),
      );

      expect(controller.offset, 0.0);

      final handler = SmoothMouseScrollHandler(
        dispatchEvent: (event) {
          tester.binding.handlePointerEvent(event);
        },
      );

      // Simulate 1 mouse wheel notch of 120px
      handler.handlePointerEvent(
        const PointerScrollEvent(
          position: Offset(100, 100),
          scrollDelta: Offset(0, 120),
          kind: PointerDeviceKind.mouse,
        ),
      );

      // Immediately after event: offset is 0.0 (no instantaneous jump)
      expect(controller.offset, 0.0);
      expect(handler.isAnimating, isTrue);

      // Frame 1 (~16ms)
      await tester.pump(const Duration(milliseconds: 16));
      final frame1 = controller.offset;
      expect(frame1 > 10.0 && frame1 < 35.0, isTrue,
          reason: 'Frame 1 should be a smooth partial offset, was $frame1');

      // Frame 2 (~16ms)
      await tester.pump(const Duration(milliseconds: 16));
      final frame2 = controller.offset;
      expect(frame2 > frame1, isTrue);

      // Settle the remaining animation
      await tester.pumpAndSettle();

      // Reached target offset smoothly
      expect((controller.offset - 120.0).abs() < 0.5, isTrue);
      expect(handler.isAnimating, isFalse);

      handler.dispose();
    });

    testWidgets('Reverses direction smoothly and immediately', (tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              controller: controller,
              itemCount: 100,
              itemExtent: 50,
              itemBuilder: (context, index) => Text('Item $index'),
            ),
          ),
        ),
      );

      final handler = SmoothMouseScrollHandler(
        dispatchEvent: (event) {
          tester.binding.handlePointerEvent(event);
        },
      );

      // Scroll down 100px
      handler.handlePointerEvent(
        const PointerScrollEvent(
          position: Offset(100, 100),
          scrollDelta: Offset(0, 100),
          kind: PointerDeviceKind.mouse,
        ),
      );

      // Advance 2 frames down (32ms)
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      final intermediateOffset = controller.offset;
      expect(intermediateOffset > 20.0, isTrue);

      // Sudden reversal: user spins wheel UP (-80px)
      handler.handlePointerEvent(
        const PointerScrollEvent(
          position: Offset(100, 100),
          scrollDelta: Offset(0, -80),
          kind: PointerDeviceKind.mouse,
        ),
      );

      // Advance 2 frames up (32ms)
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      final afterReversalOffset = controller.offset;

      // Offset moved back upwards
      expect(afterReversalOffset < intermediateOffset, isTrue);

      // Settle any residual animation before finishing
      await tester.pumpAndSettle();
      handler.dispose();
    });

    testWidgets('Clamps backlog to prevent runaway scrolling', (tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              controller: controller,
              itemCount: 200,
              itemExtent: 50,
              itemBuilder: (context, index) => Text('Item $index'),
            ),
          ),
        ),
      );

      final handler = SmoothMouseScrollHandler(
        dispatchEvent: (event) {
          tester.binding.handlePointerEvent(event);
        },
      );

      // Aggressively send 15 wheel notches of 100px (1500px total)
      for (int i = 0; i < 15; i++) {
        handler.handlePointerEvent(
          const PointerScrollEvent(
            position: Offset(100, 100),
            scrollDelta: Offset(0, 100),
            kind: PointerDeviceKind.mouse,
          ),
        );
      }

      // Settle the animation
      await tester.pumpAndSettle();

      // Backlog should have clamped max delta to ~360px instead of running away to 1500px
      expect(controller.offset <= 400.0, isTrue,
          reason: 'Excessive wheel spinning should be capped at reasonable backlog');

      handler.dispose();
    });

    testWidgets('Snaps animation if mouse moves far away', (tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              controller: controller,
              itemCount: 100,
              itemExtent: 50,
              itemBuilder: (context, index) => Text('Item $index'),
            ),
          ),
        ),
      );

      final handler = SmoothMouseScrollHandler(
        dispatchEvent: (event) {
          tester.binding.handlePointerEvent(event);
        },
      );

      handler.handlePointerEvent(
        const PointerScrollEvent(
          position: Offset(100, 100),
          scrollDelta: Offset(0, 100),
          kind: PointerDeviceKind.mouse,
        ),
      );

      expect(handler.isAnimating, isTrue);

      // Mouse jumps 150px away
      handler.handlePointerEvent(
        const PointerMoveEvent(
          position: Offset(250, 100),
        ),
      );

      // Handler detects big cursor movement and snaps ongoing scroll
      expect(handler.isAnimating, isFalse);

      await tester.pumpAndSettle();
      handler.dispose();
    });
  });

  group('CinevaScrollBehavior Tests', () {
    test('Configures drag devices to include mouse and trackpad', () {
      const behavior = CinevaScrollBehavior();
      final devices = behavior.dragDevices;

      expect(devices.contains(PointerDeviceKind.mouse), isTrue);
      expect(devices.contains(PointerDeviceKind.trackpad), isTrue);
      expect(devices.contains(PointerDeviceKind.touch), isTrue);
      expect(devices.contains(PointerDeviceKind.stylus), isTrue);
    });
  });
}
