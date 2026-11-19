import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:cineva/core/constants/app_constants.dart';
import 'package:cineva/core/localization/app_language.dart';
import 'package:cineva/core/localization/app_language_provider.dart';
import 'package:cineva/features/feedback/data/feedback_service.dart';
import 'package:cineva/features/feedback/presentation/screens/feedback_screen.dart';

class _TestLanguageNotifier extends AppLanguageNotifier {
  _TestLanguageNotifier(super.initialLanguage);

  @override
  Future<void> setLanguage(AppLanguage language) async {
    state = language;
  }
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('cineva_feedback_test_');
    Hive.init(tempDir.path);
    await Hive.openBox(AppConstants.settingsBox);
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Widget buildSubject({AppLanguage language = AppLanguage.id}) {
    return ProviderScope(
      overrides: [
        appLanguageProvider
            .overrideWith((ref) => _TestLanguageNotifier(language)),
      ],
      child: const MaterialApp(
        home: FeedbackScreen(),
      ),
    );
  }

  group('FeedbackCategory Tests', () {
    test('Returns correct Indonesian and English category labels', () {
      expect(
        FeedbackCategory.bugs.localizedLabel(true),
        equals('Bug & Masalah Teknis'),
      );
      expect(
        FeedbackCategory.bugs.localizedLabel(false),
        equals('Bugs & Technical Issues'),
      );

      expect(
        FeedbackCategory.features.localizedLabel(true),
        equals('Saran Fitur Baru'),
      );
      expect(
        FeedbackCategory.features.localizedLabel(false),
        equals('Feature Suggestions'),
      );

      expect(
        FeedbackCategory.report.localizedLabel(true),
        equals('Lapor Konten / Tayangan'),
      );
      expect(
        FeedbackCategory.report.localizedLabel(false),
        equals('Report Media / Subtitles'),
      );

      expect(
        FeedbackCategory.general.localizedLabel(true),
        equals('Lainnya / Umum'),
      );
      expect(
        FeedbackCategory.general.localizedLabel(false),
        equals('General & Other'),
      );
    });
  });

  group('FeedbackScreen Presentation Tests', () {
    testWidgets('Renders Indonesian form elements and category chips',
        (tester) async {
      await tester.pumpWidget(buildSubject(language: AppLanguage.id));
      await tester.pumpAndSettle();

      // App bar & banner
      expect(find.text('Kirim Masukan'), findsWidgets);
      expect(find.text('Kategori Masukan'), findsOneWidget);

      // Categories
      expect(find.text('Bug & Masalah Teknis'), findsOneWidget);
      expect(find.text('Saran Fitur Baru'), findsOneWidget);
      expect(find.text('Lapor Konten / Tayangan'), findsOneWidget);
      expect(find.text('Lainnya / Umum'), findsOneWidget);

      // Input labels
      expect(find.text('Nama / Panggilan'), findsOneWidget);
      expect(find.text('Judul Masukan'), findsOneWidget);
      expect(find.text('Deskripsi Lengkap'), findsOneWidget);

      // Submit button
      expect(find.text('Kirim Masukan'), findsWidgets);
    });

    testWidgets('Renders English form elements when language is EN',
        (tester) async {
      await tester.pumpWidget(buildSubject(language: AppLanguage.en));
      await tester.pumpAndSettle();

      expect(find.text('Share Your Thoughts'), findsWidgets);
      expect(find.text('Feedback Category'), findsOneWidget);
      expect(find.text('Bugs & Technical Issues'), findsOneWidget);
      expect(find.text('Feature Suggestions'), findsOneWidget);
      expect(find.text('Report Media / Subtitles'), findsOneWidget);
      expect(find.text('General & Other'), findsOneWidget);
      expect(find.text('Subject / Title'), findsOneWidget);
      expect(find.text('Detailed Description'), findsOneWidget);
      expect(find.text('Send Feedback'), findsOneWidget);
    });

    testWidgets('Validates required fields before submitting', (tester) async {
      await tester.pumpWidget(buildSubject(language: AppLanguage.id));
      await tester.pumpAndSettle();

      // Tap submit with empty title
      final submitBtn = find.widgetWithText(ElevatedButton, 'Kirim Masukan');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Snack bar should show validation error for title
      expect(
        find.text('Mohon masukkan judul masukan terlebih dahulu'),
        findsOneWidget,
      );
    });

    testWidgets('Toggles category selection when chip is tapped',
        (tester) async {
      await tester.pumpWidget(buildSubject(language: AppLanguage.id));
      await tester.pumpAndSettle();

      final featureChip = find.text('Saran Fitur Baru');
      expect(featureChip, findsOneWidget);

      await tester.tap(featureChip);
      await tester.pumpAndSettle();

      // Verify widget doesn't crash on selection
      expect(featureChip, findsOneWidget);
    });
  });
}

