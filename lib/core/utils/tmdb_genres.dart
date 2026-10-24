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

  static const Map<int, String> _genreMapEn = {
    // Movie genres
    28: 'Action',
    12: 'Adventure',
    16: 'Animation',
    35: 'Comedy',
    80: 'Crime',
    99: 'Documentary',
    18: 'Drama',
    10751: 'Family',
    14: 'Fantasy',
    36: 'History',
    27: 'Horror',
    10402: 'Music',
    9648: 'Mystery',
    10749: 'Romance',
    878: 'Sci-Fi',
    10770: 'TV Movie',
    53: 'Thriller',
    10752: 'War',
    37: 'Western',

    // TV genres
    10759: 'Action & Adventure',
    10762: 'Kids',
    10763: 'News',
    10764: 'Reality',
    10765: 'Sci-Fi & Fantasy',
    10766: 'Soap',
    10767: 'Talk',
    10768: 'War & Politics',
  };

  /// Returns the genre name for a given [id], or empty string if not found.
  static String getGenreName(int id, {bool isIndonesian = true}) {
    final map = isIndonesian ? _genreMap : _genreMapEn;
    return map[id] ?? (isIndonesian ? (_genreMapEn[id] ?? '') : (_genreMap[id] ?? ''));
  }

  /// Returns a formatted list of genre names (e.g. "Aksi • Sci-Fi") up to [limit].
  static String getFormattedGenres(List<int> ids, {int limit = 2, bool isIndonesian = true}) {
    if (ids.isEmpty) return '';
    final names = ids
        .map((id) => getGenreName(id, isIndonesian: isIndonesian))
        .where((n) => n.isNotEmpty)
        .take(limit)
        .toList();
    return names.join(' • ');
  }

  /// Returns the first primary genre name or fallback.
  static String getPrimaryGenre(List<int> ids, {String fallback = 'Film', bool isIndonesian = true}) {
    for (final id in ids) {
      final name = getGenreName(id, isIndonesian: isIndonesian);
      if (name.isNotEmpty) return name;
    }
    return fallback;
  }
}
