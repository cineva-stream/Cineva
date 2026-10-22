/// TV Series entity — domain layer representation of a TV show.
class TvSeries {
  final int id;
  final String name;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final int voteCount;
  final String firstAirDate;
  final List<int> genreIds;
  final double popularity;
  final String? mediaType;
  final String? originalLanguage;
  final List<String> originCountry;

  const TvSeries({
    required this.id,
    required this.name,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    this.voteCount = 0,
    required this.firstAirDate,
    this.genreIds = const [],
    this.popularity = 0,
    this.mediaType,
    this.originalLanguage,
    this.originCountry = const [],
  });

  /// Year extracted from first air date.
  String get year {
    if (firstAirDate.isEmpty) return '';
    return firstAirDate.substring(0, 4);
  }
}
