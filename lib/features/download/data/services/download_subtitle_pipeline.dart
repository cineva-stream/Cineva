import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../../../player/data/models/subtitle_cue.dart';
import '../../../player/data/services/subtitle_service.dart';
import '../../../player/data/services/subtitle_translator_service.dart';
import '../../../player/data/services/vixsrc_stream_service.dart';

class SubtitlePipelineResult {
  final String? subtitlePath;
  final String status; // 'ready', 'translated', 'none', 'failed'
  final String? note;

  const SubtitlePipelineResult({
    this.subtitlePath,
    required this.status,
    this.note,
  });
}

/// Pipeline that downloads requested subtitles, and if Indonesian is not found,
/// falls back to English (OpenSubtitles or Stream VTT), caches it, and translates it for free to Indonesian.
class DownloadSubtitlePipeline {
  final SubtitleService _subtitleService;
  final SubtitleTranslatorService _translatorService;

  DownloadSubtitlePipeline({
    SubtitleService? subtitleService,
    SubtitleTranslatorService? translatorService,
  })  : _subtitleService = subtitleService ?? SubtitleService(),
        _translatorService = translatorService ?? SubtitleTranslatorService();

  /// Converts a list of SubtitleCues back to standard SRT format.
  static String cuesToSrt(List<SubtitleCue> cues) {
    final sb = StringBuffer();
    for (int i = 0; i < cues.length; i++) {
      final cue = cues[i];
      sb.writeln('${i + 1}');
      sb.writeln('${_formatDuration(cue.start)} --> ${_formatDuration(cue.end)}');
      sb.writeln(cue.text);
      sb.writeln();
    }
    return sb.toString();
  }

  static String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    final millis = (d.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '$hours:$minutes:$seconds,$millis';
  }

