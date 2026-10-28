import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/watch_history_item.dart';

/// Repository for managing persistent watch history backed by Hive.
class WatchHistoryRepository {
  Box get _box => Hive.box(AppConstants.historyBox);

  /// Returns all watch history items, deduplicated and sorted by most recently watched.
  List<WatchHistoryItem> getAll() {
    final map = <String, WatchHistoryItem>{};
    for (final key in _box.keys) {
      try {
        final raw = _box.get(key);
        if (raw is Map) {
          final item = WatchHistoryItem.fromJson(raw);
          // Normalized unique identification:
          // For TV episodes: tv_<id>_s<season>_e<episode>
          // For movies: movie_<id>
          final uniqueKey = (item.mediaType == 'tv' && item.season != null && item.episode != null)
              ? 'tv_${item.id}_s${item.season}_e${item.episode}'
              : '${item.mediaType}_${item.id}';

          if (map.containsKey(uniqueKey)) {
            final existing = map[uniqueKey]!;
            // If duplicate exists, favor completed status or later timestamp
            if (!existing.isCompleted && item.isCompleted) {
              map[uniqueKey] = item;
            } else if (existing.isCompleted && !item.isCompleted) {
              // Keep completed item
            } else if (item.lastWatchedAt.isAfter(existing.lastWatchedAt)) {
              map[uniqueKey] = item;
            }
          } else {
            map[uniqueKey] = item;
          }
        }
      } catch (_) {
        // Skip corrupted entry
      }
    }

    // Filter out obsolete generic TV entries ('tv_<id>') if specific episode entries exist
    final specificTvIds = <int>{};
    for (final item in map.values) {
      if (item.mediaType == 'tv' && item.season != null && item.episode != null) {
        specificTvIds.add(item.id);
      }
    }

    final list = map.values.where((item) {
      if (item.mediaType == 'tv' && (item.season == null || item.episode == null)) {
        // If a specific episode entry exists for this series, drop the generic entry
        if (specificTvIds.contains(item.id)) return false;
      }
      return true;
    }).toList();

    list.sort((a, b) => b.lastWatchedAt.compareTo(a.lastWatchedAt));
    return list;
  }

  /// Returns items that are in-progress (progress between 2% and 95%).
  List<WatchHistoryItem> getInProgress() {
    return getAll().where((item) => item.isInProgress).toList();
  }

  /// Finds a specific history item by media type and ID, optionally with season & episode for TV series.
  WatchHistoryItem? getItem(String mediaType, int id, {int? season, int? episode}) {
    try {
      if (mediaType == 'tv' && season != null && episode != null) {
        final epRaw = _box.get('${mediaType}_${id}_s${season}_e$episode');
        if (epRaw is Map) {
          return WatchHistoryItem.fromJson(epRaw);
        }
      }
      final raw = _box.get('${mediaType}_$id');
      if (raw is Map) {
        return WatchHistoryItem.fromJson(raw);
      }
    } catch (_) {}
    return null;
  }

  /// Saves or updates watch progress and cleans up obsolete keys.
  Future<void> saveProgress(WatchHistoryItem item) async {
    // If saving a specific TV episode, clean up any generic key for this TV show
    if (item.mediaType == 'tv' && item.season != null && item.episode != null) {
      final genericTvKey = 'tv_${item.id}';
      if (_box.containsKey(genericTvKey)) {
        await _box.delete(genericTvKey);
      }
      final genericMovieKey = 'movie_${item.id}';
      if (_box.containsKey(genericMovieKey)) {
        await _box.delete(genericMovieKey);
      }
    }
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
  final inProgress = <WatchHistoryItem>[];
  final seenTvIds = <int>{};

  for (final item in all) {
    if (!item.isInProgress) continue;
    if (item.mediaType == 'tv') {
      if (seenTvIds.contains(item.id)) continue;
      seenTvIds.add(item.id);
    }
    inProgress.add(item);
  }
  return inProgress;
});
