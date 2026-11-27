import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineva/app/theme/app_colors.dart';
import 'package:cineva/core/localization/app_language.dart';
import 'package:cineva/core/localization/app_language_provider.dart';
import 'package:cineva/features/settings/data/release_notes_catalog.dart';
import 'package:cineva/features/settings/presentation/screens/release_notes_screen.dart';

void main() {
  group('ReleaseNotesCatalog & ReleaseNotesScreen Tests', () {
    test('All catalog entries provide concise core features in ID, EN, and HI', () {
      expect(ReleaseNotesCatalog.entries, isNotEmpty);
      for (final entry in ReleaseNotesCatalog.entries) {
        expect(entry.version, isNotEmpty);
        for (final lang in AppLanguage.values) {
          final date = entry.localizedDate(lang);
          final features = entry.localizedFeatures(lang);
          expect(date, isNotEmpty);
          expect(features, isNotEmpty);
          for (final feature in features) {
            // Core features only: concise titles without long sentences
            expect(feature.length, lessThan(85));
          }
        }
      }
    });

    testWidgets(
      'Renders vertical timeline with version dots and switches core feature texts across ID, EN, and HI',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            appLanguageProvider.overrideWith(
              (ref) => AppLanguageNotifier()..setLanguage(AppLanguage.id),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: ReleaseNotesScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Indonesian title & v1.2.2 core feature
        expect(find.text('Catatan Rilis'), findsOneWidget);
        expect(find.text('v1.2.2'), findsOneWidget);
        expect(
          find.text('Deteksi pertandingan sepak bola Live via Real-Time EPG'),
          findsOneWidget,
        );

        // Latest version header uses Cineva Orange
        final latestVersionText = tester.widget<Text>(find.text('v1.2.2'));
        expect(latestVersionText.style?.color, AppColors.primary);

        // Switch to English
        await container
            .read(appLanguageProvider.notifier)
            .setLanguage(AppLanguage.en);
        await tester.pumpAndSettle();

        expect(find.text('Release Notes'), findsOneWidget);
        expect(
          find.text('Real-Time EPG live football match & broadcaster detection'),
          findsOneWidget,
        );

        // Switch to Hindi
        await container
            .read(appLanguageProvider.notifier)
            .setLanguage(AppLanguage.hi);
        await tester.pumpAndSettle();

        expect(find.text('रिलीज़ नोट्स'), findsOneWidget);
        expect(
          find.text('रियल-टाइम EPG लाइव फुटबॉल मैच और प्रसारण चैनल पहचान'),
          findsOneWidget,
        );
      },
    );
  });
}
