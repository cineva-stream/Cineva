import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/profile_service.dart';
import '../../domain/models/user_profile.dart';

class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier() : super(ProfileService.getProfile());

  /// Sets name in local state
  void updateName(String name) {
    state = state.copyWith(name: name.trim());
  }

  /// Sets username in local state
  void updateUsername(String username) {
    final clean = username.trim().replaceAll('@', '');
    state = state.copyWith(username: clean);
  }

  /// Selects one of the 10 preset avatars
  void selectPresetAvatar(String avatarId) {
    state = state.copyWith(
      avatarId: avatarId,
      clearCustomAvatar: true,
    );
  }

  /// Sets custom avatar from cropped image file path
  void setCustomAvatar(String filePath) {
    state = state.copyWith(
      avatarId: 'custom',
      customAvatarPath: filePath,
    );
  }

  /// Commits changes to Hive storage
  Future<void> save({
    String? name,
    String? username,
    String? avatarId,
    String? customAvatarPath,
  }) async {
    final cleanUsername = username?.trim().replaceAll('@', '');
    final updated = state.copyWith(
      name: name?.trim(),
      username: cleanUsername,
      avatarId: avatarId,
      customAvatarPath: customAvatarPath,
      isConfigured: true,
    );
    state = updated;
    await ProfileService.saveProfile(updated);
  }

  /// Marks profile as configured and saves current state
  Future<void> completeOnboarding() async {
    final updated = state.copyWith(isConfigured: true);
    state = updated;
    await ProfileService.saveProfile(updated);
  }

  /// Skips onboarding with default profile but marks isConfigured as true
  Future<void> skipOnboarding() async {
    final updated = state.copyWith(isConfigured: true);
    state = updated;
    await ProfileService.saveProfile(updated);
  }

  /// Reloads profile from storage
  void reload() {
    state = ProfileService.getProfile();
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  return UserProfileNotifier();
});
