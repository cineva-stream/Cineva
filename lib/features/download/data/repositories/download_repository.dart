import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/models/download_item.dart';

/// Repository managing persistent download metadata backed by Hive.
class DownloadRepository {
  Box get _box => Hive.box(AppConstants.downloadsBox);

  /// Returns all download items sorted by creation date (newest first).
  List<DownloadItem> getAllDownloads() {
    final items = <DownloadItem>[];
    for (final key in _box.keys) {
      try {
        final raw = _box.get(key);
        if (raw is Map) {
          items.add(DownloadItem.fromJson(raw));
        }
      } catch (_) {
        // Skip corrupted entries
      }
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  /// Returns a download item by its unique ID.
  DownloadItem? getDownloadById(String id) {
    try {
      final raw = _box.get(id);
      if (raw is Map) {
        return DownloadItem.fromJson(raw);
      }
    } catch (_) {}
    return null;
  }

  /// Saves or updates a download item in Hive.
  Future<void> saveDownload(DownloadItem item) async {
    await _box.put(item.id, item.toJson());
  }

  /// Deletes a download item from Hive and deletes its local files from disk.
  Future<void> deleteDownload(String id) async {
    final item = getDownloadById(id);
    if (item != null) {
      try {
        final videoFile = File(item.videoPath);
        if (item.videoPath.endsWith('master.m3u8')) {
          final parentDir = videoFile.parent;
          if (await parentDir.exists()) {
            await parentDir.delete(recursive: true);
          }
        } else {
          if (await videoFile.exists()) {
            await videoFile.delete();
          }
          if (item.subtitlePath != null) {
            final subFile = File(item.subtitlePath!);
            if (await subFile.exists()) {
              await subFile.delete();
            }
          }
        }
      } catch (_) {}
    }
    await _box.delete(id);
  }

  /// Computes the total storage size in bytes occupied by all downloaded videos.
  int getTotalDownloadedBytes() {
    int total = 0;
    for (final item in getAllDownloads()) {
      if (item.isCompleted) {
        try {
          final file = File(item.videoPath);
          if (item.videoPath.endsWith('master.m3u8')) {
            final parentDir = file.parent;
            if (parentDir.existsSync()) {
              int dirSize = 0;
              for (final f in parentDir.listSync(recursive: true)) {
                if (f is File) dirSize += f.lengthSync();
              }
              if (dirSize > 0) {
                total += dirSize;
                continue;
              }
            }
          } else if (file.existsSync()) {
            total += file.lengthSync();
            continue;
          }
        } catch (_) {}
        total += item.downloadedBytes > 0 ? item.downloadedBytes : item.totalBytes;
      }
    }
    return total;
  }
}

// ── Riverpod Provider ──
final downloadRepositoryProvider = Provider<DownloadRepository>((ref) {
  return DownloadRepository();
});
