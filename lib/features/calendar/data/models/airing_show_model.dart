class AiringShowModel {
  final int id;
  final String name;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final int voteCount;
  final String? firstAirDate;
  final String originalLanguage;
  final List<String> originCountry;
  final List<int> genreIds;
  final double popularity;

  const AiringShowModel({
    required this.id,
    required this.name,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    required this.voteCount,
    this.firstAirDate,
    required this.originalLanguage,
    required this.originCountry,
    required this.genreIds,
    required this.popularity,
  });

  factory AiringShowModel.fromJson(Map<String, dynamic> json) {
    return AiringShowModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? json['original_name'] as String? ?? '',
      overview: (json['overview'] as String? ?? '').trim(),
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      voteCount: json['vote_count'] as int? ?? 0,
      firstAirDate: json['first_air_date'] as String?,
      originalLanguage: json['original_language'] as String? ?? 'en',
      originCountry: (json['origin_country'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      genreIds: (json['genre_ids'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Whether this show is classified as Anime (Japanese animation)
  bool get isAnime => originalLanguage == 'ja' && genreIds.contains(16);

  /// Human-friendly network/region badge
  String get regionBadge {
    if (isAnime) return 'ANIME';
    if (originalLanguage == 'ko') return 'K-DRAMA';
    if (originalLanguage == 'id') return 'INDONESIA';
    if (originCountry.isNotEmpty) return originCountry.first;
    return originalLanguage.toUpperCase();
  }
}

