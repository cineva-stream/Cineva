import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/platform/device_form_factor.dart';
import '../../domain/models/device_playback_session.dart';

/// Service managing cross-device active playback sessions (Seamless Device Hand-Off).
class DeviceHandoffService extends StateNotifier<DevicePlaybackSession?> {
  StreamSubscription<DatabaseEvent>? _playbackSub;
  String? _dismissedSnapshotKey;
  String? _cachedDeviceId;

  DeviceHandoffService([Ref? _]) : super(null) {
    _initListener();
  }

  /// Returns the persistent unique identifier for this installation.
  String get deviceId {
    if (_cachedDeviceId != null) return _cachedDeviceId!;
    try {
      final box = Hive.box(AppConstants.settingsBox);
      var id = box.get('device_unique_id') as String?;
      if (id == null || id.isEmpty) {
        final rand = Random().nextInt(999999).toString().padLeft(6, '0');
        id = 'dev_${DateTime.now().millisecondsSinceEpoch}_$rand';
        box.put('device_unique_id', id);
      }
      _cachedDeviceId = id;
      return id;
    } catch (_) {
      return 'dev_fallback_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Automatically derives a friendly device name based on platform and form factor.
  String get deviceName {
    if (gIsTv) return 'Android TV';
    if (!kIsWeb && Platform.isWindows) return 'Windows PC';
    if (!kIsWeb && Platform.isMacOS) return 'Mac';
    if (!kIsWeb && Platform.isLinux) return 'Linux PC';
    if (gIsTablet) return 'Tablet Android';
    if (!kIsWeb && Platform.isIOS) return 'iPhone';
    return 'Smartphone';
  }

  /// Returns 'tv', 'desktop', 'tablet', or 'mobile'.
  String get deviceFormFactor {
    if (gIsTv) return 'tv';
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      return 'desktop';
    }
    if (gIsTablet) return 'tablet';
    return 'mobile';
  }

  /// Initializes realtime listener for active playback session across devices.
  void _initListener() {
    if (kIsWeb) return;
    try {
      FirebaseAuth.instance.authStateChanges().listen((user) {
        _playbackSub?.cancel();
        if (user != null) {
          _subscribeToActivePlayback(user.uid);
        } else {
          state = null;
        }
      });
    } catch (e) {
      debugPrint('[DeviceHandoffService] Auth state listener error: $e');
    }
  }

  void _subscribeToActivePlayback(String uid) {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      final dbRef =
          FirebaseDatabase.instance.ref('users/$uid/active_playback');
      _playbackSub = dbRef.onValue.listen((event) {
        final val = event.snapshot.value;
        if (val is Map) {
          try {
            final rawMap = val.cast<String, dynamic>();
            final session = DevicePlaybackSession.fromJson(rawMap);

            // Hand-Off should only trigger if the session originates from another device
            // and meets validity criteria (in-progress, not dismissed, <24h old)
            if (session.deviceId != deviceId &&
                session.isValidForHandOff &&
                session.snapshotKey != _dismissedSnapshotKey) {
              state = session;
            } else if (session.deviceId == deviceId ||
                !session.isValidForHandOff) {
              state = null;
            }
          } catch (e) {
            debugPrint('[DeviceHandoffService] Error parsing active playback: $e');
          }
        } else {
          state = null;
        }
      }, onError: (e) {
        debugPrint('[DeviceHandoffService] Playback listener error: $e');
      });
    } catch (e) {
      debugPrint('[DeviceHandoffService] Setup playback subscription error: $e');
    }
  }

  /// Updates the active playback snapshot on the cloud when user is watching on this device.
  Future<void> updateActivePlayback({
    required String title,
    required String mediaType,
    required int tmdbId,
    String? imdbId,
    int? season,
    int? episode,
    String? episodeTitle,
    String? posterPath,
    String? backdropPath,
    required int positionSeconds,
    required int durationSeconds,
    bool isCompleted = false,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

    try {
      final session = DevicePlaybackSession(
        deviceId: deviceId,
        deviceName: deviceName,
        formFactor: deviceFormFactor,
        title: title,
        mediaType: mediaType,
        tmdbId: tmdbId,
        imdbId: imdbId,
        season: season,
        episode: episode,
        episodeTitle: episodeTitle,
        posterPath: posterPath,
        backdropPath: backdropPath,
        positionSeconds: positionSeconds,
        durationSeconds: durationSeconds,
        updatedAt: DateTime.now(),
        isCompleted: isCompleted,
      );

      final dbRef =
          FirebaseDatabase.instance.ref('users/${user.uid}/active_playback');
      await dbRef.set(session.toJson());
    } catch (e) {
      debugPrint('[DeviceHandoffService] Update active playback error: $e');
    }
  }

  /// Clears active playback snapshot (e.g. when video reaches end credits or completed).
  Future<void> clearActivePlayback() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

    try {
      final dbRef =
          FirebaseDatabase.instance.ref('users/${user.uid}/active_playback');
      await dbRef.remove();
    } catch (e) {
      debugPrint('[DeviceHandoffService] Clear active playback error: $e');
    }
  }

  /// User taps 'X' on top capsule card to dismiss this specific hand-off prompt.
  void dismissCurrentHandOff() {
    if (state != null) {
      _dismissedSnapshotKey = state!.snapshotKey;
      state = null;
    }
  }

  @override
  void dispose() {
    _playbackSub?.cancel();
    super.dispose();
  }
}

/// Riverpod provider for cross-device Seamless Hand-Off state.
final deviceHandoffProvider =
    StateNotifierProvider<DeviceHandoffService, DevicePlaybackSession?>((ref) {
  return DeviceHandoffService(ref);
});

