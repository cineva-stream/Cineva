import '../localization/app_language.dart';

/// TMDB Genre IDs to Indonesian/English/Hindi names mapper.
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

  static const Map<int, String> _genreMapHi = {
    // Movie genres
    28: 'एक्शन',
    12: 'एडवेंचर',
    16: 'एनिमेशन',
    35: 'कॉमेडी',
    80: 'क्राइम',
    99: 'डॉक्यूमेंट्री',
    18: 'ड्रामा',
    10751: 'पारिवारिक',
    14: 'फ़ैंटेसी',
    36: 'इतिहास',
    27: 'हॉरर',
    10402: 'संगीत',
    9648: 'रहस्य',
    10749: 'रोमांस',
    878: 'साइंस-फ़िक्शन',
    10770: 'टीवी फ़िल्म',
    53: 'थ्रिलर',
    10752: 'युद्ध',
    37: 'वेस्टर्न',

    // TV genres
    10759: 'एक्शन और एडवेंचर',
    10762: 'बच्चे',
    10763: 'समाचार',
    10764: 'रियलिटी',
    10765: 'साइंस-फ़िक्शन और फ़ैंटेसी',
    10766: 'सोप',
    10767: 'टॉक शो',
    10768: 'युद्ध और राजनीति',
  };

  /// Returns the genre name for a given [id], or empty string if not found.
  static String getGenreName(
    int id, {
    bool isIndonesian = true,
    AppLanguage? language,
  }) {
    final effectiveLang =
        language ?? (isIndonesian ? AppLanguage.id : AppLanguage.en);
    switch (effectiveLang) {
      case AppLanguage.id:
        return _genreMap[id] ?? _genreMapEn[id] ?? '';
      case AppLanguage.en:
        return _genreMapEn[id] ?? _genreMap[id] ?? '';
      case AppLanguage.hi:
        return _genreMapHi[id] ?? _genreMapEn[id] ?? '';
    }
  }

  /// Returns a formatted list of genre names (e.g. "Aksi • Sci-Fi") up to [limit].
  static String getFormattedGenres(
    List<int> ids, {
    int limit = 2,
    bool isIndonesian = true,
    AppLanguage? language,
  }) {
    if (ids.isEmpty) return '';
    final names = ids
        .map(
          (id) => getGenreName(
            id,
            isIndonesian: isIndonesian,
            language: language,
          ),
        )
        .where((n) => n.isNotEmpty)
        .take(limit)
        .toList();
    return names.join(' • ');
  }

  /// Returns the first primary genre name or fallback.
  static String getPrimaryGenre(
    List<int> ids, {
    String fallback = 'Film',
    bool isIndonesian = true,
    AppLanguage? language,
  }) {
    for (final id in ids) {
      final name = getGenreName(
        id,
        isIndonesian: isIndonesian,
        language: language,
      );
      if (name.isNotEmpty) return name;
    }
    return fallback;
  }
}
