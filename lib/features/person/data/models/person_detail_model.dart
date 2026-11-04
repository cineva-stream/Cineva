class PersonCreditModel {
  final int id;
  final String title;
  final String mediaType; // 'movie' or 'tv'
  final String? posterPath;
  final String? backdropPath;
  final String? releaseDate;
  final String? character;
  final double voteAverage;
  final int voteCount;
  final double popularity;

  const PersonCreditModel({
    required this.id,
    required this.title,
    required this.mediaType,
    this.posterPath,
    this.backdropPath,
    this.releaseDate,
    this.character,
    required this.voteAverage,
    required this.voteCount,
    required this.popularity,
  });

  factory PersonCreditModel.fromJson(Map<String, dynamic> json) {
    final mediaType = json['media_type'] as String? ?? 'movie';
    final title = mediaType == 'tv'
        ? (json['name'] as String? ?? json['original_name'] as String? ?? '')
        : (json['title'] as String? ?? json['original_title'] as String? ?? '');

    final releaseDate = mediaType == 'tv'
        ? (json['first_air_date'] as String?)
        : (json['release_date'] as String?);

    return PersonCreditModel(
      id: json['id'] as int? ?? 0,
      title: title,
      mediaType: mediaType,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      releaseDate: releaseDate,
      character: json['character'] as String?,
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

class PersonDetailModel {
  final int id;
  final String name;
  final String biography;
  final String? birthday;
  final String? deathday;
  final String? placeOfBirth;
  final String? profilePath;
  final String? knownForDepartment;
  final double popularity;
  final String? imdbId;
  final List<PersonCreditModel> credits;

  const PersonDetailModel({
    required this.id,
    required this.name,
    required this.biography,
    this.birthday,
    this.deathday,
    this.placeOfBirth,
    this.profilePath,
    this.knownForDepartment,
    required this.popularity,
    this.imdbId,
    required this.credits,
  });

  factory PersonDetailModel.fromJson(Map<String, dynamic> json) {
    final rawCredits =
        (json['combined_credits']?['cast'] as List<dynamic>?) ?? [];

    final parsedCredits = rawCredits
        .whereType<Map>()
        .map((m) => PersonCreditModel.fromJson(Map<String, dynamic>.from(m)))
        .where((c) => c.title.isNotEmpty && c.posterPath != null)
        .toList();

    // Sort credits by popularity descending
    parsedCredits.sort((a, b) => b.popularity.compareTo(a.popularity));

    return PersonDetailModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      biography: (json['biography'] as String? ?? '').trim(),
      birthday: json['birthday'] as String?,
      deathday: json['deathday'] as String?,
      placeOfBirth: json['place_of_birth'] as String?,
      profilePath: json['profile_path'] as String?,
      knownForDepartment: json['known_for_department'] as String?,
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0.0,
      imdbId: json['external_ids']?['imdb_id'] as String?,
      credits: parsedCredits,
    );
  }

  /// Calculates age if birthday is available
  int? get age {
    if (birthday == null || birthday!.length < 4) return null;
    try {
      final birth = DateTime.parse(birthday!);
      final end = deathday != null ? DateTime.parse(deathday!) : DateTime.now();
      int years = end.year - birth.year;
      if (end.month < birth.month ||
          (end.month == birth.month && end.day < birth.day)) {
        years--;
      }
      return years > 0 ? years : null;
    } catch (_) {
      return null;
    }
  }
}

