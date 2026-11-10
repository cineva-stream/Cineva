import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../features/history/data/repositories/watch_history_repository.dart';
import '../../../features/profile/data/profile_service.dart';
import '../../../features/profile/presentation/providers/profile_provider.dart';
import '../../../features/search/presentation/providers/search_history_provider.dart';
import '../../../features/settings/data/settings_service.dart';
import '../../../features/watchlist/data/watchlist_repository.dart';
import '../domain/models/cineva_backup_payload.dart';

/// Result of a backup export or restore operation.
class BackupOperationResult {
  final bool success;
  final String? filePath;
  final int watchlistCount;
  final int historyCount;
  final String? errorMessage;

  const BackupOperationResult({
    required this.success,
    this.filePath,
    this.watchlistCount = 0,
    this.historyCount = 0,
    this.errorMessage,
  });
}

/// Core service for creating, exporting, and restoring Cineva backup files (.cineva / .json).
class BackupRestoreService {
  BackupRestoreService._();

  /// Gathers all current application data into a single [CinevaBackupPayload].
  static Future<CinevaBackupPayload> createPayload(WidgetRef ref) async {
    final profile = ref.read(userProfileProvider);

    // Convert custom avatar to Base64 thumbnail if available
    String? customAvatarBase64;
    if (profile.customAvatarPath != null) {
      try {
        final avatarFile = File(profile.customAvatarPath!);
        if (await avatarFile.exists()) {
          final bytes = await avatarFile.readAsBytes();
          customAvatarBase64 = base64Encode(bytes);
        }
      } catch (e) {
        debugPrint('[BackupRestoreService] Failed encoding avatar: $e');
      }
    }

    final watchlist = ref.read(watchlistRepositoryProvider).getAll();
    final watchHistory = ref.read(watchHistoryRepositoryProvider).getAll();
    final settings = SettingsService.exportPreferences();
    final searchHistory = ref.read(searchHistoryProvider);

    return CinevaBackupPayload(
      appVersion: AppConstants.appVersion,
      exportedAt: DateTime.now(),
      profile: profile,
      customAvatarBase64: customAvatarBase64,
      watchlist: watchlist,
      watchHistory: watchHistory,
      settings: settings,
      searchHistory: searchHistory,
    );
  }

  /// Exports current application dataset to a user-selected `.cineva` file.
  static Future<BackupOperationResult> exportBackupToFile(WidgetRef ref) async {
    try {
      final payload = await createPayload(ref);
      final jsonString = payload.toEncodedString();
      final bytes = utf8.encode(jsonString);

      final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final defaultFileName = 'Cineva_Backup_$dateStr.cineva';

      final uri = await FilePicker.saveFile(
        dialogTitle: 'Simpan File Cadangan Cineva',
        fileName: defaultFileName,
        bytes: Uint8List.fromList(bytes),
      );

      if (uri == null) {
        // User cancelled save dialog
        return const BackupOperationResult(
          success: false,
          errorMessage: 'Penyimpanan cadangan dibatalkan.',
        );
      }

      return BackupOperationResult(
        success: true,
        filePath: uri.path,
        watchlistCount: payload.watchlist.length,
        historyCount: payload.watchHistory.length,
      );
    } catch (e) {
      debugPrint('[BackupRestoreService] Export error: $e');
      return BackupOperationResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Prompts user to pick a backup file and applies its contents to local storage.
  static Future<BackupOperationResult> pickAndRestoreBackupFile(WidgetRef ref) async {
    try {
      final files = await FilePicker.pickFiles(
        dialogTitle: 'Pilih File Cadangan Cineva',
        type: FileType.any,
      );

      if (files.isEmpty) {
        return const BackupOperationResult(
          success: false,
          errorMessage: 'Pemilihan file dibatalkan.',
        );
      }

      final file = files.first;
      Uint8List? bytes;
      if (file.path != null && file.path!.isNotEmpty) {
        final ioFile = File(file.path!);
        if (await ioFile.exists()) {
          try {
            bytes = await ioFile.readAsBytes();
          } catch (e) {
            debugPrint('[BackupRestoreService] Direct file read error: $e');
          }
        }
      }
      bytes ??= await file.readAsBytes();

      if (bytes.isEmpty) {
        return const BackupOperationResult(
          success: false,
          errorMessage: 'File cadangan yang dipilih kosong.',
        );
      }

      final jsonContent = utf8.decode(bytes);
      final payload = CinevaBackupPayload.fromEncodedString(jsonContent);
      return await applyPayload(ref, payload);
    } on FormatException catch (e) {
      debugPrint('[BackupRestoreService] Format error: $e');
      return const BackupOperationResult(
        success: false,
        errorMessage:
            'File yang dipilih bukan berkas cadangan Cineva yang valid (.cineva / .json).',
      );
    } catch (e) {
      debugPrint('[BackupRestoreService] Restore error: $e');
      return BackupOperationResult(
        success: false,
        errorMessage: 'Gagal memulihkan cadangan: $e',
      );
    }
  }

  /// Atomically restores and imports a [CinevaBackupPayload] into local Hive databases & state providers.
  static Future<BackupOperationResult> applyPayload(
    WidgetRef ref,
    CinevaBackupPayload payload,
  ) async {
    try {
      // 1. Restore Custom Avatar if encoded in payload
      String? localAvatarPath;
      if (payload.customAvatarBase64 != null &&
          payload.customAvatarBase64!.isNotEmpty) {
        try {
          final avatarBytes = base64Decode(payload.customAvatarBase64!);
          final appDir = await getApplicationDocumentsDirectory();
          final targetAvatarFile = File(
            '${appDir.path}/cineva_avatar_${DateTime.now().millisecondsSinceEpoch}.png',
          );
          await targetAvatarFile.writeAsBytes(avatarBytes, flush: true);
          localAvatarPath = targetAvatarFile.path;
        } catch (e) {
          debugPrint('[BackupRestoreService] Failed restoring avatar file: $e');
        }
      }

      // 2. Restore Profile
      final restoredProfile = payload.profile.copyWith(
        customAvatarPath: localAvatarPath ?? payload.profile.customAvatarPath,
        isConfigured: true,
      );
      await ProfileService.saveProfile(restoredProfile);
      await ref.read(userProfileProvider.notifier).save(
            name: restoredProfile.name,
            username: restoredProfile.username,
            avatarId: restoredProfile.avatarId,
            customAvatarPath: restoredProfile.customAvatarPath,
          );

      // 3. Restore Watchlist
      if (payload.watchlist.isNotEmpty) {
        await ref
            .read(watchlistRepositoryProvider)
            .importItems(payload.watchlist);
        ref.read(watchlistProvider.notifier).refresh();
      }

      // 4. Restore Watch History
      if (payload.watchHistory.isNotEmpty) {
        await ref
            .read(watchHistoryRepositoryProvider)
            .importItems(payload.watchHistory);
        ref.read(watchHistoryProvider.notifier).refresh();
      }

      // 5. Restore Settings
      if (payload.settings.isNotEmpty) {
        await SettingsService.importPreferences(payload.settings);
      }

      // 6. Restore Search History
      if (payload.searchHistory.isNotEmpty) {
        await ref
            .read(searchHistoryProvider.notifier)
            .importQueries(payload.searchHistory);
      }

      return BackupOperationResult(
        success: true,
        watchlistCount: payload.watchlist.length,
        historyCount: payload.watchHistory.length,
      );
    } catch (e) {
      debugPrint('[BackupRestoreService] Apply error: $e');
      return BackupOperationResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }
}

