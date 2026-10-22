/// Represents a single timestamped subtitle entry.
class SubtitleCue {
  final Duration start;
  final Duration end;
  final String text;

  const SubtitleCue({
    required this.start,
    required this.end,
    required this.text,
  });

  bool isActiveAt(Duration position) {
    return position >= start && position <= end;
  }

  /// Parses raw SRT or WebVTT content into an ordered list of [SubtitleCue].
  static List<SubtitleCue> parseSrt(String content) {
    final cues = <SubtitleCue>[];
    final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final blocks = normalized.split('\n\n');

    for (final block in blocks) {
      final lines = block.trim().split('\n');
      if (lines.isEmpty) continue;

      // Find timecode line (contains '-->')
      int timeLineIdx = -1;
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].contains('-->')) {
          timeLineIdx = i;
          break;
        }
      }
      if (timeLineIdx == -1) continue;

      final times = lines[timeLineIdx].split('-->');
      if (times.length != 2) continue;

      final startStr = times[0].trim().split(RegExp(r'\s+'))[0];
      final endStr = times[1].trim().split(RegExp(r'\s+'))[0];

      final start = _parseTimestamp(startStr);
      final end = _parseTimestamp(endStr);
      if (start == null || end == null) continue;

      // Text lines follow timecode line
      final textLines = lines.sublist(timeLineIdx + 1);
      final rawText = textLines.join('\n').trim();
      final cleanText = _cleanSubtitleText(rawText);

      if (cleanText.isNotEmpty) {
        cues.add(SubtitleCue(start: start, end: end, text: cleanText));
      }
    }

    return cues;
  }

  static Duration? _parseTimestamp(String timestamp) {
    try {
      final parts = timestamp.replaceAll(',', '.').split(':');
      int hours = 0;
      int minutes = 0;
      String secString = '';

      if (parts.length == 3) {
        hours = int.parse(parts[0]);
        minutes = int.parse(parts[1]);
        secString = parts[2];
      } else if (parts.length == 2) {
        minutes = int.parse(parts[0]);
        secString = parts[1];
      } else {
        return null;
      }

      final secParts = secString.split('.');
      final seconds = int.parse(secParts[0]);
      final millis = secParts.length > 1
          ? int.parse(secParts[1].padRight(3, '0').substring(0, 3))
          : 0;

      return Duration(
        hours: hours,
        minutes: minutes,
        seconds: seconds,
        milliseconds: millis,
      );
    } catch (_) {
      return null;
    }
  }

  static String _cleanSubtitleText(String text) {
    // Remove HTML tags like <i>, <b>, <font color="...">, etc.
    return text.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}
