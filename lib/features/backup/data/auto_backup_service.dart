import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_strings.dart';
import '../domain/models/cineva_backup_payload.dart';
import 'backup_restore_service.dart';

/// Supported schedules for local automatic backups to `Documents/Cineva`.
enum AutoBackupFrequency {
  off,
  weekly,
  monthly;

  Duration? get interval {
    switch (this) {
      case AutoBackupFrequency.off:
        return null;
      case AutoBackupFrequency.weekly:
        return const Duration(days: 7);
      case AutoBackupFrequency.monthly:
        return const Duration(days: 30);
    }
  }

  String localizedTitle(AppStrings s) {
    switch (this) {
      case AutoBackupFrequency.off:
        return s.autoBackupFreqOff;
      case AutoBackupFrequency.weekly:
        return s.autoBackupFreqWeekly;
      case AutoBackupFrequency.monthly:
        return s.autoBackupFreqMonthly;
    }
  }

  String localizedDescription(AppStrings s) {
    switch (this) {
      case AutoBackupFrequency.off:
        return s.autoBackupFreqOffDesc;
      case AutoBackupFrequency.weekly:
        return s.autoBackupFreqWeeklyDesc;
      case AutoBackupFrequency.monthly:
        return s.autoBackupFreqMonthlyDesc;
    }
  }

  static AutoBackupFrequency fromName(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'weekly':
        return AutoBackupFrequency.weekly;
      case 'monthly':
        return AutoBackupFrequency.monthly;
      default:
        return AutoBackupFrequency.off;
    }
  }
}

/// Metadata for a saved local `.cineva` auto-backup file.
class AutoBackupFileEntry {
  final String fileName;
  final String filePath;
  final DateTime modifiedAt;
  final int sizeBytes;

  const AutoBackupFileEntry({
    required this.fileName,
    required this.filePath,
    required this.modifiedAt,
    required this.sizeBytes,
  });

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    final kb = sizeBytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(2)} MB';
  }

  String get formattedDate =>
      DateFormat('dd/MM/yyyy HH:mm').format(modifiedAt.toLocal());
}

/// Manages local scheduled auto-backups (`Weekly` or `Monthly`) saved to
/// `Documents/Cineva` for all users (without requiring Google Sign-In).
class AutoBackupService {
  AutoBackupService._();

  static const MethodChannel _channel = MethodChannel(
    'com.cinevagroup.cinevastream/autobackup',
  );

  static const String _keyFrequency = 'auto_backup_frequency';
  static const String _keyLastRunMs = 'auto_backup_last_run_ms';
  static const String _keyLastPath = 'auto_backup_last_path';

  /// Maximum number of local auto-backup snapshots kept in rotation.
  static const int maxRetainedBackups = 5;

  /// Human-readable display path shown in the UI.
  static const String displayFolderPath = 'Documents/Cineva';

  static Box? get _box =>
      Hive.isBoxOpen(AppConstants.settingsBox)
          ? Hive.box(AppConstants.settingsBox)
          : null;

  /// Gets the currently configured [AutoBackupFrequency].
  static AutoBackupFrequency getFrequency() {
    final raw = _box?.get(_keyFrequency) as String?;
    return AutoBackupFrequency.fromName(raw);
  }

  /// Persists the selected [AutoBackupFrequency].
  static Future<void> setFrequency(AutoBackupFrequency frequency) async {
    await _box?.put(_keyFrequency, frequency.name);
  }

