import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/models/user_profile.dart';

/// Local persistence service for User Profile using Hive.
class ProfileService {
  ProfileService._();

  static const String _keyProfile = 'user_profile_data';

  static Box get _box => Hive.box(AppConstants.settingsBox);

  /// Retrieves the saved user profile, or returns default if not yet stored.
  static UserProfile getProfile() {
    try {
      final raw = _box.get(_keyProfile);
      if (raw is Map) {
        return UserProfile.fromMap(raw);
      }
    } catch (_) {
      // Fallback on read error
    }
    return UserProfile.defaultProfile();
  }

  /// Persists user profile to local Hive storage.
  static Future<void> saveProfile(UserProfile profile) async {
    await _box.put(_keyProfile, profile.toMap());
  }

  /// Returns true if user has already configured or saved their profile.
  static bool hasConfiguredProfile() {
    return getProfile().isConfigured;
  }

  /// Resets profile to default state (useful for tests or app reset).
  static Future<void> resetProfile() async {
    await _box.delete(_keyProfile);
  }
}
