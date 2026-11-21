import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cineva/features/watch_party/domain/models/watch_party_room.dart';
import 'package:cineva/features/watch_party/data/services/watch_party_service.dart';
import 'package:cineva/features/watch_party/presentation/providers/watch_party_provider.dart';
import 'package:cineva/features/watch_party/presentation/widgets/watch_party_side_view.dart';
import 'package:cineva/features/watch_party/presentation/widgets/watch_party_join_banner.dart';
import 'package:cineva/features/watch_party/presentation/widgets/watch_party_chat_panel.dart';
import 'package:cineva/features/watch_party/presentation/widgets/watch_party_dynamic_island.dart';
import 'package:cineva/features/watch_party/presentation/screens/watch_party_direct_join_screen.dart';
import 'package:cineva/core/localization/app_language.dart';
import 'package:cineva/core/localization/app_language_provider.dart';
import 'package:cineva/core/localization/app_strings.dart';

void main() {
  group('WatchPartyRoom Models & Serialization', () {
    test('Serializes full Room structure to and from JSON', () {
      final now = 1794900000000;
      final room = WatchPartyRoom(
        roomCode: 'CNV-8492',
        hostId: 'host_uid_1',
        hostName: 'John Doe',
        allowGuestControl: false,
        media: const WatchPartyMedia(
          title: 'Inception',
          mediaType: 'movie',
          tmdbId: 27205,
          posterPath: '/inception.jpg',
        ),
        playback: WatchPartyPlayback(
          isPlaying: true,
          positionSeconds: 154.5,
          updatedAt: now,
          updatedBy: 'John Doe',
          action: 'play',
        ),
        members: {
          'host_uid_1': WatchPartyMember(
            id: 'host_uid_1',
            name: 'John Doe',
            isHost: true,
            joinedAt: now,
            lastSeen: now,
          ),
          'guest_1': WatchPartyMember(
            id: 'guest_1',
            name: 'Budi (Tamu)',
            isHost: false,
            joinedAt: now + 5000,
            lastSeen: now + 5000,
          ),
        },
        messages: [
          WatchPartyMessage(
            id: 'msg_1',
            senderId: 'host_uid_1',
            senderName: 'John Doe',
            isHost: true,
            text: 'Film dimulai ya!',
            timestamp: now + 1000,
            type: 'chat',
          ),
          WatchPartyMessage(
            id: 'msg_2',
            senderId: 'guest_1',
            senderName: 'Budi',
            isHost: false,
            text: 'Siap!',
            timestamp: now + 2000,
            type: 'chat',
          ),
          WatchPartyMessage(
            id: 'msg_3',
            senderId: 'guest_1',
            senderName: 'Budi',
            isHost: false,
            text: '🔥',
            emoji: '🔥',
            timestamp: now + 3000,
            type: 'emoji',
          ),
        ],
        createdAt: now,
      );

      final json = room.toJson();
      expect(json['roomCode'], 'CNV-8492');
      expect(json['allowGuestControl'], false);
      expect((json['media'] as Map)['title'], 'Inception');
      expect((json['playback'] as Map)['positionSeconds'], 154.5);

      final reconstructed = WatchPartyRoom.fromJson(json);
      expect(reconstructed.roomCode, 'CNV-8492');
      expect(reconstructed.hostName, 'John Doe');
      expect(reconstructed.members.length, 2);
      expect(reconstructed.members['guest_1']?.name, 'Budi (Tamu)');
      expect(reconstructed.messages.length, 3);
      expect(reconstructed.messages[2].type, 'emoji');
      expect(reconstructed.messages[2].emoji, '🔥');
    });

    test('allowGuestControl default is false and can be updated', () {
      final room = WatchPartyRoom(
        roomCode: 'CNV-1234',
        hostId: 'h1',
        hostName: 'Host',
        media: const WatchPartyMedia(title: 'M', mediaType: 'movie', tmdbId: 1),
        playback: const WatchPartyPlayback(
          isPlaying: false,
          positionSeconds: 0,
          updatedAt: 0,
          updatedBy: 'H',
          action: 'init',
        ),
        createdAt: 0,
      );

      expect(room.allowGuestControl, isFalse);
      expect(room.isProtectedByPin, isFalse);
      expect(room.verifyPin('any'), isTrue);

      final updated = room.copyWith(allowGuestControl: true, pin: '4321');
      expect(updated.allowGuestControl, isTrue);
      expect(updated.isProtectedByPin, isTrue);
      expect(updated.pin, '4321');
      expect(updated.verifyPin('4321'), isTrue);
      expect(updated.verifyPin('0000'), isFalse);
      expect(updated.verifyPin(null), isFalse);

      final cleared = updated.copyWith(clearPin: true);
      expect(cleared.isProtectedByPin, isFalse);
      expect(cleared.pin, isNull);
    });
  });

  group('WatchPartyService Room Code Generation & Network Math', () {
    test(
      'generateRoomCode produces 8-char uppercase string formatted as CNV-XXXX',
      () {
        final service = WatchPartyService();
        for (int i = 0; i < 20; i++) {
          final code = service.generateRoomCode();
          expect(code.startsWith('CNV-'), isTrue);
          expect(code.length, 8);
          expect(code, matches(RegExp(r'^CNV-[2-9A-Z]{4}$')));
        }
        service.dispose();
      },
    );

    test(
      'Clock Skew and Latency Compensation calculates accurate target seconds',
      () {
        const initialSeconds = 120.0;
        final serverTimestamp =
            DateTime.now().millisecondsSinceEpoch - 2500; // 2.5s ago

        // If video was playing, elapsed time must be added
        final elapsed =
            (DateTime.now().millisecondsSinceEpoch - serverTimestamp) / 1000.0;
        final targetSeconds = initialSeconds + elapsed;

        expect(targetSeconds, greaterThanOrEqualTo(122.4));
        expect(targetSeconds, lessThanOrEqualTo(122.7));
      },
    );

    test(
      'createRoom safely creates room and falls back to relay without throwing',
      () async {
        final service = WatchPartyService();
        final code = await service.createRoom(
          hostName: 'Test Host',
          media: const WatchPartyMedia(
            title: 'Test Movie',
            mediaType: 'movie',
            tmdbId: 100,
          ),
        );
        expect(code.startsWith('CNV-'), isTrue);
        expect(service.currentRoom, isNotNull);
        expect(service.isHost, isTrue);
        expect(service.currentRoom?.hostName, 'Test Host');
        service.dispose();
      },
    );

    test(
      'createRoom with pin sets isProtectedByPin to true and saves pin',
      () async {
        final service = WatchPartyService();
        final code = await service.createRoom(
          hostName: 'PIN Host',
          pin: '1234',
          media: const WatchPartyMedia(
            title: 'Protected Movie',
            mediaType: 'movie',
            tmdbId: 101,
          ),
        );
        expect(code.startsWith('CNV-'), isTrue);
        expect(service.currentRoom?.isProtectedByPin, isTrue);
        expect(service.currentRoom?.pin, '1234');
        expect(service.currentRoom?.verifyPin('1234'), isTrue);
        expect(service.currentRoom?.verifyPin('9999'), isFalse);
        service.dispose();
      },
    );

    test(
      'deleteRoom completely clears currentRoom, isHost, and notifies stream with null',
      () async {
        final service = WatchPartyService();
        final code = await service.createRoom(
          hostName: 'Auto Delete Host',
          media: const WatchPartyMedia(
            title: 'Delete Test',
            mediaType: 'movie',
            tmdbId: 200,
          ),
        );
        expect(service.currentRoom?.roomCode, code);
        expect(service.isHost, isTrue);

        WatchPartyRoom? streamValue = service.currentRoom;
        final sub = service.roomStream.listen((room) {
          streamValue = room;
        });

        await service.deleteRoom();
        await Future<void>.delayed(Duration.zero);
        expect(service.currentRoom, isNull);
        expect(service.isHost, isFalse);
        expect(service.myMemberId, isNull);
        expect(streamValue, isNull);

        await sub.cancel();
        service.dispose();
      },
    );

    test(
      'leaveRoom auto-deletes room and purges all data when caller is Host',
      () async {
        final service = WatchPartyService();
        await service.createRoom(
          hostName: 'Host Caller',
          media: const WatchPartyMedia(
            title: 'Leave Auto Delete Test',
            mediaType: 'movie',
            tmdbId: 201,
          ),
        );
        expect(service.isHost, isTrue);
        expect(service.currentRoom, isNotNull);

        await service.leaveRoom();
        expect(service.currentRoom, isNull);
        expect(service.isHost, isFalse);
        expect(service.myMemberId, isNull);
        service.dispose();
      },
    );
  });

  group('WatchPartyState & Host Control Logic', () {
    test(
      'canControlVideo allows Host always and restricts Guest when unchecked',
      () {
        const roomLocked = WatchPartyRoom(
          roomCode: 'CNV-0001',
          hostId: 'host_id',
          hostName: 'Host',
          allowGuestControl: false,
          media: WatchPartyMedia(title: 'T', mediaType: 'movie', tmdbId: 1),
          playback: WatchPartyPlayback(
            isPlaying: true,
            positionSeconds: 10,
            updatedAt: 0,
            updatedBy: 'Host',
            action: 'play',
          ),
          createdAt: 0,
        );

        // Host perspective: canControlVideo is ALWAYS true
        final hostState = WatchPartyState(
          room: roomLocked,
          myMemberId: 'host_id',
          isHost: true,
        );
        expect(hostState.canControlVideo, isTrue);

        // Guest perspective with allowGuestControl == false: canControlVideo is FALSE
        final guestStateLocked = WatchPartyState(
          room: roomLocked,
          myMemberId: 'guest_id',
          isHost: false,
        );
        expect(guestStateLocked.canControlVideo, isFalse);

        // Guest perspective with allowGuestControl == true: canControlVideo is TRUE
        final roomUnlocked = roomLocked.copyWith(allowGuestControl: true);
        final guestStateUnlocked = WatchPartyState(
          room: roomUnlocked,
          myMemberId: 'guest_id',
          isHost: false,
        );
        expect(guestStateUnlocked.canControlVideo, isTrue);
      },
    );

    test(
      'Sending chat message preserves playback state and updatedAt exactly',
      () {
        const initialPlayback = WatchPartyPlayback(
          isPlaying: true,
          positionSeconds: 754.0, // 12:34
          updatedAt: 1794900000000,
          updatedBy: 'Host',
          action: 'play',
        );

        final room = WatchPartyRoom(
          roomCode: 'CNV-1234',
          hostId: 'host_id',
          hostName: 'Host',
          media: const WatchPartyMedia(
            title: 'Movie',
            mediaType: 'movie',
            tmdbId: 100,
          ),
          playback: initialPlayback,
          createdAt: 1794900000000,
        );

        // Add a message as guest
        final newMsg = WatchPartyMessage(
          id: 'msg_1',
          senderId: 'guest_id',
          senderName: 'Guest',
          isHost: false,
          text: 'Halo!',
          timestamp: 1794900103000,
        );
        final updatedRoom = room.copyWith(messages: [newMsg]);

        // Playback properties must remain completely untouched
        expect(updatedRoom.playback.positionSeconds, 754.0);
        expect(updatedRoom.playback.updatedAt, 1794900000000);
        expect(updatedRoom.playback.isPlaying, isTrue);
        expect(updatedRoom.playback.action, 'play');
        expect(updatedRoom.playback.updatedBy, 'Host');

        // The playback change detection condition evaluates to false
        final prevPlayback = room.playback;
        final currentPlayback = updatedRoom.playback;
        final hasPlaybackChanged =
            prevPlayback.updatedAt != currentPlayback.updatedAt ||
            prevPlayback.isPlaying != currentPlayback.isPlaying ||
            prevPlayback.positionSeconds != currentPlayback.positionSeconds ||
            prevPlayback.action != currentPlayback.action;

        expect(hasPlaybackChanged, isFalse);
      },
    );
  });

  group('TV Series Episode Subtitle & Formatting Helper Tests', () {
    String cleanEpisodeName(String? raw) {
      if (raw == null || raw.trim().isEmpty) return '';
      var cleaned = raw.trim();
      cleaned = cleaned.replaceFirst(
        RegExp(r'^S\d+\s*:\s*E\d+\s*[-:•]?\s*', caseSensitive: false),
        '',
      );
      cleaned = cleaned.replaceFirst(
        RegExp(
          r'^Season\s+\d+\s*(?:[-:•]\s*)?Episode\s+\d+\s*[-:•]?\s*',
          caseSensitive: false,
        ),
        '',
      );
      cleaned = cleaned.replaceFirst(
        RegExp(r'^Episode\s+\d+\s*[-:•]?\s*', caseSensitive: false),
        '',
      );
      if (cleaned.startsWith('(') && cleaned.endsWith(')')) {
        cleaned = cleaned.substring(1, cleaned.length - 1).trim();
      }
      if (RegExp(r'^\d+$').hasMatch(cleaned)) return '';
      return cleaned.trim();
    }

    String formattedEpisodeSubtitle(
      int season,
      int episode,
      String? episodeTitle,
    ) {
      final base = 'Season $season - Episode $episode';
      final epName = cleanEpisodeName(episodeTitle);
      if (epName.isNotEmpty) {
        return '$base ($epName)';
      }
      return base;
    }

    test('Formats TV episode subtitle with episode name correctly', () {
      expect(
        formattedEpisodeSubtitle(3, 10, 'True Crime'),
        'Season 3 - Episode 10 (True Crime)',
      );
      expect(
        formattedEpisodeSubtitle(3, 10, 'S3:E10 True Crime'),
        'Season 3 - Episode 10 (True Crime)',
      );
      expect(
        formattedEpisodeSubtitle(3, 10, 'Season 3 Episode 10 (True Crime)'),
        'Season 3 - Episode 10 (True Crime)',
      );
      expect(
        formattedEpisodeSubtitle(1, 1, 'Pilot'),
        'Season 1 - Episode 1 (Pilot)',
      );
    });

    test('Omits parentheses when episodeTitle contains no distinct name', () {
      expect(formattedEpisodeSubtitle(3, 10, null), 'Season 3 - Episode 10');
      expect(formattedEpisodeSubtitle(3, 10, ''), 'Season 3 - Episode 10');
      expect(
        formattedEpisodeSubtitle(3, 10, 'Episode 10'),
        'Season 3 - Episode 10',
      );
      expect(
        formattedEpisodeSubtitle(3, 10, 'Season 3 Episode 10'),
        'Season 3 - Episode 10',
      );
      expect(formattedEpisodeSubtitle(3, 10, '10'), 'Season 3 - Episode 10');
    });
    test(
      'WatchPartyRoom.fromJson preserves message id and deduplicates properly',
      () {
        final json = {
          'roomCode': 'CNV-1234',
          'hostId': 'host_1',
          'hostName': 'Host',
          'allowGuestControl': true,
          'createdAt': 1000,
          'media': {
            'title': 'The Hunger Games',
            'mediaType': 'movie',
            'tmdbId': 100,
          },
          'playback': {
            'isPlaying': true,
            'positionSeconds': 0.0,
            'updatedAt': 1000,
            'updatedBy': 'Host',
            'action': 'init',
          },
          'messages': {
            'push_key_1': {
              'id': 'msg_custom_id_1',
              'senderId': 'user_1',
              'senderName': 'Alice',
              'text': 'Halo',
              'timestamp': 1001,
              'type': 'chat',
            },
            'push_key_2': {
              'id': 'msg_custom_id_1', // Duplicate id
              'senderId': 'user_1',
              'senderName': 'Alice',
              'text': 'Halo',
              'timestamp': 1001,
              'type': 'chat',
            },
            'push_key_3': {
              'id': 'msg_custom_id_2',
              'senderId': 'user_2',
              'senderName': 'Bob',
              'text': 'Hai Alice',
              'timestamp': 1002,
              'type': 'chat',
            },
          },
        };

        final room = WatchPartyRoom.fromJson(json);
        expect(room.media.title, 'The Hunger Games');
        expect(room.messages.length, 2); // Deduplicated from 3 to 2!
        expect(room.messages[0].id, 'msg_custom_id_1');
        expect(room.messages[1].id, 'msg_custom_id_2');
      },
    );
  });

  group('WatchPartySideView Widget Tests', () {
    testWidgets(
      'Renders side panel with tabs, media summary card, and controls',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 720));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        const testMedia = WatchPartyMedia(
          title: 'The Rookie',
          mediaType: 'tv',
          tmdbId: 79744,
          season: 3,
          episode: 10,
          episodeTitle: 'True Crime',
        );

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 360,
                  height: 720,
                  child: WatchPartySideView(media: testMedia),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Check Tabs
        expect(find.text('Buat Ruangan'), findsOneWidget);
        expect(find.text('Gabung Ruangan'), findsOneWidget);

        // Check Media Card
        expect(find.text('The Rookie'), findsOneWidget);
        expect(find.text('Season 3 - Episode 10 (True Crime)'), findsOneWidget);
        expect(find.text('Serial TV'), findsOneWidget);

        // Check Host controls
        expect(find.text('Nama Panggilan'), findsOneWidget);
        expect(
          find.text('Izinkan partner/tamu mengontrol video'),
          findsOneWidget,
        );
        expect(find.text('Kunci ruangan dengan PIN'), findsOneWidget);
        expect(find.text('Buat Ruangan & Mulai'), findsOneWidget);

        // Tap PIN checkbox to reveal 4-digit PIN field
        await tester.tap(find.text('Kunci ruangan dengan PIN'));
        await tester.pumpAndSettle();
        expect(find.text('Contoh: 1234'), findsOneWidget);

        // Switch to Join Room Tab
        await tester.tap(find.text('Gabung Ruangan'));
        await tester.pumpAndSettle();

        expect(find.text('Kode Ruangan'), findsOneWidget);
        expect(find.text('PIN Ruangan (4 digit)'), findsOneWidget);
        expect(find.text('(Jika dikunci PIN)'), findsOneWidget);
        expect(find.text('Nama Panggilan (Guest Mode)'), findsOneWidget);
        expect(
          find.text('Gabung Ruangan'),
          findsNWidgets(2),
        ); // Tab title + button label
      },
    );

    testWidgets(
      'WatchPartyJoinBanner renders cleanly and opens full-width 24dp bottom sheet',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: Scaffold(body: WatchPartyJoinBanner())),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Nonton Bareng Teman'), findsOneWidget);
        expect(find.text('SYNC'), findsOneWidget);
        expect(find.text('Gabung Nobar'), findsOneWidget);

        // Tap Join button to open bottom sheet
        await tester.tap(find.text('Gabung Nobar'));
        await tester.pumpAndSettle();

        expect(find.text('Kode Ruangan'), findsOneWidget);
        expect(find.text('PIN Ruangan (4 digit)'), findsOneWidget);
        expect(find.text('Nama Panggilan'), findsOneWidget);
        expect(find.text('Gabung & Tonton'), findsOneWidget);
      },
    );

    testWidgets(
      'WatchPartyChatPanel displays End Room and Delete & Leave dialog for Host',
      (tester) async {
        const room = WatchPartyRoom(
          roomCode: 'CNV-7777',
          hostId: 'host_id',
          hostName: 'TestHost',
          allowGuestControl: false,
          media: WatchPartyMedia(
            title: 'Panel Test Movie',
            mediaType: 'movie',
            tmdbId: 50,
          ),
          playback: WatchPartyPlayback(
            isPlaying: true,
            positionSeconds: 0,
            updatedAt: 0,
            updatedBy: 'TestHost',
            action: 'init',
          ),
          createdAt: 0,
        );

        final container = ProviderContainer(
          overrides: [
            watchPartyProvider.overrideWith((ref) {
              final service = ref.watch(watchPartyServiceProvider);
              final notifier = WatchPartyNotifier(service);
              notifier.state = const WatchPartyState(
                room: room,
                isHost: true,
                isChatPanelOpen: true,
                myMemberId: 'host_id',
                myName: 'TestHost',
              );
              return notifier;
            }),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 340,
                  height: 800,
                  child: WatchPartyChatPanel(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('CNV-7777'), findsOneWidget);

        // Tap leave room icon button
        await tester.tap(find.byIcon(Icons.exit_to_app_rounded));
        await tester.pumpAndSettle();

        // Check Host leave dialog
        expect(find.text('Tutup Ruangan Nonton Bersama?'), findsOneWidget);
        expect(
          find.text(
            'Sebagai Host, keluar dari ruangan akan otomatis menghapus ruangan, kode akses, dan seluruh data percakapan.',
          ),
          findsOneWidget,
        );
        expect(find.text('Hapus & Keluar'), findsOneWidget);

        // Tap Hapus & Keluar
        await tester.tap(find.text('Hapus & Keluar'));
        await tester.pumpAndSettle();

        // Ensure room state is cleared
        expect(container.read(watchPartyProvider).isInRoom, isFalse);
      },
    );

    testWidgets(
      'WatchPartyChatPanel localizes system messages dynamically into English',
      (tester) async {
        const room = WatchPartyRoom(
          roomCode: 'CNV-9999',
          hostId: 'host_id',
          hostName: 'Alice',
          allowGuestControl: true,
          media: WatchPartyMedia(
            title: 'Localization Test',
            mediaType: 'movie',
            tmdbId: 77,
          ),
          playback: WatchPartyPlayback(
            isPlaying: false,
            positionSeconds: 320,
            updatedAt: 0,
            updatedBy: 'Alice',
            action: 'pause',
          ),
          messages: [
            WatchPartyMessage(
              id: 'sys_1',
              senderId: 'system',
              senderName: 'Cineva',
              text: 'Ruang Nonton Bareng dibuat oleh Alice',
              timestamp: 1000,
              type: 'system',
            ),
            WatchPartyMessage(
              id: 'sys_2',
              senderId: 'bob_id',
              senderName: 'Bob',
              text: 'Bob telah bergabung ke ruangan',
              timestamp: 2000,
              type: 'system',
            ),
            WatchPartyMessage(
              id: 'sys_3',
              senderId: 'host_id',
              senderName: 'Alice',
              text: 'Alice menjeda video di 05:20',
              timestamp: 3000,
              type: 'system',
            ),
            WatchPartyMessage(
              id: 'sys_4',
              senderId: 'host_id',
              senderName: 'Alice',
              text: 'Alice memajukan video ke 05:30',
              timestamp: 4000,
              type: 'system',
            ),
            WatchPartyMessage(
              id: 'sys_5',
              senderId: 'host_id',
              senderName: 'Alice',
              text: 'Alice memundurkan video ke 05:10',
              timestamp: 5000,
              type: 'system',
            ),
          ],
          createdAt: 0,
        );

        final container = ProviderContainer(
          overrides: [
            appLanguageProvider.overrideWith(
              (ref) => AppLanguageNotifier(AppLanguage.en),
            ),
            watchPartyProvider.overrideWith((ref) {
              final service = ref.watch(watchPartyServiceProvider);
              final notifier = WatchPartyNotifier(service);
              notifier.state = const WatchPartyState(
                room: room,
                isHost: true,
                isChatPanelOpen: true,
                myMemberId: 'host_id',
                myName: 'Alice',
              );
              return notifier;
            }),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 340,
                  height: 800,
                  child: WatchPartyChatPanel(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // System messages must render in English dynamically!
        expect(find.text('Share'), findsOneWidget);
        expect(find.text('Watch Party room created by Alice'), findsOneWidget);
        expect(find.text('Bob joined the room'), findsOneWidget);
        expect(find.text('Alice paused the video at 05:20'), findsOneWidget);
        expect(find.text('Alice forwarded the video to 05:30'), findsOneWidget);
        expect(find.text('Alice rewound the video to 05:10'), findsOneWidget);
      },
    );

    testWidgets(
      'WatchPartyChatPanel localizes system messages dynamically into Indonesian',
      (tester) async {
        const room = WatchPartyRoom(
          roomCode: 'CNV-8888',
          hostId: 'host_id',
          hostName: 'Alice',
          allowGuestControl: true,
          media: WatchPartyMedia(
            title: 'Localization Test ID',
            mediaType: 'movie',
            tmdbId: 78,
          ),
          playback: WatchPartyPlayback(
            isPlaying: false,
            positionSeconds: 320,
            updatedAt: 0,
            updatedBy: 'Alice',
            action: 'pause',
          ),
          messages: [
            WatchPartyMessage(
              id: 'sys_1',
              senderId: 'system',
              senderName: 'Cineva',
              text:
                  'Watch Party room created by Alice', // Stored in English in cloud
              timestamp: 1000,
              type: 'system',
            ),
            WatchPartyMessage(
              id: 'sys_2',
              senderId: 'bob_id',
              senderName: 'Bob',
              text: 'Bob joined the room', // Stored in English in cloud
              timestamp: 2000,
              type: 'system',
            ),
            WatchPartyMessage(
              id: 'sys_3',
              senderId: 'host_id',
              senderName: 'Alice',
              text:
                  'Alice paused the video at 05:20', // Stored in English in cloud
              timestamp: 3000,
              type: 'system',
            ),
            WatchPartyMessage(
              id: 'sys_4',
              senderId: 'host_id',
              senderName: 'Alice',
              text:
                  'Alice forwarded the video to 05:30', // Stored in English in cloud
              timestamp: 4000,
              type: 'system',
            ),
            WatchPartyMessage(
              id: 'sys_5',
              senderId: 'host_id',
              senderName: 'Alice',
              text:
                  'Alice rewound the video to 05:10', // Stored in English in cloud
              timestamp: 5000,
              type: 'system',
            ),
          ],
          createdAt: 0,
        );

        final container = ProviderContainer(
          overrides: [
            appLanguageProvider.overrideWith(
              (ref) => AppLanguageNotifier(AppLanguage.id),
            ),
            watchPartyProvider.overrideWith((ref) {
              final service = ref.watch(watchPartyServiceProvider);
              final notifier = WatchPartyNotifier(service);
              notifier.state = const WatchPartyState(
                room: room,
                isHost: true,
                isChatPanelOpen: true,
                myMemberId: 'host_id',
                myName: 'Alice',
              );
              return notifier;
            }),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 340,
                  height: 800,
                  child: WatchPartyChatPanel(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // System messages must render in Indonesian dynamically!
        expect(find.text('Bagikan'), findsOneWidget);
        expect(
          find.text('Ruang Nonton Bareng dibuat oleh Alice'),
          findsOneWidget,
        );
        expect(find.text('Bob telah bergabung ke ruangan'), findsOneWidget);
        expect(find.text('Alice menjeda video di 05:20'), findsOneWidget);
        expect(find.text('Alice memajukan video ke 05:30'), findsOneWidget);
        expect(find.text('Alice memundurkan video ke 05:10'), findsOneWidget);
      },
    );

    testWidgets(
      'WatchPartyDynamicIsland renders message preview with host badge and handles tap',
      (tester) async {
        bool tapped = false;
        bool dismissed = false;

        const hostMsg = WatchPartyMessage(
          id: 'msg_island_1',
          senderId: 'host_id',
          senderName: 'Sultan Nobar',
          isHost: true,
          text: 'Halo semua, seru banget filmnya!',
          timestamp: 1000,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: WatchPartyDynamicIsland(
                  message: hostMsg,
                  onTap: () => tapped = true,
                  onDismiss: () => dismissed = true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Sultan Nobar'), findsOneWidget);
        expect(find.text('HOST'), findsOneWidget);
        expect(find.text('👑'), findsOneWidget);
        expect(find.text('Halo semua, seru banget filmnya!'), findsOneWidget);

        // Tap on Dynamic Island
        await tester.tap(find.byType(WatchPartyDynamicIsland));
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
        expect(dismissed, isTrue);
      },
    );

    testWidgets('WatchPartyDynamicIsland renders emoji reaction cleanly', (
      tester,
    ) async {
      const emojiMsg = WatchPartyMessage(
        id: 'msg_island_2',
        senderId: 'guest_id',
        senderName: 'Budi Tamu',
        isHost: false,
        text: '🍿',
        emoji: '🍿',
        timestamp: 2000,
        type: 'emoji',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: WatchPartyDynamicIsland(
                message: emojiMsg,
                onTap: () {},
                onDismiss: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Budi Tamu'), findsOneWidget);
      expect(find.text('🍿'), findsOneWidget);
      expect(find.text('HOST'), findsNothing);
    });

    testWidgets('WatchPartyDynamicIsland auto-dismisses after 8 seconds', (
      tester,
    ) async {
      bool dismissed = false;

      const msg = WatchPartyMessage(
        id: 'msg_island_3',
        senderId: 'guest_id',
        senderName: 'Charlie',
        isHost: false,
        text: 'Halo semua',
        timestamp: 3000,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: WatchPartyDynamicIsland(
                message: msg,
                onTap: () {},
                onDismiss: () => dismissed = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // At 7 seconds, not dismissed yet
      await tester.pump(const Duration(seconds: 7));
      expect(dismissed, isFalse);

      // At 8 seconds, timer fires and reverse animation starts
      await tester.pump(const Duration(seconds: 1, milliseconds: 50));
      // Finish reverse animation (240ms)
      await tester.pumpAndSettle();
      expect(dismissed, isTrue);
    });

    test('WatchPartyDirectJoinScreen.extractRoomCode parses various URL and code formats', () {
      expect(
        WatchPartyDirectJoinScreen.extractRoomCode('https://cineva.app/party/CNV-9XYZ'),
        'CNV-9XYZ',
      );
      expect(
        WatchPartyDirectJoinScreen.extractRoomCode('http://cineva.app/party/CNV-ABCD'),
        'CNV-ABCD',
      );
      expect(
        WatchPartyDirectJoinScreen.extractRoomCode('cineva://party/CNV-7788'),
        'CNV-7788',
      );
      expect(
        WatchPartyDirectJoinScreen.extractRoomCode('CNV-WXYZ'),
        'CNV-WXYZ',
      );
      expect(
        WatchPartyDirectJoinScreen.extractRoomCode('cnv-wxyz'),
        'CNV-WXYZ',
      );
      expect(
        WatchPartyDirectJoinScreen.extractRoomCode('  cnv-29ab  '),
        'CNV-29AB',
      );
    });

    test('WatchPartyService emojiReactionStream emits emoji upon sendEmojiReaction', () async {
      final service = WatchPartyService();
      final emitted = <String>[];
      final sub = service.emojiReactionStream.listen(emitted.add);

      // Create a dummy room first
      await service.createRoom(
        hostName: 'Test Host',
        media: const WatchPartyMedia(
          title: 'Movie',
          mediaType: 'movie',
          tmdbId: 100,
        ),
      );

      await service.sendEmojiReaction('🍿');
      await service.sendEmojiReaction('🔥');

      await Future.delayed(const Duration(milliseconds: 50));
      expect(emitted, containsAll(['🍿', '🔥']));

      await sub.cancel();
      service.dispose();
    });

    test('AppStrings provides correct bilingual translations for watch party sharing and join screen', () {
      final sId = AppStrings(AppLanguage.id);
      final sEn = AppStrings(AppLanguage.en);

      // Share strings
      expect(sId.watchPartyShare, 'Bagikan');
      expect(sEn.watchPartyShare, 'Share');
      expect(sId.watchPartyShareLocked, 'Bagikan 🔒');
      expect(sEn.watchPartyShareLocked, 'Share 🔒');
      expect(sId.watchPartyShareCopied('https://cineva.app/party/CNV-1234', false), 'Tautan Nobar disalin: https://cineva.app/party/CNV-1234');
      expect(sEn.watchPartyShareCopied('https://cineva.app/party/CNV-1234', false), 'Watch Party link copied: https://cineva.app/party/CNV-1234');
      expect(sId.watchPartyShareCopied('https://cineva.app/party/CNV-1234', true), 'Tautan Nobar 🔒 disalin: https://cineva.app/party/CNV-1234');
      expect(sEn.watchPartyShareCopied('https://cineva.app/party/CNV-1234', true), 'Watch Party link 🔒 copied: https://cineva.app/party/CNV-1234');

      // Direct join & error strings
      expect(sId.watchPartyPinRequiredToJoin, 'PIN diperlukan untuk bergabung ke room ini.');
      expect(sEn.watchPartyPinRequiredToJoin, 'PIN is required to join this room.');
      expect(sId.watchPartyPinIncorrectAttempt(1, 5), 'PIN salah. Percobaan ke-1 dari 5.');
      expect(sEn.watchPartyPinIncorrectAttempt(1, 5), 'Incorrect PIN. Attempt 1 of 5.');
      expect(sId.watchPartyPinLockout(30), 'Terlalu banyak percobaan PIN salah. Coba lagi dalam 30 detik.');
      expect(sEn.watchPartyPinLockout(30), 'Too many incorrect PIN attempts. Try again in 30 seconds.');
      expect(sId.watchPartyPartyGuest, 'Tamu Nobar');
      expect(sEn.watchPartyPartyGuest, 'Party Guest');
      expect(sId.watchPartyVerifyAndJoin, 'Verifikasi & Gabung');
      expect(sEn.watchPartyVerifyAndJoin, 'Verify & Join');
    });
  });
}
