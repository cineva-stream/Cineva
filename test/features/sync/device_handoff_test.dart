import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cineva/features/sync/domain/models/device_playback_session.dart';
import 'package:cineva/features/sync/data/services/device_handoff_service.dart';
import 'package:cineva/features/sync/presentation/widgets/handoff_top_capsule.dart';
import 'package:cineva/core/localization/app_language_provider.dart';

class _FakeHandoffService extends DeviceHandoffService {
  _FakeHandoffService(DevicePlaybackSession? initial) : super(null) {
    state = initial;
  }
}

void main() {
  group('DevicePlaybackSession Model Tests', () {
    test('Serializes to and from JSON correctly', () {
      final now = DateTime.now();
      final session = DevicePlaybackSession(
        deviceId: 'dev_tv_123',
        deviceName: 'Android TV Ruang Tamu',
        formFactor: 'tv',
        title: 'Interstellar',
        mediaType: 'movie',
        tmdbId: 157336,
        imdbId: 'tt0816692',
        positionSeconds: 2712, // 45:12
        durationSeconds: 10140,
        updatedAt: now,
        isCompleted: false,
      );

      final json = session.toJson();
      expect(json['deviceId'], 'dev_tv_123');
      expect(json['title'], 'Interstellar');
      expect(json['positionSeconds'], 2712);

      final reconstructed = DevicePlaybackSession.fromJson(json);
      expect(reconstructed.deviceId, session.deviceId);
      expect(reconstructed.deviceName, session.deviceName);
      expect(reconstructed.title, session.title);
      expect(reconstructed.positionSeconds, 2712);
      expect(reconstructed.formattedPosition, '45:12');
    });

    test('formattedPosition formats hours and minutes properly', () {
      final sessionUnderHour = DevicePlaybackSession(
        deviceId: 'd1',
        deviceName: 'Phone',
        formFactor: 'mobile',
        title: 'Movie',
        mediaType: 'movie',
        tmdbId: 1,
        positionSeconds: 2712, // 45m 12s
        durationSeconds: 5000,
        updatedAt: DateTime.now(),
      );
      expect(sessionUnderHour.formattedPosition, '45:12');

      final sessionOverHour = DevicePlaybackSession(
        deviceId: 'd2',
        deviceName: 'PC',
        formFactor: 'desktop',
        title: 'Long Movie',
        mediaType: 'movie',
        tmdbId: 2,
        positionSeconds: 3930, // 1h 05m 30s
        durationSeconds: 7200,
        updatedAt: DateTime.now(),
      );
      expect(sessionOverHour.formattedPosition, '1:05:30');
    });

    test('isValidForHandOff enforces progress, credit, and time boundaries', () {
      final validSession = DevicePlaybackSession(
        deviceId: 'd1',
        deviceName: 'TV',
        formFactor: 'tv',
        title: 'Valid',
        mediaType: 'movie',
        tmdbId: 10,
        positionSeconds: 600, // 10 min
        durationSeconds: 3600,
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        isCompleted: false,
      );
      expect(validSession.isValidForHandOff, isTrue);

      // Completed session should NOT trigger hand-off
      final completed = validSession.copyWith(isCompleted: true);
      expect(completed.isValidForHandOff, isFalse);

      // Less than 30 seconds watched should NOT trigger hand-off
      final barelyStarted = validSession.copyWith(positionSeconds: 20);
      expect(barelyStarted.isValidForHandOff, isFalse);

      // End credits (>95%) should NOT trigger hand-off
      final endCredits = validSession.copyWith(positionSeconds: 3500);
      expect(endCredits.isValidForHandOff, isFalse);

      // Older than 24 hours should NOT trigger hand-off
      final stale = validSession.copyWith(
        updatedAt: DateTime.now().subtract(const Duration(hours: 26)),
      );
      expect(stale.isValidForHandOff, isFalse);
    });
  });

  group('HandOffTopCapsule Widget Tests', () {
    testWidgets('Renders nothing when no active session exists',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceHandoffProvider.overrideWith((ref) => _FakeHandoffService(null)),
          ],
          child: const MaterialApp(
            home: Scaffold(body: HandOffTopCapsule()),
          ),
        ),
      );

      expect(find.byType(HandOffTopCapsule), findsOneWidget);
      expect(find.textContaining('Lanjutkan'), findsNothing);
    });

    testWidgets('Renders floating capsule when valid other-device session exists',
        (tester) async {
      final session = DevicePlaybackSession(
        deviceId: 'dev_tv_客厅',
        deviceName: 'Android TV',
        formFactor: 'tv',
        title: 'Interstellar',
        mediaType: 'movie',
        tmdbId: 157336,
        positionSeconds: 2712, // 45:12
        durationSeconds: 10140,
        updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceHandoffProvider.overrideWith((ref) => _FakeHandoffService(session)),
          ],
          child: const MaterialApp(
            home: Scaffold(body: HandOffTopCapsule()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Android TV'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('Interstellar'),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('45:12'),
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.tv_rounded), findsWidgets);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });
  });
}
