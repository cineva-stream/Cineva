/// API constants used across the application.
class ApiConstants {
  ApiConstants._();

  // ── TMDB ──
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String tmdbImageBaseUrl = 'https://image.tmdb.org/t/p';

  /// Image sizes for TMDB poster and backdrop URLs.
  static const String posterSmall = '/w185';
  static const String posterMedium = '/w342';
  static const String posterLarge = '/w500';
  static const String posterOriginal = '/original';
  static const String backdropSmall = '/w300';
  static const String backdropMedium = '/w780';
  static const String backdropLarge = '/w1280';
  static const String backdropOriginal = '/original';

  /// Constructs a full TMDB image URL.
  static String imageUrl(String? path, {String size = posterLarge}) {
    if (path == null || path.isEmpty) return '';
    return '$tmdbImageBaseUrl$size$path';
  }

  // ── OpenSubtitles ──
  static const String openSubtitlesBaseUrl = 'https://api.opensubtitles.com/api/v1';

  // ── Torrent ──
  /// Public tracker list injected into magnet links for better peer discovery.
  static const List<String> publicTrackers = [
    'udp://tracker.opentrackr.org:1337/announce',
    'udp://open.stealth.si:80/announce',
    'udp://tracker.torrent.eu.org:451/announce',
    'udp://tracker.bittor.pw:1337/announce',
    'udp://public.popcornflix.com:1337/announce',
    'udp://tracker.dler.org:6969/announce',
    'udp://exodus.desync.com:6969/announce',
    'udp://open.demonii.com:1337/announce',
  ];
}
