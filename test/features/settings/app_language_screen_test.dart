import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineva/app/theme/app_colors.dart';
import 'package:cineva/core/constants/content_preference.dart';
import 'package:cineva/core/localization/app_language.dart';
import 'package:cineva/core/localization/app_language_provider.dart';
import 'package:cineva/features/home/presentation/providers/home_providers.dart';
import 'package:cineva/features/settings/presentation/screens/app_language_screen.dart';
import 'package:cineva/features/settings/presentation/screens/content_preference_screen.dart';

void main() {
  group('AppLanguageScreen & ContentPreferenceScreen Widget Tests', () {
    testWidgets(
      'Renders flat language list without cards, highlights active language in Cineva Orange, and shows checkmark',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appLanguageProvider.overrideWith(
                (ref) => AppLanguageNotifier()..setLanguage(AppLanguage.id),
              ),
            ],
            child: const MaterialApp(
              home: AppLanguageScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // No Card widgets should be used
        expect(find.byType(Card), findsNothing);

        // Verify all 3 languages are rendered
        expect(find.text('Bahasa Indonesia'), findsOneWidget);
        expect(find.text('English'), findsAtLeastNWidgets(1));
        expect(find.text('India (हिन्दी)'), findsOneWidget);

        // Active language has a single checkmark icon in Cineva Orange
        final checkIcons = tester.widgetList<Icon>(
          find.byIcon(Icons.check_rounded),
        );
        expect(checkIcons.length, 1);
        expect(checkIcons.first.color, AppColors.primary);

        // Active language title text uses AppColors.primary
        final idText = tester.widget<Text>(find.text('Bahasa Indonesia'));
        expect(idText.style?.color, AppColors.primary);

        // Tap Hindi to switch language
        await tester.tap(find.text('India (हिन्दी)'));
        await tester.pumpAndSettle();

        // After switching to Hindi, header updates to Hindi
        expect(find.text('ऐप की भाषा'), findsOneWidget);
      },
    );

    testWidgets(
      'ContentPreferenceScreen renders flat preference list without cards, highlights active preference in Cineva Orange, and updates on tap',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appLanguageProvider.overrideWith(
                (ref) => AppLanguageNotifier()..setLanguage(AppLanguage.id),
              ),
              contentPreferenceProvider.overrideWith(
                (ref) => ContentPreferenceNotifier(ContentPreference.all),
              ),
            ],
            child: const MaterialApp(
              home: ContentPreferenceScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // No Card widgets should be used (matches AppLanguageScreen flat list design)
        expect(find.byType(Card), findsNothing);

        // Verify preference titles are rendered
        expect(find.text('Semua (Global)'), findsOneWidget);
        expect(find.text('Indonesia'), findsOneWidget);
        expect(find.text('Anime'), findsOneWidget);

        // Initially 'Semua (Global)' is active and highlighted in Cineva Orange
        final allText = tester.widget<Text>(find.text('Semua (Global)'));
        expect(allText.style?.color, AppColors.primary);

        // Tap 'Indonesia' to change content preference
        await tester.tap(find.text('Indonesia'));
        await tester.pumpAndSettle();

        final idPrefText = tester.widget<Text>(find.text('Indonesia'));
        expect(idPrefText.style?.color, AppColors.primary);
      },
    );
  });
}