  /// Finds stream subtitle URI from master playlist if available.
  Future<String?> _findStreamSubtitleUri(String masterPlaylistUrl, String langCode) async {
    if (masterPlaylistUrl.isEmpty) return null;
    try {
      final client = HttpClient();
      final req = await client.getUrl(Uri.parse(masterPlaylistUrl));
      req.headers.set('accept', '*/*');
      final res = await req.close();
      final content = await res.transform(utf8.decoder).join();
      client.close();

      for (final line in content.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.startsWith('#EXT-X-MEDIA:TYPE=SUBTITLES')) {
          final uriMatch = RegExp(r'URI="([^"]+)"').firstMatch(trimmed);
          final langMatch = RegExp(r'LANGUAGE="([^"]+)"').firstMatch(trimmed);
          final nameMatch = RegExp(r'NAME="([^"]+)"').firstMatch(trimmed);

          final subLang = (langMatch?.group(1) ?? nameMatch?.group(1) ?? '').toLowerCase();
          bool matches = false;
          if (langCode == 'id') {
            matches = subLang.contains('id') || subLang.contains('ind');
          } else if (langCode == 'en') {
            matches = subLang.contains('en') || subLang.contains('eng');
          }

          if (matches && uriMatch != null) {
            final raw = uriMatch.group(1)!;
            return raw.startsWith('http')
                ? raw
                : Uri.parse(masterPlaylistUrl).resolve(raw).toString();
          }
        }
      }
    } catch (e) {
      debugPrint('[DownloadSubtitlePipeline] Stream subtitle inspection note: $e');
    }
    return null;
  }

  /// Downloads or translates subtitle, saving directly to [targetFilePath].
  Future<SubtitlePipelineResult> processSubtitle({
    required String targetFilePath,
    required String title,
    String? imdbId,
    int? tmdbId,
    int? season,
    int? episode,
    String preferredLang = 'id',
    SubtitleInfo? selectedSubtitle,
    bool autoTranslate = true,
    String targetTranslateLang = 'id',
    String masterPlaylistUrl = '',
    void Function(double progress, String status)? onProgress,
  }) async {
    if (preferredLang == 'none' && selectedSubtitle == null) {
      return const SubtitlePipelineResult(status: 'none');
    }

    try {
      // 0. If user explicitly picked a subtitle track from the bottom sheet:
      if (selectedSubtitle != null) {
        onProgress?.call(0.2, 'Mengunduh subtitle ${selectedSubtitle.languageName}...');
        final downloadUrl = (selectedSubtitle.downloadUrl != null &&
                selectedSubtitle.downloadUrl!.isNotEmpty)
            ? selectedSubtitle.downloadUrl
            : await _subtitleService.getDownloadUrl(selectedSubtitle.id);

        if (downloadUrl != null && downloadUrl.isNotEmpty) {
          final content = await _subtitleService.downloadSubtitleContent(downloadUrl);
          if (content != null && content.isNotEmpty) {
            final cues = SubtitleCue.parseSrt(content);
            if (cues.isNotEmpty) {
              final srcLang = selectedSubtitle.language.toLowerCase().trim();
              final dstLang = targetTranslateLang.toLowerCase().trim();
              final needsTranslation =
                  autoTranslate && dstLang.isNotEmpty && dstLang != 'off' && srcLang != dstLang;

              List<SubtitleCue> finalCues;
              String resultStatus = 'ready';
              String resultNote = 'Subtitle (${selectedSubtitle.languageName})';

              if (needsTranslation) {
                onProgress?.call(
                  0.5,
                  'Menerjemahkan subtitle ke ${dstLang.toUpperCase()}...',
                );
                final cacheKey =
                    'sub_${tmdbId ?? 0}_${season ?? 0}_${episode ?? 0}_${selectedSubtitle.id.hashCode}_$dstLang';
                finalCues = await _translatorService.translateCues(
                  cues: cues,
                  cacheKey: cacheKey,
                  targetLang: dstLang,
                  onProgress: (p) {
                    onProgress?.call(
                      0.5 + (p * 0.45),
                      'Menerjemahkan (${(p * 100).toInt()}%)...',
                    );
                  },
                );
                resultStatus = 'translated';
                resultNote = 'Diterjemahkan ke ${dstLang.toUpperCase()}';
              } else {
                finalCues = cues.map((c) {
                  return SubtitleCue(
                    start: c.start,
                    end: c.end,
                    text: srcLang == 'id'
                        ? SubtitleTranslatorService.balanceSubtitleLines(
                            SubtitleTranslatorService.smartFormatIndonesianSubtitle(
                              SubtitleTranslatorService.refineIndonesianPronouns(c.text),
                            ),
                          )
                        : SubtitleTranslatorService.balanceSubtitleLines(
                            SubtitleTranslatorService.fixAbbreviations(c.text),
                          ),
                  );
                }).toList();
              }

              final file = File(targetFilePath);
              await file.parent.create(recursive: true);
              await file.writeAsString(cuesToSrt(finalCues));
              onProgress?.call(1.0, 'Subtitle siap');
              return SubtitlePipelineResult(
                subtitlePath: targetFilePath,
                status: resultStatus,
                note: resultNote,
              );
            }
          }
        }
      }

      onProgress?.call(0.1, 'Mencari subtitle $preferredLang...');

      // 1. Try to search subtitle in preferred language via OpenSubtitles
      List<SubtitleInfo> subs = [];
      if (imdbId != null && imdbId.isNotEmpty) {
        subs = await _subtitleService.searchByImdbId(
          imdbId,
          language: preferredLang,
          seasonNumber: season,
          episodeNumber: episode,
        );
      }

      if (subs.isEmpty) {
        subs = await _subtitleService.searchByQuery(
          title,
          language: preferredLang,
          seasonNumber: season,
          episodeNumber: episode,
        );
      }

      // If preferred subtitle found directly from OpenSubtitles:
      if (subs.isNotEmpty) {
        onProgress?.call(0.5, 'Mengunduh subtitle $preferredLang...');
        final downloadUrl = await _subtitleService.getDownloadUrl(subs.first.id);
        if (downloadUrl != null) {
          final content = await _subtitleService.downloadSubtitleContent(downloadUrl);
          if (content != null && content.isNotEmpty) {
            final cues = SubtitleCue.parseSrt(content);
            final refinedCues = cues.map((c) {
              return SubtitleCue(
                start: c.start,
                end: c.end,
                text: SubtitleTranslatorService.balanceSubtitleLines(
                  SubtitleTranslatorService.smartFormatIndonesianSubtitle(
                    SubtitleTranslatorService.refineIndonesianPronouns(c.text),
                  ),
                ),
              );
            }).toList();

            final file = File(targetFilePath);
            await file.parent.create(recursive: true);
            await file.writeAsString(cuesToSrt(refinedCues));
            onProgress?.call(1.0, 'Subtitle $preferredLang siap');
            return SubtitlePipelineResult(
              subtitlePath: targetFilePath,
              status: 'ready',
              note: 'Subtitle asli (${subs.first.languageName})',
            );
          }
        }
      }

      // If preferred is Indonesian and not found in OpenSubtitles, check embedded stream subtitles
      if (preferredLang == 'id') {
        final streamIdSubUri = await _findStreamSubtitleUri(masterPlaylistUrl, 'id');
        if (streamIdSubUri != null) {
          final streamContent = await VixSrcStreamService.downloadSubtitleContent(streamIdSubUri);
          if (streamContent != null && streamContent.isNotEmpty) {
            final cues = SubtitleCue.parseSrt(streamContent);
            if (cues.isNotEmpty) {
              final refinedCues = cues.map((c) {
                return SubtitleCue(
                  start: c.start,
                  end: c.end,
                  text: SubtitleTranslatorService.balanceSubtitleLines(
                    SubtitleTranslatorService.smartFormatIndonesianSubtitle(
                      SubtitleTranslatorService.refineIndonesianPronouns(c.text),
                    ),
                  ),
                );
              }).toList();

              final file = File(targetFilePath);
              await file.parent.create(recursive: true);
              await file.writeAsString(cuesToSrt(refinedCues));
              onProgress?.call(1.0, 'Subtitle Indonesia siap');
              return SubtitlePipelineResult(
                subtitlePath: targetFilePath,
                status: 'ready',
                note: 'Subtitle asli Indonesia (Stream)',
              );
            }
          }
        }

        // Fallback: If autoTranslate is enabled, fetch English subtitle and translate to targetTranslateLang
        if (autoTranslate) {
          onProgress?.call(0.3, 'Subtitle Indonesia tidak ditemukan. Mengunduh subtitle English...');
          String? enContent;

          // Try OpenSubtitles English first
          List<SubtitleInfo> enSubs = [];
          if (imdbId != null && imdbId.isNotEmpty) {
            enSubs = await _subtitleService.searchByImdbId(
              imdbId,
              language: 'en',
              seasonNumber: season,
              episodeNumber: episode,
            );
          }
          if (enSubs.isEmpty) {
            enSubs = await _subtitleService.searchByQuery(
              title,
              language: 'en',
              seasonNumber: season,
              episodeNumber: episode,
            );
          }

          if (enSubs.isNotEmpty) {
            final downloadUrl = await _subtitleService.getDownloadUrl(enSubs.first.id);
            if (downloadUrl != null) {
              enContent = await _subtitleService.downloadSubtitleContent(downloadUrl);
            }
          }

          // If OpenSubtitles English failed, try embedded stream English subtitle
          if (enContent == null || enContent.isEmpty) {
            final streamEnUri = await _findStreamSubtitleUri(masterPlaylistUrl, 'en');
            if (streamEnUri != null) {
              enContent = await VixSrcStreamService.downloadSubtitleContent(streamEnUri);
            }
          }

          // Translate English content to targetTranslateLang
          if (enContent != null && enContent.isNotEmpty) {
            final dstLang = targetTranslateLang.isNotEmpty ? targetTranslateLang : 'id';
            onProgress?.call(0.5, 'Menerjemahkan subtitle ke ${dstLang.toUpperCase()}...');
            final cues = SubtitleCue.parseSrt(enContent);
            final cacheKey = 'sub_${tmdbId ?? 0}_${season ?? 0}_${episode ?? 0}_$dstLang';

            final translatedCues = await _translatorService.translateCues(
              cues: cues,
              cacheKey: cacheKey,
              targetLang: dstLang,
              onProgress: (p) {
                onProgress?.call(0.5 + (p * 0.45), 'Menerjemahkan (${(p * 100).toInt()}%)...');
              },
            );

            final file = File(targetFilePath);
            await file.parent.create(recursive: true);
            await file.writeAsString(cuesToSrt(translatedCues));
            onProgress?.call(1.0, 'Subtitle terjemahan siap');
            return SubtitlePipelineResult(
              subtitlePath: targetFilePath,
              status: 'translated',
              note: 'Diterjemahkan otomatis ke ${dstLang.toUpperCase()}',
            );
          }
        }
      } else if (preferredLang == 'en') {
        // Fallback for English: Stream subtitle
        final streamEnUri = await _findStreamSubtitleUri(masterPlaylistUrl, 'en');
        if (streamEnUri != null) {
          final streamContent = await VixSrcStreamService.downloadSubtitleContent(streamEnUri);
          if (streamContent != null && streamContent.isNotEmpty) {
            final cues = SubtitleCue.parseSrt(streamContent);
            if (cues.isNotEmpty) {
              final file = File(targetFilePath);
              await file.parent.create(recursive: true);
              await file.writeAsString(cuesToSrt(cues));
              onProgress?.call(1.0, 'Subtitle English siap');
              return SubtitlePipelineResult(
                subtitlePath: targetFilePath,
                status: 'ready',
                note: 'Subtitle asli English (Stream)',
              );
            }
          }
        }
      }

      return const SubtitlePipelineResult(
        status: 'failed',
        note: 'Subtitle tidak tersedia',
      );
    } catch (e) {
      debugPrint('[DownloadSubtitlePipeline] Error: $e');
      return SubtitlePipelineResult(
        status: 'failed',
        note: e.toString(),
      );
    }
  }
}
