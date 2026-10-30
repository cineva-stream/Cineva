import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/app_constants.dart';

/// Centralized service for user preferences stored in Hive.
class SettingsService {
  static const String keyAppLanguage = 'app_language';
  static const String keyDefaultSubtitleLang = 'default_subtitle_lang';
  static const String keyAutoTranslate = 'auto_translate_indonesian';
  static const String keyDefaultQuality = 'default_quality';
  static const String keySubtitleFontSize = 'subtitle_font_size';
  static const String keyWifiOnlySeeding = 'wifi_only_seeding';
  static const String keyAutoStopSeeding = 'auto_stop_seeding';
  static const String keyContentPreference = 'content_preference';

  static Box get _box => Hive.box(AppConstants.settingsBox);

  /// App interface language: 'id' (Bahasa Indonesia) or 'en' (English).
  /// Defaults to 'id'.
  static String getAppLanguage() {
    return _box.get(keyAppLanguage, defaultValue: 'id') as String;
  }

  static Future<void> setAppLanguage(String lang) async {
    await _box.put(keyAppLanguage, lang);
  }

  /// Content preference: 'all', 'indonesia', 'anime', 'hollywood', 'korea', 'japan', 'bollywood'.
  /// Defaults to 'all'.
  static String getContentPreference() {
    return _box.get(keyContentPreference, defaultValue: 'all') as String;
  }

  static Future<void> setContentPreference(String preference) async {
    await _box.put(keyContentPreference, preference);
  }

  /// Default subtitle language: 'id' (Indonesia), 'en' (English), 'off' (Matikan).
  /// Defaults to 'id' (Indonesian).
  static String getDefaultSubtitleLang() {
    return _box.get(keyDefaultSubtitleLang, defaultValue: 'id') as String;
  }

  static Future<void> setDefaultSubtitleLang(String lang) async {
    await _box.put(keyDefaultSubtitleLang, lang);
  }

  /// Whether to automatically translate English or available subtitles to Indonesian
  /// if native Indonesian subtitles are not available.
  /// Defaults to true.
  static bool getAutoTranslate() {
    return _box.get(keyAutoTranslate, defaultValue: true) as bool;
  }

  static Future<void> setAutoTranslate(bool enabled) async {
    await _box.put(keyAutoTranslate, enabled);
  }

  /// Default streaming quality: 'Auto', '1080p', '720p', '480p'.
  /// Defaults to 'Auto'.
  static String getDefaultQuality() {
    return _box.get(keyDefaultQuality, defaultValue: 'Auto') as String;
  }

  static Future<void> setDefaultQuality(String quality) async {
    await _box.put(keyDefaultQuality, quality);
  }

  /// Subtitle font size label: 'Kecil' (16), 'Sedang' (20), 'Besar' (24).
  static String getSubtitleFontSize() {
    return _box.get(keySubtitleFontSize, defaultValue: 'Sedang') as String;
  }

  static Future<void> setSubtitleFontSize(String size) async {
    await _box.put(keySubtitleFontSize, size);
  }

  /// Returns the subtitle font size in points/pixels based on user preference.
  /// 'Kecil' -> 16.0, 'Sedang' -> 20.0, 'Besar' -> 24.0.
  static double getSubtitleFontSizePoints() {
    try {
      final size = getSubtitleFontSize().toLowerCase();
      if (size.contains('kecil') || size.contains('small') || size == '16') {
        return 16.0;
      } else if (size.contains('besar') || size.contains('large') || size == '24') {
        return 24.0;
      } else {
        return 20.0;
      }
    } catch (_) {
      return 20.0;
    }
  }

  static bool getWifiOnlySeeding() {
    return _box.get(keyWifiOnlySeeding, defaultValue: true) as bool;
  }

  static Future<void> setWifiOnlySeeding(bool value) async {
    await _box.put(keyWifiOnlySeeding, value);
  }

