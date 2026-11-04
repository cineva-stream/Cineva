import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cineva/core/constants/app_constants.dart';
import 'package:cineva/core/constants/genre_constants.dart';
import 'package:cineva/features/search/presentation/screens/search_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_search_reset_test_');
    Hive.init(tempDir.path);
    await Hive.openBox(AppConstants.settingsBox);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Search Reset on Navigation Tests', () {
    test('resetSearchState resets query, tab, and genre filter in container', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Set initial values
      container.read(searchQueryProvider.notifier).state = 'Naruto Shippuden';
      container.read(searchTabProvider.notifier).state = 2; // TV Series
      container.read(selectedSearchGenreProvider.notifier).state =
          GenreConstants.filters.last;

      expect(container.read(searchQueryProvider), 'Naruto Shippuden');
      expect(container.read(searchTabProvider), 2);
      expect(
        container.read(selectedSearchGenreProvider),
        GenreConstants.filters.last,
      );

      // Manually reset via state
      container.read(searchQueryProvider.notifier).state = '';
      container.read(searchTabProvider.notifier).state = 0;
      container.read(selectedSearchGenreProvider.notifier).state =
          GenreConstants.filters.first;

      expect(container.read(searchQueryProvider), '');
      expect(container.read(searchTabProvider), 0);
      expect(
        container.read(selectedSearchGenreProvider),
        GenreConstants.filters.first,
      );
    });

    testWidgets('SearchScreen clears TextField when searchQueryProvider is reset', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      late StateController<String> queryController;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            searchQueryProvider.overrideWith((ref) => 'Initial Search'),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              queryController = ref.watch(searchQueryProvider.notifier);
              return const MaterialApp(
                home: SearchScreen(),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // TextField initially shows "Initial Search"
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);
      final textFieldWidget = tester.widget<TextField>(textFieldFinder);
      expect(textFieldWidget.controller?.text, 'Initial Search');

      // Now simulate returning to Beranda (resetting query to empty)
      queryController.state = '';
      await tester.pumpAndSettle();

      // TextField is now automatically empty!
      expect(textFieldWidget.controller?.text, '');
    });
  });
}

