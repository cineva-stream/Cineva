/// Application-wide constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'Cineva Stream';
  static const String appVersion = '1.0.2';
  static const String appTagline = 'Stream Freely';

  // ── Durations ──
  static const Duration searchDebounce = Duration(milliseconds: 500);
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 350);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // ── Layout ──
  static const double horizontalPadding = 16.0;
  static const double cardBorderRadius = 16.0;
  static const double posterAspectRatio = 2 / 3;
  static const double backdropAspectRatio = 16 / 9;

  // ── Torrent Defaults ──
  static const int defaultDownloadLimitBytes = 10 * 1024 * 1024; // 10 MB/s
  static const int defaultUploadLimitBytes = 1 * 1024 * 1024; // 1 MB/s

  // ── Hive Box Names ──
  static const String watchlistBox = 'watchlist';
  static const String historyBox = 'watch_history';
  static const String settingsBox = 'settings';
  static const String downloadsBox = 'cineva_downloads';
}
