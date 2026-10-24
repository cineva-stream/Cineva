/// Represents a watch history entry stored in Hive.
class WatchHistoryItem {
  final int id;
  final String mediaType; // 'movie' or 'tv'
  final String title;
  final String? episodeTitle;
  final int? season;
  final int? episode;
  final String? imdbId;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final int positionMs;
  final int durationMs;
  final DateTime lastWatchedAt;
  final bool isCompleted;

  WatchHistoryItem({
    required this.id,
    required this.mediaType,
    required this.title,
    this.episodeTitle,
    this.season,
    this.episode,
    this.imdbId,
    this.posterPath,
    this.backdropPath,
    this.voteAverage = 0.0,
    required this.positionMs,
    required this.durationMs,
    required this.lastWatchedAt,
    this.isCompleted = false,
  });

  /// Key used in Hive: e.g. 'movie_123' or 'tv_456'
  String get key => '${mediaType}_$id';

  /// Playback progress ratio between 0.0 and 1.0.
  double get progress {
    if (durationMs <= 0) return 0.0;
    return (positionMs / durationMs).clamp(0.0, 1.0);
  }

  /// Whether the media is currently in-progress (watched > 2% and < 95% and not completed).
  bool get isInProgress => !isCompleted && progress > 0.02 && progress < 0.95;

  /// Progress percentage (0 - 100).
  int get progressPercent => (progress * 100).round();

  /// Human-readable progress description with localization support.
  String localizedProgressSubtitle({bool isIndonesian = true}) {
    if (mediaType == 'tv' && season != null && episode != null) {
      final epLabel = 'S$season:E$episode';
      if (episodeTitle != null && episodeTitle!.isNotEmpty) {
        return '$epLabel • $episodeTitle';
      }
      return epLabel;
    }
    final remainingMs = durationMs - positionMs;
    if (remainingMs > 0) {
      final remMinutes = (remainingMs / 60000).ceil();
      if (remMinutes >= 60) {
        final hours = remMinutes ~/ 60;
        final mins = remMinutes % 60;
        return isIndonesian ? 'Sisa ${hours}j ${mins}m' : '${hours}h ${mins}m left';
      }
      return isIndonesian ? 'Sisa $remMinutes mnt' : '$remMinutes mins left';
    }
    return isIndonesian ? 'Lanjutkan Menonton' : 'Continue Watching';
  }

  /// Human-readable progress description (defaults to Indonesian).
  String get progressSubtitle => localizedProgressSubtitle(isIndonesian: true);

  /// Formatted position timestamp: "01:23 / 02:15:00".
  String get positionTimestamp {
    String formatMs(int ms) {
      final totalSec = ms ~/ 1000;
      final hours = totalSec ~/ 3600;
      final mins = (totalSec % 3600) ~/ 60;
      final secs = totalSec % 60;
      if (hours > 0) {
        return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
      }
      return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }

    return '${formatMs(positionMs)} / ${formatMs(durationMs)}';
  }

  WatchHistoryItem copyWith({
    int? positionMs,
    int? durationMs,
    DateTime? lastWatchedAt,
    bool? isCompleted,
    int? season,
    int? episode,
    String? episodeTitle,
  }) {
    return WatchHistoryItem(
      id: id,
      mediaType: mediaType,
      title: title,
      episodeTitle: episodeTitle ?? this.episodeTitle,
      season: season ?? this.season,
      episode: episode ?? this.episode,
      imdbId: imdbId,
      posterPath: posterPath,
      backdropPath: backdropPath,
      voteAverage: voteAverage,
      positionMs: positionMs ?? this.positionMs,
      durationMs: durationMs ?? this.durationMs,
      lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'mediaType': mediaType,
    'title': title,
    'episodeTitle': episodeTitle,
    'season': season,
    'episode': episode,
    'imdbId': imdbId,
    'posterPath': posterPath,
    'backdropPath': backdropPath,
    'voteAverage': voteAverage,
    'positionMs': positionMs,
    'durationMs': durationMs,
    'lastWatchedAt': lastWatchedAt.toIso8601String(),
    'isCompleted': isCompleted,
  };

  factory WatchHistoryItem.fromJson(Map<dynamic, dynamic> json) => WatchHistoryItem(
    id: json['id'] as int? ?? 0,
    mediaType: json['mediaType'] as String? ?? 'movie',
    title: json['title'] as String? ?? '',
    episodeTitle: json['episodeTitle'] as String?,
    season: json['season'] as int?,
    episode: json['episode'] as int?,
    imdbId: json['imdbId'] as String?,
    posterPath: json['posterPath'] as String?,
    backdropPath: json['backdropPath'] as String?,
    voteAverage: (json['voteAverage'] as num?)?.toDouble() ?? 0.0,
    positionMs: json['positionMs'] as int? ?? 0,
    durationMs: json['durationMs'] as int? ?? 0,
    lastWatchedAt: DateTime.tryParse(json['lastWatchedAt'] as String? ?? '') ?? DateTime.now(),
    isCompleted: json['isCompleted'] as bool? ?? false,
  );
}
