import '../../domain/entities/tv_series.dart';

/// Data model for TvSeries with JSON serialization for TMDB API.
class TvSeriesModel extends TvSeries {
  const TvSeriesModel({
    required super.id,
    required super.name,
    required super.overview,
    super.posterPath,
    super.backdropPath,
    required super.voteAverage,
    super.voteCount,
    required super.firstAirDate,
    super.genreIds,
    super.popularity,
    super.mediaType,
    super.originalLanguage,
    super.originCountry,
  });

  factory TvSeriesModel.fromJson(Map<String, dynamic> json) {
    return TvSeriesModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? json['title'] as String? ?? '',
      overview: json['overview'] as String? ?? '',
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      voteCount: json['vote_count'] as int? ?? 0,
      firstAirDate: json['first_air_date'] as String? ?? '',
      genreIds: (json['genre_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0.0,
      mediaType: json['media_type'] as String?,
      originalLanguage: json['original_language'] as String?,
      originCountry: (json['origin_country'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'overview': overview,
      'poster_path': posterPath,
      'backdrop_path': backdropPath,
      'vote_average': voteAverage,
      'vote_count': voteCount,
      'first_air_date': firstAirDate,
      'genre_ids': genreIds,
      'popularity': popularity,
      'media_type': mediaType,
      'original_language': originalLanguage,
      'origin_country': originCountry,
    };
  }
}
