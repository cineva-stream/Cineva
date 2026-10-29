import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/app_update_service.dart';
import '../../domain/entities/app_update_info.dart';
import '../../../settings/data/settings_service.dart';

/// Service provider
final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  return AppUpdateService();
});

/// Lifecycle status for app updater
enum AppUpdateStatus {
  idle,
  checking,
  available,
  downloading,
  readyToInstall,
  installing,
  error,
}

/// State holding in-app update information and download progress
class AppUpdateState {
  final AppUpdateStatus status;
  final AppUpdateInfo? updateInfo;
  final double progress; // 0.0 to 1.0
  final int receivedBytes;
  final int totalBytes;
  final String? localApkPath;
  final String? errorMessage;
  final bool isDismissed;

  const AppUpdateState({
    this.status = AppUpdateStatus.idle,
    this.updateInfo,
    this.progress = 0.0,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.localApkPath,
    this.errorMessage,
    this.isDismissed = false,
  });

  AppUpdateState copyWith({
    AppUpdateStatus? status,
    AppUpdateInfo? updateInfo,
    double? progress,
    int? receivedBytes,
    int? totalBytes,
    String? localApkPath,
    String? errorMessage,
    bool? isDismissed,
  }) {
    return AppUpdateState(
      status: status ?? this.status,
      updateInfo: updateInfo ?? this.updateInfo,
      progress: progress ?? this.progress,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      localApkPath: localApkPath ?? this.localApkPath,
      errorMessage: errorMessage,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }
}

/// State notifier that orchestrates checking, downloading, and launching app update installer
class AppUpdateNotifier extends StateNotifier<AppUpdateState> {
  final AppUpdateService _service;
  CancelToken? _cancelToken;

  AppUpdateNotifier(this._service) : super(const AppUpdateState()) {
    // Automatically trigger cache cleanup of old APKs and check for updates on startup
    _init();
  }

  Future<void> _init() async {
    // 1. Automatically delete old downloaded APK files from previous updates
    await _service.cleanupDownloadedApks();

    // 2. Schedule persistent background update checks via Android WorkManager
    await _service.scheduleBackgroundUpdateCheck();

    // 3. Perform immediate check for new release
    await checkForUpdate();
  }

  /// Checks GitHub Releases for a newer version
  Future<void> checkForUpdate() async {
    if (state.status == AppUpdateStatus.downloading) return;

    state = state.copyWith(status: AppUpdateStatus.checking, errorMessage: null);

    final info = await _service.checkForUpdate();
    if (info != null) {
      state = state.copyWith(
        status: AppUpdateStatus.available,
        updateInfo: info,
        isDismissed: false,
      );
      // Automatically post system notification with dynamic version and changelog
      final isId = SettingsService.getAppLanguage() == 'id';
      final body = isId
          ? 'Update Tersedia, Segera update sekarang untuk menikmati layanan streaming dengan lebih baik.'
          : 'New version available, Update now to improve your streaming.';
      await _service.showUpdateNotification(info, customBody: body);
    } else {
      state = state.copyWith(
        status: AppUpdateStatus.idle,
        updateInfo: null,
      );
    }
  }

  /// Starts downloading the APK file with real-time progress updates
  Future<void> startDownload() async {
    final info = state.updateInfo;
    if (info == null) return;

    _cancelToken = CancelToken();

    state = state.copyWith(
      status: AppUpdateStatus.downloading,
      progress: 0.0,
      receivedBytes: 0,
      totalBytes: info.apkSizeBytes,
      errorMessage: null,
    );

    try {
      final savePath = await _service.downloadApk(
        info.apkUrl,
        info.apkFileName,
        cancelToken: _cancelToken,
        onProgress: (received, total) {
          final frac = total > 0 ? (received / total).clamp(0.0, 1.0) : 0.0;
          state = state.copyWith(
            progress: frac,
            receivedBytes: received,
            totalBytes: total,
          );
        },
      );

      state = state.copyWith(
        status: AppUpdateStatus.readyToInstall,
        localApkPath: savePath,
        progress: 1.0,
      );

      // Automatically attempt to prompt package installer
      await triggerInstall();
    } catch (e) {
      if (_cancelToken?.isCancelled ?? false) {
        state = state.copyWith(
          status: AppUpdateStatus.available,
          progress: 0.0,
        );
      } else {
        debugPrint('[AppUpdateNotifier] Download failed: $e');
        state = state.copyWith(
          status: AppUpdateStatus.error,
          errorMessage: e.toString(),
        );
      }
    }
  }

  /// Cancels any active APK download
  void cancelDownload() {
    _cancelToken?.cancel('Cancelled by user');
    state = state.copyWith(
      status: AppUpdateStatus.available,
      progress: 0.0,
      receivedBytes: 0,
    );
  }

  /// Checks if Android has allowed "Install unknown apps" permission for Cineva
  Future<bool> canRequestPackageInstalls() async {
    return await _service.canRequestPackageInstalls();
  }

  /// Opens the system Settings screen to toggle install permission
  Future<void> openInstallSettings() async {
    await _service.openInstallSettings();
  }

  /// Triggers the native Android package installer modal
  Future<bool> triggerInstall() async {
    final path = state.localApkPath;
    if (path == null || !File(path).existsSync()) {
      state = state.copyWith(
        status: AppUpdateStatus.error,
        errorMessage: 'APK file missing',
      );
      return false;
    }

    state = state.copyWith(status: AppUpdateStatus.installing);

    final success = await _service.installApk(path);
    if (!success) {
      // Revert to ready to install so user can tap again
      state = state.copyWith(status: AppUpdateStatus.readyToInstall);
    }
    return success;
  }

  /// Cleans up any cached APK files on device
  Future<int> cleanupStorage() async {
    final count = await _service.cleanupDownloadedApks();
    if (state.status == AppUpdateStatus.readyToInstall) {
      state = state.copyWith(
        status: AppUpdateStatus.available,
        localApkPath: null,
      );
    }
    return count;
  }

  /// Dismisses the update banner for the current session
  void dismiss() {
    state = state.copyWith(isDismissed: true);
  }
}

/// Provider for app update state
final appUpdateProvider = StateNotifierProvider<AppUpdateNotifier, AppUpdateState>((ref) {
  final service = ref.watch(appUpdateServiceProvider);
  return AppUpdateNotifier(service);
});