  /// Gets the timestamp of the last successful auto-backup, or `null` if never run.
  static DateTime? getLastBackupTime() {
    final ms = _box?.get(_keyLastRunMs) as int?;
    if (ms == null || ms <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Computes the next scheduled auto-backup time based on [frequency] and [lastRunAt].
  static DateTime? getNextScheduledTime({
    AutoBackupFrequency? frequency,
    DateTime? lastRunAt,
  }) {
    final freq = frequency ?? getFrequency();
    final interval = freq.interval;
    if (interval == null) return null;
    final last = lastRunAt ?? getLastBackupTime();
    if (last == null) return DateTime.now();
    return last.add(interval);
  }

  /// Pure helper that determines whether a scheduled auto-backup is due.
  static bool isBackupDue({
    required AutoBackupFrequency frequency,
    required DateTime? lastRunAt,
    DateTime? now,
  }) {
    final interval = frequency.interval;
    if (interval == null) return false;
    if (lastRunAt == null) return true;
    final current = now ?? DateTime.now();
    return current.difference(lastRunAt) >= interval;
  }

  /// Resolves the local directory where auto-backup files are stored and indexed.
  ///
  /// - On Windows / Desktop: `<User Documents>/Cineva`
  /// - On Android: mirrors in `<AppDocuments>/Cineva` AND writes to public
  ///   `/storage/emulated/0/Documents/Cineva` via `MediaStore`.
  static Future<Directory> resolveLocalBackupDirectory({
    Directory? overrideBaseDir,
  }) async {
    final baseDir = overrideBaseDir ?? await getApplicationDocumentsDirectory();
    final targetDir = Directory(
      '${baseDir.path}${Platform.pathSeparator}Cineva',
    );
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    return targetDir;
  }

  /// Saves a backup payload directly to `Documents/Cineva`, rotates old snapshots
  /// beyond [maxRetainedBackups], and records the last backup timestamp.
  static Future<BackupOperationResult> savePayloadToAutoBackup(
    CinevaBackupPayload payload, {
    Directory? overrideBaseDir,
    DateTime? timestampOverride,
  }) async {
    try {
      final now = timestampOverride ?? DateTime.now();
      final encoded = payload.toEncodedString();
      final bytes = Uint8List.fromList(utf8.encode(encoded));
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(now);
      final fileName = 'Cineva_AutoBackup_$stamp.cineva';

      final localDir = await resolveLocalBackupDirectory(
        overrideBaseDir: overrideBaseDir,
      );
      final localFile = File(
        '${localDir.path}${Platform.pathSeparator}$fileName',
      );
      await localFile.writeAsBytes(bytes, flush: true);

      String finalDisplayPath = localFile.path;

      // On Android, also write to public /storage/emulated/0/Documents/Cineva
      if (!kIsWeb &&
          overrideBaseDir == null &&
          !Platform.environment.containsKey('FLUTTER_TEST') &&
          Platform.isAndroid) {
        try {
          final pubPath = await _channel.invokeMethod<String>(
            'saveToPublicDocuments',
            {
              'fileName': fileName,
              'bytes': bytes,
            },
          );
          if (pubPath != null && pubPath.isNotEmpty) {
            finalDisplayPath = pubPath;
          }
        } catch (e) {
          debugPrint('[AutoBackupService] Android public Documents note: $e');
        }
      }

      await _rotateOldBackups(localDir);

      await _box?.put(_keyLastRunMs, now.millisecondsSinceEpoch);
      await _box?.put(_keyLastPath, finalDisplayPath);

      return BackupOperationResult(
        success: true,
        filePath: finalDisplayPath,
        watchlistCount: payload.watchlist.length,
        historyCount: payload.watchHistory.length,
      );
    } catch (e) {
      debugPrint('[AutoBackupService] savePayloadToAutoBackup error: $e');
      return BackupOperationResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Creates a snapshot of all current app data and saves it immediately to `Documents/Cineva`.
  static Future<BackupOperationResult> runAutoBackupNow(
    dynamic ref, {
    Directory? overrideBaseDir,
  }) async {
    try {
      final payload = await BackupRestoreService.createPayload(ref);
      return await savePayloadToAutoBackup(
        payload,
        overrideBaseDir: overrideBaseDir,
      );
    } catch (e) {
      return BackupOperationResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Checks if the user's scheduled auto-backup (`Weekly` or `Monthly`) is due,
  /// and if so, runs it silently in the background.
  static Future<bool> checkAndRunScheduledBackup(
    dynamic ref, {
    Directory? overrideBaseDir,
  }) async {
    try {
      final freq = getFrequency();
      final lastRun = getLastBackupTime();
      if (!isBackupDue(frequency: freq, lastRunAt: lastRun)) {
        return false;
      }
      final result = await runAutoBackupNow(
        ref,
        overrideBaseDir: overrideBaseDir,
      );
      return result.success;
    } catch (e) {
      debugPrint('[AutoBackupService] checkAndRunScheduledBackup error: $e');
      return false;
    }
  }

  /// Lists all saved `.cineva` auto-backup files sorted newest first.
  static Future<List<AutoBackupFileEntry>> listSavedAutoBackups({
    Directory? overrideBaseDir,
  }) async {
    if (overrideBaseDir == null &&
        !kIsWeb &&
        Platform.environment.containsKey('FLUTTER_TEST')) {
      return const [];
    }
    try {
      final dir = await resolveLocalBackupDirectory(
        overrideBaseDir: overrideBaseDir,
      );
      if (!await dir.exists()) return const [];

      final entities = await dir.list().toList();
      final entries = <AutoBackupFileEntry>[];
      for (final entity in entities) {
        if (entity is File &&
            entity.path.toLowerCase().endsWith('.cineva')) {
          final stat = await entity.stat();
          final name = entity.uri.pathSegments.isNotEmpty
              ? entity.uri.pathSegments.last
              : entity.path.split(Platform.pathSeparator).last;
          entries.add(
            AutoBackupFileEntry(
              fileName: name,
              filePath: entity.path,
              modifiedAt: stat.modified,
              sizeBytes: stat.size,
            ),
          );
        }
      }
      entries.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
      return entries;
    } catch (e) {
      debugPrint('[AutoBackupService] listSavedAutoBackups error: $e');
      return const [];
    }
  }

  /// Restores application data directly from a saved auto-backup file at [filePath].
  static Future<BackupOperationResult> restoreFromFile(
    dynamic ref,
    String filePath,
  ) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return const BackupOperationResult(
          success: false,
          errorMessage: 'File cadangan tidak ditemukan.',
        );
      }
      final content = await file.readAsString();
      final payload = CinevaBackupPayload.fromEncodedString(content);
      return await BackupRestoreService.applyPayload(ref, payload);
    } catch (e) {
      return BackupOperationResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Deletes a saved auto-backup file at [filePath].
  static Future<bool> deleteBackupFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _rotateOldBackups(Directory dir) async {
    try {
      final entities = await dir.list().toList();
      final files = <File>[];
      for (final entity in entities) {
        if (entity is File &&
            entity.path.toLowerCase().endsWith('.cineva')) {
          files.add(entity);
        }
      }
      if (files.length <= maxRetainedBackups) return;

      final withStats = <({File file, DateTime modified})>[];
      for (final f in files) {
        final stat = await f.stat();
        withStats.add((file: f, modified: stat.modified));
      }
      withStats.sort((a, b) => b.modified.compareTo(a.modified));

      for (var i = maxRetainedBackups; i < withStats.length; i++) {
        try {
          await withStats[i].file.delete();
        } catch (_) {}
      }
    } catch (_) {}
  }
}
