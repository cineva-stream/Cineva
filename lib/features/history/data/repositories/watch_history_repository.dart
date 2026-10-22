import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/watch_history_item.dart';

/// Repository for managing persistent watch history backed by Hive.
class WatchHistoryRepository {
  Box get _box => Hive.box(AppConstants.historyBox);

  /// Returns all watch history items, sorted by most recently watched.
  List<WatchHistoryItem> getAll() {
    final list = <WatchHistoryItem>[];
    for (final key in _box.keys) {
      try {
        final raw = _box.get(key);
        if (raw is Map) {
          list.add(WatchHistoryItem.fromJson(raw));
        }
      } catch (_) {
        // Skip corrupted entry
      }
    }
    list.sort((a, b) => b.lastWatchedAt.compareTo(a.lastWatchedAt));
    return list;
  }

  /// Returns items that are in-progress (progress between 2% and 95%).
  List<WatchHistoryItem> getInProgress() {
    return getAll().where((item) => item.isInProgress).toList();
  }

  /// Finds a specific history item by media type and ID.
  WatchHistoryItem? getItem(String mediaType, int id) {
    try {
      final raw = _box.get('${mediaType}_$id');
      if (raw is Map) {
        return WatchHistoryItem.fromJson(raw);
      }
    } catch (_) {}
    return null;
  }

  /// Saves or updates watch progress.
  Future<void> saveProgress(WatchHistoryItem item) async {
    await _box.put(item.key, item.toJson());
  }

  /// Removes an individual watch history item.
  Future<void> removeItem(String key) async {
    await _box.delete(key);
  }

  /// Clears all watch history.
  Future<void> clearAll() async {
    await _box.clear();
  }
}

// ── Riverpod Providers ──

final watchHistoryRepositoryProvider = Provider<WatchHistoryRepository>((ref) {
  return WatchHistoryRepository();
});

/// Notifier managing real-time watch history state.
class WatchHistoryNotifier extends StateNotifier<List<WatchHistoryItem>> {
  final WatchHistoryRepository _repo;

  WatchHistoryNotifier(this._repo) : super(_repo.getAll());

  void refresh() {
    state = _repo.getAll();
  }

  Future<void> saveProgress(WatchHistoryItem item) async {
    await _repo.saveProgress(item);
    state = _repo.getAll();
  }

  Future<void> removeItem(String key) async {
    await _repo.removeItem(key);
    state = _repo.getAll();
  }

  Future<void> clearAll() async {
    await _repo.clearAll();
    state = [];
  }
}

final watchHistoryProvider = StateNotifierProvider<WatchHistoryNotifier, List<WatchHistoryItem>>((ref) {
  final repo = ref.watch(watchHistoryRepositoryProvider);
  return WatchHistoryNotifier(repo);
});

/// Real-time provider for in-progress items (for Home Screen "Lanjutkan Menonton").
final inProgressWatchHistoryProvider = Provider<List<WatchHistoryItem>>((ref) {
  final all = ref.watch(watchHistoryProvider);
  return all.where((item) => item.isInProgress).toList();
});
