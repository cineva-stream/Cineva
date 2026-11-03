/// Model representing remote application release metadata from GitHub Releases API.
class AppUpdateInfo {
  /// The latest version string (e.g. "1.0.4" without 'v' prefix).
  final String latestVersion;

  /// The title of the GitHub release.
  final String releaseTitle;

  /// The changelog or description provided in the release body.
  final String changelog;

  /// Direct browser download URL for the .apk asset.
  final String apkUrl;

  /// File name of the .apk asset (e.g. "Cineva_v1.0.4.apk").
  final String apkFileName;

  /// File size of the APK in bytes.
  final int apkSizeBytes;

  /// Timestamp when the release was published.
  final DateTime? publishedAt;

  /// The currently running version of the app on device (e.g. "1.0.3").
  final String currentVersion;

  /// Target CPU architecture of this APK asset (e.g. "arm64-v8a", "armeabi-v7a", "x86_64", or "universal").
  final String targetAbi;

  const AppUpdateInfo({
    required this.latestVersion,
    required this.releaseTitle,
    required this.changelog,
    required this.apkUrl,
    required this.apkFileName,
    required this.apkSizeBytes,
    this.publishedAt,
    required this.currentVersion,
    this.targetAbi = 'universal',
  });

  /// True if this update asset is optimized specifically for the device's CPU architecture.
  bool get isArchitectureSpecific => targetAbi.isNotEmpty && targetAbi != 'universal';

  /// Formatted string representing file size (e.g. "16.5 MB").
  String get formattedSize {
    if (apkSizeBytes <= 0) {
      return isArchitectureSpecific ? '~16 MB' : '~38 MB';
    }
    final mb = apkSizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  /// Extracts a brief 1-2 sentence clean summary from markdown changelog.
  String get shortSummary {
    if (changelog.trim().isEmpty) return '';
    final lines = changelog
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !l.startsWith('#') && !l.startsWith('---'))
        .toList();

    if (lines.isEmpty) return changelog.trim();
    // Clean bullet points
    final clean = lines.map((l) => l.replaceFirst(RegExp(r'^[-*•]\s*'), '')).join(' ');
    if (clean.length > 140) {
      return '${clean.substring(0, 137)}...';
    }
    return clean;
  }
}
