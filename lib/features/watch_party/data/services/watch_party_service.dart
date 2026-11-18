import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:dio/dio.dart';

import '../../domain/models/watch_party_room.dart';

/// Core networking service for Watch Party rooms, sync play, live chat, and emoji reactions.
class WatchPartyService {
  static const String _rtdbBaseUrl =
      'https://cineva-platform-default-rtdb.asia-southeast1.firebasedatabase.app';

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  StreamSubscription<DatabaseEvent>? _nativeRoomSub;
  Timer? _restPollingTimer;

  final StreamController<WatchPartyRoom?> _roomController =
      StreamController<WatchPartyRoom?>.broadcast();
  Stream<WatchPartyRoom?> get roomStream => _roomController.stream;

  WatchPartyRoom? _currentRoom;
  WatchPartyRoom? get currentRoom => _currentRoom;

  String? _myMemberId;
  String? get myMemberId => _myMemberId;

  String? _myName;
  String? get myName => _myName;

  bool _isHost = false;
  bool get isHost => _isHost;

  bool get isNativeSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Generates a human-friendly 6-character room code (e.g., 'CNV-8492').
  String generateRoomCode() {
    const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    final random = Random();
    final code = List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
    return 'CNV-$code';
  }

  /// Determines current member ID (Firebase UID if signed in, or generated unique ID).
  String _resolveMemberId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.uid.isNotEmpty) {
      return user.uid;
    }
    final rand = Random().nextInt(999999).toString().padLeft(6, '0');
    return 'guest_${DateTime.now().millisecondsSinceEpoch}_$rand';
  }

  /// Creates a new Watch Party room as Host.
  Future<String> createRoom({
    required String hostName,
    required WatchPartyMedia media,
    bool allowGuestControl = false,
  }) async {
    final roomCode = generateRoomCode();
    _myMemberId = _resolveMemberId();
    _myName = hostName.trim().isNotEmpty ? hostName.trim() : 'Host';
    _isHost = true;

    final now = DateTime.now().millisecondsSinceEpoch;
    final initialPlayback = WatchPartyPlayback(
      isPlaying: true,
      positionSeconds: 0.0,
      updatedAt: now,
      updatedBy: _myName!,
      action: 'init',
    );

    final hostMember = WatchPartyMember(
      id: _myMemberId!,
      name: _myName!,
      isHost: true,
      joinedAt: now,
      lastSeen: now,
    );

    final initialMessage = WatchPartyMessage(
      id: 'sys_created',
      senderId: 'system',
      senderName: 'Cineva',
      isHost: false,
      text: 'Ruang Nonton Bareng dibuat oleh $_myName',
      timestamp: now,
      type: 'system',
    );

    final room = WatchPartyRoom(
      roomCode: roomCode,
      hostId: _myMemberId!,
      hostName: _myName!,
      allowGuestControl: allowGuestControl,
      media: media,
      playback: initialPlayback,
      members: {_myMemberId!: hostMember},
      messages: [initialMessage],
      createdAt: now,
    );

    await _writeRoomToCloud(room);
    _currentRoom = room;
    _roomController.add(room);

    _startListeningToRoom(roomCode);
    return roomCode;
  }

  /// Joins an existing Watch Party room as a Member (Guest or Signed-in user).
  Future<bool> joinRoom({
    required String roomCode,
    required String memberName,
  }) async {
    final cleanCode = roomCode.trim().toUpperCase();
    _myMemberId = _resolveMemberId();
    _myName = memberName.trim().isNotEmpty ? memberName.trim() : 'Tamu';
    _isHost = false;

    final existingRoom = await _fetchRoomFromCloud(cleanCode);
    if (existingRoom == null) {
      return false;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final myMember = WatchPartyMember(
      id: _myMemberId!,
      name: _myName!,
      isHost: false,
      joinedAt: now,
      lastSeen: now,
    );

    final joinMessage = WatchPartyMessage(
      id: 'join_${_myMemberId}_$now',
      senderId: _myMemberId!,
      senderName: _myName!,
      isHost: false,
      text: '$_myName telah bergabung ke ruangan',
      timestamp: now,
      type: 'system',
    );

    // Add member and system message to room
    if (isNativeSupported) {
      final roomRef =
          FirebaseDatabase.instance.ref('watch_party_rooms/$cleanCode');
      await roomRef.child('members/$_myMemberId').set(myMember.toJson());
      await roomRef.child('messages').push().set(joinMessage.toJson());
    } else {
      await _dio.put(
        '$_rtdbBaseUrl/watch_party_rooms/$cleanCode/members/$_myMemberId.json',
        data: myMember.toJson(),
      );
      await _dio.post(
        '$_rtdbBaseUrl/watch_party_rooms/$cleanCode/messages.json',
        data: joinMessage.toJson(),
      );
    }

    _currentRoom = existingRoom;
    _startListeningToRoom(cleanCode);
    return true;
  }

  /// Synchronizes video Play, Pause, or Seek state across the room.
  Future<void> updatePlayback({
    required bool isPlaying,
    required double positionSeconds,
    required String action,
  }) async {
    if (_currentRoom == null) return;
    final code = _currentRoom!.roomCode;

    // Check permission: If user is not host and guest control is disabled, block action.
    if (!_isHost && !_currentRoom!.allowGuestControl) {
      debugPrint('[WatchPartyService] Guest control is disabled by Host.');
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final updatedPlayback = WatchPartyPlayback(
      isPlaying: isPlaying,
      positionSeconds: positionSeconds,
      updatedAt: now,
      updatedBy: _myName ?? 'User',
      action: action,
    );

    // Build system message for seek or pause
    WatchPartyMessage? actionMsg;
    final formattedTime = _formatDuration(positionSeconds);
    if (action == 'pause') {
      actionMsg = WatchPartyMessage(
        id: 'act_${now}_pause',
        senderId: _myMemberId ?? 'system',
        senderName: _myName ?? 'User',
        isHost: _isHost,
        text: '$_myName menjeda video di $formattedTime',
        timestamp: now,
        type: 'system',
      );
    } else if (action == 'seek') {
      actionMsg = WatchPartyMessage(
        id: 'act_${now}_seek',
        senderId: _myMemberId ?? 'system',
        senderName: _myName ?? 'User',
        isHost: _isHost,
        text: '$_myName melompat ke $formattedTime',
        timestamp: now,
        type: 'system',
      );
    }

    try {
      if (isNativeSupported) {
        final roomRef = FirebaseDatabase.instance.ref('watch_party_rooms/$code');
        await roomRef.child('playback').set(updatedPlayback.toJson());
        if (actionMsg != null) {
          await roomRef.child('messages').push().set(actionMsg.toJson());
        }
      } else {
        await _dio.patch(
          '$_rtdbBaseUrl/watch_party_rooms/$code/playback.json',
          data: updatedPlayback.toJson(),
        );
        if (actionMsg != null) {
          await _dio.post(
            '$_rtdbBaseUrl/watch_party_rooms/$code/messages.json',
            data: actionMsg.toJson(),
          );
        }
      }
    } catch (e) {
      debugPrint('[WatchPartyService] Failed updating playback: $e');
    }
  }

  /// Host setting: Toggle whether guests/partners are permitted to control video playback.
  Future<void> setAllowGuestControl(bool allow) async {
    if (_currentRoom == null || !_isHost) return;
    final code = _currentRoom!.roomCode;
    final now = DateTime.now().millisecondsSinceEpoch;

    final sysMsg = WatchPartyMessage(
      id: 'perm_$now',
      senderId: _myMemberId ?? 'host',
      senderName: _myName ?? 'Host',
      isHost: true,
      text: allow
          ? 'Host mengizinkan peserta mengontrol video (Play/Pause/Seek)'
          : 'Host mengunci kontrol video hanya untuk Host',
      timestamp: now,
      type: 'system',
    );

    try {
      if (isNativeSupported) {
        final roomRef = FirebaseDatabase.instance.ref('watch_party_rooms/$code');
        await roomRef.child('allowGuestControl').set(allow);
        await roomRef.child('messages').push().set(sysMsg.toJson());
      } else {
        await _dio.patch(
          '$_rtdbBaseUrl/watch_party_rooms/$code.json',
          data: {'allowGuestControl': allow},
        );
        await _dio.post(
          '$_rtdbBaseUrl/watch_party_rooms/$code/messages.json',
          data: sysMsg.toJson(),
        );
      }
    } catch (e) {
      debugPrint('[WatchPartyService] Failed toggling guest control: $e');
    }
  }

  /// Sends a text message to the live chat panel.
  Future<void> sendMessage(String text) async {
    if (_currentRoom == null || text.trim().isEmpty) return;
    final code = _currentRoom!.roomCode;
    final now = DateTime.now().millisecondsSinceEpoch;

    final msg = WatchPartyMessage(
      id: 'msg_${now}_$_myMemberId',
      senderId: _myMemberId ?? 'user',
      senderName: _myName ?? 'User',
      isHost: _isHost,
      text: text.trim(),
      timestamp: now,
      type: 'chat',
    );

    try {
      if (isNativeSupported) {
        await FirebaseDatabase.instance
            .ref('watch_party_rooms/$code/messages')
            .push()
            .set(msg.toJson());
      } else {
        await _dio.post(
          '$_rtdbBaseUrl/watch_party_rooms/$code/messages.json',
          data: msg.toJson(),
        );
      }
    } catch (e) {
      debugPrint('[WatchPartyService] Send message error: $e');
    }
  }

  /// Sends a quick emoji reaction to trigger floating animation and chat feed.
  Future<void> sendEmojiReaction(String emoji) async {
    if (_currentRoom == null || emoji.trim().isEmpty) return;
    final code = _currentRoom!.roomCode;
    final now = DateTime.now().millisecondsSinceEpoch;

    final msg = WatchPartyMessage(
      id: 'emoji_${now}_$_myMemberId',
      senderId: _myMemberId ?? 'user',
      senderName: _myName ?? 'User',
      isHost: _isHost,
      text: emoji,
      emoji: emoji,
      timestamp: now,
      type: 'emoji',
    );

    try {
      if (isNativeSupported) {
        await FirebaseDatabase.instance
            .ref('watch_party_rooms/$code/messages')
            .push()
            .set(msg.toJson());
      } else {
        await _dio.post(
          '$_rtdbBaseUrl/watch_party_rooms/$code/messages.json',
          data: msg.toJson(),
        );
      }
    } catch (e) {
      debugPrint('[WatchPartyService] Send emoji error: $e');
    }
  }

  /// Leaves the active Watch Party room and cleans up listeners.
  Future<void> leaveRoom() async {
    if (_currentRoom != null && _myMemberId != null) {
      final code = _currentRoom!.roomCode;
      final now = DateTime.now().millisecondsSinceEpoch;
      final leaveMsg = WatchPartyMessage(
        id: 'leave_${_myMemberId}_$now',
        senderId: _myMemberId!,
        senderName: _myName ?? 'User',
        isHost: _isHost,
        text: '$_myName meninggalkan ruangan',
        timestamp: now,
        type: 'system',
      );

      try {
        if (isNativeSupported) {
          final roomRef =
              FirebaseDatabase.instance.ref('watch_party_rooms/$code');
          await roomRef.child('members/$_myMemberId').remove();
          await roomRef.child('messages').push().set(leaveMsg.toJson());
        } else {
          await _dio.delete(
            '$_rtdbBaseUrl/watch_party_rooms/$code/members/$_myMemberId.json',
          );
          await _dio.post(
            '$_rtdbBaseUrl/watch_party_rooms/$code/messages.json',
            data: leaveMsg.toJson(),
          );
        }
      } catch (e) {
        debugPrint('[WatchPartyService] Leave room error: $e');
      }
    }

    _stopListening();
    _currentRoom = null;
    _myMemberId = null;
    _myName = null;
    _isHost = false;
    _roomController.add(null);
  }

  void _startListeningToRoom(String roomCode) {
    _stopListening();

    if (isNativeSupported) {
      final roomRef =
          FirebaseDatabase.instance.ref('watch_party_rooms/$roomCode');
      _nativeRoomSub = roomRef.onValue.listen((event) {
        final val = event.snapshot.value;
        if (val is Map) {
          try {
            final rawMap = val.cast<String, dynamic>();
            final room = WatchPartyRoom.fromJson(rawMap);
            _currentRoom = room;
            _roomController.add(room);
          } catch (e) {
            debugPrint('[WatchPartyService] Parse room update error: $e');
          }
        }
      }, onError: (e) {
        debugPrint('[WatchPartyService] Room stream error: $e');
      });
    } else {
      // Desktop / Web polling fallback (every 1 second during active watch party)
      _restPollingTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
        final room = await _fetchRoomFromCloud(roomCode);
        if (room != null) {
          _currentRoom = room;
          _roomController.add(room);
        }
      });
    }
  }

  void _stopListening() {
    _nativeRoomSub?.cancel();
    _nativeRoomSub = null;
    _restPollingTimer?.cancel();
    _restPollingTimer = null;
  }

  Future<void> _writeRoomToCloud(WatchPartyRoom room) async {
    if (isNativeSupported) {
      final roomRef =
          FirebaseDatabase.instance.ref('watch_party_rooms/${room.roomCode}');
      await roomRef.set(room.toJson());
    } else {
      await _dio.put(
        '$_rtdbBaseUrl/watch_party_rooms/${room.roomCode}.json',
        data: room.toJson(),
      );
    }
  }

  Future<WatchPartyRoom?> _fetchRoomFromCloud(String roomCode) async {
    try {
      if (isNativeSupported) {
        final snapshot = await FirebaseDatabase.instance
            .ref('watch_party_rooms/$roomCode')
            .get();
        if (snapshot.exists && snapshot.value is Map) {
          final rawMap = (snapshot.value as Map).cast<String, dynamic>();
          return WatchPartyRoom.fromJson(rawMap);
        }
      } else {
        final resp = await _dio.get(
          '$_rtdbBaseUrl/watch_party_rooms/$roomCode.json',
        );
        if (resp.data != null && resp.data is Map) {
          return WatchPartyRoom.fromJson(
            (resp.data as Map).cast<String, dynamic>(),
          );
        }
      }
    } catch (e) {
      debugPrint('[WatchPartyService] Fetch room error: $e');
    }
    return null;
  }

  String _formatDuration(double totalSeconds) {
    final d = Duration(seconds: totalSeconds.toInt());
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    final minStr = minutes.toString().padLeft(2, '0');
    final secStr = seconds.toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minStr:$secStr' : '$minStr:$secStr';
  }

  void dispose() {
    _stopListening();
    _roomController.close();
  }
}

