/// Represents a participant in a Watch Party room.
class WatchPartyMember {
  final String id;
  final String name;
  final bool isHost;
  final int joinedAt;
  final int lastSeen;

  const WatchPartyMember({
    required this.id,
    required this.name,
    this.isHost = false,
    required this.joinedAt,
    required this.lastSeen,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isHost': isHost,
        'joinedAt': joinedAt,
        'lastSeen': lastSeen,
      };

  factory WatchPartyMember.fromJson(Map<dynamic, dynamic> json) {
    return WatchPartyMember(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? 'Penonton',
      isHost: (json['isHost'] as bool?) ?? false,
      joinedAt: (json['joinedAt'] as num?)?.toInt() ?? 0,
      lastSeen: (json['lastSeen'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Information about the media currently playing in the room.
class WatchPartyMedia {
  final String title;
  final String mediaType; // 'movie' or 'tv'
  final int tmdbId;
  final String? imdbId;
  final int? season;
  final int? episode;
  final String? episodeTitle;
  final String? posterPath;
  final String? backdropPath;
  final String? streamServer;

  const WatchPartyMedia({
    required this.title,
    required this.mediaType,
    required this.tmdbId,
    this.imdbId,
    this.season,
    this.episode,
    this.episodeTitle,
    this.posterPath,
    this.backdropPath,
    this.streamServer,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'mediaType': mediaType,
        'tmdbId': tmdbId,
        'imdbId': imdbId,
        'season': season,
        'episode': episode,
        'episodeTitle': episodeTitle,
        'posterPath': posterPath,
        'backdropPath': backdropPath,
        'streamServer': streamServer,
      };

  factory WatchPartyMedia.fromJson(Map<dynamic, dynamic> json) {
    return WatchPartyMedia(
      title: (json['title'] as String?) ?? '',
      mediaType: (json['mediaType'] as String?) ?? 'movie',
      tmdbId: (json['tmdbId'] as num?)?.toInt() ?? 0,
      imdbId: json['imdbId'] as String?,
      season: (json['season'] as num?)?.toInt(),
      episode: (json['episode'] as num?)?.toInt(),
      episodeTitle: json['episodeTitle'] as String?,
      posterPath: json['posterPath'] as String?,
      backdropPath: json['backdropPath'] as String?,
      streamServer: json['streamServer'] as String?,
    );
  }
}

/// Real-time playback synchronization state.
class WatchPartyPlayback {
  final bool isPlaying;
  final double positionSeconds;
  final int updatedAt; // Milliseconds since epoch
  final String updatedBy;
  final String action; // 'play', 'pause', 'seek', 'init'

  const WatchPartyPlayback({
    required this.isPlaying,
    required this.positionSeconds,
    required this.updatedAt,
    required this.updatedBy,
    required this.action,
  });

  Map<String, dynamic> toJson() => {
        'isPlaying': isPlaying,
        'positionSeconds': positionSeconds,
        'updatedAt': updatedAt,
        'updatedBy': updatedBy,
        'action': action,
      };

  factory WatchPartyPlayback.fromJson(Map<dynamic, dynamic> json) {
    return WatchPartyPlayback(
      isPlaying: (json['isPlaying'] as bool?) ?? false,
      positionSeconds: (json['positionSeconds'] as num?)?.toDouble() ?? 0.0,
      updatedAt: (json['updatedAt'] as num?)?.toInt() ?? 0,
      updatedBy: (json['updatedBy'] as String?) ?? 'Host',
      action: (json['action'] as String?) ?? 'init',
    );
  }

  WatchPartyPlayback copyWith({
    bool? isPlaying,
    double? positionSeconds,
    int? updatedAt,
    String? updatedBy,
    String? action,
  }) {
    return WatchPartyPlayback(
      isPlaying: isPlaying ?? this.isPlaying,
      positionSeconds: positionSeconds ?? this.positionSeconds,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      action: action ?? this.action,
    );
  }
}

/// Chat and notification messages within a Watch Party room.
class WatchPartyMessage {
  final String id;
  final String senderId;
  final String senderName;
  final bool isHost;
  final String text;
  final String? emoji;
  final int timestamp;
  final String type; // 'chat', 'system', 'emoji'

  const WatchPartyMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.isHost = false,
    required this.text,
    this.emoji,
    required this.timestamp,
    this.type = 'chat',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'senderName': senderName,
        'isHost': isHost,
        'text': text,
        'emoji': emoji,
        'timestamp': timestamp,
        'type': type,
      };

  factory WatchPartyMessage.fromJson(Map<dynamic, dynamic> json) {
    return WatchPartyMessage(
      id: (json['id'] as String?) ?? '',
      senderId: (json['senderId'] as String?) ?? '',
      senderName: (json['senderName'] as String?) ?? 'Anonim',
      isHost: (json['isHost'] as bool?) ?? false,
      text: (json['text'] as String?) ?? '',
      emoji: json['emoji'] as String?,
      timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
      type: (json['type'] as String?) ?? 'chat',
    );
  }
}

/// Represents the entire Watch Party Room state.
class WatchPartyRoom {
  final String roomCode;
  final String hostId;
  final String hostName;
  final bool allowGuestControl; // Host toggle checkbox
  final WatchPartyMedia media;
  final WatchPartyPlayback playback;
  final Map<String, WatchPartyMember> members;
  final List<WatchPartyMessage> messages;
  final int createdAt;

  const WatchPartyRoom({
    required this.roomCode,
    required this.hostId,
    required this.hostName,
    this.allowGuestControl = false,
    required this.media,
    required this.playback,
    this.members = const {},
    this.messages = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'roomCode': roomCode,
        'hostId': hostId,
        'hostName': hostName,
        'allowGuestControl': allowGuestControl,
        'media': media.toJson(),
        'playback': playback.toJson(),
        'members': members.map((k, v) => MapEntry(k, v.toJson())),
        'messages': {for (final m in messages) m.id: m.toJson()},
        'createdAt': createdAt,
      };

  factory WatchPartyRoom.fromJson(Map<dynamic, dynamic> json) {
    final rawMembers = json['members'];
    final membersMap = <String, WatchPartyMember>{};
    if (rawMembers is Map) {
      rawMembers.forEach((k, v) {
        if (v is Map) {
          membersMap[k.toString()] =
              WatchPartyMember.fromJson(v.cast<dynamic, dynamic>());
        }
      });
    }

    final rawMessages = json['messages'];
    final messageList = <WatchPartyMessage>[];
    if (rawMessages is Map) {
      rawMessages.forEach((k, v) {
        if (v is Map) {
          final m = v.cast<dynamic, dynamic>();
          messageList.add(WatchPartyMessage.fromJson({
            ...m,
            'id': k.toString(),
          }));
        }
      });
      messageList.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } else if (rawMessages is List) {
      for (final v in rawMessages) {
        if (v is Map) {
          messageList.add(
              WatchPartyMessage.fromJson(v.cast<dynamic, dynamic>()));
        }
      }
      messageList.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }

    return WatchPartyRoom(
      roomCode: (json['roomCode'] as String?) ?? '',
      hostId: (json['hostId'] as String?) ?? '',
      hostName: (json['hostName'] as String?) ?? 'Host',
      allowGuestControl: (json['allowGuestControl'] as bool?) ?? false,
      media: WatchPartyMedia.fromJson(
        (json['media'] as Map?)?.cast<dynamic, dynamic>() ?? {},
      ),
      playback: WatchPartyPlayback.fromJson(
        (json['playback'] as Map?)?.cast<dynamic, dynamic>() ?? {},
      ),
      members: membersMap,
      messages: messageList,
      createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
    );
  }

  WatchPartyRoom copyWith({
    String? roomCode,
    String? hostId,
    String? hostName,
    bool? allowGuestControl,
    WatchPartyMedia? media,
    WatchPartyPlayback? playback,
    Map<String, WatchPartyMember>? members,
    List<WatchPartyMessage>? messages,
    int? createdAt,
  }) {
    return WatchPartyRoom(
      roomCode: roomCode ?? this.roomCode,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      allowGuestControl: allowGuestControl ?? this.allowGuestControl,
      media: media ?? this.media,
      playback: playback ?? this.playback,
      members: members ?? this.members,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

