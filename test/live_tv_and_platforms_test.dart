import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cineva/features/history/data/models/watch_history_item.dart';
import 'package:cineva/features/history/data/repositories/watch_history_repository.dart';
import 'package:cineva/core/constants/app_constants.dart';
import 'package:cineva/features/live_tv/data/datasources/live_tv_channels_data.dart';
import 'package:cineva/features/live_tv/presentation/providers/live_tv_providers.dart';
import 'package:cineva/features/live_tv/presentation/screens/live_tv_screen.dart';
import 'package:cineva/features/search/domain/entities/streaming_platform.dart';
import 'package:cineva/features/search/presentation/providers/platform_catalog_provider.dart';
import 'package:cineva/features/search/presentation/screens/platform_catalog_screen.dart';
import 'package:cineva/features/home/domain/entities/movie.dart';
import 'package:cineva/features/home/domain/entities/tv_series.dart';
import 'package:cineva/shared/widgets/main_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('cineva_livetv_test_');
    Hive.init(tempDir.path);
    await Hive.openBox(AppConstants.settingsBox);
    await Hive.openBox(AppConstants.historyBox);
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('StreamingPlatform Entity Tests', () {
    test('Supported platforms list contains all 8 major networks', () {
      expect(StreamingPlatform.supportedPlatforms.length, 8);
      expect(StreamingPlatform.fromId('netflix').providerId, 8);
      expect(StreamingPlatform.fromId('prime').providerId, 9);
      expect(StreamingPlatform.fromId('disney').providerId, 337);
      expect(StreamingPlatform.fromId('apple').providerId, 350);
      expect(StreamingPlatform.fromId('max').providerId, 384);
      expect(StreamingPlatform.fromId('hulu').providerId, 15);
      expect(StreamingPlatform.fromId('paramount').providerId, 531);
      expect(StreamingPlatform.fromId('peacock').providerId, 387);
    });

    test('Fallback to first platform for unknown id', () {
      expect(StreamingPlatform.fromId('unknown').id, 'netflix');
    });
  });

  group('LiveTvChannelsData Registry Tests', () {
    test('Default channels list contains curated valid channels', () {
      final channels = LiveTvChannelsData.defaultChannels;
      expect(channels.isNotEmpty, isTrue);

      final sports = channels.where((c) => c.category == 'Olahraga');
      expect(sports.isNotEmpty, isTrue);

      final news = channels.where((c) => c.category == 'Berita');
      expect(news.isNotEmpty, isTrue);

      final indo = channels.where((c) => c.category == 'Indonesia');
      expect(indo.isNotEmpty, isTrue);

      for (final ch in channels) {
        expect(ch.id.isNotEmpty, isTrue);
        expect(ch.name.isNotEmpty, isTrue);
        expect(ch.streamUrl.startsWith('http'), isTrue);
      }
    });
  });

  group('Live TV Providers Filtering Tests', () {
    test('Filters channels by category correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(liveTvCategoryProvider.notifier).state = 'Olahraga';
      final filtered = container.read(filteredLiveTvChannelsProvider);
      expect(filtered.every((c) => c.category == 'Olahraga'), isTrue);
    });

    test('Filters channels by search query correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(liveTvCategoryProvider.notifier).state = 'Semua';
      container.read(liveTvSearchQueryProvider.notifier).state = 'NASA';
      final filtered = container.read(filteredLiveTvChannelsProvider);
      expect(filtered.any((c) => c.name.contains('NASA')), isTrue);
    });
  });

  group('LiveTvScreen Widget Tests', () {
    testWidgets('Renders TV Live header, search bar, and channels', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LiveTvScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('TV Live'), findsWidgets);
      expect(find.text('LIVE'), findsWidgets);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Olahraga'), findsWidgets);
      expect(find.text('Berita'), findsWidgets);
    });
  });

  group('PlatformCatalogScreen Widget Tests', () {
    final mockMovies = [
      const Movie(
        id: 101,
        title: 'Stranger Things: The Movie',
        overview: 'Supernatural thriller in Hawkins',
        posterPath: '/stranger.jpg',
        backdropPath: '/stranger_bg.jpg',
        voteAverage: 8.7,
        releaseDate: '2024-05-10',
        genreIds: [18, 9648],
      ),
    ];

    final mockTv = [
      const TvSeries(
        id: 201,
        name: 'Wednesday',
        overview: 'Nevermore academy mysteries',
        posterPath: '/wednesday.jpg',
        backdropPath: '/wednesday_bg.jpg',
        voteAverage: 8.5,
        firstAirDate: '2022-11-23',
        genreIds: [35, 9648],
      ),
    ];

    testWidgets('Renders platform name, filter chips, and posters', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final platform = StreamingPlatform.fromId('netflix');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            platformMoviesProvider(platform.providerId)
                .overrideWith((ref) => Future.value(mockMovies)),
            platformTvProvider(platform.providerId)
                .overrideWith((ref) => Future.value(mockTv)),
          ],
          child: MaterialApp(
            home: PlatformCatalogScreen(platform: platform),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Film'), findsWidgets);
      expect(find.text('Serial TV'), findsWidgets);
      expect(find.text('Stranger Things: The Movie'), findsOneWidget);
      expect(find.text('Wednesday'), findsOneWidget);
    });
  });

  group('MainShell Navigation Tests', () {
    testWidgets('Renders TV Live navigation tab icon and label', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const MainShell(child: Text('Content')),
          ),
          GoRoute(
            path: '/live-tv',
            builder: (context, state) => const MainShell(child: Text('Live TV Content')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('TV Live'), findsOneWidget);
      expect(find.byIcon(Icons.live_tv_outlined), findsOneWidget);
    });
  });

  group('Watch History TV Series & Deduplication Tests', () {
    test('Overwrites previous in-progress TV episode with completed status and removes duplicates', () async {
      final repo = WatchHistoryRepository();
      await repo.clearAll();

      final inProgressEp2 = WatchHistoryItem(
        id: 84958,
        mediaType: 'tv',
        title: 'The Rookie',
        episodeTitle: 'S1:E2 Crash Course',
        season: 1,
        episode: 2,
        positionMs: 600000,
        durationMs: 2500000,
        lastWatchedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        isCompleted: false,
      );

      await repo.saveProgress(inProgressEp2);
      expect(repo.getAll().length, 1);
      expect(repo.getAll().first.isInProgress, isTrue);
      expect(repo.getAll().first.isCompleted, isFalse);

      // Next Episode: Ep 2 is saved as 100% completed
      final completedEp2 = inProgressEp2.copyWith(
        positionMs: 2500000,
        isCompleted: true,
        lastWatchedAt: DateTime.now(),
      );

      await repo.saveProgress(completedEp2);

      final all = repo.getAll();
      expect(all.length, 1);
      expect(all.first.isCompleted, isTrue);
      expect(all.first.isInProgress, isFalse);
    });

    test('Consolidates in-progress TV series so only the latest episode is shown in Continue Watching', () async {
      final repo = WatchHistoryRepository();
      await repo.clearAll();

      final ep1 = WatchHistoryItem(
        id: 84958,
        mediaType: 'tv',
        title: 'The Rookie',
        episodeTitle: 'S1:E1 Pilot',
        season: 1,
        episode: 1,
        positionMs: 500000,
        durationMs: 2500000,
        lastWatchedAt: DateTime.now().subtract(const Duration(hours: 1)),
        isCompleted: false,
      );

      final ep2 = WatchHistoryItem(
        id: 84958,
        mediaType: 'tv',
        title: 'The Rookie',
        episodeTitle: 'S1:E2 Crash Course',
        season: 1,
        episode: 2,
        positionMs: 300000,
        durationMs: 2500000,
        lastWatchedAt: DateTime.now(),
        isCompleted: false,
      );

      await repo.saveProgress(ep1);
      await repo.saveProgress(ep2);

      final container = ProviderContainer();
      final inProgress = container.read(inProgressWatchHistoryProvider);

      // Should only contain 1 entry for The Rookie (the latest one, Episode 2)
      expect(inProgress.where((i) => i.id == 84958).length, 1);
      expect(inProgress.firstWhere((i) => i.id == 84958).episode, 2);
    });
  });
}
