class TrailerVideoModel {
  final String id;
  final String key;
  final String name;
  final String site;
  final String type;
  final bool official;
  final String? publishedAt;

  const TrailerVideoModel({
    required this.id,
    required this.key,
    required this.name,
    required this.site,
    required this.type,
    required this.official,
    this.publishedAt,
  });

  factory TrailerVideoModel.fromJson(Map<String, dynamic> json) {
    return TrailerVideoModel(
      id: json['id'] as String? ?? '',
      key: json['key'] as String? ?? '',
      name: json['name'] as String? ?? 'Trailer',
      site: json['site'] as String? ?? '',
      type: json['type'] as String? ?? 'Trailer',
      official: json['official'] as bool? ?? false,
      publishedAt: json['published_at'] as String?,
    );
  }

  /// YouTube video URL
  String get youtubeUrl => 'https://www.youtube.com/watch?v=$key';

  /// YouTube No-Cookie embed URL
  String get embedUrl =>
      'https://www.youtube-nocookie.com/embed/$key?autoplay=1&playsinline=1&modestbranding=1&rel=0';

  /// High quality YouTube thumbnail
  String get thumbnailUrl => 'https://img.youtube.com/vi/$key/hqdefault.jpg';

  /// Selects the best trailer video from TMDB `videos.results` JSON.
  /// Prioritizes:
  /// 1. YouTube + Official + Type 'Trailer'
  /// 2. YouTube + Type 'Trailer'
  /// 3. YouTube + Type 'Teaser'
  /// 4. Any YouTube video
  static TrailerVideoModel? findBestTrailer(dynamic rawVideos) {
    if (rawVideos == null) return null;

    List<dynamic> list = [];
    if (rawVideos is Map && rawVideos['results'] is List) {
      list = rawVideos['results'] as List<dynamic>;
    } else if (rawVideos is List) {
      list = rawVideos;
    }

    if (list.isEmpty) return null;

    final parsed = list
        .whereType<Map>()
        .map((m) => TrailerVideoModel.fromJson(Map<String, dynamic>.from(m)))
        .where((v) => v.site.toLowerCase() == 'youtube' && v.key.isNotEmpty)
        .toList();

    if (parsed.isEmpty) return null;

    // 1. Official Trailer
    try {
      return parsed.firstWhere(
        (v) => v.official && v.type.toLowerCase() == 'trailer',
      );
    } catch (_) {}

    // 2. Any Trailer
    try {
      return parsed.firstWhere(
        (v) => v.type.toLowerCase() == 'trailer',
      );
    } catch (_) {}

    // 3. Teaser
    try {
      return parsed.firstWhere(
        (v) => v.type.toLowerCase() == 'teaser',
      );
    } catch (_) {}

    // 4. Fallback to first YouTube video
    return parsed.first;
  }
}

