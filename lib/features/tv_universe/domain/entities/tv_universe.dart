import '../../../../core/localization/app_strings.dart';

enum TvUniverseEntryType {
  mainSeries,
  prequel,
  sequel,
  spinoff;

  String localizedLabel(AppStrings s) {
    switch (this) {
      case TvUniverseEntryType.mainSeries:
        return s.tvUniverseMainSeries;
      case TvUniverseEntryType.prequel:
        return s.tvUniversePrequel;
      case TvUniverseEntryType.sequel:
        return s.tvUniverseSequel;
      case TvUniverseEntryType.spinoff:
        return s.tvUniverseSpinoff;
    }
  }
}

class TvUniverseEntry {
  final int tmdbTvId;
  final String title;
  final int orderIndex;
  final TvUniverseEntryType type;
  final String yearRange;
  final String note;
  final String? posterPath;

  const TvUniverseEntry({
    required this.tmdbTvId,
    required this.title,
    required this.orderIndex,
    required this.type,
    required this.yearRange,
    required this.note,
    this.posterPath,
  });
}

class TvUniverse {
  final String id;
  final String name;
  final String description;
  final String? backdropPath;
  final String? posterPath;
  final List<TvUniverseEntry> entries;

  const TvUniverse({
    required this.id,
    required this.name,
    required this.description,
    this.backdropPath,
    this.posterPath,
    required this.entries,
  });

  /// Finds the order index for a specific TV show ID
  int indexOfShow(int tvId) {
    final entry = entries.where((e) => e.tmdbTvId == tvId).firstOrNull;
    return entry?.orderIndex ?? 1;
  }
}

