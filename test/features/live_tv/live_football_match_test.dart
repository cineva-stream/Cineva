import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineva/core/localization/app_language.dart';
import 'package:cineva/core/localization/app_language_provider.dart';
import 'package:cineva/features/live_tv/data/datasources/live_tv_channels_data.dart';
import 'package:cineva/features/live_tv/data/services/live_football_match_service.dart';
import 'package:cineva/features/live_tv/domain/entities/live_tv_channel.dart';
import 'package:cineva/features/live_tv/presentation/widgets/live_football_match_modal.dart';

class _TestLanguageNotifier extends AppLanguageNotifier {
  _TestLanguageNotifier([super.initial = AppLanguage.id]);

  @override
  Future<void> setLanguage(AppLanguage lang) async {
    state = lang;
  }
}

void main() {
  group('LiveTvChannelsData Football Channels & Logos Verification', () {
    test(
      'every Live TV channel has a non-empty logoUrl and football channels are registered',
      () {
        for (final ch in LiveTvChannelsData.defaultChannels) {
          expect(
            ch.logoUrl,
            isNotNull,
            reason: 'Channel ${ch.id} (${ch.name}) must have a logoUrl',
          );
          expect(
            ch.logoUrl!.trim(),
            isNotEmpty,
            reason: 'Channel ${ch.id} (${ch.name}) logoUrl must not be empty',
          );
        }

        // Check new football & sports channels exist
        expect(LiveTvChannelsData.findById('ch_bein_sports_1'), isNotNull);
        expect(LiveTvChannelsData.findById('ch_bein_sports_2'), isNotNull);
        expect(LiveTvChannelsData.findById('ch_bein_sports_3'), isNotNull);
        expect(LiveTvChannelsData.findById('ch_bein_sports_xtra'), isNotNull);
        expect(LiveTvChannelsData.findById('ch_soccer_channel'), isNotNull);
        expect(LiveTvChannelsData.findById('ch_fifa_plus'), isNotNull);
        expect(LiveTvChannelsData.findById('ch_realmadrid_tv'), isNotNull);
        expect(LiveTvChannelsData.findById('id_tvri_sport'), isNotNull);
        expect(LiveTvChannelsData.findById('ch_cbs_sports_hq'), isNotNull);
        expect(LiveTvChannelsData.findById('id_rcti'), isNotNull);
        expect(LiveTvChannelsData.findById('id_mnctv'), isNotNull);
        expect(LiveTvChannelsData.findById('id_gtv'), isNotNull);
        expect(
          LiveTvChannelsData.footballChannels.length,
          greaterThanOrEqualTo(10),
        );

        // Verify Indonesian & sports channels never use mismatched DensTV h217-h220 or geo-redirected Pluto TV URLs
        final sctv = LiveTvChannelsData.findById('id_sctv')!;
        final rcti = LiveTvChannelsData.findById('id_rcti')!;
        final gtv = LiveTvChannelsData.findById('id_gtv')!;
        final mnctv = LiveTvChannelsData.findById('id_mnctv')!;
        expect(sctv.streamUrl.contains('h217'), isFalse);
        expect(rcti.streamUrl.contains('h218'), isFalse);
        expect(gtv.streamUrl.contains('h219'), isFalse);
        expect(mnctv.streamUrl.contains('h220'), isFalse);
        expect(rcti.allStreamUrls.length, greaterThanOrEqualTo(2));
        expect(gtv.allStreamUrls.length, greaterThanOrEqualTo(2));
        expect(mnctv.allStreamUrls.length, greaterThanOrEqualTo(2));

        for (final ch in LiveTvChannelsData.defaultChannels) {
          expect(
            ch.streamUrl.contains('service-stitcher.clusters.pluto.tv'),
            isFalse,
            reason:
                'Channel ${ch.id} should not use geo-redirected Pluto stitcher URL',
          );
        }
      },
    );
  });

  group('LiveFootballMatchService ESPN Scoreboard Parser & Channel Mapping', () {
    test(
      'filters only in-progress (state == "in") matches and maps to broadcasting channel',
      () {
        final sampleJson = <String, dynamic>{
          'leagues': [
            {'name': 'UEFA Champions League'},
          ],
          'events': [
            {
              'id': 'match_live_1',
              'status': {
                'type': {'state': 'in', 'shortDetail': "64'"},
              },
              'competitions': [
                {
                  'competitors': [
                    {
                      'homeAway': 'home',
                      'score': '2',
                      'team': {
                        'shortDisplayName': 'Arsenal',
                        'logo':
                            'https://a.espncdn.com/i/teamlogos/soccer/500/359.png',
                      },
                    },
                    {
                      'homeAway': 'away',
                      'score': '1',
                      'team': {
                        'shortDisplayName': 'PSG',
                        'logo':
                            'https://a.espncdn.com/i/teamlogos/soccer/500/160.png',
                      },
                    },
                  ],
                },
              ],
            },
            {
              'id': 'match_finished_2',
              'status': {
                'type': {'state': 'post', 'shortDetail': 'FT'},
              },
              'competitions': [
                {
                  'competitors': [
                    {
                      'homeAway': 'home',
                      'score': '1',
                      'team': {'shortDisplayName': 'Team A'},
                    },
                    {
                      'homeAway': 'away',
                      'score': '0',
                      'team': {'shortDisplayName': 'Team B'},
                    },
                  ],
                },
              ],
            },
          ],
        };

        final liveMatches = LiveFootballMatchService.parseEspnScoreboardJson(
          sampleJson,
        );
        expect(liveMatches.length, 1);
        final match = liveMatches.single;
        expect(match.id, 'match_live_1');
        expect(match.homeTeamName, 'Arsenal');
        expect(match.awayTeamName, 'PSG');
        expect(match.homeScore, '2');
        expect(match.awayScore, '1');
        expect(match.statusDetail, "64'");
        expect(match.primaryChannel.id, 'id_sctv');
        expect(
          match.allChannels.any((c) => c.id == 'ch_bein_sports_xtra'),
          isTrue,
        );
      },
    );

    test(
      'maps BRI Liga 1 to Indosiar HD and Real Madrid to Real Madrid TV HD',
      () {
        final liga1 = LiveFootballMatchService.resolveBroadcastingChannels(
          competitionName: 'BRI Liga 1 Indonesia',
          homeTeamName: 'Persib Bandung',
          awayTeamName: 'Persija Jakarta',
        );
        expect(liga1.primary.id, 'id_indosiar');

        final rm = LiveFootballMatchService.resolveBroadcastingChannels(
          competitionName: 'Spanish LaLiga',
          homeTeamName: 'Real Madrid',
          awayTeamName: 'Girona',
        );
        expect(rm.primary.id, 'ch_realmadrid_tv');
      },
    );

    test(
      'Real-Time EPG + ESPN cross-verification maps simultaneous matches to their exact broadcasting channels and excludes unbroadcast foreign matches & non-football sports',
      () {
        const sampleEpgXml = '''
<tv>
  <programme start="20261127004000 +0700" stop="20261127025500 +0700" channel="beInSports1.id">
    <title lang="id">UEL 2026/27: CEL Vs BOU (L)</title>
  </programme>
  <programme start="20261127004000 +0700" stop="20261127025500 +0700" channel="beInSports2.id">
    <title lang="id">UECL 2026/27: BHA Vs UCR (L)</title>
  </programme>
  <programme start="20261127004000 +0700" stop="20261127025500 +0700" channel="beInSports3.id">
    <title lang="id">UEL 2026/27: OLY Vs MIL (L)</title>
  </programme>
  <programme start="20261127004500 +0700" stop="20261127030000 +0700" channel="SCTV.id">
    <title lang="id">UEFA Europa League (L)</title>
  </programme>
  <programme start="20261126172600 +0000" stop="20261126194300 +0000" channel="SCTV.id">
    <title lang="id">Olympiacos Vs Ac Milan - Uefa Europa League - Live</title>
  </programme>
  <programme start="20261127003000 +0700" stop="20261127023000 +0700" channel="Sportstars.id">
    <title lang="id">V-League 2026-2027: Women (L)</title>
  </programme>
  <programme start="20261127003000 +0700" stop="20261127023000 +0700" channel="MNCTV.id">
    <title lang="id">Liga DMD Panggung Rezeki 2 (L)</title>
  </programme>
</tv>
''';

        // Timestamp: 2026-11-27 01:30 WIB (2026-11-26 18:30 UTC)
        final nowUtc = DateTime.utc(2026, 11, 26, 18, 30);
        final activeProgs =
            LiveFootballMatchService.parseActiveEpgFootballProgrammes(
              sampleEpgXml,
              nowUtc: nowUtc,
            );

        // V-League (Volleyball) and Liga DMD (Music show) must be excluded,
        // and SCTV's overlapping blocks must deduplicate to the team-specific block.
        expect(activeProgs.length, 4);

        final espnEvents = LiveFootballMatchService.parseEspnLiveEvents({
          'leagues': [
            {'name': 'UEFA Europa League'},
          ],
          'events': [
            // 1. Olympiacos vs AC Milan (airing on SCTV HD & beIN Sports 3 HD)
            {
              'id': 'espn_oly_mil',
              'status': {
                'type': {'state': 'in', 'shortDetail': "51'"},
              },
              'competitions': [
                {
                  'competitors': [
                    {
                      'homeAway': 'home',
                      'score': '1',
                      'team': {
                        'abbreviation': 'OLY',
                        'shortDisplayName': 'Olympiacos',
                      },
                    },
                    {
                      'homeAway': 'away',
                      'score': '2',
                      'team': {
                        'abbreviation': 'MIL',
                        'shortDisplayName': 'AC Milan',
                      },
                    },
                  ],
                },
              ],
            },
            // 2. Celta Vigo vs Bournemouth (airing ONLY on beIN Sports 1 HD)
            {
              'id': 'espn_cel_bou',
              'status': {
                'type': {'state': 'in', 'shortDetail': "49'"},
              },
              'competitions': [
                {
                  'competitors': [
                    {
                      'homeAway': 'home',
                      'score': '0',
                      'team': {
                        'abbreviation': 'CEL',
                        'shortDisplayName': 'Celta Vigo',
                      },
                    },
                    {
                      'homeAway': 'away',
                      'score': '0',
                      'team': {
                        'abbreviation': 'BOU',
                        'shortDisplayName': 'Bournemouth',
                      },
                    },
                  ],
                },
              ],
            },
            // 3. Unbroadcast foreign match (Liga MX: León vs Cruz Azul) -> MUST NOT APPEAR!
            {
              'id': 'espn_leon_cruz',
              'status': {
                'type': {'state': 'in', 'shortDetail': "12'"},
              },
              'competitions': [
                {
                  'competitors': [
                    {
                      'homeAway': 'home',
                      'score': '0',
                      'team': {
                        'abbreviation': 'LEO',
                        'shortDisplayName': 'León',
                      },
                    },
                    {
                      'homeAway': 'away',
                      'score': '1',
                      'team': {
                        'abbreviation': 'CAZ',
                        'shortDisplayName': 'Cruz Azul',
                      },
                    },
                  ],
                },
              ],
            },
          ],
        });

        final verifiedMatches =
            LiveFootballMatchService.buildVerifiedLiveMatches(
              activeProgrammes: activeProgs,
              espnEvents: espnEvents,
            );

        // Exactly 3 matches are verified (OLY vs MIL, CEL vs BOU, BHA vs UCR);
        // León vs Cruz Azul is excluded because no channel in EPG airs it.
        expect(verifiedMatches.length, 3);
        expect(
          verifiedMatches.any((m) => m.homeTeamName.contains('León')),
          isFalse,
        );

        // Verify Match 1: Celta Vigo vs Bournemouth -> ONLY on beIN Sports 1 HD
        final celBou = verifiedMatches.firstWhere(
          (m) => m.id == 'espn_cel_bou',
        );
        expect(
          celBou.allChannels.map((c) => c.id).toList(),
          equals(['ch_bein_sports_1']),
        );
        expect(
          celBou.programInfoForChannel('ch_bein_sports_1'),
          contains('CEL Vs BOU (L)'),
        );

        // Verify Match 2: Brighton vs U Craiova (from EPG directly) -> ONLY on beIN Sports 2 HD
        final bhaUcr = verifiedMatches.firstWhere(
          (m) => m.homeTeamName == 'Brighton',
        );
        expect(bhaUcr.awayTeamName, 'U Craiova');
        expect(
          bhaUcr.allChannels.map((c) => c.id).toList(),
          equals(['ch_bein_sports_2']),
        );

        // Verify Match 3: Olympiacos vs AC Milan -> on BOTH beIN Sports 3 HD and SCTV HD
        final olyMil = verifiedMatches.firstWhere(
          (m) => m.id == 'espn_oly_mil',
        );
        expect(
          olyMil.allChannels.map((c) => c.id).toSet(),
          equals({'ch_bein_sports_3', 'id_sctv'}),
        );
        expect(olyMil.homeScore, '1');
        expect(olyMil.awayScore, '2');
      },
    );
  });

  group('LiveFootballMatchModal Widget & Watch Now Action Test', () {
    testWidgets(
      'Renders live match scoreboard in ID, EN, and HI and triggers onWatchChannel when Watch Now is tapped',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            appLanguageProvider.overrideWith(
              (ref) => _TestLanguageNotifier(AppLanguage.id),
            ),
          ],
        );
        addTearDown(container.dispose);

        final matches = LiveFootballMatchService.parseEspnScoreboardJson({
          'leagues': [
            {'name': 'UEFA Champions League'},
          ],
          'events': [
            {
              'id': 'm100',
              'status': {
                'type': {'state': 'in', 'shortDetail': "52'"},
              },
              'competitions': [
                {
                  'competitors': [
                    {
                      'homeAway': 'home',
                      'score': '1',
                      'team': {'shortDisplayName': 'Barcelona'},
                    },
                    {
                      'homeAway': 'away',
                      'score': '1',
                      'team': {'shortDisplayName': 'Bayern Munich'},
                    },
                  ],
                },
              ],
            },
          ],
        });

        LiveTvChannel? launchedChannel;

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: LiveFootballMatchModal(
                  matches: matches,
                  onWatchChannel: (ch) {
                    launchedChannel = ch;
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Sepak Bola Sedang Tayang!'), findsOneWidget);
        expect(find.text('Tayang di'), findsOneWidget);
        expect(find.text('Barcelona'), findsOneWidget);
        expect(find.text('Bayern Munich'), findsOneWidget);
        expect(find.text('SCTV HD'), findsOneWidget);
        expect(find.text('Tonton Sekarang'), findsOneWidget);
        expect(find.text('Nanti Saja'), findsOneWidget);

        // Switch language to English (EN) and verify all tournament modal labels update
        await container
            .read(appLanguageProvider.notifier)
            .setLanguage(AppLanguage.en);
        await tester.pump();

        expect(find.text('Live Football is On Now!'), findsOneWidget);
        expect(find.text('Broadcasting on'), findsOneWidget);
        expect(find.text('Watch Now'), findsOneWidget);
        expect(find.text('Maybe Later'), findsOneWidget);

        // Switch language to Hindi (HI) and verify all tournament modal labels update
        await container
            .read(appLanguageProvider.notifier)
            .setLanguage(AppLanguage.hi);
        await tester.pump();

        expect(find.text('लाइव फुटबॉल अभी चल रहा है!'), findsOneWidget);
        expect(find.text('प्रसारण चैनल'), findsOneWidget);
        expect(find.text('अभी देखें'), findsOneWidget);
        expect(find.text('बाद में'), findsOneWidget);

        // Switch back to Indonesian (ID) and tap Watch Now ("Tonton Sekarang")
        await container
            .read(appLanguageProvider.notifier)
            .setLanguage(AppLanguage.id);
        await tester.pump();

        await tester.tap(find.text('Tonton Sekarang'));
        await tester.pump();

        expect(launchedChannel, isNotNull);
        expect(launchedChannel!.id, 'id_sctv');
      },
    );
  });
}
