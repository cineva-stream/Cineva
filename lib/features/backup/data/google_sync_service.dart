import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';

import '../../profile/presentation/providers/profile_provider.dart';
import '../domain/models/cineva_backup_payload.dart';
import 'backup_restore_service.dart';

/// State of Google Cloud Sync.
class GoogleSyncState {
  final bool isSupported;
  final bool isLoading;
  final bool isSignedIn;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final DateTime? lastSyncedAt;
  final String? errorMessage;

  const GoogleSyncState({
    required this.isSupported,
    this.isLoading = false,
    this.isSignedIn = false,
    this.email,
    this.displayName,
    this.photoUrl,
    this.lastSyncedAt,
    this.errorMessage,
  });

  GoogleSyncState copyWith({
    bool? isSupported,
    bool? isLoading,
    bool? isSignedIn,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? lastSyncedAt,
    String? errorMessage,
    bool clearError = false,
  }) {
    return GoogleSyncState(
      isSupported: isSupported ?? this.isSupported,
      isLoading: isLoading ?? this.isLoading,
      isSignedIn: isSignedIn ?? this.isSignedIn,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Service managing Google Sign-In and Firebase Realtime Database cloud synchronization.
class GoogleSyncService extends StateNotifier<GoogleSyncState> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  GoogleSyncService()
      : super(GoogleSyncState(
          isSupported: !kIsWeb && (Platform.isAndroid || Platform.isIOS),
        )) {
    _initAuthState();
  }

  void _initAuthState() {
    if (!state.isSupported) return;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        state = state.copyWith(
          isSignedIn: true,
          email: currentUser.email,
          displayName: currentUser.displayName,
          photoUrl: currentUser.photoURL,
        );
      }
    } catch (e) {
      debugPrint('[GoogleSyncService] Auth init check: $e');
    }
  }

  /// Triggers Google Sign-In flow, then pulls cloud data or pushes initial snapshot.
  Future<bool> signInWithGoogle(WidgetRef ref) async {
    if (!state.isSupported) {
      state = state.copyWith(
        errorMessage:
            'Sinkronisasi Google Cloud saat ini aktif di Android. Gunakan Cadangan File .cineva di PC.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled picker
        state = state.copyWith(isLoading: false);
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Gagal mendapatkan akun Google.',
        );
        return false;
      }

      state = state.copyWith(
        isSignedIn: true,
        email: user.email ?? googleUser.email,
        displayName: user.displayName ?? googleUser.displayName,
        photoUrl: user.photoURL ?? googleUser.photoUrl,
      );

      // 1. Download and set avatar from Google profile if photoURL exists
      String? downloadedAvatarPath;
      final photoUrl = user.photoURL ?? googleUser.photoUrl;
      if (photoUrl != null && photoUrl.isNotEmpty) {
        try {
          final client = HttpClient()
            ..connectionTimeout = const Duration(seconds: 5);
          final request = await client.getUrl(Uri.parse(photoUrl));
          final response =
              await request.close().timeout(const Duration(seconds: 6));
          if (response.statusCode == HttpStatus.ok) {
            final bytes = await consolidateHttpClientResponseBytes(response);
            final appDir = await getApplicationDocumentsDirectory();
            final avatarFile = File(
              '${appDir.path}/cineva_avatar_google_${DateTime.now().millisecondsSinceEpoch}.png',
            );
            await avatarFile.writeAsBytes(bytes, flush: true);
            downloadedAvatarPath = avatarFile.path;
          }
          client.close();
        } catch (e) {
          debugPrint(
              '[GoogleSyncService] Failed downloading Google profile photo: $e');
        }
      }

      // 2. Derive default Nickname and Username from Google account
      final googleDisplayName = user.displayName ?? googleUser.displayName;
      final defaultName = (googleDisplayName != null &&
              googleDisplayName.trim().isNotEmpty)
          ? googleDisplayName.trim()
          : 'Penikmat Film';

      final userEmail = user.email ?? googleUser.email;
      String defaultUsername = 'cineva_fan';
      if (userEmail.contains('@')) {
        final emailPrefix = userEmail.split('@').first.toLowerCase();
        defaultUsername = emailPrefix.replaceAll(RegExp(r'[^a-z0-9_]'), '_');
        if (defaultUsername.isEmpty) defaultUsername = 'cineva_fan';
      } else if (googleDisplayName != null &&
          googleDisplayName.trim().isNotEmpty) {
        defaultUsername = googleDisplayName
            .trim()
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9_]'), '_');
      }

