import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/data/settings_service.dart';
import 'app_language.dart';
import 'app_strings.dart';

/// State notifier that manages the currently active application language.
class AppLanguageNotifier extends StateNotifier<AppLanguage> {
  AppLanguageNotifier([AppLanguage? initialLanguage])
      : super(initialLanguage ?? _loadInitialLanguage());

  static AppLanguage _loadInitialLanguage() {
    try {
      return AppLanguage.fromCode(SettingsService.getAppLanguage());
    } catch (_) {
      return AppLanguage.id;
    }
  }

  /// Changes application language and persists to Hive storage.
  Future<void> setLanguage(AppLanguage language) async {
    if (state == language) return;
    try {
      await SettingsService.setAppLanguage(language.code);
    } catch (_) {
      // Allow in-memory state change even if storage is unavailable (e.g. in tests)
    }
    state = language;
  }
}

/// Provider for current AppLanguage.
final appLanguageProvider = StateNotifierProvider<AppLanguageNotifier, AppLanguage>((ref) {
  return AppLanguageNotifier();
});

/// Reactive provider for localized application strings.
final appStringsProvider = Provider<AppStrings>((ref) {
  final lang = ref.watch(appLanguageProvider);
  return AppStrings(lang);
});
