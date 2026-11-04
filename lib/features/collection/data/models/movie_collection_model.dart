class CollectionPartModel {
  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final double voteAverage;
  final int voteCount;
  final double popularity;

  const CollectionPartModel({
    required this.id,
    required this.title,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    required this.voteAverage,
    required this.voteCount,
    required this.popularity,
  });

  factory CollectionPartModel.fromJson(Map<String, dynamic> json) {
    return CollectionPartModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? json['original_title'] as String? ?? '',
      overview: (json['overview'] as String? ?? '').trim(),
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      releaseDate: json['release_date'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      voteCount: json['vote_count'] as int? ?? 0,
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String get year {
    if (releaseDate != null && releaseDate!.length >= 4) {
      return releaseDate!.substring(0, 4);
    }
    return '';
  }
}

class MovieCollectionModel {
  final int id;
  final String name;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final List<CollectionPartModel> parts;

  const MovieCollectionModel({
    required this.id,
    required this.name,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    required this.parts,
  });

  factory MovieCollectionModel.fromJson(Map<String, dynamic> json) {
    final rawParts = (json['parts'] as List<dynamic>?) ?? [];
    final parsedParts = rawParts
        .whereType<Map>()
        .map((m) => CollectionPartModel.fromJson(Map<String, dynamic>.from(m)))
        .toList();

    // Sort parts chronologically by release_date
    parsedParts.sort((a, b) {
      final aDate = a.releaseDate ?? '9999';
      final bDate = b.releaseDate ?? '9999';
      return aDate.compareTo(bDate);
    });

    return MovieCollectionModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Franchise Collection',
      overview: (json['overview'] as String? ?? '').trim(),
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      parts: parsedParts,
    );
  }
}

