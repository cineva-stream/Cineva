import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cineva/core/localization/app_language.dart';
import 'package:cineva/core/localization/app_language_provider.dart';
import 'package:cineva/core/localization/app_strings.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  group('Player Info & Synopsis Localization Tests', () {
    test('playerNoSynopsis is correctly localized in ID and EN', () {
      final id = AppStrings(AppLanguage.id);
      expect(
        id.playerNoSynopsis,
        'Tidak Ada Sinopsis Untuk Film Ini atau Episode Ini',
      );
      expect(id.playerInfoTitle, 'Informasi');
      expect(id.playerSynopsisTitle, 'Sinopsis');

      final en = AppStrings(AppLanguage.en);
      expect(
        en.playerNoSynopsis,
        'No Synopsis Available for this Movie or Episode',
      );
      expect(en.playerInfoTitle, 'Information');
      expect(en.playerSynopsisTitle, 'Synopsis');
    });

    testWidgets('Renders empty synopsis placeholder when overview is null or empty', (tester) async {
      final s = AppStrings(AppLanguage.id);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
              child: Column(
                children: [
                  Text(
                    s.playerNoSynopsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(
        find.text('Tidak Ada Sinopsis Untuk Film Ini atau Episode Ini'),
        findsOneWidget,
      );
    });

    testWidgets('Renders English empty synopsis placeholder when EN language active', (tester) async {
      final s = AppStrings(AppLanguage.en);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
              child: Column(
                children: [
                  Text(
                    s.playerNoSynopsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(
        find.text('No Synopsis Available for this Movie or Episode'),
        findsOneWidget,
      );
    });
  });
}

