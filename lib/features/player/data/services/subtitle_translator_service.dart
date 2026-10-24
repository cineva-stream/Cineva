import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/subtitle_cue.dart';

/// Free automated subtitle translation service to Indonesian using Google Translate GTX endpoint.
class SubtitleTranslatorService {
  final Dio _dio;

  SubtitleTranslatorService()
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'},
        ));

  /// Translates a list of [SubtitleCue] to a target language with progress notification.
  /// Supports dynamic targetLang (e.g. 'id', 'en', 'es', 'ja', 'fr', etc.).
  Future<List<SubtitleCue>> translateCues({
    required List<SubtitleCue> cues,
    required String cacheKey,
    String targetLang = 'id',
    void Function(double progress)? onProgress,
  }) async {
    if (cues.isEmpty) return [];

    // 1. Check local cache first
    final cached = await _loadFromCache(cacheKey, targetLang: targetLang);
    if (cached != null && cached.isNotEmpty) {
      debugPrint('[SubtitleTranslator] Loaded from local cache ($targetLang): $cacheKey');
      onProgress?.call(1.0);
      return cached;
    }

    const delimiter = '\n[[DELIM]]\n';
    const batchSize = 35; // optimal for URL length and rate limit
    final translatedCues = <SubtitleCue>[];

    final totalBatches = (cues.length / batchSize).ceil();

    for (int i = 0; i < cues.length; i += batchSize) {
      final currentBatchIndex = i ~/ batchSize;
      final end = (i + batchSize < cues.length) ? i + batchSize : cues.length;
      final batch = cues.sublist(i, end);

      final combinedText = batch.map((c) => c.text.replaceAll('\n', ' ')).join(delimiter);

      try {
        final translatedBatchText = await _translateText(combinedText, targetLang: targetLang);
        final splitTranslated = translatedBatchText.split('[[DELIM]]');

        for (int j = 0; j < batch.length; j++) {
          final translatedLine = (j < splitTranslated.length)
              ? splitTranslated[j].trim()
              : batch[j].text;

          final rawText = translatedLine.isNotEmpty ? translatedLine : batch[j].text;
          final refinedText = targetLang.toLowerCase() == 'id'
              ? balanceSubtitleLines(smartFormatIndonesianSubtitle(refineIndonesianPronouns(rawText)))
              : balanceSubtitleLines(rawText);

          translatedCues.add(SubtitleCue(
            start: batch[j].start,
            end: batch[j].end,
            text: refinedText,
          ));
        }
      } catch (e) {
        debugPrint('[SubtitleTranslator] Batch $currentBatchIndex translation error: $e');
        // Fallback to original cues if a batch fails
        translatedCues.addAll(batch);
      }

      final progress = (currentBatchIndex + 1) / totalBatches;
      onProgress?.call(progress.clamp(0.0, 1.0));

      // Small throttle to avoid aggressive rate limiting
      if (i + batchSize < cues.length) {
        await Future.delayed(const Duration(milliseconds: 150));
      }
    }

    // 2. Save translated cues to local cache
    await _saveToCache(cacheKey, translatedCues);

    return translatedCues;
  }

  /// Backward-compatible method that translates cues specifically to Indonesian.
  Future<List<SubtitleCue>> translateCuesToIndonesian({
    required List<SubtitleCue> cues,
    required String cacheKey,
    void Function(double progress)? onProgress,
  }) {
    return translateCues(
      cues: cues,
      cacheKey: cacheKey,
      targetLang: 'id',
      onProgress: onProgress,
    );
  }

  Future<String> _translateText(String text, {String targetLang = 'id'}) async {
    final response = await _dio.get(
      'https://translate.googleapis.com/translate_a/single',
      queryParameters: {
        'client': 'gtx',
        'sl': 'auto',
        'tl': targetLang,
        'dt': 't',
        'q': text,
      },
    );

    final data = response.data;
    if (data is List && data.isNotEmpty && data[0] is List) {
      final parts = data[0] as List<dynamic>;
      final buffer = StringBuffer();
      for (final part in parts) {
        if (part is List && part.isNotEmpty && part[0] != null) {
          buffer.write(part[0].toString());
        }
      }
      return buffer.toString();
    }
    return text;
  }

  /// Balances long subtitle text lines so they wrap cleanly across 2-3 lines
  /// at natural word and punctuation boundaries, preventing horizontal cut-off on mobile screens.
  static String balanceSubtitleLines(String text, {int maxLineChars = 42}) {
    if (text.isEmpty) return text;

    // If text already has newlines, process each line individually
    if (text.contains('\n')) {
      final lines = text.split('\n');
      return lines.map((l) => balanceSubtitleLines(l.trim(), maxLineChars: maxLineChars)).join('\n');
    }

    final trimmed = text.trim();
    if (trimmed.length <= maxLineChars) return trimmed;

    final words = trimmed.split(RegExp(r'\s+'));
    if (words.length <= 1) return trimmed;

    // Determine target number of lines based on length
    final targetLineCount = (trimmed.length / maxLineChars).ceil().clamp(2, 4);
    final targetCharsPerLine = trimmed.length / targetLineCount;

    final resultLines = <String>[];
    var currentLine = StringBuffer();

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (currentLine.isEmpty) {
        currentLine.write(word);
      } else {
        final potentialLength = currentLine.length + 1 + word.length;
        // Check if adding this word significantly exceeds targetCharsPerLine
        // and we haven't reached the last line yet
        if (potentialLength > targetCharsPerLine &&
            resultLines.length < targetLineCount - 1 &&
            currentLine.length >= targetCharsPerLine * 0.7) {
          resultLines.add(currentLine.toString());
          currentLine = StringBuffer()..write(word);
        } else {
          currentLine.write(' ');
          currentLine.write(word);
        }
      }
    }

    if (currentLine.isNotEmpty) {
      resultLines.add(currentLine.toString());
    }

    return resultLines.join('\n');
  }

  /// Replaces formal Indonesian pronouns with natural cinematic conversational speech:
  /// - "KAMU" / "ANDA" -> "KAU", "Kamu" / "Anda" -> "Kau", "kamu" / "anda" -> "kau"
  /// - "KAMULAH" / "ANDALAH" -> "KAULAH", "Kamulah" / "Andalah" -> "Kaulah", "kamulah" / "andalah" -> "kaulah"
  /// - "SAYA" -> "AKU", "Saya" -> "Aku", "saya" -> "aku"
  static String refineIndonesianPronouns(String text) {
    if (text.isEmpty) return text;

    return text.replaceAllMapped(
      RegExp(r'\b(kamulah|andalah|kamu|anda|saya)\b', caseSensitive: false),
      (match) {
        final word = match.group(0)!;
        final lower = word.toLowerCase();
        final isAllUpper = word == word.toUpperCase();
        final isCapitalized = word[0] == word[0].toUpperCase();

        if (lower == 'saya') {
          if (isAllUpper) return 'AKU';
          if (isCapitalized) return 'Aku';
          return 'aku';
        } else if (lower == 'kamulah' || lower == 'andalah') {
          if (isAllUpper) return 'KAULAH';
          if (isCapitalized) return 'Kaulah';
          return 'kaulah';
        } else {
          // kamu or anda
          if (isAllUpper) return 'KAU';
          if (isCapitalized) return 'Kau';
          return 'kau';
        }
      },
    );
  }

  static const Set<String> _knownAcronyms = {
    'FBI', 'CIA', 'NASA', 'DNA', 'RNA', 'TV', 'ID', 'OK', 'AS', 'PBB',
    'RS', 'UGD', 'ICU', 'SWAT', 'CEO', 'CFO', 'CTO', 'VIP', 'VVIP',
    'DJ', 'PC', 'AI', 'GPS', 'USB', 'PIN', 'ATM', 'SIM', 'KTP', 'BOM',
    'UFO', 'AC', 'CD', 'DVD', 'HD', 'FHD', '4K', 'CSI', 'NCIS', 'MI6',
    'KGB', 'UN', 'EU', 'US', 'UK', 'USA', 'SOS', 'HQ', 'WIB', 'WITA', 'WIT',
  };

  static const Set<String> _sacredNames = {
    'tuhan', 'tuhanku', 'tuhan-ku', 'tuhanmu', 'tuhan-mu', 'tuhannya', 'tuhan-nya',
    'allah', 'allahku', 'allah-ku', 'allahmu', 'allah-mu', 'allahnya', 'allah-nya',
    'yesus', 'kristus', 'bapa', 'pencipta',
  };

  static const Set<String> _fixedProperNouns = {
    // Days & Months
    'senin', 'selasa', 'rabu', 'kamis', 'jumat', 'sabtu', 'minggu',
    'januari', 'februari', 'maret', 'april', 'mei', 'juni',
    'juli', 'agustus', 'september', 'oktober', 'november', 'desember',

    // Common countries, cities & major locations
    'indonesia', 'jakarta', 'surabaya', 'bandung', 'medan', 'bali', 'yogyakarta',
    'amerika', 'inggris', 'jepang', 'korea', 'cina', 'tiongkok', 'rusia', 'prancis',
    'jerman', 'italia', 'spanyol', 'kanada', 'australia', 'belanda', 'meksiko',
    'brasil', 'india', 'mesir', 'london', 'paris', 'tokyo', 'seoul', 'washington',
    'new', 'york', 'angeles', 'chicago', 'roma', 'berlin', 'moskow', 'beijing',
    'singapura', 'bangkok',
  };

  static const Set<String> _titleAndPlacePrefixes = {
    // Titles / Honorifics
    'pak', 'bapak', 'bu', 'ibu', 'tuan', 'nyonya', 'nona', 'dokter', 'dok',
    'profesor', 'prof', 'kapten', 'detektif', 'sersan', 'mayor', 'jenderal',
    'inspektur', 'komandan', 'paman', 'bibi', 'kakek', 'nenek', 'raja', 'ratu',
    'pangeran', 'putri', 'presiden',

    // Places / Geographic markers
    'jalan', 'jl', 'gang', 'gg', 'kota', 'provinsi', 'pulau',
    'gunung', 'danau', 'sungai', 'laut', 'samudra', 'bandara', 'stasiun',
    'gedung', 'rumah sakit',
  };

  /// Intelligently formats Indonesian subtitle text:
  /// - Normalizes chaotic mixed casing from machine translations (e.g., "KAmi", "KAMI sedang")
  /// - Enforces uppercase at the start of sentences, dialogues, and after terminal punctuation (., ?, !, ...)
  /// - Capitalizes sacred entities (Tuhan, Allah, Yesus, Kristus, etc.)
  /// - Capitalizes days, months, and major cities/countries
  /// - Capitalizes titles, honorifics, and geographic markers followed by names (e.g. "Jalan Sudirman", "Dokter Smith")
  /// - Preserves recognized acronyms (FBI, CIA, TV, etc.) in uppercase
  /// - Handles hyphenated words and Indonesian reduplications gracefully
  static String smartFormatIndonesianSubtitle(String text) {
    if (text.isEmpty) return text;

    final lines = text.split('\n');
    final formattedLines = lines.map(_formatSingleLine).toList();
    return formattedLines.join('\n');
  }

  static String _formatSingleLine(String line) {
    if (line.trim().isEmpty) return line;

    final tokenRegex = RegExp(r'([A-Za-z0-9\u00C0-\u024F]+(?:-[A-Za-z0-9\u00C0-\u024F]+)*|[^\sA-Za-z0-9\u00C0-\u024F]+|\s+)');
    final matches = tokenRegex.allMatches(line);

    final tokens = matches.map((m) => m.group(0)!).toList();
    final result = <String>[];

    bool isStartOfSentence = true;
    bool capitalizeNextWord = false;

    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];

      // Whitespace
      if (RegExp(r'^\s+$').hasMatch(token)) {
        result.add(token);
        continue;
      }

      // Punctuation / symbols
      if (RegExp(r'^[^\sA-Za-z0-9\u00C0-\u024F]+$').hasMatch(token)) {
        result.add(token);

        if (token.contains('.') || token.contains('!') || token.contains('?') || token.contains('…')) {
          isStartOfSentence = true;
          capitalizeNextWord = false;
        } else if (token.contains('-') || token.contains('—') || token.contains('"') || token.contains('“') || token.contains('”') || token.contains(':')) {
          if (result.where((t) => RegExp(r'[A-Za-z0-9]').hasMatch(t)).isEmpty || isStartOfSentence) {
            isStartOfSentence = true;
          }
        }
        continue;
      }

      // Word token
      final lower = token.toLowerCase();
      final upper = token.toUpperCase();

      // 1. Acronyms (FBI, CIA, TV, etc.)
      if (_knownAcronyms.contains(upper)) {
        result.add(upper);
        isStartOfSentence = false;
        capitalizeNextWord = false;
        continue;
      }

      // 2. Sacred names (Tuhan, Allah, Yesus, Kristus)
      if (_sacredNames.contains(lower)) {
        result.add(_capitalizeWord(lower));
        isStartOfSentence = false;
        capitalizeNextWord = false;
        continue;
      }

      // 3. Fixed proper nouns (days, months, countries, major cities)
      if (_fixedProperNouns.contains(lower)) {
        result.add(_capitalizeWord(lower));
        isStartOfSentence = false;
        capitalizeNextWord = false;
        continue;
      }

      // 4. Honorific/Place following word (e.g. "Jalan Sudirman", "Dokter Smith")
      if (capitalizeNextWord) {
        result.add(_capitalizeWord(lower));
        capitalizeNextWord = false;
        isStartOfSentence = false;
        continue;
      }

      // 5. Honorific/Place prefix itself
      if (_titleAndPlacePrefixes.contains(lower)) {
        result.add(_capitalizeWord(lower));
        capitalizeNextWord = true;
        isStartOfSentence = false;
        continue;
      }

      // 6. Sentence or dialogue beginning
      if (isStartOfSentence) {
        result.add(_capitalizeWord(lower));
        isStartOfSentence = false;
        continue;
      }

      // 7. Standard lowercase word within sentence
      result.add(lower);
    }

    return result.join('');
  }

  static String _capitalizeWord(String word) {
    if (word.isEmpty) return word;
    if (word.contains('-')) {
      final parts = word.split('-');
      // Indonesian reduplication (e.g. anak-anak, tiba-tiba), only capitalize first part
      if (parts.length == 2 && parts[0].toLowerCase() == parts[1].toLowerCase()) {
        return '${parts[0][0].toUpperCase()}${parts[0].substring(1).toLowerCase()}-${parts[1].toLowerCase()}';
      }
      // Hyphenated proper names (e.g. Soekarno-Hatta)
      return parts.map((p) => p.isNotEmpty ? '${p[0].toUpperCase()}${p.substring(1)}' : p).join('-');
    }
    return '${word[0].toUpperCase()}${word.substring(1)}';
  }

  Future<List<SubtitleCue>?> _loadFromCache(String cacheKey, {String targetLang = 'id'}) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/subtitles_cache/$cacheKey.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        return jsonList.map((item) {
          final rawText = item['text'] as String;
          final textWithPronouns = targetLang.toLowerCase() == 'id'
              ? smartFormatIndonesianSubtitle(refineIndonesianPronouns(rawText))
              : rawText;
          return SubtitleCue(
            start: Duration(milliseconds: item['startMs'] as int),
            end: Duration(milliseconds: item['endMs'] as int),
            text: balanceSubtitleLines(textWithPronouns),
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('[SubtitleTranslator] Cache load error: $e');
    }
    return null;
  }

  Future<void> _saveToCache(String cacheKey, List<SubtitleCue> cues) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${dir.path}/subtitles_cache');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }
      final file = File('${cacheDir.path}/$cacheKey.json');
      final jsonList = cues.map((c) => {
        'startMs': c.start.inMilliseconds,
        'endMs': c.end.inMilliseconds,
        'text': c.text,
      }).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      debugPrint('[SubtitleTranslator] Cache save error: $e');
    }
  }

  void dispose() {
    _dio.close();
  }
}
