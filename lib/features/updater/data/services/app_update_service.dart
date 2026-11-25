import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/platform/device_form_factor.dart';
import '../../domain/entities/app_update_info.dart';

/// Service that handles GitHub release checking, APK download with streaming progress,
/// native package installer execution, and automated cache cleanup.
class AppUpdateService {
  static const MethodChannel _channel = MethodChannel(
    'com.cinevagroup.cinevastream/updater',
  );
  static const String _latestReleaseUrl =
      'https://api.github.com/repos/cineva-stream/Cineva/releases/latest';
  static const String _releasesListUrl =
      'https://api.github.com/repos/cineva-stream/Cineva/releases?per_page=15';

  /// Threshold of missed updates that triggers a mandatory update screen.
  static const int mandatoryUpdateThreshold =
      AppUpdateInfo.mandatoryUpdateThreshold;

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

  /// Calculates the semantic version step distance between [remoteVer] and [currentVer].
  ///
  /// For example:
  /// - `1.2.1` -> `1.2.4` = `3` updates
  /// - `1.1.8` -> `1.2.1` = `3` updates (treating each minor bump as 10 patch steps)
  /// Returns `0` if [remoteVer] is not newer than [currentVer].
  static int calculateVersionDistance(String remoteVer, String currentVer) {
    if (!isVersionNewer(remoteVer, currentVer)) return 0;
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

      final rMajor = rParts.isNotEmpty ? rParts[0] : 0;
      final rMinor = rParts.length > 1 ? rParts[1] : 0;
      final rPatch = rParts.length > 2 ? rParts[2] : 0;

      final cMajor = cParts.isNotEmpty ? cParts[0] : 0;
      final cMinor = cParts.length > 1 ? cParts[1] : 0;
      final cPatch = cParts.length > 2 ? cParts[2] : 0;

      final diff =
          ((rMajor - cMajor) * 100) + ((rMinor - cMinor) * 10) + (rPatch - cPatch);
      return diff >= 1 ? diff : 1;
    } catch (_) {
      return 1;
    }
  }

  /// Counts how many published (non-draft, non-prerelease) releases in [releases]
  /// have a version tag strictly newer than [currentVersion].
  static int countMissedReleases(
    List<dynamic> releases,
    String currentVersion,
  ) {
    int count = 0;
    for (final item in releases) {
      if (item is! Map) continue;
      if (item['draft'] == true || item['prerelease'] == true) continue;
      final tag = item['tag_name']?.toString() ?? '';
      final cleanTag = tag.replaceFirst(RegExp(r'^[vV]'), '').trim();
      if (cleanTag.isNotEmpty && isVersionNewer(cleanTag, currentVersion)) {
        count++;
      }
    }
    return count;
  }

  /// Retrieves the list of CPU ABIs supported by the current device.
  static Future<List<String>> getSupportedAbis() async {
    try {
      final res = await _channel.invokeMethod<List<dynamic>>('getSupportedAbis');
      if (res != null && res.isNotEmpty) {
        return res.map((e) => e.toString().toLowerCase().trim()).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Selects the best matching APK asset based on device CPU architecture and form factor.
  /// Prioritizes dedicated Android TV build on TV, and specific ABIs (arm64-v8a, armeabi-v7a, x86_64) on mobile
  /// to minimize download size, falling back to universal or default Cineva_v{ver}.apk for maximum compatibility.
  static Map<String, dynamic> selectBestApkAsset({
    required List<Map<String, dynamic>> assets,
    required List<String> supportedAbis,
    required String version,
    bool isTv = false,
  }) {
    final apkAssets = assets.where((a) {
      final name = a['name']?.toString().toLowerCase() ?? '';
      return name.endsWith('.apk');
    }).toList();

    if (apkAssets.isEmpty) return {};

    // 0. If running on Android TV, prioritize the dedicated Cineva_v{ver}-android-tv.apk build
    if (isTv) {
      for (final a in apkAssets) {
        final name = a['name']?.toString().toLowerCase() ?? '';
        if (name.contains('android-tv')) {
          return {
            ...a,
            'targetAbi': 'Android TV',
          };
        }
      }
    }

    // 1. Try matching against device's supported ABIs in priority order
    for (final abi in supportedAbis) {
      final cleanAbi = abi.toLowerCase();
      for (final a in apkAssets) {
        final name = a['name']?.toString().toLowerCase() ?? '';
        // Skip android-tv asset on mobile phones if specific ABI assets are available
        if (!isTv && name.contains('android-tv')) continue;
        if (name.contains(cleanAbi)) {
          return {
            ...a,
            'targetAbi': cleanAbi,
          };
        }
      }
    }

    // 2. Fallback: Universal build (standard Cineva_v{ver}.apk without ABI/TV suffix)
    for (final a in apkAssets) {
      final name = a['name']?.toString().toLowerCase() ?? '';
      if (!name.contains('arm64') &&
          !name.contains('armeabi') &&
          !name.contains('armv7') &&
          !name.contains('x86_64') &&
          !name.contains('android-tv')) {
        return {
          ...a,
          'targetAbi': 'universal',
        };
      }
    }

    return {
      ...apkAssets.first,
      'targetAbi': 'universal',
    };
  }

  /// Checks the official GitHub repository for a newer release and counts missed updates.
  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      Map<String, dynamic>? data;
      int newerReleasesFromList = 0;

      // 1. Fetch recent releases list to accurately count how many updates the user has missed
      try {
        final listResponse = await _dio.get(_releasesListUrl);
        if (listResponse.statusCode == 200 && listResponse.data is List) {
          final releaseList = listResponse.data as List<dynamic>;
          newerReleasesFromList = countMissedReleases(
            releaseList,
            currentVersion,
          );
          for (final item in releaseList) {
            if (item is Map &&
                item['draft'] != true &&
                item['prerelease'] != true) {
              data = Map<String, dynamic>.from(item);
              break;
            }
          }
        }
      } catch (_) {
        // Fallback to /releases/latest below
      }

      // 2. Fallback to /releases/latest if list endpoint didn't yield a release
      if (data == null) {
        final response = await _dio.get(_latestReleaseUrl);
        if (response.statusCode != 200 || response.data is! Map) {
          return null;
        }
        data = Map<String, dynamic>.from(response.data as Map);
      }

      final tagName = data['tag_name']?.toString() ?? '';
      final cleanRemoteVersion = tagName
          .replaceFirst(RegExp(r'^[vV]'), '')
          .trim();

      if (!isVersionNewer(cleanRemoteVersion, currentVersion)) {
        return null;
      }

      final semverDistance = calculateVersionDistance(
        cleanRemoteVersion,
        currentVersion,
      );
      final missedUpdateCount = newerReleasesFromList > semverDistance
          ? newerReleasesFromList
          : semverDistance;

      final releaseTitle =
          data['name']?.toString() ?? 'Cineva v$cleanRemoteVersion';
      final changelog = data['body']?.toString() ?? '';
      final publishedAtStr = data['published_at']?.toString();
      final publishedAt = publishedAtStr != null
          ? DateTime.tryParse(publishedAtStr)
          : null;

      // Locate the release asset matching platform and CPU architecture
      final assets =
          (data['assets'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      Map<String, dynamic> selectedAsset = {};
      String targetAbi = 'universal';

      // On Windows desktop, look for .exe installer
      if (!kIsWeb && Platform.isWindows) {
        final exeAssets = assets.where((a) {
          final name = a['name']?.toString().toLowerCase() ?? '';
          return name.endsWith('.exe');
        }).toList();

        if (exeAssets.isNotEmpty) {
          selectedAsset = exeAssets.first;
          targetAbi = 'Windows x64';
        }
      }

      // Android fallback or default APK selection
      if (selectedAsset.isEmpty) {
        final supportedAbis = await getSupportedAbis();
        selectedAsset = selectBestApkAsset(
          assets: assets,
          supportedAbis: supportedAbis,
          version: cleanRemoteVersion,
          isTv: gIsTelevision,
        );
        targetAbi = selectedAsset['targetAbi']?.toString() ?? 'universal';
      }

      final apkUrl = selectedAsset['browser_download_url']?.toString();
      if (apkUrl == null || apkUrl.isEmpty) {
        return null;
      }

      final apkFileName =
          selectedAsset['name']?.toString() ?? 'Cineva_v$cleanRemoteVersion.apk';
      final apkSizeBytes = (selectedAsset['size'] as num?)?.toInt() ?? 0;

      return AppUpdateInfo(
        latestVersion: cleanRemoteVersion,
        releaseTitle: releaseTitle,
        changelog: changelog,
        apkUrl: apkUrl,
        apkFileName: apkFileName,
        apkSizeBytes: apkSizeBytes,
        publishedAt: publishedAt,
        currentVersion: currentVersion,
        targetAbi: targetAbi,
        missedUpdateCount: missedUpdateCount,
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
    if (kIsWeb) return false;
    if (Platform.isWindows) return true; // Windows does not require Android unknown app permission
    if (!Platform.isAndroid) return false;
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

  /// Launches the native installer for the downloaded package (APK on Android, setup.exe on Windows).
  Future<bool> installApk(String filePath) async {
    if (kIsWeb) return false;

    // Launch Windows installer executable
    if (Platform.isWindows) {
      try {
        await Process.start(filePath, []);
        return true;
      } catch (e) {
        debugPrint('[AppUpdateService] Windows launch error: $e');
        return false;
      }
    }

    if (!Platform.isAndroid) return false;
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

  /// Checks whether a system update notification has already been shown for [version].
  Future<bool> isUpdateNotified(String version) async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final bool? notified = await _channel.invokeMethod<bool>(
        'isUpdateNotified',
        {'version': version},
      );
      return notified ?? false;
    } catch (e) {
      debugPrint('[AppUpdateService] isUpdateNotified error: $e');
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
