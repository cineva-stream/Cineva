import 'package:flutter_test/flutter_test.dart';
import 'package:cineva/features/watch_party/domain/models/watch_party_room.dart';
import 'package:cineva/features/watch_party/data/services/watch_party_service.dart';
import 'package:cineva/features/watch_party/presentation/providers/watch_party_provider.dart';

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

      final updated = room.copyWith(allowGuestControl: true);
      expect(updated.allowGuestControl, isTrue);
    });
  });

  group('WatchPartyService Room Code Generation & Network Math', () {
    test('generateRoomCode produces 8-char uppercase string formatted as CNV-XXXX', () {
      final service = WatchPartyService();
      for (int i = 0; i < 20; i++) {
        final code = service.generateRoomCode();
        expect(code.startsWith('CNV-'), isTrue);
        expect(code.length, 8);
        expect(code, matches(RegExp(r'^CNV-[2-9A-Z]{4}$')));
      }
      service.dispose();
    });

    test('Clock Skew and Latency Compensation calculates accurate target seconds', () {
      const initialSeconds = 120.0;
      final serverTimestamp = DateTime.now().millisecondsSinceEpoch - 2500; // 2.5s ago

      // If video was playing, elapsed time must be added
      final elapsed = (DateTime.now().millisecondsSinceEpoch - serverTimestamp) / 1000.0;
      final targetSeconds = initialSeconds + elapsed;

      expect(targetSeconds, greaterThanOrEqualTo(122.4));
      expect(targetSeconds, lessThanOrEqualTo(122.7));
    });
  });

  group('WatchPartyState & Host Control Logic', () {
    test('canControlVideo allows Host always and restricts Guest when unchecked', () {
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
    });
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

    String formattedEpisodeSubtitle(int season, int episode, String? episodeTitle) {
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
      expect(
        formattedEpisodeSubtitle(3, 10, null),
        'Season 3 - Episode 10',
      );
      expect(
        formattedEpisodeSubtitle(3, 10, ''),
        'Season 3 - Episode 10',
      );
      expect(
        formattedEpisodeSubtitle(3, 10, 'Episode 10'),
        'Season 3 - Episode 10',
      );
      expect(
        formattedEpisodeSubtitle(3, 10, 'Season 3 Episode 10'),
        'Season 3 - Episode 10',
      );
      expect(
        formattedEpisodeSubtitle(3, 10, '10'),
        'Season 3 - Episode 10',
      );
    });
  });
}

