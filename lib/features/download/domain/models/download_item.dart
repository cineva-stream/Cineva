enum DownloadStatus {
  resolving,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

/// Represents a downloaded or actively downloading movie/TV episode.
class DownloadItem {
  final String id;
  final int tmdbId;
  final String title;
  final String mediaType; // 'movie' or 'tv'
  final String releaseYear;
  final int? seasonNumber;
  final int? episodeNumber;
  final String? episodeTitle;
  final String? posterPath;
  final String? backdropPath;
  final String resolution; // '1080p', '720p', '480p', '360p'
  final int estimatedSizeBytes;
  final int downloadedBytes;
  final int totalBytes;
  final DownloadStatus status;
  final double progress; // 0.0 - 1.0
  final String speed; // e.g. "2.4 MB/s"
  final String videoFileName;
  final String subtitleFileName;
  final String videoPath;
  final String? subtitlePath;
  final String selectedSubtitleLang;
  final String subtitleStatus; // 'none', 'ready', 'translated', 'failed'
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? completedAt;

  const DownloadItem({
    required this.id,
    required this.tmdbId,
    required this.title,
    required this.mediaType,
    this.releaseYear = '',
    this.seasonNumber,
    this.episodeNumber,
    this.episodeTitle,
    this.posterPath,
    this.backdropPath,
    this.resolution = '1080p',
    this.estimatedSizeBytes = 0,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.status = DownloadStatus.resolving,
    this.progress = 0.0,
    this.speed = '0 KB/s',
    required this.videoFileName,
    required this.subtitleFileName,
    required this.videoPath,
    this.subtitlePath,
    this.selectedSubtitleLang = 'id',
    this.subtitleStatus = 'none',
    this.errorMessage,
    required this.createdAt,
    this.completedAt,
  });

  bool get isMovie => mediaType == 'movie';
  bool get isTv => mediaType == 'tv';
  bool get isCompleted => status == DownloadStatus.completed;
  bool get isDownloading => status == DownloadStatus.downloading || status == DownloadStatus.resolving;
  bool get isPaused => status == DownloadStatus.paused;
  bool get isFailed => status == DownloadStatus.failed;

  String get formattedTotalSize {
    final bytes = totalBytes > 0 ? totalBytes : estimatedSizeBytes;
    if (bytes >= 1073741824) {
      return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
    } else if (bytes >= 1048576) {
      return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '$bytes B';
  }

  String get formattedDownloadedSize {
    if (downloadedBytes >= 1073741824) {
      return '${(downloadedBytes / 1073741824).toStringAsFixed(2)} GB';
    } else if (downloadedBytes >= 1048576) {
      return '${(downloadedBytes / 1048576).toStringAsFixed(1)} MB';
    } else if (downloadedBytes >= 1024) {
      return '${(downloadedBytes / 1024).toStringAsFixed(0)} KB';
    }
    return '$downloadedBytes B';
  }

  DownloadItem copyWith({
    String? id,
    int? tmdbId,
    String? title,
    String? mediaType,
    String? releaseYear,
    int? seasonNumber,
    int? episodeNumber,
    String? episodeTitle,
    String? posterPath,
    String? backdropPath,
    String? resolution,
    int? estimatedSizeBytes,
    int? downloadedBytes,
    int? totalBytes,
    DownloadStatus? status,
    double? progress,
    String? speed,
    String? videoFileName,
    String? subtitleFileName,
    String? videoPath,
    String? subtitlePath,
    String? selectedSubtitleLang,
    String? subtitleStatus,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return DownloadItem(
      id: id ?? this.id,
      tmdbId: tmdbId ?? this.tmdbId,
      title: title ?? this.title,
      mediaType: mediaType ?? this.mediaType,
      releaseYear: releaseYear ?? this.releaseYear,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      episodeTitle: episodeTitle ?? this.episodeTitle,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      resolution: resolution ?? this.resolution,
      estimatedSizeBytes: estimatedSizeBytes ?? this.estimatedSizeBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      speed: speed ?? this.speed,
      videoFileName: videoFileName ?? this.videoFileName,
      subtitleFileName: subtitleFileName ?? this.subtitleFileName,
      videoPath: videoPath ?? this.videoPath,
      subtitlePath: subtitlePath ?? this.subtitlePath,
      selectedSubtitleLang: selectedSubtitleLang ?? this.selectedSubtitleLang,
      subtitleStatus: subtitleStatus ?? this.subtitleStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tmdbId': tmdbId,
      'title': title,
      'mediaType': mediaType,
      'releaseYear': releaseYear,
      'seasonNumber': seasonNumber,
      'episodeNumber': episodeNumber,
      'episodeTitle': episodeTitle,
      'posterPath': posterPath,
      'backdropPath': backdropPath,
      'resolution': resolution,
      'estimatedSizeBytes': estimatedSizeBytes,
      'downloadedBytes': downloadedBytes,
      'totalBytes': totalBytes,
      'status': status.name,
      'progress': progress,
      'speed': speed,
      'videoFileName': videoFileName,
      'subtitleFileName': subtitleFileName,
      'videoPath': videoPath,
      'subtitlePath': subtitlePath,
      'selectedSubtitleLang': selectedSubtitleLang,
      'subtitleStatus': subtitleStatus,
      'errorMessage': errorMessage,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory DownloadItem.fromJson(Map<dynamic, dynamic> json) {
    return DownloadItem(
      id: json['id'] as String? ?? '',
      tmdbId: json['tmdbId'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      mediaType: json['mediaType'] as String? ?? 'movie',
      releaseYear: json['releaseYear'] as String? ?? '',
      seasonNumber: json['seasonNumber'] as int?,
      episodeNumber: json['episodeNumber'] as int?,
      episodeTitle: json['episodeTitle'] as String?,
      posterPath: json['posterPath'] as String?,
      backdropPath: json['backdropPath'] as String?,
      resolution: json['resolution'] as String? ?? '1080p',
      estimatedSizeBytes: json['estimatedSizeBytes'] as int? ?? 0,
      downloadedBytes: json['downloadedBytes'] as int? ?? 0,
      totalBytes: json['totalBytes'] as int? ?? 0,
      status: DownloadStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String? ?? ''),
        orElse: () => DownloadStatus.failed,
      ),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      speed: json['speed'] as String? ?? '0 KB/s',
      videoFileName: json['videoFileName'] as String? ?? '',
      subtitleFileName: json['subtitleFileName'] as String? ?? '',
      videoPath: json['videoPath'] as String? ?? '',
      subtitlePath: json['subtitlePath'] as String?,
      selectedSubtitleLang: json['selectedSubtitleLang'] as String? ?? 'id',
      subtitleStatus: json['subtitleStatus'] as String? ?? 'none',
      errorMessage: json['errorMessage'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
    );
  }
}
