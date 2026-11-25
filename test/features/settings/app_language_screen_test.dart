import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineva/app/theme/app_colors.dart';
import 'package:cineva/core/localization/app_language.dart';
import 'package:cineva/core/localization/app_language_provider.dart';
import 'package:cineva/features/settings/presentation/screens/app_language_screen.dart';

void main() {
  group('AppLanguageScreen Widget Tests', () {
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

        // Tap English to switch language
        await tester.tap(find.text('India (हिन्दी)'));
        await tester.pumpAndSettle();

        // After switching to Hindi, header updates to Hindi
        expect(find.text('ऐप की भाषा'), findsOneWidget);
      },
    );
  });
}