  static const String keySubtitleBackground = 'subtitle_background';
  static const String keySubtitleStrokeWidth = 'subtitle_stroke_width';
  static const String keySubtitleBottomOffset = 'subtitle_bottom_offset';
  static const String keySubtitleTextColor = 'subtitle_text_color';
  static const String keyHardwareAcceleration = 'hardware_acceleration';
  static const String keyDownloadLimit = 'download_limit';
  static const String keyUploadLimit = 'upload_limit';

  static String getSubtitleBackground() {
    return _box.get(keySubtitleBackground, defaultValue: 'Transparan') as String;
  }

  static Future<void> setSubtitleBackground(String bg) async {
    await _box.put(keySubtitleBackground, bg);
  }

  /// Returns the subtitle background opacity (0.0 to 1.0) based on user preference.
  /// 'Transparan' -> 0.0, 'Semi-Transparan' -> 0.5, 'Hitam Pekat' -> 1.0.
  static double getSubtitleBackgroundOpacity() {
    try {
      final bg = getSubtitleBackground().toLowerCase();
      if (bg.contains('semi')) {
        return 0.5;
      } else if (bg.contains('hitam') || bg.contains('pekat') || bg.contains('solid') || bg.contains('dark')) {
        return 1.0;
      } else {
        return 0.0;
      }
    } catch (_) {
      return 0.0;
    }
  }

  /// Subtitle stroke width (outline) in pixels. Default: 2.5
  static double getSubtitleStrokeWidth() {
    try {
      final val = _box.get(keySubtitleStrokeWidth);
      if (val is num) return val.toDouble();
      return 2.5;
    } catch (_) {
      return 2.5;
    }
  }

  static Future<void> setSubtitleStrokeWidth(double width) async {
    await _box.put(keySubtitleStrokeWidth, width);
  }

  /// Subtitle vertical position (bottom offset) in pixels. Default: 32.0
  static double getSubtitleBottomOffset() {
    try {
      final val = _box.get(keySubtitleBottomOffset);
      if (val is num) return val.toDouble();
      return 32.0;
    } catch (_) {
      return 32.0;
    }
  }

  static Future<void> setSubtitleBottomOffset(double offset) async {
    await _box.put(keySubtitleBottomOffset, offset);
  }

  /// Subtitle text color as ARGB integer. Default: 0xFFFFFFFF (White)
  static int getSubtitleTextColorValue() {
    try {
      final val = _box.get(keySubtitleTextColor);
      if (val is int) return val;
      return 0xFFFFFFFF;
    } catch (_) {
      return 0xFFFFFFFF;
    }
  }

  static Future<void> setSubtitleTextColorValue(int colorValue) async {
    await _box.put(keySubtitleTextColor, colorValue);
  }

  static bool getHardwareAcceleration() {
    return _box.get(keyHardwareAcceleration, defaultValue: true) as bool;
  }

  static Future<void> setHardwareAcceleration(bool enabled) async {
    await _box.put(keyHardwareAcceleration, enabled);
  }

  static String getDownloadLimit() {
    return _box.get(keyDownloadLimit, defaultValue: '10 MB/s') as String;
  }

  static Future<void> setDownloadLimit(String limit) async {
    await _box.put(keyDownloadLimit, limit);
  }

  static String getUploadLimit() {
    return _box.get(keyUploadLimit, defaultValue: '1 MB/s') as String;
  }

  static Future<void> setUploadLimit(String limit) async {
    await _box.put(keyUploadLimit, limit);
  }

  /// Clears user watch history.
  static Future<void> clearWatchHistory() async {
    final historyBox = Hive.box(AppConstants.historyBox);
    await historyBox.clear();
  }

  // ── Legal Terms & Privacy Acceptance ──
  static const String keyLegalAccepted = 'legal_terms_accepted';

  static bool hasAcceptedLegal() {
    return _box.get(keyLegalAccepted, defaultValue: false) as bool;
  }

  static Future<void> setLegalAccepted(bool accepted) async {
    await _box.put(keyLegalAccepted, accepted);
  }
}
