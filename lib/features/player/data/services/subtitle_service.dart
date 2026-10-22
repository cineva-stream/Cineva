import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'vixsrc_stream_service.dart';

/// Represents a subtitle file available for download.
class SubtitleInfo {
  final String id;
  final String language;
  final String languageName;
  final String fileName;
  final int downloadCount;
  final String? downloadUrl;
  final double? rating;
  final bool isHearingImpaired;

  SubtitleInfo({
    required this.id,
    required this.language,
    required this.languageName,
    required this.fileName,
    required this.downloadCount,
    this.downloadUrl,
    this.rating,
    this.isHearingImpaired = false,
  });

  factory SubtitleInfo.fromOpenSubtitlesJson(Map<String, dynamic> json) {
    final attributes = json['attributes'] as Map<String, dynamic>? ?? {};
    final files = attributes['files'] as List<dynamic>? ?? [];
    final firstFile = files.isNotEmpty ? files.first as Map<String, dynamic> : <String, dynamic>{};

    return SubtitleInfo(
      id: firstFile['file_id']?.toString() ?? json['id']?.toString() ?? '',
      language: attributes['language'] as String? ?? '',
      languageName: _languageCodeToName(attributes['language'] as String? ?? ''),
      fileName: attributes['release'] as String? ?? firstFile['file_name'] as String? ?? '',
      downloadCount: attributes['download_count'] as int? ?? 0,
      rating: (attributes['ratings'] as num?)?.toDouble(),
      isHearingImpaired: attributes['hearing_impaired'] as bool? ?? false,
    );
  }

  static String _languageCodeToName(String code) {
    const languages = {
      'en': 'English',
      'id': 'Indonesia',
      'ms': 'Malay',
      'es': 'Spanish',
      'fr': 'French',
      'de': 'German',
      'it': 'Italian',
      'pt-br': 'Portuguese (BR)',
      'pt-pt': 'Portuguese',
      'zh-cn': 'Chinese (Simplified)',
      'zh-tw': 'Chinese (Traditional)',
      'ja': 'Japanese',
      'ko': 'Korean',
      'ar': 'Arabic',
      'hi': 'Hindi',
      'th': 'Thai',
      'vi': 'Vietnamese',
      'tr': 'Turkish',
      'nl': 'Dutch',
      'pl': 'Polish',
      'sv': 'Swedish',
      'ru': 'Russian',
    };
    return languages[code] ?? code.toUpperCase();
  }
}

/// Service for searching and downloading subtitles from OpenSubtitles API.
class SubtitleService {
  late final Dio _dio;

  SubtitleService() {
    final apiKey = dotenv.env['OPENSUBTITLES_API_KEY'] ?? '';
    _dio = Dio(BaseOptions(
      baseUrl: 'https://api.opensubtitles.com/api/v1',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Api-Key': apiKey,
        'Content-Type': 'application/json',
        'User-Agent': 'Cineva v1.0.1',
      },
    ));
  }

  /// Search subtitles by IMDb ID, with optional language, season, and episode filters.
  Future<List<SubtitleInfo>> searchByImdbId(
    String imdbId, {
    String? language,
    int? seasonNumber,
    int? episodeNumber,
    int page = 1,
  }) async {
    try {
      // Remove 'tt' prefix if present, API expects just the number
      final cleanId = imdbId.startsWith('tt') ? imdbId : 'tt$imdbId';

      final queryParams = <String, dynamic>{
        'imdb_id': cleanId,
        'page': page,
        'order_by': 'download_count',
        'order_direction': 'desc',
      };

      if (language != null && language.isNotEmpty) {
        queryParams['languages'] = language;
      }
      if (seasonNumber != null) {
        queryParams['season_number'] = seasonNumber;
      }
      if (episodeNumber != null) {
        queryParams['episode_number'] = episodeNumber;
      }

      final response = await _dio.get('/subtitles', queryParameters: queryParams);

      final data = response.data;
      if (data == null) return [];

      final results = data['data'] as List<dynamic>? ?? [];

      return results
          .map((item) => SubtitleInfo.fromOpenSubtitlesJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Search subtitles by text query (movie/show title).
  Future<List<SubtitleInfo>> searchByQuery(
    String query, {
    String? language,
    int? seasonNumber,
    int? episodeNumber,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'query': query,
        'order_by': 'download_count',
        'order_direction': 'desc',
      };

      if (language != null) queryParams['languages'] = language;
      if (seasonNumber != null) queryParams['season_number'] = seasonNumber;
      if (episodeNumber != null) queryParams['episode_number'] = episodeNumber;

      final response = await _dio.get('/subtitles', queryParameters: queryParams);
      final data = response.data;
      if (data == null) return [];

      final results = data['data'] as List<dynamic>? ?? [];
      return results
          .map((item) => SubtitleInfo.fromOpenSubtitlesJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Download a subtitle file and return the download URL.
  Future<String?> getDownloadUrl(String fileId) async {
    try {
      if (fileId.startsWith('http')) return fileId;
      final response = await _dio.post(
        '/download',
        data: {
          'file_id': int.tryParse(fileId) ?? fileId,
        },
      );

      final data = response.data;
      return data?['link'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Download raw subtitle text content from a download URL.
  Future<String?> downloadSubtitleContent(String downloadUrl) async {
    try {
      if (downloadUrl.contains('vixsrc.to') ||
          downloadUrl.contains('amberrocket') ||
          downloadUrl.contains('.vtt') ||
          downloadUrl.contains('type=subtitle')) {
        final content = await VixSrcStreamService.downloadSubtitleContent(downloadUrl);
        if (content != null && content.isNotEmpty) return content;
      }

      final client = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      final response = await client.get<String>(
        downloadUrl,
        options: Options(responseType: ResponseType.plain),
      );
      client.close();
      return response.data;
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _dio.close();
  }
}
