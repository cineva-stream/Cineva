/// Movie entity — domain layer representation of a movie.
class Movie {
  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final int voteCount;
  final String releaseDate;
  final List<int> genreIds;
  final double popularity;
  final String? mediaType;
  final String? originalLanguage;
  final List<String> originCountry;

  const Movie({
    required this.id,
    required this.title,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    this.voteCount = 0,
    required this.releaseDate,
    this.genreIds = const [],
    this.popularity = 0,
    this.mediaType,
    this.originalLanguage,
    this.originCountry = const [],
  });

  /// Year extracted from release date.
  String get year {
    if (releaseDate.isEmpty) return '';
    return releaseDate.substring(0, 4);
  }
}
