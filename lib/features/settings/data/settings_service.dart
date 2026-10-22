import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/app_constants.dart';

/// Centralized service for user preferences stored in Hive.
class SettingsService {
  static const String keyDefaultSubtitleLang = 'default_subtitle_lang';
  static const String keyAutoTranslate = 'auto_translate_indonesian';
  static const String keyDefaultQuality = 'default_quality';
  static const String keySubtitleFontSize = 'subtitle_font_size';
  static const String keyWifiOnlySeeding = 'wifi_only_seeding';
  static const String keyAutoStopSeeding = 'auto_stop_seeding';
  static const String keyContentPreference = 'content_preference';

  static Box get _box => Hive.box(AppConstants.settingsBox);

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

  static bool getWifiOnlySeeding() {
    return _box.get(keyWifiOnlySeeding, defaultValue: true) as bool;
  }

  static Future<void> setWifiOnlySeeding(bool value) async {
    await _box.put(keyWifiOnlySeeding, value);
  }

  static const String keySubtitleBackground = 'subtitle_background';
  static const String keyHardwareAcceleration = 'hardware_acceleration';
  static const String keyDownloadLimit = 'download_limit';
  static const String keyUploadLimit = 'upload_limit';

  static String getSubtitleBackground() {
    return _box.get(keySubtitleBackground, defaultValue: 'Transparan') as String;
  }

  static Future<void> setSubtitleBackground(String bg) async {
    await _box.put(keySubtitleBackground, bg);
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
}
