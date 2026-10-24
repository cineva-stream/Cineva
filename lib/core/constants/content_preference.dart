import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../features/home/domain/entities/movie.dart';
import '../../features/home/domain/entities/tv_series.dart';

/// User content preference for filtering and prioritizing Movies & TV Series.
enum ContentPreference {
  all(
    code: 'all',
    label: 'Semua (Global)',
    description: 'Tampilkan seluruh film & serial dunia tanpa batasan khusus',
    icon: Iconsax.global,
  ),
  indonesia(
    code: 'indonesia',
    label: 'Indonesia',
    description: 'Prioritaskan Film Bioskop & Serial TV Indonesia',
    icon: Icons.flag_rounded,
  ),
  anime(
    code: 'anime',
    label: 'Anime',
    description: 'Prioritaskan Film Animasi & Serial TV Anime Jepang',
    icon: Iconsax.video_play,
  ),
  hollywood(
    code: 'hollywood',
    label: 'Hollywood (Barat)',
    description: 'Prioritaskan Film Blockbuster & Serial Hollywood / USA',
    icon: Iconsax.video,
  ),
  korea(
    code: 'korea',
    label: 'Korea (K-Drama)',
    description: 'Prioritaskan Serial Drama Korea & Film K-Cinema',
    icon: Iconsax.heart,
  ),
  japan(
    code: 'japan',
    label: 'Jepang (J-Drama)',
    description: 'Prioritaskan Film & Serial TV Live-Action Jepang',
    icon: Iconsax.lamp_charge,
  ),
  bollywood(
    code: 'bollywood',
    label: 'Bollywood (India)',
    description: 'Prioritaskan Film Sinema India & Serial Bollywood',
    icon: Iconsax.music,
  );

  final String code;
  final String label;
  final String description;
  final IconData icon;

  const ContentPreference({
    required this.code,
    required this.label,
    required this.description,
    required this.icon,
  });

  /// Factory helper from storage code.
  static ContentPreference fromCode(String? code) {
    if (code == null) return ContentPreference.all;
    return ContentPreference.values.firstWhere(
      (e) => e.code == code,
      orElse: () => ContentPreference.all,
    );
  }

  /// Returns localized label based on user's active language.
  String getLocalizedLabel(bool isIndonesian) {
    if (isIndonesian) return label;
    switch (this) {
      case ContentPreference.all:
        return 'All (Global)';
      case ContentPreference.indonesia:
        return 'Indonesia';
      case ContentPreference.anime:
        return 'Anime';
      case ContentPreference.hollywood:
        return 'Hollywood (Western)';
      case ContentPreference.korea:
        return 'Korea (K-Drama)';
      case ContentPreference.japan:
        return 'Japan (J-Drama)';
      case ContentPreference.bollywood:
        return 'Bollywood (India)';
    }
  }

  /// Returns localized description based on user's active language.
  String getLocalizedDescription(bool isIndonesian) {
    if (isIndonesian) return description;
    switch (this) {
      case ContentPreference.all:
        return 'Show all movies and TV shows worldwide without restrictions';
      case ContentPreference.indonesia:
        return 'Prioritize Indonesian movies & TV series';
      case ContentPreference.anime:
        return 'Prioritize Japanese anime movies & TV series';
      case ContentPreference.hollywood:
        return 'Prioritize Hollywood blockbusters & US TV series';
      case ContentPreference.korea:
        return 'Prioritize Korean dramas & K-Cinema';
      case ContentPreference.japan:
        return 'Prioritize Japanese live-action movies & series';
      case ContentPreference.bollywood:
        return 'Prioritize Indian cinema & Bollywood series';
    }
  }

  /// Whether a movie matches this preference for search sorting.
  bool matchesMovie(Movie movie) {
    if (this == ContentPreference.all) return false;
    final lang = (movie.originalLanguage ?? '').toLowerCase().trim();
    final genres = movie.genreIds;
    final countries = movie.originCountry.map((c) => c.toUpperCase().trim()).toList();

    switch (this) {
      case ContentPreference.indonesia:
        return lang == 'id' || countries.contains('ID');
      case ContentPreference.anime:
        // TMDB Animation genre is 16. Anime is Japanese animation.
        return genres.contains(16) && (lang == 'ja' || countries.contains('JP'));
      case ContentPreference.hollywood:
        return lang == 'en' || countries.contains('US');
      case ContentPreference.korea:
        return lang == 'ko' || countries.contains('KR');
      case ContentPreference.japan:
        return lang == 'ja' || countries.contains('JP');
      case ContentPreference.bollywood:
        return lang == 'hi' || countries.contains('IN');
      case ContentPreference.all:
        return false;
    }
  }

  /// Whether a TV show matches this preference for search sorting.
  bool matchesTv(TvSeries tv) {
    if (this == ContentPreference.all) return false;
    final lang = (tv.originalLanguage ?? '').toLowerCase().trim();
    final genres = tv.genreIds;
    final countries = tv.originCountry.map((c) => c.toUpperCase().trim()).toList();

    switch (this) {
      case ContentPreference.indonesia:
        return lang == 'id' || countries.contains('ID');
      case ContentPreference.anime:
        return genres.contains(16) && (lang == 'ja' || countries.contains('JP'));
      case ContentPreference.hollywood:
        return lang == 'en' || countries.contains('US');
      case ContentPreference.korea:
        return lang == 'ko' || countries.contains('KR');
      case ContentPreference.japan:
        return lang == 'ja' || countries.contains('JP');
      case ContentPreference.bollywood:
        return lang == 'hi' || countries.contains('IN');
      case ContentPreference.all:
        return false;
    }
  }
}
