import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:dio/dio.dart';

import '../../domain/models/watch_party_room.dart';

/// Core networking service for Watch Party rooms, sync play, live chat, and emoji reactions.
/// Supports Firebase Realtime Database with an automatic zero-config Realtime Cloud Relay fallback.
class WatchPartyService {
  static const String _rtdbBaseUrl =
      'https://cineva-platform-default-rtdb.asia-southeast1.firebasedatabase.app';

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 6),
    receiveTimeout: const Duration(seconds: 6),
  ));

  StreamSubscription<DatabaseEvent>? _nativeRoomSub;
  Timer? _pollingTimer;

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

  bool _isUsingRelay = false;
  bool get isUsingRelay => _isUsingRelay;

  bool get isNativeSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Generates a human-friendly 6-character room code (e.g., 'CNV-8492').
  String generateRoomCode() {
    const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    final random = Random();
    final code =
        List.generate(4, (_) => chars[random.nextInt(chars.length)]).join();
    return 'CNV-$code';
  }

  /// Determines current member ID (Firebase UID if signed in, or generated unique ID).
  String _resolveMemberId() {
    try {
      if (isNativeSupported && Firebase.apps.isNotEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && user.uid.isNotEmpty) {
          return user.uid;
        }
      }
    } catch (e) {
      debugPrint('[WatchPartyService] Member ID resolve note: $e');
    }
    final rand = Random().nextInt(999999).toString().padLeft(6, '0');
    return 'guest_${DateTime.now().millisecondsSinceEpoch}_$rand';
  }

  /// Creates a new Watch Party room as Host.
  Future<String> createRoom({
    required String hostName,
    required WatchPartyMedia media,
    bool allowGuestControl = false,
    String? pin,
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

    final cleanPin = pin?.trim().isNotEmpty == true ? pin!.trim() : null;

    final room = WatchPartyRoom(
      roomCode: roomCode,
      hostId: _myMemberId!,
      hostName: _myName!,
      allowGuestControl: allowGuestControl,
      pin: cleanPin,
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

  /// Fetches an existing Watch Party room by its code (Firebase RTDB or Cloud Relay).
  Future<WatchPartyRoom?> fetchRoom(String roomCode) async {
    return _fetchRoomFromCloud(roomCode.trim().toUpperCase());
  }

  /// Joins an existing Watch Party room as a Member (Guest or Signed-in user).
  Future<bool> joinRoom({
    required String roomCode,
    required String memberName,
    String? pin,
  }) async {
    final cleanCode = roomCode.trim().toUpperCase();
    _myMemberId = _resolveMemberId();
    _myName = memberName.trim().isNotEmpty ? memberName.trim() : 'Tamu';
    _isHost = false;

    final existingRoom = await _fetchRoomFromCloud(cleanCode);
    if (existingRoom == null) {
      return false;
    }

    if (existingRoom.isProtectedByPin && !existingRoom.verifyPin(pin)) {
      debugPrint('[WatchPartyService] Access denied: Incorrect room PIN.');
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

    // 1. Update native Firebase if not using relay
    if (!_isUsingRelay) {
      try {
        if (isNativeSupported && Firebase.apps.isNotEmpty) {
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
      } catch (e) {
        debugPrint('[WatchPartyService] Firebase join note: $e');
        _isUsingRelay = true;
      }
    }

    // 2. Publish to Cloud Relay
    await _publishToRelay(cleanCode, {
      'event': 'member_join',
      'member': myMember.toJson(),
      'message': joinMessage.toJson(),
    });

    // Update local state with joined member
    final updatedMembers = Map<String, WatchPartyMember>.from(
      existingRoom.members,
    );
    updatedMembers[_myMemberId!] = myMember;
    final updatedMessages = List<WatchPartyMessage>.from(
      existingRoom.messages,
    )..add(joinMessage);

    _currentRoom = existingRoom.copyWith(
      members: updatedMembers,
      messages: updatedMessages,
    );
    _roomController.add(_currentRoom);

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
    } else if (action == 'play') {
      actionMsg = WatchPartyMessage(
        id: 'act_${now}_play',
        senderId: _myMemberId ?? 'system',
        senderName: _myName ?? 'User',
        isHost: _isHost,
        text: '$_myName memutar video di $formattedTime',
        timestamp: now,
        type: 'system',
      );
    } else if (action == 'forward') {
      actionMsg = WatchPartyMessage(
        id: 'act_${now}_forward',
        senderId: _myMemberId ?? 'system',
        senderName: _myName ?? 'User',
        isHost: _isHost,
        text: '$_myName memajukan video ke $formattedTime',
        timestamp: now,
        type: 'system',
      );
    } else if (action == 'rewind') {
      actionMsg = WatchPartyMessage(
        id: 'act_${now}_rewind',
        senderId: _myMemberId ?? 'system',
        senderName: _myName ?? 'User',
        isHost: _isHost,
        text: '$_myName memundurkan video ke $formattedTime',
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

    if (!_isUsingRelay) {
      try {
        if (isNativeSupported && Firebase.apps.isNotEmpty) {
          final roomRef =
              FirebaseDatabase.instance.ref('watch_party_rooms/$code');
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
        debugPrint('[WatchPartyService] Firebase updatePlayback note: $e');
        _isUsingRelay = true;
      }
    }

    await _publishToRelay(code, {
      'event': 'playback',
      'playback': updatedPlayback.toJson(),
      if (actionMsg != null) 'message': actionMsg.toJson(),
    });

    _currentRoom = _currentRoom!.copyWith(playback: updatedPlayback);
    _roomController.add(_currentRoom);
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

    if (!_isUsingRelay) {
      try {
        if (isNativeSupported && Firebase.apps.isNotEmpty) {
          final roomRef =
              FirebaseDatabase.instance.ref('watch_party_rooms/$code');
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
        debugPrint('[WatchPartyService] Firebase setAllowGuestControl note: $e');
        _isUsingRelay = true;
      }
    }

    await _publishToRelay(code, {
      'event': 'guest_control',
      'allowGuestControl': allow,
      'message': sysMsg.toJson(),
    });

    _currentRoom = _currentRoom!.copyWith(allowGuestControl: allow);
    _roomController.add(_currentRoom);
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

    // Optimistically append message with ID deduplication
    final existingIds = _currentRoom!.messages.map((m) => m.id).toSet();
    if (!existingIds.contains(msg.id)) {
      final updatedMessages = List<WatchPartyMessage>.from(
        _currentRoom!.messages,
      )..add(msg);
      _currentRoom = _currentRoom!.copyWith(messages: updatedMessages);
      _roomController.add(_currentRoom);
    }

    if (!_isUsingRelay) {
      try {
        if (isNativeSupported && Firebase.apps.isNotEmpty) {
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
        debugPrint('[WatchPartyService] Firebase sendMessage note: $e');
        _isUsingRelay = true;
      }
    }

    await _publishToRelay(code, {
      'event': 'message',
      'message': msg.toJson(),
    });
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

    // Optimistically append emoji message with ID deduplication
    final existingIds = _currentRoom!.messages.map((m) => m.id).toSet();
    if (!existingIds.contains(msg.id)) {
      final updatedMessages = List<WatchPartyMessage>.from(
        _currentRoom!.messages,
      )..add(msg);
      _currentRoom = _currentRoom!.copyWith(messages: updatedMessages);
      _roomController.add(_currentRoom);
    }

    if (!_isUsingRelay) {
      try {
        if (isNativeSupported && Firebase.apps.isNotEmpty) {
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
        debugPrint('[WatchPartyService] Firebase sendEmoji note: $e');
        _isUsingRelay = true;
      }
    }

    await _publishToRelay(code, {
      'event': 'message',
      'message': msg.toJson(),
    });
  }

  /// Leaves the active Watch Party room and cleans up listeners.
  /// If current user is the Host, this automatically deletes the entire room
  /// (wiping the room code, member list, and all conversation messages).
  /// If current user is a guest/member, only removes this member from the room.
  Future<void> leaveRoom() async {
    if (_isHost) {
      await deleteRoom();
      return;
    }

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

      if (!_isUsingRelay) {
        try {
          if (isNativeSupported && Firebase.apps.isNotEmpty) {
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

      await _publishToRelay(code, {
        'event': 'member_leave',
        'memberId': _myMemberId,
        'message': leaveMsg.toJson(),
      });
    }

    _stopListening();
    _currentRoom = null;
    _myMemberId = null;
    _myName = null;
    _isHost = false;
    _isUsingRelay = false;
    _roomController.add(null);
  }

  /// Completely deletes the active Watch Party room from Firebase and Relay.
  /// Wipes out the room code, all members, and all conversation messages.
  Future<void> deleteRoom() async {
    if (_currentRoom != null) {
      final code = _currentRoom!.roomCode;

      if (!_isUsingRelay) {
        try {
          if (isNativeSupported && Firebase.apps.isNotEmpty) {
            final roomRef =
                FirebaseDatabase.instance.ref('watch_party_rooms/$code');
            await roomRef.remove();
          } else {
            await _dio.delete(
              '$_rtdbBaseUrl/watch_party_rooms/$code.json',
            );
          }
        } catch (e) {
          debugPrint('[WatchPartyService] Firebase deleteRoom error: $e');
        }
      }

      // Broadcast room_deleted to Cloud Relay so any connected guests are notified immediately
      await _publishToRelay(code, {
        'event': 'room_deleted',
        'roomCode': code,
        'hostId': _myMemberId,
        'message': {
          'id': 'del_${DateTime.now().millisecondsSinceEpoch}',
          'senderId': 'system',
          'senderName': 'Cineva',
          'isHost': true,
          'text': 'Ruangan telah ditutup dan dihapus oleh Host',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'type': 'system',
        },
      });
    }

    _stopListening();
    _currentRoom = null;
    _myMemberId = null;
    _myName = null;
    _isHost = false;
    _isUsingRelay = false;
    _roomController.add(null);
  }

  void _startListeningToRoom(String roomCode) {
    _stopListening();

    if (!_isUsingRelay && isNativeSupported && Firebase.apps.isNotEmpty) {
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
        } else if (val == null) {
          debugPrint('[WatchPartyService] Room $roomCode was deleted from database.');
          _stopListening();
          _currentRoom = null;
          _roomController.add(null);
        }
      }, onError: (e) {
        debugPrint(
          '[WatchPartyService] Room stream error: $e, switching to polling...',
        );
        _isUsingRelay = true;
        _startListeningToRoom(roomCode);
      });
    } else {
      // High-performance polling loop (1.2s interval)
      _pollingTimer =
          Timer.periodic(const Duration(milliseconds: 1200), (_) async {
        final room = await _fetchRoomFromCloud(roomCode);
        if (room != null) {
          _currentRoom = room;
          _roomController.add(room);
        } else {
          debugPrint('[WatchPartyService] Room $roomCode not found / deleted during polling.');
          _stopListening();
          _currentRoom = null;
          _roomController.add(null);
        }
      });
    }
  }

  void _stopListening() {
    _nativeRoomSub?.cancel();
    _nativeRoomSub = null;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _writeRoomToCloud(WatchPartyRoom room) async {
    bool firebaseSuccess = false;
    try {
      if (isNativeSupported && Firebase.apps.isNotEmpty) {
        final roomRef =
            FirebaseDatabase.instance.ref('watch_party_rooms/${room.roomCode}');
        await roomRef.set(room.toJson()).timeout(const Duration(seconds: 3));
        firebaseSuccess = true;
      } else {
        final resp = await _dio
            .put(
              '$_rtdbBaseUrl/watch_party_rooms/${room.roomCode}.json',
              data: room.toJson(),
            )
            .timeout(const Duration(seconds: 3));
        if (resp.statusCode == 200) {
          firebaseSuccess = true;
        }
      }
    } catch (e) {
      if (e is DioException) {
        debugPrint(
          '[WatchPartyService] Firebase error response: ${e.response?.data}',
        );
      }
      debugPrint(
        '[WatchPartyService] Firebase RTDB write note ($e). Activating Cloud Relay fallback.',
      );
      firebaseSuccess = false;
    }

    _isUsingRelay = !firebaseSuccess;

    // Always publish to Cloud Relay to guarantee cross-device & guest interoperability
    await _publishToRelay(room.roomCode, {
      'event': 'room_init',
      'room': room.toJson(),
    });
  }

  Future<WatchPartyRoom?> _fetchRoomFromCloud(String roomCode) async {
    final cleanCode = roomCode.trim().toUpperCase();

    // 1. Try Firebase RTDB if not forced to relay
    if (!_isUsingRelay) {
      try {
        if (isNativeSupported && Firebase.apps.isNotEmpty) {
          final snapshot = await FirebaseDatabase.instance
              .ref('watch_party_rooms/$cleanCode')
              .get()
              .timeout(const Duration(seconds: 3));
          if (snapshot.exists && snapshot.value is Map) {
            final rawMap = (snapshot.value as Map).cast<String, dynamic>();
            return WatchPartyRoom.fromJson(rawMap);
          }
        } else {
          final resp = await _dio
              .get(
                '$_rtdbBaseUrl/watch_party_rooms/$cleanCode.json',
              )
              .timeout(const Duration(seconds: 3));
          if (resp.data != null && resp.data is Map) {
            return WatchPartyRoom.fromJson(
              (resp.data as Map).cast<String, dynamic>(),
            );
          }
        }
      } catch (e) {
        debugPrint('[WatchPartyService] Firebase fetch note: $e');
      }
    }

    // 2. Fetch from Cloud Relay
    try {
      final topic = 'cineva_wp_${cleanCode.toLowerCase()}';
      final resp = await _dio.get(
        'https://ntfy.sh/$topic/json?poll=1',
        options: Options(responseType: ResponseType.plain),
      );
      if (resp.data != null) {
        final room = _reconstructRoomFromRelayData(cleanCode, resp.data);
        if (room != null) {
          _isUsingRelay = true;
          return room;
        }
      }
    } catch (e) {
      debugPrint('[WatchPartyService] Relay fetch error: $e');
    }

    return null;
  }

  Future<void> _publishToRelay(
    String roomCode,
    Map<String, dynamic> payload,
  ) async {
    try {
      final topic = 'cineva_wp_${roomCode.trim().toLowerCase()}';
      await _dio.post(
        'https://ntfy.sh/$topic',
        data: jsonEncode(payload),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
    } catch (e) {
      if (e is DioException) {
        debugPrint('[WatchPartyService] Relay error response: ${e.response?.data}');
      }
      debugPrint('[WatchPartyService] Relay publish note: $e');
    }
  }

  WatchPartyRoom? _reconstructRoomFromRelayData(
    String roomCode,
    dynamic data,
  ) {
    try {
      final lines = <Map<String, dynamic>>[];
      if (data is String) {
        for (final line in data.split('\n')) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;
          try {
            final decoded = jsonDecode(trimmed);
            if (decoded is Map<String, dynamic>) {
              lines.add(decoded);
            }
          } catch (_) {}
        }
      } else if (data is Map<String, dynamic>) {
        lines.add(data);
      } else if (data is List) {
        for (final item in data) {
          if (item is Map<String, dynamic>) lines.add(item);
        }
      }

      if (lines.isEmpty) return null;

      WatchPartyRoom? room;
      final members = <String, WatchPartyMember>{};
      final messages = <WatchPartyMessage>[];

      for (final entry in lines) {
        final rawMsg = entry['message'];
        if (rawMsg is! String) continue;

        Map<String, dynamic>? payload;
        try {
          payload = jsonDecode(rawMsg) as Map<String, dynamic>?;
        } catch (_) {}

        if (payload == null) continue;
        final event = payload['event'] as String?;

        if (event == 'room_deleted') {
          // Room was completely deleted by the Host
          return null;
        }

        if (event == 'room_init') {
          final roomJson = payload['room'] as Map<dynamic, dynamic>?;
          if (roomJson != null) {
            room = WatchPartyRoom.fromJson(roomJson);
            members.addAll(room.members);
            messages.addAll(room.messages);
          }
        } else if (event == 'member_join') {
          final mJson = payload['member'] as Map<dynamic, dynamic>?;
          final msgJson = payload['message'] as Map<dynamic, dynamic>?;
          if (mJson != null) {
            final member = WatchPartyMember.fromJson(mJson);
            members[member.id] = member;
          }
          if (msgJson != null) {
            messages.add(WatchPartyMessage.fromJson(msgJson));
          }
        } else if (event == 'playback' && room != null) {
          final pJson = payload['playback'] as Map<dynamic, dynamic>?;
          if (pJson != null) {
            final pb = WatchPartyPlayback.fromJson(pJson);
            room = room.copyWith(playback: pb);
          }
          final msgJson = payload['message'] as Map<dynamic, dynamic>?;
          if (msgJson != null) {
            messages.add(WatchPartyMessage.fromJson(msgJson));
          }
        } else if (event == 'message') {
          final msgJson = payload['message'] as Map<dynamic, dynamic>?;
          if (msgJson != null) {
            messages.add(WatchPartyMessage.fromJson(msgJson));
          }
        } else if (event == 'guest_control' && room != null) {
          final allow = payload['allowGuestControl'] as bool? ?? false;
          room = room.copyWith(allowGuestControl: allow);
          final msgJson = payload['message'] as Map<dynamic, dynamic>?;
          if (msgJson != null) {
            messages.add(WatchPartyMessage.fromJson(msgJson));
          }
        } else if (event == 'member_leave') {
          final memberId = payload['memberId'] as String?;
          if (memberId != null) members.remove(memberId);
          final msgJson = payload['message'] as Map<dynamic, dynamic>?;
          if (msgJson != null) {
            messages.add(WatchPartyMessage.fromJson(msgJson));
          }
        }
      }

      if (room != null) {
        // Sort and deduplicate messages
        final seen = <String>{};
        final uniqueMessages = <WatchPartyMessage>[];
        for (final m in messages) {
          if (seen.add(m.id)) {
            uniqueMessages.add(m);
          }
        }
        uniqueMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        return room.copyWith(
          members: members,
          messages: uniqueMessages,
        );
      }
    } catch (e) {
      debugPrint('[WatchPartyService] Reconstruct room error: $e');
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
