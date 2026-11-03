import '../services/subtitle_service.dart';

enum VideoProviderType { directVixSrc, scraperApi }

class RegularVideoLinks {
  String? url;
  String? quality;
  String? server;
  bool? isM3U8;
  bool? isDash;
  Map<String, String>? headers;
  String? sizeToken;

  RegularVideoLinks({
    this.url,
    this.quality = 'Auto',
    this.server,
    this.isM3U8,
    this.isDash,
    this.headers,
    this.sizeToken,
  });

  factory RegularVideoLinks.fromJson(Map<String, dynamic> json) {
    Map<String, String>? parsedHeaders;
    final rawHeaders = json['headers'];
    if (rawHeaders is Map) {
      parsedHeaders = {
        for (final entry in rawHeaders.entries)
          if (entry.value is String)
            entry.key.toString(): entry.value as String,
      };
    }

    return RegularVideoLinks(
      url: json['url']?.toString(),
      quality: json['quality']?.toString() ?? 'Auto',
      server: json['server']?.toString(),
      isM3U8:
          json['isM3U8'] == true ||
          (json['url']?.toString().contains('.m3u8') ?? false),
      isDash: json['isDASH'] == true,
      headers: parsedHeaders,
      sizeToken: json['sizeToken']?.toString(),
    );
  }
}

class RegularSubtitleLinks {
  String? url;
  String? language;
  Map<String, String>? headers;

  RegularSubtitleLinks({this.url, this.language, this.headers});

  factory RegularSubtitleLinks.fromJson(Map<String, dynamic> json) {
    Map<String, String>? parsedHeaders;
    final rawHeaders = json['headers'];
    if (rawHeaders is Map) {
      parsedHeaders = {
        for (final entry in rawHeaders.entries)
          if (entry.value is String)
            entry.key.toString(): entry.value as String,
      };
    }

    return RegularSubtitleLinks(
      url: json['url']?.toString() ?? json['file']?.toString(),
      language:
          json['lang']?.toString() ?? json['label']?.toString() ?? 'Unknown',
      headers: parsedHeaders,
    );
  }

  /// Converts this provider subtitle into Cineva's native SubtitleInfo model.
  SubtitleInfo toSubtitleInfo() {
    final rawLang = (language ?? 'en').toLowerCase().trim();
    String normLang = rawLang;
    if (normLang == 'eng' || normLang == 'en' || normLang.startsWith('en-')) {
      normLang = 'en';
    } else if (normLang == 'ind' ||
        normLang == 'id' ||
        normLang == 'in' ||
        normLang.contains('indonesia')) {
      normLang = 'id';
    } else if (normLang == 'ita' || normLang == 'it') {
      normLang = 'it';
    } else if (normLang == 'spa' || normLang == 'es') {
      normLang = 'es';
    } else if (normLang == 'fra' || normLang == 'fre' || normLang == 'fr') {
      normLang = 'fr';
    } else if (normLang == 'deu' || normLang == 'ger' || normLang == 'de') {
      normLang = 'de';
    } else if (normLang.length > 2) {
      normLang = normLang.substring(0, 2);
    }

    final targetUrl = url ?? '';
    final label = language ?? 'Subtitle';

    return SubtitleInfo(
      id: targetUrl,
      language: normLang,
      languageName: '$label (Stream)',
      fileName: label,
      downloadCount: 9999,
      downloadUrl: targetUrl,
    );
  }
}

class ProviderLoadResult {
  final List<RegularVideoLinks>? videoLinks;
  final List<RegularSubtitleLinks>? subtitleLinks;
  final bool success;
  final String? errorMessage;
  final String? providerName;

  const ProviderLoadResult({
    this.videoLinks,
    this.subtitleLinks,
    this.success = false,
    this.errorMessage,
    this.providerName,
  });

  bool get hasPlayableStreams =>
      success && videoLinks != null && videoLinks!.isNotEmpty;
}

class VideoProvider {
  final String fullName;
  final String codeName;
  final String? alias;
  final String? content;
  final VideoProviderType type;
  final String? apiId;

  const VideoProvider({
    required this.fullName,
    required this.codeName,
    this.alias,
    this.content,
    this.type = VideoProviderType.directVixSrc,
    this.apiId,
  });

  String get displayName {
    final value = alias?.trim();
    return value == null || value.isEmpty ? fullName : value;
  }

  String get contentDescription {
    final value = content?.trim();
    if (value != null && value.isNotEmpty) return value;
    return type == VideoProviderType.directVixSrc
        ? 'Direct HLS Native'
        : 'High-Speed Stream';
  }

  static const directVixSrc = VideoProvider(
    fullName: 'VixSrc Direct',
    alias: 'VixSrc (FHD)',
    codeName: 'cineva_direct',
    content: 'Full HD 1080p • Direct HLS',
    type: VideoProviderType.directVixSrc,
    apiId: 'vixsrc',
  );

  factory VideoProvider.scraper({
    required String id,
    required String name,
    String? alias,
    String? content,
  }) {
    return VideoProvider(
      fullName: name,
      alias: alias,
      content: content,
      codeName: 'scraper:$id',
      type: VideoProviderType.scraperApi,
      apiId: id,
    );
  }
}
