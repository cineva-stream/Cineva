/// TMDB Genre IDs to Indonesian/International names mapper.
class TmdbGenres {
  TmdbGenres._();

  static const Map<int, String> _genreMap = {
    // Movie genres
    28: 'Aksi',
    12: 'Petualangan',
    16: 'Animasi',
    35: 'Komedi',
    80: 'Kriminal',
    99: 'Dokumenter',
    18: 'Drama',
    10751: 'Keluarga',
    14: 'Fantasi',
    36: 'Sejarah',
    27: 'Horor',
    10402: 'Musik',
    9648: 'Misteri',
    10749: 'Romantis',
    878: 'Sci-Fi',
    10770: 'Film TV',
    53: 'Thriller',
    10752: 'Perang',
    37: 'Western',

    // TV genres
    10759: 'Aksi & Petualangan',
    10762: 'Anak-anak',
    10763: 'Berita',
    10764: 'Reality TV',
    10765: 'Sci-Fi & Fantasi',
    10766: 'Soap',
    10767: 'Talkshow',
    10768: 'Perang & Politik',
  };

  /// Returns the genre name for a given [id], or empty string if not found.
  static String getGenreName(int id) {
    return _genreMap[id] ?? '';
  }

  /// Returns a formatted list of genre names (e.g. "Aksi • Sci-Fi") up to [limit].
  static String getFormattedGenres(List<int> ids, {int limit = 2}) {
    if (ids.isEmpty) return '';
    final names = ids
        .map((id) => _genreMap[id])
        .whereType<String>()
        .take(limit)
        .toList();
    return names.join(' • ');
  }

  /// Returns the first primary genre name or fallback.
  static String getPrimaryGenre(List<int> ids, {String fallback = 'Film'}) {
    for (final id in ids) {
      final name = _genreMap[id];
      if (name != null) return name;
    }
    return fallback;
  }
}
