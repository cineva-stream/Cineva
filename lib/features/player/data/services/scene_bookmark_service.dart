import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/app_constants.dart';

/// Represents a saved timestamped scene bookmark / subtitle quote for a movie
/// or TV episode.
class SceneBookmark {
  final String id;
  final String mediaKey;
  final String title;
  final String? episodeLabel;
  final int positionMs;
  final String quoteText;
  final String? backdropPath;
  final DateTime createdAt;

  const SceneBookmark({
    required this.id,
    required this.mediaKey,
    required this.title,
    this.episodeLabel,
    required this.positionMs,
    required this.quoteText,
    this.backdropPath,
    required this.createdAt,
  });

  String get formattedTimestamp => formatDurationMs(positionMs);

  static String formatDurationMs(int ms) {
    final totalSeconds = (ms < 0 ? 0 : ms) ~/ 1000;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'mediaKey': mediaKey,
    'title': title,
    'episodeLabel': episodeLabel,
    'positionMs': positionMs,
    'quoteText': quoteText,
    'backdropPath': backdropPath,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SceneBookmark.fromJson(Map<String, dynamic> json) {
    return SceneBookmark(
      id: (json['id'] as String?) ?? '',
      mediaKey: (json['mediaKey'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      episodeLabel: json['episodeLabel'] as String?,
      positionMs: (json['positionMs'] as num?)?.toInt() ?? 0,
      quoteText: (json['quoteText'] as String?) ?? '',
      backdropPath: json['backdropPath'] as String?,
      createdAt:
          DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

/// Manages local persistence of [SceneBookmark] items in Hive.
class SceneBookmarkService {
  SceneBookmarkService._();

  static const String _storageKey = 'scene_bookmarks_v1';

  /// Builds a canonical media key for a movie or TV episode.
  static String buildMediaKey({
    int? tmdbId,
    String? imdbId,
    required String title,
    int? season,
    int? episode,
  }) {
    final baseId = (tmdbId != null && tmdbId > 0)
        ? 'tmdb_$tmdbId'
        : (imdbId != null && imdbId.isNotEmpty)
        ? 'imdb_$imdbId'
        : 'title_${title.trim().toLowerCase()}';
    if (season != null && episode != null) {
      return '${baseId}_s${season}_e$episode';
    }
    return baseId;
  }

  static Map<String, List<SceneBookmark>> _readAllFromBox() {
    if (!Hive.isBoxOpen(AppConstants.settingsBox)) {
      return {};
    }
    final box = Hive.box(AppConstants.settingsBox);
    final raw = box.get(_storageKey);
    if (raw is! String || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final result = <String, List<SceneBookmark>>{};
      decoded.forEach((key, value) {
        if (key is String && value is List) {
          result[key] = value
              .whereType<Map>()
              .map(
                (item) => SceneBookmark.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList();
        }
      });
      return result;
    } catch (_) {
      return {};
    }
  }

  static Future<void> _writeAllToBox(
    Map<String, List<SceneBookmark>> all,
  ) async {
    if (!Hive.isBoxOpen(AppConstants.settingsBox)) return;
    final box = Hive.box(AppConstants.settingsBox);
    final serializable = <String, dynamic>{};
    all.forEach((key, list) {
      if (list.isNotEmpty) {
        serializable[key] = list.map((b) => b.toJson()).toList();
      }
    });
    await box.put(_storageKey, jsonEncode(serializable));
  }

  /// Returns all bookmarks for [mediaKey], sorted by timestamp ascending.
  static List<SceneBookmark> getBookmarks(String mediaKey) {
    final all = _readAllFromBox();
    final list = List<SceneBookmark>.from(all[mediaKey] ?? const []);
    list.sort((a, b) => a.positionMs.compareTo(b.positionMs));
    return list;
  }

  /// Saves a new [SceneBookmark] and returns the updated list for its mediaKey.
  static Future<List<SceneBookmark>> addBookmark(SceneBookmark bookmark) async {
    final all = _readAllFromBox();
    final current = List<SceneBookmark>.from(
      all[bookmark.mediaKey] ?? const [],
    );
    current.removeWhere((b) => b.id == bookmark.id);
    current.add(bookmark);
    current.sort((a, b) => a.positionMs.compareTo(b.positionMs));
    all[bookmark.mediaKey] = current;
    await _writeAllToBox(all);
    return current;
  }

  /// Deletes a bookmark by [id] for [mediaKey] and returns the updated list.
  static Future<List<SceneBookmark>> deleteBookmark(
    String mediaKey,
    String id,
  ) async {
    final all = _readAllFromBox();
    final current = List<SceneBookmark>.from(all[mediaKey] ?? const []);
    current.removeWhere((b) => b.id == id);
    all[mediaKey] = current;
    await _writeAllToBox(all);
    return current;
  }
}
