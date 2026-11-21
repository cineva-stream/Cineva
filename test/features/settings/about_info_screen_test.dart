import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cineva/features/settings/presentation/screens/about_info_screen.dart';
import 'package:cineva/shared/widgets/github_brand_icon.dart';

void main() {
  testWidgets('AboutInfoScreen renders GitHub Cineva Group and Developer email cleanly', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AboutInfoScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify GitHub card and details
    expect(find.text('Cineva Group'), findsOneWidget);
    expect(find.text('https://github.com/cineva-stream'), findsOneWidget);
    expect(find.byType(GithubBrandIcon), findsOneWidget);

    // Verify Developer Contact email card
    expect(find.text('cineva.dev@gmail.com'), findsOneWidget);

    // Verify Footer
    expect(find.text('Made with '), findsOneWidget);
    expect(find.text(' by Cineva Group'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsWidgets);
  });
}
