import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../data/datasources/live_tv_channels_data.dart';
import '../../domain/entities/live_tv_channel.dart';

/// Active category filter on the Live TV screen ('Semua', 'Olahraga', etc.)
final liveTvCategoryProvider = StateProvider<String>((ref) => 'Semua');

/// Search query for filtering live channels
final liveTvSearchQueryProvider = StateProvider<String>((ref) => '');

/// Notifier that manages user favorite channel IDs stored in Hive.
class LiveTvFavoritesNotifier extends StateNotifier<Set<String>> {
  static const String _key = 'live_tv_favorites';

  LiveTvFavoritesNotifier() : super({}) {
    _loadFavorites();
  }

  void _loadFavorites() {
    try {
      final box = Hive.box(AppConstants.settingsBox);
      final list = box.get(_key, defaultValue: <dynamic>[]) as List;
      state = list.map((e) => e.toString()).toSet();
    } catch (_) {}
  }

  void toggleFavorite(String channelId) {
    final next = Set<String>.from(state);
    if (next.contains(channelId)) {
      next.remove(channelId);
    } else {
      next.add(channelId);
    }
    state = next;
    try {
      final box = Hive.box(AppConstants.settingsBox);
      box.put(_key, next.toList());
    } catch (_) {}
  }

  bool isFavorite(String channelId) => state.contains(channelId);
}

final liveTvFavoritesProvider =
    StateNotifierProvider<LiveTvFavoritesNotifier, Set<String>>((ref) {
  return LiveTvFavoritesNotifier();
});

/// Filtered list of Live TV channels based on selected category, search query, and favorites.
final filteredLiveTvChannelsProvider = Provider<List<LiveTvChannel>>((ref) {
  final category = ref.watch(liveTvCategoryProvider);
  final query = ref.watch(liveTvSearchQueryProvider).trim().toLowerCase();
  final favorites = ref.watch(liveTvFavoritesProvider);

  return LiveTvChannelsData.defaultChannels.where((channel) {
    // 1. Category check
    if (category == 'Favorit') {
      if (!favorites.contains(channel.id)) return false;
    } else if (category != 'Semua' && channel.category != category) {
      return false;
    }

    // 2. Query check
    if (query.isNotEmpty) {
      final matchName = channel.name.toLowerCase().contains(query);
      final matchCategory = channel.category.toLowerCase().contains(query);
      final matchCountry = channel.country.toLowerCase().contains(query);
      final matchDesc = (channel.description ?? '').toLowerCase().contains(query);
      if (!matchName && !matchCategory && !matchCountry && !matchDesc) {
        return false;
      }
    }

    return true;
  }).toList();
});
