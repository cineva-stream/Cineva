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

  /// Translates a list of [SubtitleCue] to Indonesian with progress notification.
  Future<List<SubtitleCue>> translateCuesToIndonesian({
    required List<SubtitleCue> cues,
    required String cacheKey,
    void Function(double progress)? onProgress,
  }) async {
    if (cues.isEmpty) return [];

    // 1. Check local cache first
    final cached = await _loadFromCache(cacheKey);
    if (cached != null && cached.isNotEmpty) {
      debugPrint('[SubtitleTranslator] Loaded from local cache: $cacheKey');
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
        final translatedBatchText = await _translateText(combinedText);
        final splitTranslated = translatedBatchText.split('[[DELIM]]');

        for (int j = 0; j < batch.length; j++) {
          final translatedLine = (j < splitTranslated.length)
              ? splitTranslated[j].trim()
              : batch[j].text;

          final rawText = translatedLine.isNotEmpty ? translatedLine : batch[j].text;
          final refinedText = balanceSubtitleLines(refineIndonesianPronouns(rawText));

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

  Future<String> _translateText(String text) async {
    final response = await _dio.get(
      'https://translate.googleapis.com/translate_a/single',
      queryParameters: {
        'client': 'gtx',
        'sl': 'auto',
        'tl': 'id',
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
  /// - "SAYA" -> "AKU", "Saya" -> "Aku", "saya" -> "aku"
  static String refineIndonesianPronouns(String text) {
    if (text.isEmpty) return text;

    return text.replaceAllMapped(
      RegExp(r'\b(kamu|anda|saya)\b', caseSensitive: false),
      (match) {
        final word = match.group(0)!;
        final lower = word.toLowerCase();
        final isAllUpper = word == word.toUpperCase();
        final isCapitalized = word[0] == word[0].toUpperCase();

        if (lower == 'saya') {
          if (isAllUpper) return 'AKU';
          if (isCapitalized) return 'Aku';
          return 'aku';
        } else {
          // kamu or anda
          if (isAllUpper) return 'KAU';
          if (isCapitalized) return 'Kau';
          return 'kau';
        }
      },
    );
  }

  Future<List<SubtitleCue>?> _loadFromCache(String cacheKey) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/subtitles_cache/$cacheKey.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        return jsonList.map((item) {
          final textWithPronouns = refineIndonesianPronouns(item['text'] as String);
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
