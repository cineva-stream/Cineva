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

  /// Number of releases/updates missed between [currentVersion] and [latestVersion].
  final int missedUpdateCount;

  /// Minimum number of missed updates required to trigger the mandatory full-screen update gate.
  static const int mandatoryUpdateThreshold = 3;

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
    this.missedUpdateCount = 1,
  });

  /// True when the user has skipped [mandatoryUpdateThreshold] (3) or more updates.
  bool get isMandatoryUpdate => missedUpdateCount >= mandatoryUpdateThreshold;

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

  static String _stripMarkdownTokens(String input) {
    var s = input.trim();
    // Convert markdown links [label](url) -> label
    s = s.replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]+\)'), (m) => m.group(1) ?? '');
    // Remove heading hashes and numbered prefixes like "### 1. "
    s = s.replaceFirst(RegExp(r'^#{1,6}\s*(?:\d+\.\s*)?'), '');
    // Remove leading bullet symbols
    s = s.replaceFirst(RegExp(r'^[-*•+]\s+'), '');
    // Strip bold/italic/code markers
    s = s.replaceAll('**', '').replaceAll('__', '').replaceAll('`', '');
    s = s.replaceAll('*', '');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    s = s.replaceAll(RegExp(r'^[:\-–—\s]+|[:\-–—\s]+$'), '');
    return s;
  }

  /// Extracts only the concise core feature highlights (up to [maxItems]) from [changelog],
  /// stripping verbose sub-descriptions, older version history, and build asset tables.
  List<String> extractCoreFeatures({
    bool preferEnglish = false,
    int maxItems = 7,
  }) {
    final raw = changelog.trim();
    if (raw.isEmpty) return const [];

    final lines = raw.split('\n');
    final headingFeatures = <String>[];
    final bulletFeatures = <String>[];

    for (final rawLine in lines) {
      final stripped = rawLine.trim();
      if (stripped.isEmpty || stripped.startsWith('---')) continue;

      // Stop before older version history or build file list sections
      if (RegExp(
        r'^#{1,3}\s*(?:Riwayat Versi|Previous Versions|Informasi Versi|Version Info)',
        caseSensitive: false,
      ).hasMatch(stripped)) {
        break;
      }

      // 1. Capture numbered feature headings like "### 1. Judul Fitur (*English Feature Title*)"
      final headMatch = RegExp(r'^###\s+(?:\d+\.\s*)?(.+)$').firstMatch(stripped);
      if (headMatch != null) {
        final rawHeading = headMatch.group(1)!.trim();
        final parenMatch = RegExp(r'\(\*([^*]+)\*\)').firstMatch(rawHeading);
        String cleaned;
        if (parenMatch != null) {
          if (preferEnglish) {
            cleaned = _stripMarkdownTokens(parenMatch.group(1)!);
          } else {
            final withoutParen = rawHeading.replaceAll(RegExp(r'\s*\(\*[^*]+\*\)\s*'), '').trim();
            cleaned = _stripMarkdownTokens(withoutParen);
          }
        } else {
          final withoutParen = rawHeading.replaceAll(RegExp(r'\s*\([^)]+\)\s*$'), '').trim();
          cleaned = _stripMarkdownTokens(withoutParen.isNotEmpty ? withoutParen : rawHeading);
        }
        if (cleaned.length >= 4) {
          headingFeatures.add(cleaned);
        }
        continue;
      }

      // 2. Capture top-level bullets (ignore deeply indented sub-bullets and APK file names)
      final indent = rawLine.length - rawLine.trimLeft().length;
      if (indent <= 2 && RegExp(r'^[-*•]\s+').hasMatch(stripped)) {
        var cleaned = _stripMarkdownTokens(stripped);
        if (cleaned.toLowerCase().startsWith('cineva_') ||
            cleaned.toLowerCase().endsWith('.apk') ||
            cleaned.toLowerCase().endsWith('.exe')) {
          continue;
        }
        // Keep only the concise feature title before ':' if the line is long
        if (cleaned.contains(':') && cleaned.length > 85) {
          final parts = cleaned.split(':');
          final head = parts.first.trim();
          final tail = parts.sublist(1).join(':').trim();
          if (head.length >= 10 && head.length <= 75) {
            cleaned = head;
          } else if (tail.isNotEmpty) {
            final shortTail = tail.length > 65 ? '${tail.substring(0, 62).trimRight()}...' : tail;
            cleaned = '$head: $shortTail';
          }
        } else if (cleaned.length > 100) {
          cleaned = '${cleaned.substring(0, 97).trimRight()}...';
        }
        if (cleaned.length >= 4) {
          bulletFeatures.add(cleaned);
        }
      }
    }

    final chosen = headingFeatures.length >= 2 ? headingFeatures : bulletFeatures;
    if (chosen.isNotEmpty) {
      return chosen.take(maxItems).toList();
    }

    // Fallback: take first few non-heading clean lines
    final fallback = <String>[];
    for (final rawLine in lines) {
      final stripped = rawLine.trim();
      if (stripped.isEmpty || stripped.startsWith('#') || stripped.startsWith('---')) continue;
      final cleaned = _stripMarkdownTokens(stripped);
      if (cleaned.length >= 6) {
        fallback.add(cleaned.length > 100 ? '${cleaned.substring(0, 97)}...' : cleaned);
      }
      if (fallback.length >= maxItems) break;
    }
    return fallback;
  }

  /// Formats the extracted core features as a clean, concise bulleted Markdown list
  /// for in-app display (`UpdateDetailModal` and `MandatoryUpdateScreen`).
  String formatCoreChangelogMarkdown({
    bool preferEnglish = false,
    int maxItems = 7,
  }) {
    final features = extractCoreFeatures(
      preferEnglish: preferEnglish,
      maxItems: maxItems,
    );
    if (features.isEmpty) return changelog.trim();
    return features.map((f) => '• $f').join('\n\n');
  }
}
