/// Formatter for video and subtitle file names according to exact user specifications:
/// - Movie: "{Movie Name} - {Release Year}.mp4" (e.g. "SpiderMan Brand New Day - 2026.mp4")
/// - TV Series: "{TV Series Name} - S{Season} E{Episode}.mp4" (e.g. "The Originals - S1 E01.mp4")
/// - Subtitle: identical basename with .srt extension
class DownloadFileNamer {
  /// Strips OS-illegal characters like \ / : * ? " < > |
  static String sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Formats movie file name: "{Movie Name} - {Release Year}.mp4"
  static String formatMovieFileName(String title, String releaseYear) {
    final cleanTitle = sanitizeFileName(title);
    final cleanYear = releaseYear.trim().isNotEmpty ? releaseYear.trim() : 'Unknown';
    return '$cleanTitle - $cleanYear.mp4';
  }

  /// Formats TV episode file name: "{TV Series Name} - S{Season} E{Episode}.mp4"
  /// Episode is formatted with 2 digits (e.g. E01, E02, E12) to match "The Originals - S1 E01.mp4"
  static String formatTvFileName(String title, int season, int episode) {
    final cleanTitle = sanitizeFileName(title);
    final epFormatted = episode.toString().padLeft(2, '0');
    return '$cleanTitle - S$season E$epFormatted.mp4';
  }

  /// Formats corresponding subtitle file name (.srt)
  static String formatSubtitleFileName(String videoFileName) {
    if (videoFileName.toLowerCase().endsWith('.mp4')) {
      return '${videoFileName.substring(0, videoFileName.length - 4)}.srt';
    }
    return '$videoFileName.srt';
  }
}
