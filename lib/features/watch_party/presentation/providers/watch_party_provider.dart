import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/watch_party_service.dart';
import '../../domain/models/watch_party_room.dart';

/// Active Watch Party state for UI components and video player synchronization.
class WatchPartyState {
  final WatchPartyRoom? room;
  final String? myMemberId;
  final String? myName;
  final bool isHost;
  final bool isChatPanelOpen;
  final bool hasUnreadMessages;
  final String? latestEmoji;
  final bool isLoading;
  final String? errorMessage;

  const WatchPartyState({
    this.room,
    this.myMemberId,
    this.myName,
    this.isHost = false,
    this.isChatPanelOpen = false,
    this.hasUnreadMessages = false,
    this.latestEmoji,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isInRoom => room != null;

  /// Whether current user has permission to pause, play, or seek video.
  /// Host can ALWAYS control; Guest can control ONLY if Host checked [allowGuestControl].
  bool get canControlVideo => isHost || (room?.allowGuestControl == true);

  WatchPartyState copyWith({
    WatchPartyRoom? room,
    bool clearRoom = false,
    String? myMemberId,
    String? myName,
    bool? isHost,
    bool? isChatPanelOpen,
    bool? hasUnreadMessages,
    String? latestEmoji,
    bool clearEmoji = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return WatchPartyState(
      room: clearRoom ? null : (room ?? this.room),
      myMemberId: myMemberId ?? this.myMemberId,
      myName: myName ?? this.myName,
      isHost: isHost ?? this.isHost,
      isChatPanelOpen: isChatPanelOpen ?? this.isChatPanelOpen,
      hasUnreadMessages: hasUnreadMessages ?? this.hasUnreadMessages,
      latestEmoji: clearEmoji ? null : (latestEmoji ?? this.latestEmoji),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Manages Watch Party room creation, joining, permissions, chat, and synchronization.
class WatchPartyNotifier extends StateNotifier<WatchPartyState> {
  final WatchPartyService _service;
  StreamSubscription<WatchPartyRoom?>? _roomSub;
  int _lastReadMessageTimestamp = 0;

  WatchPartyNotifier(this._service) : super(const WatchPartyState()) {
    _initStream();
  }

  void _initStream() {
    _roomSub = _service.roomStream.listen((room) {
      if (room == null) {
        state = state.copyWith(
          clearRoom: true,
          isHost: false,
          hasUnreadMessages: false,
          isChatPanelOpen: false,
        );
        return;
      }

      // Detect unread messages
      bool hasUnread = false;
      String? newEmoji;
      if (room.messages.isNotEmpty) {
        final lastMsg = room.messages.last;
        if (lastMsg.timestamp > _lastReadMessageTimestamp) {
          if (!state.isChatPanelOpen && lastMsg.senderId != _service.myMemberId) {
            hasUnread = true;
          }
          if (lastMsg.type == 'emoji' && lastMsg.emoji != null) {
            newEmoji = lastMsg.emoji;
          }
        }
      }

      state = state.copyWith(
        room: room,
        myMemberId: _service.myMemberId,
        myName: _service.myName,
        isHost: _service.isHost,
        hasUnreadMessages: hasUnread || state.hasUnreadMessages,
        latestEmoji: newEmoji,
      );
    });
  }

  /// Creates a room as Host.
  Future<String?> createRoom({
    required String hostName,
    required WatchPartyMedia media,
    bool allowGuestControl = false,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final code = await _service.createRoom(
        hostName: hostName,
        media: media,
        allowGuestControl: allowGuestControl,
      );
      state = state.copyWith(
        isLoading: false,
        isHost: true,
        myMemberId: _service.myMemberId,
        myName: _service.myName,
      );
      return code;
    } catch (e, stack) {
      debugPrint('[WatchPartyNotifier] createRoom error: $e\n$stack');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal membuat ruang Nonton Bareng: $e',
      );
      return null;
    }
  }

  /// Joins an existing room by code.
  Future<bool> joinRoom({
    required String roomCode,
    required String memberName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final success = await _service.joinRoom(
        roomCode: roomCode,
        memberName: memberName,
      );
      if (success) {
        state = state.copyWith(
          isLoading: false,
          isHost: false,
          myMemberId: _service.myMemberId,
          myName: _service.myName,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Ruangan tidak ditemukan. Periksa kembali kodenya.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal bergabung ke ruangan: $e',
      );
      return false;
    }
  }

  /// Toggles visibility of the right side Live Chat panel.
  void toggleChatPanel([bool? open]) {
    final next = open ?? !state.isChatPanelOpen;
    if (next) {
      // Mark messages read when panel opens
      _lastReadMessageTimestamp = DateTime.now().millisecondsSinceEpoch;
      state = state.copyWith(isChatPanelOpen: true, hasUnreadMessages: false);
    } else {
      state = state.copyWith(isChatPanelOpen: false);
    }
  }

  /// Host toggle: Allow or disallow partner/guest to control video playback.
  Future<void> setAllowGuestControl(bool allow) async {
    if (!state.isHost) return;
    await _service.setAllowGuestControl(allow);
  }

  /// Sends a text message.
  Future<void> sendMessage(String text) async {
    await _service.sendMessage(text);
  }

  /// Sends an emoji reaction.
  Future<void> sendEmojiReaction(String emoji) async {
    await _service.sendEmojiReaction(emoji);
  }

  /// Clears floating emoji after animation completes.
  void clearLatestEmoji() {
    state = state.copyWith(clearEmoji: true);
  }

  /// Updates synchronized video playback state.
  Future<void> updatePlayback({
    required bool isPlaying,
    required double positionSeconds,
    required String action,
  }) async {
    if (!state.canControlVideo) return;
    await _service.updatePlayback(
      isPlaying: isPlaying,
      positionSeconds: positionSeconds,
      action: action,
    );
  }

  /// Disconnects from current room.
  Future<void> leaveRoom() async {
    await _service.leaveRoom();
    state = const WatchPartyState();
  }

  @override
  void dispose() {
    _roomSub?.cancel();
    super.dispose();
  }
}

/// Service instance provider.
final watchPartyServiceProvider = Provider<WatchPartyService>((ref) {
  final service = WatchPartyService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Riverpod provider for active Watch Party state.
final watchPartyProvider =
    StateNotifierProvider<WatchPartyNotifier, WatchPartyState>((ref) {
  final service = ref.watch(watchPartyServiceProvider);
  return WatchPartyNotifier(service);
});