      // 3. Save Google profile defaults locally
      await ref.read(userProfileProvider.notifier).save(
            name: defaultName,
            username: defaultUsername,
            avatarId: downloadedAvatarPath != null ? 'custom' : 'avatar_popcorn',
            customAvatarPath: downloadedAvatarPath,
          );

      // 4. Check for remote cloud backup
      final rtdb = FirebaseDatabase.instance.ref('users/${user.uid}/backup');
      final snapshot = await rtdb.get();

      if (snapshot.exists && snapshot.value is Map) {
        // Restore existing cloud data
        final rawMap = (snapshot.value as Map).cast<String, dynamic>();
        final payload = CinevaBackupPayload.fromJson(rawMap);
        await BackupRestoreService.applyPayload(ref, payload);

        // Ensure downloaded Google avatar/name is retained if cloud was default
        final currentProfile = ref.read(userProfileProvider);
        if (downloadedAvatarPath != null ||
            currentProfile.name == 'Penikmat Film') {
          await ref.read(userProfileProvider.notifier).save(
                name: currentProfile.name != 'Penikmat Film'
                    ? currentProfile.name
                    : defaultName,
                username: currentProfile.username != 'cineva_fan'
                    ? currentProfile.username
                    : defaultUsername,
                avatarId: downloadedAvatarPath != null
                    ? 'custom'
                    : currentProfile.avatarId,
                customAvatarPath:
                    downloadedAvatarPath ?? currentProfile.customAvatarPath,
              );
        }

        state = state.copyWith(
          isLoading: false,
          lastSyncedAt: payload.exportedAt,
        );
      } else {
        // No remote data yet: initial sync local -> cloud
        await syncToCloud(ref);
        state = state.copyWith(isLoading: false);
      }

      return true;
    } catch (e) {
      debugPrint('[GoogleSyncService] Sign in error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal masuk dengan Google: $e',
      );
      return false;
    }
  }

  /// Synchronizes local data to Firebase Realtime Database (`users/{uid}/backup`).
  Future<bool> syncToCloud(WidgetRef ref) async {
    if (!state.isSupported) return false;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      state = state.copyWith(errorMessage: 'Belum masuk ke akun Google.');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final payload = await BackupRestoreService.createPayload(ref);
      final rtdb = FirebaseDatabase.instance.ref('users/${user.uid}/backup');
      await rtdb.set(payload.toJson());

      final now = DateTime.now();
      state = state.copyWith(
        isLoading: false,
        lastSyncedAt: now,
      );
      return true;
    } catch (e) {
      debugPrint('[GoogleSyncService] Cloud upload error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal mengunggah cadangan ke cloud: $e',
      );
      return false;
    }
  }

  /// Pulls remote backup from Firebase Realtime Database and restores locally.
  Future<bool> syncFromCloud(WidgetRef ref) async {
    if (!state.isSupported) return false;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final rtdb = FirebaseDatabase.instance.ref('users/${user.uid}/backup');
      final snapshot = await rtdb.get();

      if (snapshot.exists && snapshot.value is Map) {
        final rawMap = (snapshot.value as Map).cast<String, dynamic>();
        final payload = CinevaBackupPayload.fromJson(rawMap);
        await BackupRestoreService.applyPayload(ref, payload);
        state = state.copyWith(
          isLoading: false,
          lastSyncedAt: payload.exportedAt,
        );
        return true;
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Tidak ditemukan data cadangan di akun Google ini.',
      );
      return false;
    } catch (e) {
      debugPrint('[GoogleSyncService] Cloud pull error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal mengunduh cadangan: $e',
      );
      return false;
    }
  }

  /// Disconnects Google account without wiping local data.
  Future<void> signOut() async {
    try {
      if (state.isSupported) {
        await _googleSignIn.signOut();
        await FirebaseAuth.instance.signOut();
      }
    } catch (e) {
      debugPrint('[GoogleSyncService] Sign out error: $e');
    }

    state = state.copyWith(
      isSignedIn: false,
      email: null,
      displayName: null,
      photoUrl: null,
      lastSyncedAt: null,
      clearError: true,
    );
  }
}

