import 'dart:io';
import 'package:cineva/app/theme/app_colors.dart';
import 'package:cineva/core/constants/app_constants.dart';
import 'package:cineva/features/watchlist/data/watchlist_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('cineva_watchlist_test_');
    Hive.init(tempDir.path);
    await Hive.openBox(AppConstants.watchlistBox);
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() async {
    final box = Hive.box(AppConstants.watchlistBox);
    await box.clear();
  });

  test('isInWatchlistProvider reactively reflects additions and removals', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const movieArg = (id: 101, type: 'movie');
    const tvArg = (id: 202, type: 'tv');

    // Initially neither is in the watchlist
    expect(container.read(isInWatchlistProvider(movieArg)), isFalse);
    expect(container.read(isInWatchlistProvider(tvArg)), isFalse);

    // Add movie to watchlist
    final movieItem = WatchlistItem(
      id: 101,
      title: 'Interstellar',
      posterPath: '/interstellar.jpg',
      voteAverage: 8.7,
      type: 'movie',
      addedAt: DateTime.now(),
    );
    await container.read(watchlistProvider.notifier).toggle(movieItem);

    // Should immediately be true
    expect(container.read(isInWatchlistProvider(movieArg)), isTrue);
    expect(container.read(isInWatchlistProvider(tvArg)), isFalse);

    // Add TV show to watchlist
    final tvItem = WatchlistItem(
      id: 202,
      title: 'Breaking Bad',
      posterPath: '/bb.jpg',
      voteAverage: 9.5,
      type: 'tv',
      addedAt: DateTime.now(),
    );
    await container.read(watchlistProvider.notifier).toggle(tvItem);

    // Both should now be true
    expect(container.read(isInWatchlistProvider(movieArg)), isTrue);
    expect(container.read(isInWatchlistProvider(tvArg)), isTrue);

    // Remove movie via toggle
    await container.read(watchlistProvider.notifier).toggle(movieItem);
    expect(container.read(isInWatchlistProvider(movieArg)), isFalse);
    expect(container.read(isInWatchlistProvider(tvArg)), isTrue);
  });

  testWidgets('Watchlist button updates icon to filled realtime without changing background', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const mediaId = 550;
    const mediaType = 'movie';

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Consumer(
                builder: (context, ref, _) {
                  final isInWatchlist = ref.watch(
                    isInWatchlistProvider((id: mediaId, type: mediaType)),
                  );
                  return GestureDetector(
                    key: const ValueKey('watchlist_btn'),
                    onTap: () async {
                      final item = WatchlistItem(
                        id: mediaId,
                        title: 'Fight Club',
                        posterPath: '/fc.jpg',
                        voteAverage: 8.8,
                        type: mediaType,
                        addedAt: DateTime.now(),
                      );
                      await ref.read(watchlistProvider.notifier).toggle(item);
                    },
                    child: Container(
                      key: const ValueKey('watchlist_container'),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isInWatchlist
                              ? AppColors.primary.withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.12),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        isInWatchlist ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        key: ValueKey(isInWatchlist),
                        color: isInWatchlist ? AppColors.primary : Colors.white,
                        size: 26,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    // Initial state: outline icon, white color
    expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_rounded), findsNothing);

    // Container background color should be surfaceVariant with alpha
    Container containerWidget = tester.widget(find.byKey(const ValueKey('watchlist_container')));
    BoxDecoration decoration = containerWidget.decoration as BoxDecoration;
    expect(decoration.color, AppColors.surfaceVariant.withValues(alpha: 0.6));

    final item = WatchlistItem(
      id: mediaId,
      title: 'Fight Club',
      posterPath: '/fc.jpg',
      voteAverage: 8.8,
      type: mediaType,
      addedAt: DateTime.now(),
    );

    // Toggle to add into watchlist
    await tester.runAsync(() async {
      await container.read(watchlistProvider.notifier).toggle(item);
    });
    await tester.pumpAndSettle();

    // In real-time: icon becomes filled bookmark with primary orange color
    expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_border_rounded), findsNothing);

    final iconWidget = tester.widget<Icon>(find.byIcon(Icons.bookmark_rounded));
    expect(iconWidget.color, AppColors.primary);

    // Container background color remains the detail surface background (NOT solid orange!)
    containerWidget = tester.widget(find.byKey(const ValueKey('watchlist_container')));
    decoration = containerWidget.decoration as BoxDecoration;
    expect(decoration.color, AppColors.surfaceVariant.withValues(alpha: 0.6));
    expect(decoration.color, isNot(AppColors.primary));

    // Toggle again to remove from watchlist
    await tester.runAsync(() async {
      await container.read(watchlistProvider.notifier).toggle(item);
    });
    await tester.pumpAndSettle();

    // Real-time revert to outline icon
    expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_rounded), findsNothing);
  });
}
