import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/constants/app_constants.dart';

/// Represents a watchlist item stored in Hive.
class WatchlistItem {
  final int id;
  final String title;
  final String? posterPath;
  final double voteAverage;
  final String type; // 'movie' or 'tv'
  final DateTime addedAt;

  WatchlistItem({
    required this.id,
    required this.title,
    this.posterPath,
    required this.voteAverage,
    required this.type,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'posterPath': posterPath,
        'voteAverage': voteAverage,
        'type': type,
        'addedAt': addedAt.toIso8601String(),
      };

  factory WatchlistItem.fromJson(Map<dynamic, dynamic> json) => WatchlistItem(
        id: json['id'] as int,
        title: json['title'] as String,
        posterPath: json['posterPath'] as String?,
        voteAverage: (json['voteAverage'] as num).toDouble(),
        type: json['type'] as String? ?? 'movie',
        addedAt: DateTime.tryParse(json['addedAt'] as String? ?? '') ?? DateTime.now(),
      );
}

/// Repository for watchlist operations backed by Hive.
class WatchlistRepository {
  Box get _box => Hive.box(AppConstants.watchlistBox);

  /// Get all watchlist items, sorted by most recently added.
  List<WatchlistItem> getAll() {
    final items = <WatchlistItem>[];
    for (final key in _box.keys) {
      try {
        final raw = _box.get(key);
        if (raw is Map) {
          items.add(WatchlistItem.fromJson(raw));
        }
      } catch (_) {
        // Skip corrupted entries
      }
    }
    items.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return items;
  }

  /// Check if an item is in the watchlist.
  bool isInWatchlist(int id, String type) {
    return _box.containsKey('${type}_$id');
  }

  /// Add item to watchlist.
  Future<void> add(WatchlistItem item) async {
    await _box.put('${item.type}_${item.id}', item.toJson());
  }

  /// Remove item from watchlist.
  Future<void> remove(int id, String type) async {
    await _box.delete('${type}_$id');
  }

  /// Toggle item in watchlist. Returns true if added, false if removed.
  Future<bool> toggle(WatchlistItem item) async {
    if (isInWatchlist(item.id, item.type)) {
      await remove(item.id, item.type);
      return false;
    } else {
      await add(item);
      return true;
    }
  }
}

// ── Riverpod Providers ──

final watchlistRepositoryProvider = Provider<WatchlistRepository>((ref) {
  return WatchlistRepository();
});

/// Notifier that manages the watchlist state.
class WatchlistNotifier extends StateNotifier<List<WatchlistItem>> {
  final WatchlistRepository _repo;

  WatchlistNotifier(this._repo) : super(_repo.getAll());

  bool isInWatchlist(int id, String type) => _repo.isInWatchlist(id, type);

  Future<bool> toggle(WatchlistItem item) async {
    final added = await _repo.toggle(item);
    state = _repo.getAll();
    return added;
  }

  Future<void> remove(int id, String type) async {
    await _repo.remove(id, type);
    state = _repo.getAll();
  }
}

final watchlistProvider = StateNotifierProvider<WatchlistNotifier, List<WatchlistItem>>((ref) {
  final repo = ref.watch(watchlistRepositoryProvider);
  return WatchlistNotifier(repo);
});
