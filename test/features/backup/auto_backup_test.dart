import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:cineva/app/theme/app_colors.dart';
import 'package:cineva/core/constants/app_constants.dart';
import 'package:cineva/core/localization/app_language.dart';
import 'package:cineva/core/localization/app_language_provider.dart';
import 'package:cineva/features/backup/data/auto_backup_service.dart';
import 'package:cineva/features/backup/domain/models/cineva_backup_payload.dart';
import 'package:cineva/features/backup/presentation/screens/auto_backup_screen.dart';
import 'package:cineva/features/profile/domain/models/user_profile.dart';

class _TestLanguageNotifier extends AppLanguageNotifier {
  _TestLanguageNotifier([super.initial = AppLanguage.id]);

  @override
  Future<void> setLanguage(AppLanguage lang) async {
    state = lang;
  }
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('cineva_autobackup_test_');
    Hive.init(tempDir.path);
    await Hive.openBox(AppConstants.settingsBox);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('AutoBackupService Schedule & Snapshot Rotation Tests', () {
    test('isBackupDue evaluates off, weekly (7 days), and monthly (30 days)', () {
      final now = DateTime(2026, 11, 26, 10, 0);

      // Off is never due
      expect(
        AutoBackupService.isBackupDue(
          frequency: AutoBackupFrequency.off,
          lastRunAt: null,
          now: now,
        ),
        isFalse,
      );

      // Weekly: due if never run or >= 7 days ago
      expect(
        AutoBackupService.isBackupDue(
          frequency: AutoBackupFrequency.weekly,
          lastRunAt: null,
          now: now,
        ),
        isTrue,
      );
      expect(
        AutoBackupService.isBackupDue(
          frequency: AutoBackupFrequency.weekly,
          lastRunAt: now.subtract(const Duration(days: 5)),
          now: now,
        ),
        isFalse,
      );
      expect(
        AutoBackupService.isBackupDue(
          frequency: AutoBackupFrequency.weekly,
          lastRunAt: now.subtract(const Duration(days: 7)),
          now: now,
        ),
        isTrue,
      );

      // Monthly: due if >= 30 days ago
      expect(
        AutoBackupService.isBackupDue(
          frequency: AutoBackupFrequency.monthly,
          lastRunAt: now.subtract(const Duration(days: 20)),
          now: now,
        ),
        isFalse,
      );
      expect(
        AutoBackupService.isBackupDue(
          frequency: AutoBackupFrequency.monthly,
          lastRunAt: now.subtract(const Duration(days: 30)),
          now: now,
        ),
        isTrue,
      );
    });

    test('saves .cineva files into Documents/Cineva and rotates beyond 5 snapshots', () async {
      final samplePayload = CinevaBackupPayload(
        appVersion: '1.2.1',
        exportedAt: DateTime(2026, 11, 26),
        profile: UserProfile(
          name: 'Guest Viewer',
          username: 'guest',
          avatarId: 'avatar_1',
          isConfigured: true,
          createdAt: DateTime(2026, 1, 1),
        ),
        watchlist: const [],
        watchHistory: const [],
        settings: const {'theme': 'dark'},
        searchHistory: const ['Inception'],
      );

      for (var i = 1; i <= 7; i++) {
        final res = await AutoBackupService.savePayloadToAutoBackup(
          samplePayload,
          overrideBaseDir: tempDir,
          timestampOverride: DateTime(2026, 11, i, 12, 0, i),
        );
        expect(res.success, isTrue);
      }

      final listed = await AutoBackupService.listSavedAutoBackups(
        overrideBaseDir: tempDir,
      );
      expect(listed.length, AutoBackupService.maxRetainedBackups);
      expect(AutoBackupService.getLastBackupTime(), isNotNull);
    });
  });

  group('AutoBackupScreen 3-Language Widget Tests', () {
    testWidgets(
      'Renders schedule options in ID, EN, and HI with Cineva Orange active text and checkmark',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            appLanguageProvider.overrideWith(
              (ref) => _TestLanguageNotifier(AppLanguage.id),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: AutoBackupScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Cadangan Otomatis'), findsOneWidget);
        expect(find.text('Nonaktif'), findsOneWidget);
        expect(find.text('Mingguan'), findsOneWidget);
        expect(find.text('Bulanan'), findsOneWidget);
        expect(find.text('Documents/Cineva'), findsOneWidget);

        // Active option ("Nonaktif" by default) uses Cineva Orange text + checkmark
        final offText = tester.widget<Text>(find.text('Nonaktif'));
        expect(offText.style?.color, AppColors.primary);
        expect(find.byIcon(Icons.check_rounded), findsOneWidget);

        // Switch to English
        await container
            .read(appLanguageProvider.notifier)
            .setLanguage(AppLanguage.en);
        await tester.pumpAndSettle();

        expect(find.text('Auto Backup'), findsOneWidget);
        expect(find.text('Weekly'), findsOneWidget);
        expect(find.text('Monthly'), findsOneWidget);

        // Switch to Hindi
        await container
            .read(appLanguageProvider.notifier)
            .setLanguage(AppLanguage.hi);
        await tester.pumpAndSettle();

        expect(find.text('ऑटो बैकअप'), findsOneWidget);
        expect(find.text('साप्ताहिक'), findsOneWidget);
        expect(find.text('मासिक'), findsOneWidget);
      },
    );
  });
}
