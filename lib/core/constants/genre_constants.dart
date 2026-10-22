import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../features/home/domain/entities/movie.dart';
import '../../features/home/domain/entities/tv_series.dart';

/// Represents a selectable Genre Filter across Movies and TV Series.
class GenreFilter {
  final String id;
  final String label;
  final List<int> movieGenreIds;
  final List<int> tvGenreIds;
  final IconData? icon;

  const GenreFilter({
    required this.id,
    required this.label,
    required this.movieGenreIds,
    required this.tvGenreIds,
    this.icon,
  });

  /// Checks if a [movie] has any matching genre ID.
  bool matchesMovie(Movie movie) {
    if (id == 'all' || movieGenreIds.isEmpty) return true;
    return movie.genreIds.any((gid) => movieGenreIds.contains(gid));
  }

  /// Checks if a [tv] series has any matching genre ID.
  bool matchesTv(TvSeries tv) {
    if (id == 'all' || tvGenreIds.isEmpty) return true;
    return tv.genreIds.any((gid) => tvGenreIds.contains(gid));
  }
}

/// Curated Genre Definitions used on Home (Beranda) and Search (Pencarian).
class GenreConstants {
  GenreConstants._();

  static const List<GenreFilter> filters = [
    GenreFilter(
      id: 'all',
      label: 'Semua Genre',
      movieGenreIds: [],
      tvGenreIds: [],
      icon: Iconsax.category_2,
    ),
    GenreFilter(
      id: 'action',
      label: 'Action',
      movieGenreIds: [28, 10759],
      tvGenreIds: [10759, 28],
      icon: Icons.flash_on_rounded,
    ),
    GenreFilter(
      id: 'scifi',
      label: 'Sci-Fi',
      movieGenreIds: [878, 10765],
      tvGenreIds: [10765, 878],
      icon: Icons.rocket_launch_rounded,
    ),
    GenreFilter(
      id: 'romance',
      label: 'Romance',
      movieGenreIds: [10749],
      tvGenreIds: [10749, 18],
      icon: Icons.favorite_rounded,
    ),
    GenreFilter(
      id: 'drama',
      label: 'Drama',
      movieGenreIds: [18],
      tvGenreIds: [18],
      icon: Icons.theater_comedy_rounded,
    ),
    GenreFilter(
      id: 'comedy',
      label: 'Komedi',
      movieGenreIds: [35],
      tvGenreIds: [35],
      icon: Icons.sentiment_very_satisfied_rounded,
    ),
    GenreFilter(
      id: 'horror',
      label: 'Horor',
      movieGenreIds: [27],
      tvGenreIds: [27, 9648],
      icon: Icons.nightlight_round,
    ),
    GenreFilter(
      id: 'animation',
      label: 'Animasi',
      movieGenreIds: [16],
      tvGenreIds: [16],
      icon: Icons.auto_awesome_rounded,
    ),
    GenreFilter(
      id: 'adventure',
      label: 'Petualangan',
      movieGenreIds: [12, 10759],
      tvGenreIds: [10759, 12],
      icon: Icons.explore_rounded,
    ),
    GenreFilter(
      id: 'thriller',
      label: 'Thriller',
      movieGenreIds: [53, 80],
      tvGenreIds: [53, 80],
      icon: Icons.psychology_rounded,
    ),
    GenreFilter(
      id: 'fantasy',
      label: 'Fantasi',
      movieGenreIds: [14, 10765],
      tvGenreIds: [10765, 14],
      icon: Icons.auto_fix_high_rounded,
    ),
    GenreFilter(
      id: 'mystery',
      label: 'Misteri',
      movieGenreIds: [9648],
      tvGenreIds: [9648],
      icon: Icons.search_rounded,
    ),
    GenreFilter(
      id: 'family',
      label: 'Keluarga',
      movieGenreIds: [10751, 10762],
      tvGenreIds: [10762, 10751],
      icon: Icons.family_restroom_rounded,
    ),
    GenreFilter(
      id: 'crime',
      label: 'Kriminal',
      movieGenreIds: [80],
      tvGenreIds: [80],
      icon: Icons.gavel_rounded,
    ),
  ];
}

/// Active Genre Filter on the Home Screen.
final selectedHomeGenreProvider = StateProvider<GenreFilter>((ref) => GenreConstants.filters.first);

/// Active Genre Filter on the Search / Explore Screen.
final selectedSearchGenreProvider = StateProvider<GenreFilter>((ref) => GenreConstants.filters.first);
