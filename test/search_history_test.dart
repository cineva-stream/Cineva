import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cineva/core/constants/app_constants.dart';
import 'package:cineva/features/search/presentation/providers/search_history_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_search_test_');
    Hive.init(tempDir.path);
    await Hive.openBox(AppConstants.settingsBox);
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('SearchHistoryNotifier Tests', () {
    test('Adds new queries to the top and deduplicates', () async {
      final notifier = SearchHistoryNotifier();

      await notifier.addQuery('Interstellar');
      await notifier.addQuery('Inception');
      await notifier.addQuery('interstellar'); // case-insensitive deduplication

      expect(notifier.state.length, 2);
      expect(notifier.state.first, 'interstellar');
      expect(notifier.state[1], 'Inception');
    });

    test('Removes individual query and clears all', () async {
      final notifier = SearchHistoryNotifier();

      await notifier.addQuery('Dune');
      await notifier.addQuery('Avatar');
      expect(notifier.state.length, 2);

      await notifier.removeQuery('Dune');
      expect(notifier.state, ['Avatar']);

      await notifier.clearHistory();
      expect(notifier.state, isEmpty);
    });
  });
}
