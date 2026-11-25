import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineva/core/localization/app_language.dart';
import 'package:cineva/features/history/data/models/watch_history_item.dart';
import 'package:cineva/features/home/presentation/providers/home_providers.dart';
import 'package:cineva/features/profile/domain/entities/watch_insights.dart';
import 'package:cineva/features/profile/domain/models/user_profile.dart';
import 'package:cineva/features/profile/presentation/providers/watch_insights_provider.dart';
import 'package:cineva/features/profile/presentation/widgets/cineva_member_card_widget.dart';
import 'package:cineva/features/watchlist/data/watchlist_repository.dart';

void main() {
  group('Personalized Recommendation Seed Selection ("Because You Watched...")', () {
    test('deduplicates TV episodes and falls back to watchlist when history has < 2 seeds', () {
      final now = DateTime(2026, 11, 24, 9, 0);
      final history = [
        WatchHistoryItem(
          id: 100,
          mediaType: 'tv',
          title: 'Breaking Bad',
          season: 1,
          episode: 2,
          positionMs: 1200000,
          durationMs: 2400000,
          lastWatchedAt: now,
        ),
        WatchHistoryItem(
          id: 100,
          mediaType: 'tv',
          title: 'Breaking Bad',
          season: 1,
          episode: 1,
          positionMs: 2400000,
          durationMs: 2400000,
          lastWatchedAt: now.subtract(const Duration(hours: 1)),
          isCompleted: true,
        ),
      ];

      final watchlist = [
        WatchlistItem(
          id: 550,
          title: 'Fight Club',
          voteAverage: 8.8,
          type: 'movie',
          addedAt: now,
        ),
      ];

      final seeds = selectRecommendationSeeds(
        history: history,
        watchlist: watchlist,
        maxSeeds: 2,
      );

      expect(seeds.length, 2);
      expect(seeds[0].id, 100);
      expect(seeds[0].title, 'Breaking Bad');
      expect(seeds[0].mediaType, 'tv');
      expect(seeds[0].isFromWatchlist, isFalse);

      expect(seeds[1].id, 550);
      expect(seeds[1].title, 'Fight Club');
      expect(seeds[1].mediaType, 'movie');
      expect(seeds[1].isFromWatchlist, isTrue);
    });
  });

  group('Cineva Insights & Humorous ID / ATM Member Card Calculations', () {
    final now = DateTime(2026, 11, 24, 20, 0);
    final testProfile = UserProfile(
      name: 'Budi Santoso',
      username: 'budicineva',
      avatarId: 'avatar_popcorn',
      createdAt: now,
    );

    final testHistory = [
      WatchHistoryItem(
        id: 101,
        mediaType: 'movie',
        title: 'Interstellar',
        voteAverage: 8.7,
        positionMs: 3 * 3600 * 1000, // 3 hours
        durationMs: 3 * 3600 * 1000,
        lastWatchedAt: now,
        isCompleted: true,
      ),
      WatchHistoryItem(
        id: 202,
        mediaType: 'tv',
        title: 'Squid Game',
        season: 1,
        episode: 1,
        voteAverage: 8.1,
        positionMs: 4 * 3600 * 1000, // 4 hours
        durationMs: 4 * 3600 * 1000,
        lastWatchedAt: now.subtract(const Duration(days: 1)),
        isCompleted: true,
      ),
      WatchHistoryItem(
        id: 202,
        mediaType: 'tv',
        title: 'Squid Game',
        season: 1,
        episode: 2,
        voteAverage: 8.3,
        positionMs: 5 * 3600 * 1000, // 5 hours
        durationMs: 5 * 3600 * 1000,
        lastWatchedAt: now.subtract(const Duration(days: 2)),
        isCompleted: true,
      ),
    ];

    test('computes watch hours, persona rank, 16-digit card numbers, and humorous captions in ID/EN/HI', () {
      final insights = computeWatchInsights(
        history: testHistory,
        watchlist: const [],
        profile: testProfile,
      );

      // Total hours = 3 + 4 + 5 = 12 hours -> Level 3 (10-30 hours)
      expect(insights.totalHours, 12);
      expect(insights.moviesWatchedCount, 1);
      expect(insights.episodesWatchedCount, 2);
      expect(insights.tvSeriesWatchedCount, 1);
      expect(insights.completedTitlesCount, 3);
      expect(insights.personaLevel, 3);
      expect(insights.activeDaysStreak, 3);

      // Squid Game (4h + 5h = 9h total) must rank #1 in topWatchedTitles ahead of Interstellar (3h)!
      expect(insights.topWatchedTitles.isNotEmpty, isTrue);
      expect(insights.topWatchedTitles.first.title, 'Squid Game');
      expect(insights.topWatchedTitles.first.totalWatchedMs, 9 * 3600 * 1000);
      expect(insights.topWatchedTitles.first.episodesCount, 2);
    });

    test('multi-season TV series (e.g. The Rookie at Season 4) aggregates cumulative duration and ranks #1 over a 1.5h movie', () {
      final historyWithMultiSeason = [
        WatchHistoryItem(
          id: 999,
          mediaType: 'movie',
          title: 'Spider-Man: Brand New Day',
          positionMs: 90 * 60 * 1000, // 1h 30m
          durationMs: 90 * 60 * 1000,
          lastWatchedAt: now,
          isCompleted: true,
        ),
        WatchHistoryItem(
          id: 79744,
          mediaType: 'tv',
          title: 'The Rookie',
          season: 4,
          episode: 3,
          positionMs: 30 * 60 * 1000, // 30m into S4E3
          durationMs: 42 * 60 * 1000, // 42m per episode
          lastWatchedAt: now,
          isCompleted: false,
        ),
      ];

      final insights = computeWatchInsights(
        history: historyWithMultiSeason,
        watchlist: const [],
        profile: testProfile,
      );

      expect(insights.topWatchedTitles.first.title, 'The Rookie');
      // 3 prior seasons (30 eps) + 2 prior eps in S4 = 32 eps * 42m + 30m = 1374 mins (> 22 hours)
      expect(insights.topWatchedTitles.first.totalWatchedMs, greaterThan(20 * 3600 * 1000));
      expect(insights.topWatchedTitles.first.episodesCount, greaterThanOrEqualTo(33));

      // Persona titles in all 3 languages
      expect(insights.personaTitle(AppLanguage.id), 'Duta Maraton Malam');
      expect(insights.personaTitle(AppLanguage.en), 'Midnight Binge Ambassador');
      expect(insights.personaTitle(AppLanguage.hi), 'मिडनाइट बिंज एंबेसडर');

      // Card numbers formatted properly
      expect(insights.idCardNumber.startsWith('3273 • '), isTrue);
      expect(insights.atmCardNumber.startsWith('8842  '), isTrue);

      // Humorous captions contain download link and watch metrics in all 3 languages
      for (final lang in AppLanguage.values) {
        final captions = insights.generateHumorousCaptions(
          lang: lang,
          profile: testProfile,
        );
        expect(captions.length, greaterThanOrEqualTo(6));
        for (final caption in captions) {
          expect(
            caption.contains('https://github.com/cineva-stream/Cineva/releases'),
            isTrue,
          );
        }
      }
    });

    testWidgets('renders CinevaMemberCardWidget in ID and ATM styles without overflow', (tester) async {
      final insights = computeWatchInsights(
        history: testHistory,
        watchlist: const [],
        profile: testProfile,
      );

      for (final style in MemberCardStyle.values) {
        for (final lang in AppLanguage.values) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 360,
                    child: CinevaMemberCardWidget(
                      profile: testProfile,
                      insights: insights,
                      language: lang,
                      style: style,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
        }
      }
    });
  });
}
