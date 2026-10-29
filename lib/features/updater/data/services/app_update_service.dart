import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/app_update_info.dart';

/// Service that handles GitHub release checking, APK download with streaming progress,
/// native package installer execution, and automated cache cleanup.
class AppUpdateService {
  static const MethodChannel _channel = MethodChannel(
    'com.primadev.cineva/updater',
  );
  static const String _latestReleaseUrl =
      'https://api.github.com/repos/cineva-stream/Cineva/releases/latest';

  final Dio _dio;

  AppUpdateService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              headers: {'Accept': 'application/vnd.github.v3+json'},
            ),
          );

  /// Compares whether [remoteVer] is strictly greater than [currentVer] using semantic versioning.
  static bool isVersionNewer(String remoteVer, String currentVer) {
    try {
      final cleanRemote = remoteVer.toLowerCase().replaceAll(
        RegExp(r'[^0-9.]'),
        '',
      );
      final cleanCurrent = currentVer.toLowerCase().replaceAll(
        RegExp(r'[^0-9.]'),
        '',
      );

      final rParts = cleanRemote
          .split('.')
          .map((p) => int.tryParse(p) ?? 0)
          .toList();
      final cParts = cleanCurrent
          .split('.')
          .map((p) => int.tryParse(p) ?? 0)
          .toList();

      final maxLen = rParts.length > cParts.length
          ? rParts.length
          : cParts.length;
      for (int i = 0; i < maxLen; i++) {
        final r = i < rParts.length ? rParts[i] : 0;
        final c = i < cParts.length ? cParts[i] : 0;
        if (r > c) return true;
        if (r < c) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Checks the official GitHub repository for a newer release.
  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await _dio.get(_latestReleaseUrl);
      if (response.statusCode != 200 || response.data is! Map) {
        return null;
      }

      final data = response.data as Map<String, dynamic>;
      final tagName = data['tag_name']?.toString() ?? '';
      final cleanRemoteVersion = tagName
          .replaceFirst(RegExp(r'^[vV]'), '')
          .trim();

      if (!isVersionNewer(cleanRemoteVersion, currentVersion)) {
        return null;
      }

      final releaseTitle =
          data['name']?.toString() ?? 'Cineva v$cleanRemoteVersion';
      final changelog = data['body']?.toString() ?? '';
      final publishedAtStr = data['published_at']?.toString();
      final publishedAt = publishedAtStr != null
          ? DateTime.tryParse(publishedAtStr)
          : null;

      // Locate the APK asset in release
      final assets =
          (data['assets'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final apkAsset = assets.firstWhere(
        (a) => a['name']?.toString().toLowerCase().endsWith('.apk') ?? false,
        orElse: () => <String, dynamic>{},
      );

      final apkUrl = apkAsset['browser_download_url']?.toString();
      if (apkUrl == null || apkUrl.isEmpty) {
        return null;
      }

      final apkFileName =
          apkAsset['name']?.toString() ?? 'Cineva_v$cleanRemoteVersion.apk';
      final apkSizeBytes = (apkAsset['size'] as num?)?.toInt() ?? 0;

      return AppUpdateInfo(
        latestVersion: cleanRemoteVersion,
        releaseTitle: releaseTitle,
        changelog: changelog,
        apkUrl: apkUrl,
        apkFileName: apkFileName,
        apkSizeBytes: apkSizeBytes,
        publishedAt: publishedAt,
        currentVersion: currentVersion,
      );
    } catch (e) {
      debugPrint('[AppUpdateService] Check update error: $e');
      return null;
    }
  }

  /// Downloads the APK file to temporary cache storage while emitting real-time progress.
  Future<String> downloadApk(
    String url,
    String fileName, {
    required void Function(int received, int total) onProgress,
    CancelToken? cancelToken,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final savePath = '${tempDir.path}/$fileName';

    final tempFile = File(savePath);
    if (await tempFile.exists()) {
      try {
        await tempFile.delete();
      } catch (_) {}
    }

    await _dio.download(
      url,
      savePath,
      cancelToken: cancelToken,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          onProgress(received, total);
        }
      },
    );

    return savePath;
  }

  /// Checks if Cineva currently has permission to install unknown apps on Android 8.0+.
  Future<bool> canRequestPackageInstalls() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final bool? allowed = await _channel.invokeMethod<bool>(
        'canRequestPackageInstalls',
      );
      return allowed ?? false;
    } catch (e) {
      debugPrint('[AppUpdateService] canRequestPackageInstalls error: $e');
      return false;
    }
  }

  /// Opens the system Settings screen allowing the user to toggle "Install unknown apps".
  Future<void> openInstallSettings() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('openInstallSettings');
    } catch (e) {
      debugPrint('[AppUpdateService] openInstallSettings error: $e');
    }
  }

  /// Launches the native Android package installer modal for the given [filePath].
  Future<bool> installApk(String filePath) async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final bool? success = await _channel.invokeMethod<bool>('installApk', {
        'filePath': filePath,
      });
      return success ?? false;
    } catch (e) {
      debugPrint('[AppUpdateService] installApk error: $e');
      return false;
    }
  }

  /// Schedules periodic background update checks using Android WorkManager.
  /// Runs reliably even when the app is completely terminated or closed.
  Future<bool> scheduleBackgroundUpdateCheck() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final bool? success = await _channel.invokeMethod<bool>(
        'scheduleBackgroundUpdateCheck',
      );
      return success ?? false;
    } catch (e) {
      debugPrint('[AppUpdateService] scheduleBackgroundUpdateCheck error: $e');
      return false;
    }
  }

  /// Displays a system notification for the available update with dynamic version, title, and localized message.
  Future<bool> showUpdateNotification(AppUpdateInfo info, {String? customBody}) async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final bodyText = (customBody != null && customBody.isNotEmpty)
          ? customBody
          : 'Update Tersedia, Segera update sekarang untuk menikmati layanan streaming dengan lebih baik.';
      final bool? success = await _channel
          .invokeMethod<bool>('showUpdateNotification', {
            'version': info.latestVersion,
            'title': info.releaseTitle,
            'body': bodyText,
          });
      return success ?? false;
    } catch (e) {
      debugPrint('[AppUpdateService] showUpdateNotification error: $e');
      return false;
    }
  }

  /// Checks if system notification permission is granted on Android.
  Future<bool> hasNotificationPermission() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final bool? granted = await _channel.invokeMethod<bool>(
        'hasNotificationPermission',
      );
      return granted ?? false;
    } catch (e) {
      debugPrint('[AppUpdateService] hasNotificationPermission error: $e');
      return false;
    }
  }

  /// Explicitly requests system notification permission on Android 13+ (API 33+).
  Future<void> requestNotificationPermission() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('requestNotificationPermission');
    } catch (e) {
      debugPrint('[AppUpdateService] requestNotificationPermission error: $e');
    }
  }

  /// Automatically or manually cleans up old update APK files from temporary and cache storage.
  /// This frees up internal device storage after updates or interrupted downloads.
  Future<int> cleanupDownloadedApks() async {
    int deletedCount = 0;
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        final files = tempDir.listSync();
        for (final file in files) {
          if (file is File && file.path.toLowerCase().endsWith('.apk')) {
            try {
              await file.delete();
              deletedCount++;
              debugPrint(
                '[AppUpdateService] Cleaned up cached APK: ${file.path}',
              );
            } catch (e) {
              debugPrint(
                '[AppUpdateService] Failed to delete APK: ${file.path}, error: $e',
              );
            }
          }
        }
      }

      // Also inspect external cache if present on Android
      if (Platform.isAndroid) {
        try {
          final extCaches = await getExternalCacheDirectories();
          if (extCaches != null) {
            for (final extDir in extCaches) {
              if (await extDir.exists()) {
                final files = extDir.listSync();
                for (final file in files) {
                  if (file is File &&
                      file.path.toLowerCase().endsWith('.apk')) {
                    try {
                      await file.delete();
                      deletedCount++;
                      debugPrint(
                        '[AppUpdateService] Cleaned up external cached APK: ${file.path}',
                      );
                    } catch (_) {}
                  }
                }
              }
            }
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[AppUpdateService] cleanupDownloadedApks error: $e');
    }
    return deletedCount;
  }
}
