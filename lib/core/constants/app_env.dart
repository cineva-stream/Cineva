import 'dart:io';
import 'package:flutter/foundation.dart';

/// Secure Environment Configuration (Zero-Hardcode Policy).
///
/// Credentials are injected at compile-time via:
/// 1. `--dart-define-from-file=.env` or `--dart-define=KEY=VALUE`
/// 2. Android Gradle automatic `dart-defines` injection from git-ignored
///    `android/key.properties`, `android/local.properties`, or `.env`.
/// 3. Local development fallback loader (`AppEnv.init()`) that reads untracked
///    local `.env`, `android/key.properties`, or `android/local.properties` on disk
///    when running on Desktop or in local tests without explicit CLI flags.
///
/// No API keys, tokens, or private scraper URLs are hardcoded in this file.
class AppEnv {
  AppEnv._();

  static const String _envTmdbApiKey = String.fromEnvironment(
    'TMDB_API_KEY',
    defaultValue: '',
  );

  static const String _envTmdbAccessToken = String.fromEnvironment(
    'TMDB_ACCESS_TOKEN',
    defaultValue: '',
  );

  static const String _envOpenSubtitlesApiKey = String.fromEnvironment(
    'OPENSUBTITLES_API_KEY',
    defaultValue: '',
  );

  static const String _envScraperApiUrl = String.fromEnvironment(
    'CINEVA_SCRAPER_API_URL',
    defaultValue: '',
  );

  static const String _envScraperFallbackUrl = String.fromEnvironment(
    'CINEVA_SCRAPER_FALLBACK_URL',
    defaultValue: '',
  );

  static final Map<String, String> _localProps = <String, String>{};
  static bool _isInitialized = false;

  /// Initializes local environment fallback from untracked `.env`,
  /// `android/key.properties`, and `android/local.properties` if available on disk.
  static void init() {
    if (_isInitialized) return;
    _isInitialized = true;

    if (kIsWeb) return;

    final candidatePaths = <String>[
      '.env',
      'android/key.properties',
      'android/local.properties',
      '../.env',
      '../android/key.properties',
      '../android/local.properties',
    ];

    for (final relPath in candidatePaths) {
      try {
        final file = File(relPath);
        if (!file.existsSync()) continue;
        final lines = file.readAsLinesSync();
        for (final rawLine in lines) {
          final line = rawLine.trim();
          if (line.isEmpty || line.startsWith('#')) continue;
          final eqIdx = line.indexOf('=');
          if (eqIdx <= 0) continue;
          final key = line.substring(0, eqIdx).trim();
          var value = line.substring(eqIdx + 1).trim();
          if ((value.startsWith('"') && value.endsWith('"')) ||
              (value.startsWith("'") && value.endsWith("'"))) {
            value = value.substring(1, value.length - 1);
          }
          if (key.isNotEmpty && value.isNotEmpty) {
            _localProps.putIfAbsent(key, () => value);
          }
        }
      } catch (_) {
        // Ignore file access errors on restricted mobile sandboxes where compile-time dart-defines are used.
      }
    }
  }

  static String _resolve(String compileTimeVal, String key) {
    if (compileTimeVal.isNotEmpty) return compileTimeVal;
    if (!_isInitialized) init();
    return _localProps[key] ?? '';
  }

  /// TMDB v3 API Key
  static String get tmdbApiKey => _resolve(_envTmdbApiKey, 'TMDB_API_KEY');

  /// TMDB v4 Read Access Token (Bearer token)
  static String get tmdbAccessToken =>
      _resolve(_envTmdbAccessToken, 'TMDB_ACCESS_TOKEN');

  /// OpenSubtitles REST API Key
  static String get openSubtitlesApiKey =>
      _resolve(_envOpenSubtitlesApiKey, 'OPENSUBTITLES_API_KEY');

  /// Cineva Scraper / Streaming Proxy API Primary Base URL
  static String get cinevaScraperApiUrl =>
      _resolve(_envScraperApiUrl, 'CINEVA_SCRAPER_API_URL');

  /// Cineva Scraper / Streaming Proxy API Fallback Base URL
  static String get cinevaScraperFallbackUrl =>
      _resolve(_envScraperFallbackUrl, 'CINEVA_SCRAPER_FALLBACK_URL');
}
