/// Secure Environment Configuration
///
/// Values are embedded at compile-time via `--dart-define-from-file=.env` or `--dart-define`.
/// This eliminates raw plaintext `.env` files from application installation directories
/// and distributed binary packages (Windows, Android TV, Mobile).
class AppEnv {
  AppEnv._();

  /// TMDB v3 API Key
  static const String tmdbApiKey = String.fromEnvironment(
    'TMDB_API_KEY',
    defaultValue: 'a219d8d995720253534ff876696baf3b',
  );

  /// TMDB v4 Read Access Token (Bearer token)
  static const String tmdbAccessToken = String.fromEnvironment(
    'TMDB_ACCESS_TOKEN',
    defaultValue:
        'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJhMjE5ZDhkOTk1NzIwMjUzNTM0ZmY4NzY2OTZiYWYzYiIsIm5iZiI6MTc5MjQ2MzU4MS45MDcsInN1YiI6IjZhZDZkMmRkOTI5ODAyZmY0ZTg0NWM4ZCIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.cugNx4ayrZSRibmn6SnTX3RqIJUE6fKynws0c8F7q-8',
  );

  /// OpenSubtitles REST API Key
  static const String openSubtitlesApiKey = String.fromEnvironment(
    'OPENSUBTITLES_API_KEY',
    defaultValue: 'U4f32C5BH7K7ht1Wspek97qoozXvHJy6',
  );

  /// Cineva Scraper / Streaming Proxy API Base URL
  static const String cinevaScraperApiUrl = String.fromEnvironment(
    'CINEVA_SCRAPER_API_URL',
    defaultValue: 'https://scraper.flix.quest',
  );
}

