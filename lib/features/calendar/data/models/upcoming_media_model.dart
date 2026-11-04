import '../../../../core/localization/app_strings.dart';

class UpcomingMediaModel {
  final int id;
  final String title;
  final String mediaType; // 'movie' or 'tv'
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final String releaseDate; // 'YYYY-MM-DD'
  final double voteAverage;
  final int voteCount;
  final double popularity;
  final List<int> genreIds;

  const UpcomingMediaModel({
    required this.id,
    required this.title,
    required this.mediaType,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    required this.releaseDate,
    required this.voteAverage,
    required this.voteCount,
    required this.popularity,
    required this.genreIds,
  });

  factory UpcomingMediaModel.fromJson(Map<String, dynamic> json, {String mediaType = 'movie'}) {
    final title = mediaType == 'tv'
        ? (json['name'] as String? ?? json['original_name'] as String? ?? '')
        : (json['title'] as String? ?? json['original_title'] as String? ?? '');

    final releaseDate = mediaType == 'tv'
        ? (json['first_air_date'] as String? ?? '')
        : (json['release_date'] as String? ?? '');

    return UpcomingMediaModel(
      id: json['id'] as int? ?? 0,
      title: title,
      mediaType: mediaType,
      overview: (json['overview'] as String? ?? '').trim(),
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      releaseDate: releaseDate,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      voteCount: json['vote_count'] as int? ?? 0,
      popularity: (json['popularity'] as num?)?.toDouble() ?? 0.0,
      genreIds: (json['genre_ids'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
    );
  }

  bool get isMovie => mediaType == 'movie';
  bool get isTv => mediaType == 'tv';
  String get mediaTypeBadge => isMovie ? 'MOVIE' : 'TV';

  /// Calculates number of days remaining until release date
  int get daysUntilRelease {
    if (releaseDate.isEmpty) return 0;
    try {
      final target = DateTime.parse(releaseDate);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final targetDay = DateTime(target.year, target.month, target.day);
      return targetDay.difference(today).inDays;
    } catch (_) {
      return 0;
    }
  }

  /// Human-friendly localized countdown label
  String countdownLabel(AppStrings s) {
    final days = daysUntilRelease;
    if (days <= 0) return s.upcomingReleasedToday;
    if (days == 1) return s.upcomingTomorrow;
    return s.upcomingInDays(days);
  }

  /// Formatted date e.g. "15 Nov 2026"
  String get formattedDate {
    if (releaseDate.isEmpty) return '';
    try {
      final d = DateTime.parse(releaseDate);
      const enMonths = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${d.day} ${enMonths[d.month - 1]} ${d.year}';
    } catch (_) {
      return releaseDate;
    }
  }
}

