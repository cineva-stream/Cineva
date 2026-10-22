import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/app_constants.dart';

class SearchHistoryNotifier extends StateNotifier<List<String>> {
  SearchHistoryNotifier() : super([]) {
    _loadHistory();
  }

  static const String _key = 'recent_search_history';

  void _loadHistory() {
    try {
      final box = Hive.box(AppConstants.settingsBox);
      final raw = box.get(_key, defaultValue: <String>[]);
      if (raw is List) {
        state = raw.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
      }
    } catch (_) {
      state = [];
    }
  }

  Future<void> addQuery(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;

    final updated = [
      clean,
      ...state.where((q) => q.toLowerCase() != clean.toLowerCase()),
    ].take(10).toList();

    state = updated;
    try {
      final box = Hive.box(AppConstants.settingsBox);
      await box.put(_key, updated);
    } catch (_) {}
  }

  Future<void> removeQuery(String query) async {
    final updated = state.where((q) => q != query).toList();
    state = updated;
    try {
      final box = Hive.box(AppConstants.settingsBox);
      await box.put(_key, updated);
    } catch (_) {}
  }

  Future<void> clearHistory() async {
    state = [];
    try {
      final box = Hive.box(AppConstants.settingsBox);
      await box.delete(_key);
    } catch (_) {}
  }
}

final searchHistoryProvider = StateNotifierProvider<SearchHistoryNotifier, List<String>>((ref) {
  return SearchHistoryNotifier();
});
