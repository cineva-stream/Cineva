import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineva/core/localization/app_language.dart';
import 'package:cineva/core/localization/app_language_provider.dart';
import 'package:cineva/features/backup/data/google_sync_service.dart';
import 'package:cineva/features/backup/presentation/providers/backup_providers.dart';
import 'package:cineva/features/feedback/data/feedback_smtp_service.dart';
import 'package:cineva/features/feedback/presentation/screens/feedback_screen.dart';
import 'package:cineva/features/profile/domain/models/user_profile.dart';
import 'package:cineva/features/profile/presentation/providers/profile_provider.dart';

class _FakeGoogleSyncService extends GoogleSyncService {
  _FakeGoogleSyncService(super.ref, {String? email}) {
    state = GoogleSyncState(
      isSupported: true,
      isSignedIn: email != null,
      email: email,
    );
  }
}

class _FakeUserProfileNotifier extends UserProfileNotifier {
  _FakeUserProfileNotifier() : super() {
    state = UserProfile(
      name: 'Rizky Pratama',
      username: 'rizky',
      avatarId: 'avatar_1',
      isConfigured: true,
      createdAt: DateTime(2026, 1, 1),
    );
  }
}

void main() {
  group('FeedbackSmtpService Unit Tests', () {
    test('validates email addresses accurately', () {
      expect(FeedbackSmtpService.isValidEmail('user@gmail.com'), isTrue);
      expect(FeedbackSmtpService.isValidEmail('cineva.dev@gmail.com'), isTrue);
      expect(FeedbackSmtpService.isValidEmail('invalid-email'), isFalse);
      expect(FeedbackSmtpService.isValidEmail(''), isFalse);
    });

    test('parses 16-digit Google App Password from .env content', () {
      const sampleEnv = '''
# Google SMTP App Password
CINEVA_SMTP_APP_PASSWORD="abcd efgh ijkl mnop"
''';
      expect(
        FeedbackSmtpService.parseEnvForPassword(sampleEnv),
        'abcdefghijklmnop',
      );
    });

    test(
      'builds professional English MIME message from noreply.cineva@gmail.com mentioning cineva.dev@gmail.com',
      () {
        final mime = FeedbackSmtpService.buildAutoReplyMimeMessage(
          recipientEmail: 'viewer@gmail.com',
          userName: 'Rizky Pratama',
          category: 'Bug / Kendala Teknis',
          title: 'Subtitle delay on Episode 3',
          description: 'The subtitle is 2 seconds late.',
          appVersion: 'v1.2.1+22',
        );

        expect(
          mime,
          contains('From: "Cineva Stream" <noreply.cineva@gmail.com>'),
        );
        expect(mime, contains('To: <viewer@gmail.com>'));
        expect(mime, contains('Reply-To: <cineva.dev@gmail.com>'));

        // Decode base64 chunks in the MIME body to verify plain text & HTML content
        final decodedString = utf8.decode(
          base64.decode(
            RegExp(r'Content-Transfer-Encoding: base64\r\n\r\n([A-Za-z0-9+/=\r\n]+?)\r\n--')
                .firstMatch(mime)!
                .group(1)!
                .replaceAll(RegExp(r'\s+'), ''),
          ),
        );

        expect(decodedString, contains('Dear Rizky Pratama,'));
        expect(
          decodedString,
          contains('Thank you for taking the time to share your thoughts'),
        );
        expect(decodedString, contains('noreply.cineva@gmail.com'));
        expect(decodedString, contains('cineva.dev@gmail.com'));
        expect(decodedString, contains('Bugs & Technical Issues'));
      },
    );
  });

  group('FeedbackScreen Email Auto-Fill & 3-Language Helper Note', () {
    testWidgets(
      'auto-fills email from Google Sign-In state and displays developer follow-up note in ID, EN, and HI',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            appLanguageProvider.overrideWith(
              (ref) => AppLanguageNotifier()..setLanguage(AppLanguage.id),
            ),
            googleSyncProvider.overrideWith(
              (ref) => _FakeGoogleSyncService(
                ref,
                email: 'logged.user@gmail.com',
              ),
            ),
            userProfileProvider.overrideWith(
              (ref) => _FakeUserProfileNotifier(),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: FeedbackScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Auto-filled Google email is present in the Email TextField
        expect(find.text('logged.user@gmail.com'), findsOneWidget);
        expect(find.text('Alamat Email (Opsional)'), findsOneWidget);
        expect(
          find.textContaining('cineva.dev@gmail.com'),
          findsOneWidget,
        );

        // Switch to English
        await container
            .read(appLanguageProvider.notifier)
            .setLanguage(AppLanguage.en);
        await tester.pumpAndSettle();

        expect(find.text('Email Address (Optional)'), findsOneWidget);
        expect(
          find.textContaining(
            'Include an active email address so our developer can contact you further',
          ),
          findsOneWidget,
        );

        // Switch to Hindi
        await container
            .read(appLanguageProvider.notifier)
            .setLanguage(AppLanguage.hi);
        await tester.pumpAndSettle();

        expect(find.text('ईमेल पता (वैकल्पिक)'), findsOneWidget);
      },
    );
  });
}
