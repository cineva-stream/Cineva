import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/platform/device_form_factor.dart';

/// Categories for user feedback and reports.
enum FeedbackCategory {
  bugs,
  features,
  report,
  general;

  String localizedLabel(bool isIndonesian) {
    switch (this) {
      case FeedbackCategory.bugs:
        return isIndonesian ? 'Bug & Masalah Teknis' : 'Bugs & Technical Issues';
      case FeedbackCategory.features:
        return isIndonesian ? 'Saran Fitur Baru' : 'Feature Suggestions';
      case FeedbackCategory.report:
        return isIndonesian ? 'Lapor Konten / Tayangan' : 'Report Media / Subtitles';
      case FeedbackCategory.general:
        return isIndonesian ? 'Lainnya / Umum' : 'General & Other';
    }
  }

  String get idLabel {
    switch (this) {
      case FeedbackCategory.bugs:
        return 'Bug / Kendala Teknis';
      case FeedbackCategory.features:
        return 'Saran Fitur';
      case FeedbackCategory.report:
        return 'Lapor Konten / Tayangan';
      case FeedbackCategory.general:
        return 'Lainnya';
    }
  }
}

/// Service that securely submits user feedback, bug reports, and media issues
/// to the Google Apps Script Webhook, which forwards them directly to the
/// developer's Telegram Bot and logs them in Google Sheets.
class FeedbackService {
  static const String defaultWebhookUrl =
      'https://script.google.com/macros/s/AKfycbz9b43oU7_URzpCGGG337pf2yDU7-VObkAB9dXHYg8fWHob0fcyEbKH0tdQaSC-YeLh/exec';

  final Dio _dio;
  final String webhookUrl;

  FeedbackService({Dio? dio, String? webhookUrl})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 20),
                followRedirects: true,
                maxRedirects: 5,
                validateStatus: (status) => status != null && status < 500,
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ),
        webhookUrl = webhookUrl ?? defaultWebhookUrl;

  /// Retrieves human-readable device and OS details.
  static Future<String> getDeviceInfo() async {
    if (kIsWeb) return 'Web Browser';
    try {
      final os = Platform.operatingSystem;
      final osVersion = Platform.operatingSystemVersion;
      final formFactor = gIsTv
          ? 'Android TV'
          : (Platform.isAndroid ? 'Android Mobile/Tablet' : (Platform.isWindows ? 'Windows Desktop' : os));
      return '$formFactor ($osVersion)';
    } catch (_) {
      return 'Unknown Device';
    }
  }

  /// Retrieves the current Cineva version string.
  static Future<String> getAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final build = AppConstants.normalizeBuildNumber(info.buildNumber);
      return 'v${info.version}+$build';
    } catch (_) {
      return 'v${AppConstants.appVersion}+${AppConstants.appBuildNumber}';
    }
  }

  /// Submits the feedback payload to the Google Apps Script Webhook.
  Future<bool> submitFeedback({
    required String name,
    required String category,
    required String title,
    required String description,
    String? deviceInfo,
    String? appVersion,
  }) async {
    final devInfo = deviceInfo ?? await getDeviceInfo();
    final ver = appVersion ?? await getAppVersion();

    final payload = {
      'name': name.trim().isEmpty ? 'Anonim' : name.trim(),
      'category': category,
      'title': title.trim(),
      'description': description.trim(),
      'deviceInfo': devInfo,
      'appVersion': ver,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      final response = await _dio.post<dynamic>(
        webhookUrl,
        data: jsonEncode(payload),
        options: Options(
          contentType: 'application/json',
        ),
      );

      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 400) {
        final data = response.data;
        if (data is Map && data['status'] == 'error') {
          debugPrint('[FeedbackService] Warning: Script returned error status: ${data['message']}');
          // Even if Google Sheets failed to append a row, the Telegram notification might have triggered,
          // or vice versa. Return true if HTTP succeeded, or false if explicit script error.
          return false;
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[FeedbackService] Failed to submit feedback: $e');
      return false;
    }
  }
}

