import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineva/core/localization/app_language.dart';
import 'package:cineva/core/localization/app_strings.dart';
import 'package:cineva/features/watch_party/presentation/widgets/watch_party_beta_notice_card.dart';

void main() {
  group('WatchPartyBetaNoticeCard Tests', () {
    testWidgets('Renders Indonesian beta disclaimer referencing Kirim Masukan',
        (tester) async {
      const s = AppStrings(AppLanguage.id);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WatchPartyBetaNoticeCard(strings: s),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('BETA'), findsOneWidget);
      expect(find.text('Fitur Dalam Tahap Beta'), findsOneWidget);
      expect(
        find.textContaining('Kirim Masukan'),
        findsOneWidget,
      );
      expect(
        find.textContaining('mohon dimaklumi'),
        findsOneWidget,
      );
    });

    testWidgets('Renders English beta disclaimer referencing Share Your Thoughts',
        (tester) async {
      const s = AppStrings(AppLanguage.en);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WatchPartyBetaNoticeCard(strings: s),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('BETA'), findsOneWidget);
      expect(find.text('Beta Feature Notice'), findsOneWidget);
      expect(
        find.textContaining('Share Your Thoughts'),
        findsOneWidget,
      );
      expect(
        find.textContaining('please understand'),
        findsOneWidget,
      );
    });
  });
}

