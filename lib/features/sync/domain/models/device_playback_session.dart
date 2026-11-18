/// Model representing an active playback checkpoint on a specific device.
/// Used for cross-device Seamless Hand-Off (e.g., continuing on mobile/desktop
/// after stopping on Android TV).
class DevicePlaybackSession {
  final String deviceId;
  final String deviceName;
  final String formFactor; // 'tv', 'desktop', 'mobile', 'tablet'
  final String title;
  final String mediaType; // 'movie', 'tv'
  final int tmdbId;
  final String? imdbId;
  final int? season;
  final int? episode;
  final String? episodeTitle;
  final String? posterPath;
  final String? backdropPath;
  final int positionSeconds;
  final int durationSeconds;
  final DateTime updatedAt;
  final bool isCompleted;

  const DevicePlaybackSession({
    required this.deviceId,
    required this.deviceName,
    required this.formFactor,
    required this.title,
    required this.mediaType,
    required this.tmdbId,
    this.imdbId,
    this.season,
    this.episode,
    this.episodeTitle,
    this.posterPath,
    this.backdropPath,
    required this.positionSeconds,
    required this.durationSeconds,
    required this.updatedAt,
    this.isCompleted = false,
  });

  /// Check whether the session is valid to be presented as a Hand-Off capsule.
  /// Must be in-progress (not completed), watched at least 30 seconds, not at end credits (<95%),
  /// and updated within the last 24 hours.
  bool get isValidForHandOff {
    if (isCompleted) return false;
    if (positionSeconds < 30) return false;
    if (durationSeconds > 0 && (positionSeconds / durationSeconds >= 0.95)) {
      return false;
    }
    final age = DateTime.now().difference(updatedAt);
    return age.inHours < 24 && !age.isNegative;
  }

  /// Formats [positionSeconds] as 'mm:ss' or 'hh:mm:ss'.
  String get formattedPosition {
    final d = Duration(seconds: positionSeconds);
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);

    final minStr = minutes.toString().padLeft(2, '0');
    final secStr = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:$minStr:$secStr';
    }
    return '$minStr:$secStr';
  }

  /// Unique snapshot key for dismissing this exact playback state.
  String get snapshotKey =>
      '${tmdbId}_${season ?? 0}_${episode ?? 0}_${updatedAt.millisecondsSinceEpoch}';

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'deviceName': deviceName,
        'formFactor': formFactor,
        'title': title,
        'mediaType': mediaType,
        'tmdbId': tmdbId,
        'imdbId': imdbId,
        'season': season,
        'episode': episode,
        'episodeTitle': episodeTitle,
        'posterPath': posterPath,
        'backdropPath': backdropPath,
        'positionSeconds': positionSeconds,
        'durationSeconds': durationSeconds,
        'updatedAt': updatedAt.toIso8601String(),
        'isCompleted': isCompleted,
      };

  factory DevicePlaybackSession.fromJson(Map<dynamic, dynamic> json) {
    return DevicePlaybackSession(
      deviceId: (json['deviceId'] as String?) ?? '',
      deviceName: (json['deviceName'] as String?) ?? 'Perangkat Lain',
      formFactor: (json['formFactor'] as String?) ?? 'mobile',
      title: (json['title'] as String?) ?? '',
      mediaType: (json['mediaType'] as String?) ?? 'movie',
      tmdbId: (json['tmdbId'] as num?)?.toInt() ?? 0,
      imdbId: json['imdbId'] as String?,
      season: (json['season'] as num?)?.toInt(),
      episode: (json['episode'] as num?)?.toInt(),
      episodeTitle: json['episodeTitle'] as String?,
      posterPath: json['posterPath'] as String?,
      backdropPath: json['backdropPath'] as String?,
      positionSeconds: (json['positionSeconds'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      isCompleted: (json['isCompleted'] as bool?) ?? false,
    );
  }

  DevicePlaybackSession copyWith({
    String? deviceId,
    String? deviceName,
    String? formFactor,
    String? title,
    String? mediaType,
    int? tmdbId,
    String? imdbId,
    int? season,
    int? episode,
    String? episodeTitle,
    String? posterPath,
    String? backdropPath,
    int? positionSeconds,
    int? durationSeconds,
    DateTime? updatedAt,
    bool? isCompleted,
  }) {
    return DevicePlaybackSession(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      formFactor: formFactor ?? this.formFactor,
      title: title ?? this.title,
      mediaType: mediaType ?? this.mediaType,
      tmdbId: tmdbId ?? this.tmdbId,
      imdbId: imdbId ?? this.imdbId,
      season: season ?? this.season,
      episode: episode ?? this.episode,
      episodeTitle: episodeTitle ?? this.episodeTitle,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      positionSeconds: positionSeconds ?? this.positionSeconds,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      updatedAt: updatedAt ?? this.updatedAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

