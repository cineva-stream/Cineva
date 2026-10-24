import 'package:cineva/core/constants/app_constants.dart';
import 'package:cineva/core/localization/app_language.dart';
import 'package:cineva/core/localization/app_strings.dart';
import 'package:cineva/features/settings/data/legal_content.dart';
import 'package:cineva/features/settings/presentation/screens/about_info_screen.dart';
import 'package:cineva/features/settings/presentation/screens/legal_document_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LegalContentRepository Unit Tests', () {
    test('Privacy Policy contains comprehensive global privacy clauses in ID and EN', () {
      final docId = LegalContentRepository.getDocument(LegalDocType.privacyPolicy, true);
      expect(docId.title, 'Kebijakan Privasi');
      expect(docId.calloutSummary, contains('Zero Data Collection'));
      expect(docId.sections.length, 6);
      expect(docId.sections.any((s) => s.title.contains('P2P') || s.body.contains('P2P')), isTrue);
      expect(docId.sections.any((s) => s.body.contains('Hive') || s.bulletPoints.any((b) => b.contains('Hive'))), isTrue);
      expect(docId.sections.any((s) => s.body.contains('TMDB') || s.bulletPoints.any((b) => b.contains('TMDB'))), isTrue);

      final docEn = LegalContentRepository.getDocument(LegalDocType.privacyPolicy, false);
      expect(docEn.title, 'Privacy Policy');
      expect(docEn.calloutSummary, contains('Zero-Data-Collection'));
      expect(docEn.sections.length, 6);
      expect(docEn.sections.any((s) => s.title.contains('P2P') || s.body.contains('P2P')), isTrue);
    });

    test('Terms & Conditions contains all required clauses (As-Is, Third-Party, Non-Commercial, Availability) in ID and EN', () {
      final docId = LegalContentRepository.getDocument(LegalDocType.termsAndConditions, true);
      expect(docId.title, 'Syarat dan Ketentuan');
      expect(docId.calloutSummary, contains('sebagaimana adanya'));
      expect(docId.calloutSummary, contains('BUKAN layanan komersial'));
      expect(docId.sections.length, 6);

      // 1. As-Is clause
      expect(docId.sections.any((s) => s.body.contains('SEBAGAIMANA ADANYA')), isTrue);
      // 2. Third-party content ownership
      expect(docId.sections.any((s) => s.bulletPoints.any((b) => b.contains('BUKAN merupakan milik aplikasi Cineva'))), isTrue);
      // 3. Not commercial & not a substitute for official streaming
      expect(docId.sections.any((s) => s.bulletPoints.any((b) => b.contains('BUKAN merupakan pengganti layanan streaming resmi'))), isTrue);
      // 4. Content availability not guaranteed
      expect(docId.sections.any((s) => s.body.contains('TIDAK SELURUH film atau serial TV dijamin tersedia')), isTrue);
      // 5. Worldwide user responsibility
      expect(docId.sections.any((s) => s.title.contains('Tanggung Jawab Hukum')), isTrue);

      final docEn = LegalContentRepository.getDocument(LegalDocType.termsAndConditions, false);
      expect(docEn.title, 'Terms and Conditions');
      expect(docEn.calloutSummary, contains('as-is'));
      expect(docEn.calloutSummary, contains('NOT a substitute'));
      expect(docEn.sections.length, 6);
      expect(docEn.sections.any((s) => s.body.contains('AS IS')), isTrue);
      expect(docEn.sections.any((s) => s.bulletPoints.any((b) => b.contains('NOT the property of Cineva'))), isTrue);
      expect(docEn.sections.any((s) => s.bulletPoints.any((b) => b.contains('NOT a substitute or alternative for licensed commercial streaming'))), isTrue);
      expect(docEn.sections.any((s) => s.body.contains('NOT ALL movies or TV series are guaranteed')), isTrue);
    });

    test('Disclaimer contains Copyright, DMCA, Non-Hosting, and Liability limits in ID and EN', () {
      final docId = LegalContentRepository.getDocument(LegalDocType.disclaimer, true);
      expect(docId.title, 'Disclaimer');
      expect(docId.sections.length, 5);
      expect(docId.sections.any((s) => s.body.contains('TIDAK meng-host')), isTrue);
      expect(docId.sections.any((s) => s.title.contains('DMCA')), isTrue);
      expect(docId.sections.any((s) => s.title.contains('Ketiadaan Jaminan Ketersediaan')), isTrue);
      expect(docId.sections.any((s) => s.title.contains('Pembatasan Tanggung Jawab')), isTrue);

      final docEn = LegalContentRepository.getDocument(LegalDocType.disclaimer, false);
      expect(docEn.title, 'Disclaimer');
      expect(docEn.sections.length, 5);
      expect(docEn.sections.any((s) => s.body.contains('DOES NOT host')), isTrue);
      expect(docEn.sections.any((s) => s.title.contains('DMCA')), isTrue);
      expect(docEn.sections.any((s) => s.title.contains('Zero Guarantee on Catalog Availability')), isTrue);
      expect(docEn.sections.any((s) => s.title.contains('Limitation of Liability')), isTrue);
    });
  });

  group('AppStrings Settings & About Localization Tests', () {
    test('Settings menu tile strings are distinct and non-empty in Indonesian and English', () {
      const sId = AppStrings(AppLanguage.id);
      expect(sId.settingsPrivacyPolicyTitle, 'Kebijakan Privasi');
      expect(sId.settingsPrivacyPolicySubtitle, isNotEmpty);
      expect(sId.settingsTermsTitle, 'Syarat dan Ketentuan');
      expect(sId.settingsTermsSubtitle, isNotEmpty);
      expect(sId.settingsDisclaimerMenuTitle, 'Disclaimer');
      expect(sId.settingsDisclaimerTitle, 'Disclaimer & Hak Cipta');
      expect(sId.settingsDisclaimerSubtitle, isNotEmpty);
      expect(sId.settingsInfoTitle, 'Info');
      expect(sId.settingsInfoSubtitle, isNotEmpty);

      const sEn = AppStrings(AppLanguage.en);
      expect(sEn.settingsPrivacyPolicyTitle, 'Privacy Policy');
      expect(sEn.settingsPrivacyPolicySubtitle, isNotEmpty);
      expect(sEn.settingsTermsTitle, 'Terms and Conditions');
      expect(sEn.settingsTermsSubtitle, isNotEmpty);
      expect(sEn.settingsDisclaimerMenuTitle, 'Disclaimer');
      expect(sEn.settingsDisclaimerTitle, 'Disclaimer & Copyright');
      expect(sEn.settingsDisclaimerSubtitle, isNotEmpty);
      expect(sEn.settingsInfoTitle, 'Info');
      expect(sEn.settingsInfoSubtitle, isNotEmpty);
    });

    test('About screen detailed strings are non-empty in ID and EN', () {
      const sId = AppStrings(AppLanguage.id);
      expect(sId.aboutDescription, contains('Cineva'));
      expect(sId.aboutTagline, isNotEmpty);
      expect(sId.aboutFeatureP2PTitle, isNotEmpty);
      expect(sId.aboutFeatureHwTitle, isNotEmpty);
      expect(sId.aboutFeatureSubTitle, isNotEmpty);
      expect(sId.aboutFeatureDownloadTitle, isNotEmpty);
      expect(sId.aboutFeatureFreeTitle, isNotEmpty);

      const sEn = AppStrings(AppLanguage.en);
      expect(sEn.aboutDescription, contains('Cineva'));
      expect(sEn.aboutTagline, isNotEmpty);
      expect(sEn.aboutFeatureP2PTitle, isNotEmpty);
      expect(sEn.aboutFeatureHwTitle, isNotEmpty);
      expect(sEn.aboutFeatureSubTitle, isNotEmpty);
      expect(sEn.aboutFeatureDownloadTitle, isNotEmpty);
      expect(sEn.aboutFeatureFreeTitle, isNotEmpty);
    });
  });

  group('LegalDocumentScreen Widget Tests', () {
    testWidgets('Renders Privacy Policy full width without cards and with back button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LegalDocumentScreen(type: LegalDocType.privacyPolicy),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Title & callout summary
      expect(find.text('Kebijakan Privasi'), findsWidgets);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      // No Card widget should wrap the legal document (user strictly requested cardless/full-width)
      expect(find.byType(Card), findsNothing);

      // Section paragraphs
      expect(find.textContaining('Zero Data Collection'), findsOneWidget);
      // Official notice badge and last updated were removed per user request
      expect(find.text('PEMBERITAHUAN HUKUM RESMI'), findsNothing);

      // Back button
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    });

    testWidgets('Renders Terms and Conditions with all 6 numbered section headers', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LegalDocumentScreen(type: LegalDocType.termsAndConditions),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Syarat dan Ketentuan'), findsWidgets);
      expect(find.text('§1'), findsOneWidget);
      expect(find.text('§2'), findsOneWidget);
      expect(find.text('§3'), findsOneWidget);
      expect(find.text('§4'), findsOneWidget);
      expect(find.text('§5'), findsOneWidget);
      expect(find.text('§6'), findsOneWidget);
    });

    testWidgets('Renders Disclaimer with DMCA and limitation clauses', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LegalDocumentScreen(type: LegalDocType.disclaimer),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Disclaimer'), findsWidgets);
      expect(find.text('§1'), findsOneWidget);
      expect(find.text('§2'), findsOneWidget);
      expect(find.textContaining('Cineva TIDAK meng-host'), findsOneWidget);
    });
  });

  group('AboutInfoScreen Widget Tests', () {
    testWidgets('Renders poster collage mosaic, app name, badges, description, and feature tiles', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AboutInfoScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // App name & tagline
      expect(find.text(AppConstants.appName), findsOneWidget);
      expect(find.text('Modern Decentralized Media Player'), findsOneWidget);

      // Poster mosaic (multiple images from assets/images/)
      expect(find.byType(Image), findsWidgets);

      // Feature pills / tiles
      expect(find.text('Streaming P2P Cerdas'), findsOneWidget);
      expect(find.text('Akselerasi Perangkat Keras'), findsOneWidget);
      expect(find.text('Katalog 65+ Bahasa Subtitle'), findsOneWidget);
      expect(find.text('Manajer Unduhan Offline'), findsOneWidget);
      expect(find.text('Non-Profit & Bebas Iklan'), findsOneWidget);

      // Extra badges removed per user request
      expect(find.text('Edisi Publik Gratis'), findsNothing);
      expect(find.text('Android Native'), findsNothing);

      // Footer signature
      expect(find.textContaining('Made With'), findsOneWidget);
      expect(find.textContaining('by Cineva Group'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsWidgets);

      // Back button
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    });
  });
}
