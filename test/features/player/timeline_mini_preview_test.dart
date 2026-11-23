import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cineva/features/player/presentation/widgets/timeline_mini_preview_bubble.dart';

void main() {
  group('TimelineMiniPreviewBubble Unit Tests', () {
    test('formatTimestamp correctly formats duration with and without hours', () {
      // With hours
      expect(
        TimelineMiniPreviewBubble.formatTimestamp(
          const Duration(hours: 1, minutes: 24, seconds: 15),
        ),
        '01:24:15',
      );
      expect(
        TimelineMiniPreviewBubble.formatTimestamp(
          const Duration(hours: 2, minutes: 5, seconds: 9),
        ),
        '02:05:09',
      );

      // Without hours (< 1 hour)
      expect(
        TimelineMiniPreviewBubble.formatTimestamp(
          const Duration(minutes: 15, seconds: 30),
        ),
        '15:30',
      );
      expect(
        TimelineMiniPreviewBubble.formatTimestamp(
          const Duration(seconds: 45),
        ),
        '00:45',
      );

      // Forced hours (< 1 hour but forceHours is true)
      expect(
        TimelineMiniPreviewBubble.formatTimestamp(
          const Duration(minutes: 15, seconds: 30),
          forceHours: true,
        ),
        '00:15:30',
      );
    });

    test('formatDelta correctly formats forward and backward seek differences', () {
      const current = Duration(minutes: 10);

      // Forward seek (+05:30)
      const targetForward = Duration(minutes: 15, seconds: 30);
      expect(
        TimelineMiniPreviewBubble.formatDelta(targetForward, current),
        '+05:30',
      );

      // Forward seek across hour (+01:05:00)
      const targetForwardHour = Duration(hours: 1, minutes: 15);
      expect(
        TimelineMiniPreviewBubble.formatDelta(targetForwardHour, current),
        '+01:05:00',
      );

      // Backward seek (-02:15)
      const targetBackward = Duration(minutes: 7, seconds: 45);
      expect(
        TimelineMiniPreviewBubble.formatDelta(targetBackward, current),
        '-02:15',
      );

      // Negligible difference (< 1 second)
      const targetSame = Duration(minutes: 10, milliseconds: 300);
      expect(
        TimelineMiniPreviewBubble.formatDelta(targetSame, current),
        '00:00',
      );
    });
  });

  group('TimelineMiniPreviewBubble Widget Presentation Tests', () {
    testWidgets('Renders 16:9 preview card with target time, title, and seek delta', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              clipBehavior: Clip.none,
              children: [
                TimelineMiniPreviewBubble(
                  targetTime: Duration(hours: 1, minutes: 15, seconds: 45),
                  currentTime: Duration(hours: 1, minutes: 10, seconds: 15),
                  totalDuration: Duration(hours: 2, minutes: 30),
                  title: 'Avengers: Endgame',
                  pointerPositionX: 250,
                  trackWidth: 600,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Formatted digital timecode (HH:MM:SS)
      expect(find.text('01:15:45'), findsOneWidget);

      // Seek delta (+05:30)
      expect(find.text('+05:30'), findsOneWidget);
      expect(find.byIcon(Icons.fast_forward_rounded), findsOneWidget);

      // Title header
      expect(find.text('Avengers: Endgame'), findsOneWidget);

      // Beak pointer CustomPaint
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('Renders backward seek delta in orange/coral with rewind icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              clipBehavior: Clip.none,
              children: [
                TimelineMiniPreviewBubble(
                  targetTime: Duration(minutes: 5, seconds: 30),
                  currentTime: Duration(minutes: 8, seconds: 0),
                  totalDuration: Duration(minutes: 45),
                  title: 'Breaking Bad S01:E01',
                  pointerPositionX: 100,
                  trackWidth: 500,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('05:30'), findsOneWidget);
      expect(find.text('-02:30'), findsOneWidget);
      expect(find.byIcon(Icons.fast_rewind_rounded), findsOneWidget);
      expect(find.text('Breaking Bad S01:E01'), findsOneWidget);
    });

    testWidgets('Clamps horizontally at left boundary (pointerPositionX = 0)', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              clipBehavior: Clip.none,
              children: [
                TimelineMiniPreviewBubble(
                  targetTime: Duration(seconds: 0),
                  currentTime: Duration(minutes: 5),
                  totalDuration: Duration(minutes: 20),
                  pointerPositionX: 0,
                  trackWidth: 400,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final positionedFinder = find.byWidgetPredicate(
        (w) => w is Positioned && w.bottom == 24.0,
      );
      expect(positionedFinder, findsOneWidget);
      final positioned = tester.widget<Positioned>(positionedFinder);
      // Left should be clamped to 0.0, never negative!
      expect(positioned.left, 0.0);
    });

    testWidgets('Clamps horizontally at right boundary (pointerPositionX = trackWidth)', (
      tester,
    ) async {
      const trackWidth = 500.0;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              clipBehavior: Clip.none,
              children: [
                TimelineMiniPreviewBubble(
                  targetTime: Duration(minutes: 50),
                  currentTime: Duration(minutes: 10),
                  totalDuration: Duration(minutes: 50),
                  pointerPositionX: trackWidth,
                  trackWidth: trackWidth,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final positionedFinder = find.byWidgetPredicate(
        (w) => w is Positioned && w.bottom == 24.0,
      );
      expect(positionedFinder, findsOneWidget);
      final positioned = tester.widget<Positioned>(positionedFinder);
      // Left should be clamped to (trackWidth - bubbleWidth) = (500 - 160) = 340.0
      expect(
        positioned.left,
        trackWidth - TimelineMiniPreviewBubble.bubbleWidth,
      );
    });
  });
}
