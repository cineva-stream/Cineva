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
              : balanceSubtitleLines(fixAbbreviations(rawText));

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

  /// Matches the casing of [original] onto [replacement]:
  /// - If [original] is ALL CAPS -> [replacement] is uppercase
  /// - If [original] is TitleCase / Capitalized -> [replacement] is capitalized
  /// - Otherwise -> [replacement] is lowercase
  static String _matchCase(String original, String replacement) {
    if (original.isEmpty || replacement.isEmpty) return replacement;

    final hasLetters = RegExp(r'[A-Za-z]').hasMatch(original);
    if (hasLetters && original == original.toUpperCase()) {
      return replacement.toUpperCase();
    }

    final firstLetterMatch = RegExp(r'[A-Za-z]').firstMatch(original);
    if (firstLetterMatch != null) {
      final firstChar = firstLetterMatch.group(0)!;
      if (firstChar == firstChar.toUpperCase() && firstChar != firstChar.toLowerCase()) {
        final prefix = original.substring(0, firstLetterMatch.start);
        return '$prefix${replacement[0].toUpperCase()}${replacement.substring(1)}';
      }
    }

    return replacement.toLowerCase();
  }

  /// Ordered rulebook for the Cinematic NLP Post-Processing Engine:
  /// Transforms stiff, literal machine translations into natural film conversational dialogue.
  static final List<({RegExp pattern, String replacement})> _cinematicRules = [
    // --- 1. POLICE, ACTION & CRIME SHOWS (The Rookie, SWAT, FBI, Chicago PD) ---
    (
      pattern: RegExp(r'\b(salin itu|salinan itu)\b', caseSensitive: false),
      replacement: 'dimengerti',
    ),
    (
      pattern: RegExp(r'\b(tahan apimu|pegang apimu|tahan tembakanmu)\b', caseSensitive: false),
      replacement: 'tahan tembakan',
    ),
    (
      pattern: RegExp(r'\b(tembak sesuka hati)\b', caseSensitive: false),
      replacement: 'bebas menembak',
    ),
    (
      pattern: RegExp(r'\b(tembakan dilepaskan|tembakan dilepas)\b', caseSensitive: false),
      replacement: 'ada tembakan',
    ),
    (
      pattern: RegExp(r'\b(pria jatuh|orang jatuh)\b', caseSensitive: false),
      replacement: 'ada korban jatuh',
    ),
    (
      pattern: RegExp(r'\b(butuh cadangan|membutuhkan cadangan)\b', caseSensitive: false),
      replacement: 'butuh bantuan',
    ),
    (
      pattern: RegExp(r'\b(tersangka dalam tahanan)\b', caseSensitive: false),
      replacement: 'tersangka sudah diamankan',
    ),
    (
      pattern: RegExp(r'\b(tersangka melarikan diri|pelaku melarikan diri)\b', caseSensitive: false),
      replacement: 'tersangka kabur',
    ),
    (
      pattern: RegExp(r'\b(angkat kedua tanganmu|angkat tanganmu)\b', caseSensitive: false),
      replacement: 'angkat tangan',
    ),
    (
      pattern: RegExp(r'\b(jatuhkan senjatamu|taruh senjatamu)\b', caseSensitive: false),
      replacement: 'jatuhkan senjatamu',
    ),
    (
      pattern: RegExp(r'\b(jangan bergerak|jangan berpindah)\b', caseSensitive: false),
      replacement: 'jangan bergerak',
    ),
    (
      pattern: RegExp(r'\b(tetap di belakang|berdiri di belakang)\b', caseSensitive: false),
      replacement: 'jangan mendekat',
    ),
    (
      pattern: RegExp(r'\b(tetaplah di sana|tetap di sana)\b', caseSensitive: false),
      replacement: 'tetap di tempatmu',
    ),
    (
      pattern: RegExp(r'\b(dalam perjalanan saya|dalam perjalanan kita)\b', caseSensitive: false),
      replacement: 'aku segera ke sana',
    ),
    (
      pattern: RegExp(r'\b(semua bersih|semuanya bersih)\b', caseSensitive: false),
      replacement: 'area aman',
    ),
    (
      pattern: RegExp(r'\b(kamar darurat|ruang darurat)\b', caseSensitive: false),
      replacement: 'ruang gawat darurat',
    ),
    (
      pattern: RegExp(r'\b(adegan kejahatan)\b', caseSensitive: false),
      replacement: 'TKP',
    ),
    (
      pattern: RegExp(r'\b(panggilan darurat 911|panggilan 911)\b', caseSensitive: false),
      replacement: 'panggilan darurat',
    ),
    (
      pattern: RegExp(r'\b(tiarap di lantai|ke lantai sekarang|di lantai sekarang)\b', caseSensitive: false),
      replacement: 'tiarap',
    ),

    // --- 2. ENGLISH IDIOMS LITERALLY TRANSLATED BY GTX ---
    (
      pattern: RegExp(r'\b(punya punggungmu|memiliki punggungmu|dapat punggungmu|menjaga punggungmu)\b', caseSensitive: false),
      replacement: 'melindungimu',
    ),
    (
      pattern: RegExp(r'\b(punya punggungku|memiliki punggungku|dapat punggungku|menjaga punggungku)\b', caseSensitive: false),
      replacement: 'melindungiku',
    ),
    (
      pattern: RegExp(r'\b(punya punggung kita|memiliki punggung kita)\b', caseSensitive: false),
      replacement: 'melindungi kita',
    ),
    (
      pattern: RegExp(r'\b(beri aku istirahat|berikan aku istirahat)\b', caseSensitive: false),
      replacement: 'yang benar saja',
    ),
    (
      pattern: RegExp(r'\b(kepala ke atas|kepala di atas)\b', caseSensitive: false),
      replacement: 'awas',
    ),
    (
      pattern: RegExp(r'\b(sebut itu sehari|menyebutnya sehari|sebutlah sehari)\b', caseSensitive: false),
      replacement: 'cukup untuk hari ini',
    ),
    (
      pattern: RegExp(r'\b(bukan sepotong kue)\b', caseSensitive: false),
      replacement: 'tidak mudah',
    ),
    (
      pattern: RegExp(r'\b(sepotong kue)\b', caseSensitive: false),
      replacement: 'sangat mudah',
    ),
    (
      pattern: RegExp(r'\b(gigit peluru|menggigit peluru)\b', caseSensitive: false),
      replacement: 'hadapi saja',
    ),
    (
      pattern: RegExp(r'\b(keluar dari pertanyaan)\b', caseSensitive: false),
      replacement: 'mustahil',
    ),
    (
      pattern: RegExp(r'\b(berada di perahu yang sama|di perahu yang sama|berada di kapal yang sama|di kapal yang sama)\b', caseSensitive: false),
      replacement: 'senasib',
    ),
    (
      pattern: RegExp(r'\b(di bawah cuaca)\b', caseSensitive: false),
      replacement: 'kurang enak badan',
    ),
    (
      pattern: RegExp(r'\b(hanya tarik kakimu|hanya menarik kakimu|tarik kakimu|menarik kakimu)\b', caseSensitive: false),
      replacement: 'hanya bercanda',
    ),
    (
      pattern: RegExp(r'\b(kehilangan akalmu|kehilangan kepalamu)\b', caseSensitive: false),
      replacement: 'kehilangan akal sehat',
    ),
    (
      pattern: RegExp(r'\b(buat pikiranmu|membuat pikiranmu)\b', caseSensitive: false),
      replacement: 'tentukan pilihanmu',
    ),
    (
      pattern: RegExp(r'\b(ujung gunung es)\b', caseSensitive: false),
      replacement: 'puncak gunung es',
    ),
    (
      pattern: RegExp(r'\b(tetesan terakhir|sedotan terakhir)\b', caseSensitive: false),
      replacement: 'batas kesabaran',
    ),
    (
      pattern: RegExp(r'\b(memotong sudut)\b', caseSensitive: false),
      replacement: 'mengambil jalan pintas',
    ),
    (
      pattern: RegExp(r'\b(dalam kulit kacang|singkatnya dalam cangkang)\b', caseSensitive: false),
      replacement: 'singkatnya',
    ),
    (
      pattern: RegExp(r'\b(tangan ke bawah)\b', caseSensitive: false),
      replacement: 'tanpa ragu',
    ),

    // --- 3. CONVERSATIONAL SMOOTHING (Film Dialogue) ---
    (
      pattern: RegExp(r'\b(apa yang sedang kau bicarakan|apa yang sedang kamu bicarakan|apa yang kau bicarakan|apa yang kamu bicarakan)\b', caseSensitive: false),
      replacement: 'kau bicara apa',
    ),
    (
      pattern: RegExp(r'\b(apa yang sedang terjadi)\b', caseSensitive: false),
      replacement: 'apa yang terjadi',
    ),
    (
      pattern: RegExp(r'\b(apa yang kau maksudkan|apa yang kamu maksudkan|apa yang kau maksud|apa yang kamu maksud)\b', caseSensitive: false),
      replacement: 'apa maksudmu',
    ),
    (
      pattern: RegExp(r'\b(di sanalah kau berada|di sanalah kamu berada|di sana kau berada|di sana kamu berada)\b', caseSensitive: false),
      replacement: 'rupanya kau di sana',
    ),
    (
      pattern: RegExp(r'\b(apa yang kau tunggu|apa yang kamu tunggu)\b', caseSensitive: false),
      replacement: 'tunggu apa lagi',
    ),
    (
      pattern: RegExp(r'\b(aku tidak berpikir begitu|aku tak berpikir begitu|saya tidak berpikir begitu)\b', caseSensitive: false),
      replacement: 'kurasa tidak',
    ),
    (
      pattern: RegExp(r'\b(aku pikir begitu|aku rasa begitu|saya pikir begitu)\b', caseSensitive: false),
      replacement: 'kurasa begitu',
    ),
    (
      pattern: RegExp(r'\b(aku pikir bahwa|aku berpikir bahwa|saya pikir bahwa)\b', caseSensitive: false),
      replacement: 'kurasa',
    ),
    (
      pattern: RegExp(r'\b(aku pikir|aku berpikir|saya pikir)\b', caseSensitive: false),
      replacement: 'kurasa',
    ),
    (
      pattern: RegExp(r'\b(itu tidak masuk akal|itu tak masuk akal)\b', caseSensitive: false),
      replacement: 'tak masuk akal',
    ),
    (
      pattern: RegExp(r'\b(tidak masuk akal)\b', caseSensitive: false),
      replacement: 'tak masuk akal',
    ),
    (
      pattern: RegExp(r'\b(itu masuk akal)\b', caseSensitive: false),
      replacement: 'masuk akal',
    ),
    (
      pattern: RegExp(r'\b(itu tidak apa-apa|itu tak apa-apa)\b', caseSensitive: false),
      replacement: 'tak apa',
    ),
    (
      pattern: RegExp(r'\b(tidak apa-apa|tidak apa apa)\b', caseSensitive: false),
      replacement: 'tak apa',
    ),
    (
      pattern: RegExp(r'\b(jangan khawatir tentang itu|jangan khawatir tentang hal itu)\b', caseSensitive: false),
      replacement: 'jangan khawatir',
    ),
    (
      pattern: RegExp(r'\b(jangan khawatirkan aku|jangan khawatir tentang aku)\b', caseSensitive: false),
      replacement: 'jangan cemaskan aku',
    ),
    (
      pattern: RegExp(r'\b(aku harus pergi sekarang|saya harus pergi sekarang)\b', caseSensitive: false),
      replacement: 'aku harus pergi',
    ),
    (
      pattern: RegExp(r'\b(mari kita lakukan ini|ayo kita lakukan ini)\b', caseSensitive: false),
      replacement: 'ayo kita mulai',
    ),
    (
      pattern: RegExp(r'\b(tunggu satu menit|tunggu sebentar satu menit)\b', caseSensitive: false),
      replacement: 'tunggu sebentar',
    ),
    (
      pattern: RegExp(r'\b(tidak ada cara|tidak ada jalan)\b', caseSensitive: false),
      replacement: 'mustahil',
    ),
    (
      pattern: RegExp(r'\b(kamu dipersilakan|kau dipersilakan|anda dipersilakan)\b', caseSensitive: false),
      replacement: 'sama-sama',
    ),
    (
      pattern: RegExp(r'\b(aku tidak sabar menunggu|aku tak sabar menunggu)\b', caseSensitive: false),
      replacement: 'aku tak sabar',
    ),
    (
      pattern: RegExp(r'\b(aku tidak sabar untuk|aku tak sabar untuk)\b', caseSensitive: false),
      replacement: 'aku tak sabar ingin',
    ),
    (
      pattern: RegExp(r'\b(aku tidak peduli tentang itu|aku tidak peduli tentang hal itu)\b', caseSensitive: false),
      replacement: 'aku tak peduli soal itu',
    ),
    (
      pattern: RegExp(r'\b(hati-hati di luar sana)\b', caseSensitive: false),
      replacement: 'hati-hati di sana',
    ),

    // --- 4. EXCLAMATIONS, SWEARING & EMOTIONAL DIALOGUE ---
    (
      pattern: RegExp(r'\b(apa neraka|apa-apaan ini)\b', caseSensitive: false),
      replacement: 'apa-apaan ini',
    ),
    (
      pattern: RegExp(r'\b(persetan denganmu|sekrup kamu|sekrup kau)\b', caseSensitive: false),
      replacement: 'persetan denganmu',
    ),
    (
      pattern: RegExp(r'\b(anak jalang)\b', caseSensitive: false),
      replacement: 'brengsek',
    ),
    (
      pattern: RegExp(r'\b(sialan itu)\b', caseSensitive: false),
      replacement: 'sialan',
    ),
    (
      pattern: RegExp(r'\b(demi tuhan saya|demi tuhan)\b', caseSensitive: false),
      replacement: 'demi Tuhan',
    ),
    (
      pattern: RegExp(r'\b(oh tuhan saya|oh tuhan)\b', caseSensitive: false),
      replacement: 'ya Tuhan',
    ),
    (
      pattern: RegExp(r'\b(ya tuhan saya)\b', caseSensitive: false),
      replacement: 'ya Tuhan',
    ),

    // --- 5. STIFF CONNECTORS & CLUNKY FILLERS ---
    (
      pattern: RegExp(r'\b(oleh karena itu)\b', caseSensitive: false),
      replacement: 'karena itu',
    ),
    (
      pattern: RegExp(r'\b(pada saat ini)\b', caseSensitive: false),
      replacement: 'saat ini',
    ),
    (
      pattern: RegExp(r'\b(di dalam rangka)\b', caseSensitive: false),
      replacement: 'untuk',
    ),
    (
      pattern: RegExp(r'\b(sehubungan dengan)\b', caseSensitive: false),
      replacement: 'soal',
    ),
    (
      pattern: RegExp(r'\b(melakukan hal itu)\b', caseSensitive: false),
      replacement: 'melakukannya',
    ),
    (
      pattern: RegExp(r'\b(mengatakan hal itu)\b', caseSensitive: false),
      replacement: 'mengatakannya',
    ),
    (
      pattern: RegExp(r'\b(melihat hal itu)\b', caseSensitive: false),
      replacement: 'melihatnya',
    ),
  ];

  /// Transforms stiff, literal machine-translated Indonesian text into crisp,
  /// natural conversational cinema dialogue (Lebah Ganteng / Netflix ID style).
  ///
  /// - Normalizes literal idioms (e.g., "punya punggungmu" -> "melindungimu", "beri aku istirahat" -> "yang benar saja")
  /// - Smooths stiff robotic phrasing (e.g., "aku tidak berpikir begitu" -> "kurasa tidak")
  /// - Enhances police, crime and action show dialogue (e.g., "salin itu" -> "dimengerti", "pegang apimu" -> "tahan tembakan")
  /// - Preserves case (TitleCase, lowercase, UPPERCASE) and sentence flow seamlessly.
  static String applyCinematicIndonesianNaturalizer(String text) {
    if (text.isEmpty) return text;

    var result = text;
    for (final rule in _cinematicRules) {
      result = result.replaceAllMapped(rule.pattern, (match) {
        final original = match.group(0)!;
        return _matchCase(original, rule.replacement);
      });
    }

    return result;
  }

  /// Normalizes spaced single letters with dots, e.g. "l. a. p. d." -> "l.a.p.d." or "i. a." -> "i.a."
  static String _normalizeSpacedAbbreviations(String text) {
    if (text.isEmpty) return text;
    var prev = text;
    while (true) {
      final next = prev.replaceAllMapped(
        RegExp(r'\b([A-Za-z])\.\s+([A-Za-z](?:\.|\b))'),
        (m) => '${m[1]}.${m[2]}',
      );
      if (next == prev) break;
      prev = next;
    }
    return prev;
  }

  /// Normalizes messy abbreviation and acronym casing across any subtitle text:
  /// - Dotted abbreviations: "l.A.P.D" -> "L.A.P.D", "i.A" -> "I.A", "t.O" -> "T.O", "t.O.-ku" -> "T.O.-ku"
  /// - Spaced abbreviations: "l. a. p. d." -> "L.A.P.D.", "i. a." -> "I.A."
  /// - Standalone acronyms: "lapd", "nypd", "swat", "cpr", etc. -> "LAPD", "NYPD", etc.
  /// - Leaves common Indonesian words ("ia", "doa", "to") unaffected when written without dots.
  static String fixAbbreviations(String text) {
    if (text.isEmpty) return text;

    // 1. Normalize spaced abbreviations
    var normalized = _normalizeSpacedAbbreviations(text);

    // 2. Normalize dotted abbreviations (letters separated by dots, optional trailing dot and hyphenated suffix)
    normalized = normalized.replaceAllMapped(
      RegExp(r'\b([A-Za-z](?:\.[A-Za-z0-9])+\.?)(-[A-Za-z0-9\u00C0-\u024F]+)?\b'),
      (match) {
        final abbr = match.group(1)!.toUpperCase();
        final suffix = match.group(2);
        if (suffix != null && suffix.isNotEmpty) {
          return '$abbr${suffix.toLowerCase()}';
        }
        return abbr;
      },
    );

    // 3. Normalize safe standalone acronyms (that do not collide with Indonesian or English words)
    normalized = normalized.replaceAllMapped(
      RegExp(
        r'\b(lapd|nypd|cpd|sfpd|swat|dea|atf|dhs|doj|nsa|tsa|fbi|cia|ems|emt|cpr|bolo|apb|polri|tni|kpk|bnn|bmkg|bpbd|basarnas)\b',
        caseSensitive: false,
      ),
      (match) => match.group(0)!.toUpperCase(),
    );

    return normalized;
  }

  static const Set<String> _knownAcronyms = {
    // Law Enforcement / Military / Intelligence
    'FBI', 'CIA', 'NSA', 'DHS', 'DOJ', 'ATF', 'DEA', 'TSA', 'SWAT',
    'LAPD', 'NYPD', 'CPD', 'SFPD', 'CID', 'CSI', 'NCIS', 'MI6', 'MI5',
    'KGB', 'INTERPOL', 'BOLO', 'APB', 'MIA', 'KIA', 'POW', 'AWOL', 'K9',
    'UAV', 'RPG', 'IED', 'EMP',

    // Indonesian Security & Government Agencies
    'POLRI', 'TNI', 'KPK', 'BNN', 'BMKG', 'BPBD', 'BASARNAS', 'BIN',
    'POLDA', 'POLRES', 'POLSEK', 'TKP',

    // Medical & Emergency
    'EMS', 'EMT', 'CPR', 'ICU', 'UGD', 'IGD', 'EKG', 'ECG', 'MRI',
    'CT', 'IV', 'OD', 'DNA', 'RNA', 'RS',

    // Tech, Media & Corporate
    'NASA', 'CEO', 'CFO', 'CTO', 'COO', 'CMO', 'CIO', 'VIP', 'VVIP',
    'DJ', 'PC', 'AI', 'GPS', 'USB', 'PIN', 'ATM', 'SIM', 'BOM',
    'UFO', 'AC', 'CD', 'DVD', 'HD', 'FHD', '4K', 'TV', 'ID', 'OK',
    'HQ', 'WIB', 'WITA', 'WIT', 'SOS', 'RIP', 'ETA', 'ASAP', 'AKA',
    'FYI', 'DIY', 'POV', 'FAQ', 'HRD', 'PR',

    // International Organizations & Countries
    'UN', 'EU', 'US', 'UK', 'USA', 'AS', 'PBB', 'NATO', 'ASEAN', 'APEC',
    'FIFA', 'UEFA', 'NBA', 'UFC', 'WWE',
  };

  static const Set<String> _continuationWords = {
    // Demonstratives & Pronouns
    'itu', 'ini', 'tersebut', 'begini', 'begitu',
    'nya', 'ku', 'mu',

    // Conjunctions & Relative pronouns
    'yang', 'dan', 'atau', 'serta', 'tetapi', 'tapi', 'namun',
    'melainkan', 'padahal', 'sedangkan', 'karena', 'sebab',
    'sehingga', 'sampai', 'hingga', 'agar', 'supaya', 'untuk',
    'bagi', 'demi', 'jika', 'kalau', 'bila', 'apabila', 'walaupun',
    'meskipun', 'kendati', 'seperti', 'bagai', 'bagaikan', 'laksana',

    // Prepositions
    'di', 'ke', 'dari', 'pada', 'kepada', 'dalam', 'atas', 'oleh',
    'dengan', 'bersama', 'tentang', 'mengenai', 'tanpa', 'antara',

    // Auxiliaries / Modals / Aspects
    'adalah', 'ialah', 'merupakan', 'yaitu', 'yakni',
    'akan', 'sedang', 'telah', 'sudah', 'pernah', 'belum', 'tidak',
    'tak', 'bukan', 'bisa', 'dapat', 'boleh', 'harus', 'mesti', 'wajib',

    // Particles & Adverbs
    'pun', 'lah', 'kah', 'tah', 'juga', 'saja', 'hanya', 'lagi',
    'pula', 'sekali', 'sangat', 'amat', 'terlalu', 'paling',
    'sendiri', 'kembali', 'segera', 'langsung',
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
    'letnan', 'kopral', 'kolonel', 'perwira', 'opsir',
    'inspektur', 'komandan', 'paman', 'bibi', 'kakek', 'nenek', 'raja', 'ratu',
    'pangeran', 'putri', 'presiden', 'santo', 'santa',

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

    // 1. Naturalize stiff literal machine phrases into cinematic dialogue
    final naturalized = applyCinematicIndonesianNaturalizer(text);

    // 2. Format line by line: casing, abbreviations, sentence starts, acronyms
    final lines = naturalized.split('\n');
    final formattedLines = lines.map(_formatSingleLine).toList();
    return formattedLines.join('\n');
  }

  static String _formatSingleLine(String line) {
    if (line.trim().isEmpty) return line;

    // 1. Normalize spaced abbreviations before tokenizing: e.g. "l. a. p. d." -> "l.a.p.d."
    final preprocessedLine = _normalizeSpacedAbbreviations(line);

    // 2. Tokenize: dotted abbreviations, standard words, punctuation, whitespace
    final tokenRegex = RegExp(
      r'('
      r'[A-Za-z](?:\.[A-Za-z0-9])+\.?(?:-[A-Za-z0-9\u00C0-\u024F]+)?' // Dotted abbreviation (e.g. L.A.P.D., l.a.p.d, i.A, t.O.-ku)
      r'|[A-Za-z0-9\u00C0-\u024F]+(?:-[A-Za-z0-9\u00C0-\u024F]+)*'     // Standard word
      r'|[^\sA-Za-z0-9\u00C0-\u024F]+'                                 // Punctuation
      r'|\s+'                                                          // Whitespace
      r')',
    );
    final matches = tokenRegex.allMatches(preprocessedLine);

    final tokens = matches.map((m) => m.group(0)!).toList();
    final result = <String>[];

    bool isStartOfSentence = true;
    bool capitalizeNextWord = false;

    final dottedAbbrRegex = RegExp(
      r'^[A-Za-z](?:\.[A-Za-z0-9])+\.?(?:-[A-Za-z0-9\u00C0-\u024F]+)?$',
    );

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

      // Dotted abbreviations (e.g. L.A.P.D., l.A.P.D, i.A, t.O, t.O.-ku)
      if (dottedAbbrRegex.hasMatch(token)) {
        String formatted;
        if (token.contains('-')) {
          final dashIdx = token.indexOf('-');
          final abbrPart = token.substring(0, dashIdx).toUpperCase();
          final suffix = token.substring(dashIdx).toLowerCase();
          formatted = '$abbrPart$suffix';
        } else {
          formatted = token.toUpperCase();
        }
        result.add(formatted);

        // Determine whether the next word should start a new sentence.
        // In subtitles, abbreviations like L.A.P.D., I.A., T.O. often appear before
        // nouns or continuation words (e.g. "L.A.P.D. itu", "Divisi I.A. sedang", "T.O.-ku adalah").
        // A dot in an abbreviation only terminates the sentence if the next word was
        // originally capitalized and is not an Indonesian continuation word.
        bool nextIsNewSentence = false;
        if (token.endsWith('.')) {
          for (int j = i + 1; j < tokens.length; j++) {
            final nextToken = tokens[j];
            if (RegExp(r'^\s+$').hasMatch(nextToken)) continue;

            if (nextToken.contains('-') ||
                nextToken.contains('—') ||
                nextToken.contains('"') ||
                nextToken.contains('“')) {
              nextIsNewSentence = true;
              break;
            }

            final firstChar = nextToken.isNotEmpty ? nextToken[0] : '';
            final isOriginalCapital = firstChar == firstChar.toUpperCase() &&
                firstChar != firstChar.toLowerCase();
            final nextLower = nextToken.toLowerCase();

            if (isOriginalCapital && !_continuationWords.contains(nextLower)) {
              nextIsNewSentence = true;
            }
            break;
          }
        }

        isStartOfSentence = nextIsNewSentence;
        capitalizeNextWord = false;
        continue;
      }

      // Word token
      final lower = token.toLowerCase();
      final upper = token.toUpperCase();

      // 0. Hyphenated word with known acronym prefix (e.g. "LAPD-nya", "FBI-ku", "SWAT-nya")
      if (token.contains('-')) {
        final dashIdx = token.indexOf('-');
        final basePart = token.substring(0, dashIdx);
        final suffixPart = token.substring(dashIdx);
        final upperBase = basePart.toUpperCase();
        if (_knownAcronyms.contains(upperBase)) {
          result.add('$upperBase${suffixPart.toLowerCase()}');
          isStartOfSentence = false;
          capitalizeNextWord = false;
          continue;
        }
      }

      // 1. Acronyms (FBI, CIA, LAPD, NYPD, CPR, etc.)
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
              : fixAbbreviations(rawText);
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
