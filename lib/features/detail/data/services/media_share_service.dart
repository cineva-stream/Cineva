import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/localization/app_strings.dart';

/// Builds and shares rich GitHub Pages deep-link URLs for Movies and TV Series,
/// automatically attaching the movie/series poster image for apps like WhatsApp
/// and Telegram.
class MediaShareService {
  MediaShareService._();

  static const MethodChannel _shareChannel = MethodChannel(
    'com.cinevagroup.cinevastream/share',
  );

  static const String deepLinkBaseUrl =
      'https://cineva-stream.github.io';

  /// Constructs a rich deep-link URL with query parameters for the web fallback preview.
  static String buildShareUrl({
    required int tmdbId,
    required String mediaType,
    required String title,
    String? year,
    String? releaseYear,
    double? rating,
    String? posterPath,
    String? overview,
  }) {
    final cleanType = mediaType.toLowerCase() == 'tv' ? 'tv' : 'movie';
    final base = '$deepLinkBaseUrl/$cleanType/$tmdbId';

    final queryParams = <String, String>{};
    final cleanTitle = title.trim();
    if (cleanTitle.isNotEmpty) {
      queryParams['title'] = cleanTitle.length > 60
          ? cleanTitle.substring(0, 60)
          : cleanTitle;
    }
    final cleanYear = (year ?? releaseYear ?? '').trim();
    if (cleanYear.length >= 4) {
      queryParams['year'] = cleanYear.substring(0, 4);
    }
    if (rating != null && rating > 0) {
      queryParams['rating'] = rating.toStringAsFixed(1);
    }
    final cleanPoster = (posterPath ?? '').trim();
    if (cleanPoster.startsWith('/')) {
      queryParams['poster'] = cleanPoster;
    }
    var cleanOverview = (overview ?? '').trim();
    if (cleanOverview.isNotEmpty) {
      if (cleanOverview.length > 200) {
        cleanOverview = '${cleanOverview.substring(0, 197).trimRight()}...';
      }
      queryParams['overview'] = cleanOverview;
    }

    if (queryParams.isEmpty) return base;
    return Uri.parse(base).replace(queryParameters: queryParams).toString();
  }

  /// Downloads the movie/series poster image into the temporary directory so it
  /// can be shared as an image attachment alongside the deep-link caption on
  /// WhatsApp, Telegram, Instagram, etc.
  static Future<File?> _downloadPosterTempFile({
    required int tmdbId,
    required String mediaType,
    String? posterPath,
  }) async {
    final cleanPoster = (posterPath ?? '').trim();
    if (cleanPoster.isEmpty) return null;

    final imageUrl = cleanPoster.startsWith('http')
        ? cleanPoster
        : ApiConstants.imageUrl(cleanPoster, size: ApiConstants.posterLarge);

    try {
      final tempDir = await getTemporaryDirectory();
      final cleanType = mediaType.toLowerCase() == 'tv' ? 'tv' : 'movie';
      final file = File('${tempDir.path}/Cineva_${cleanType}_$tmdbId.jpg');

      // Reuse already downloaded poster if present and non-empty
      if (await file.exists() && await file.length() > 1024) {
        return file;
      }

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 8),
          responseType: ResponseType.bytes,
        ),
      );
      final response = await dio.get<List<int>>(imageUrl);
      final bytes = response.data;
      if (bytes != null && bytes.isNotEmpty) {
        await file.writeAsBytes(bytes, flush: true);
        return file;
      }
    } catch (e) {
      debugPrint('MediaShareService._downloadPosterTempFile note: $e');
    }
    return null;
  }

  /// Shares the media deep link together with the poster image using the native
  /// Android share sheet (and copies the caption + URL to clipboard).
  static Future<void> shareMedia(
    BuildContext context, {
    required AppStrings s,
    required int tmdbId,
    required String mediaType,
    required String title,
    String? year,
    String? releaseYear,
    double? rating,
    String? posterPath,
    String? overview,
  }) async {
    final url = buildShareUrl(
      tmdbId: tmdbId,
      mediaType: mediaType,
      title: title,
      year: year,
      releaseYear: releaseYear,
      rating: rating,
      posterPath: posterPath,
      overview: overview,
    );
    final shareText = s.detailShareMessage(title, url);

    await Clipboard.setData(ClipboardData(text: shareText));

    if (!kIsWeb && Platform.isAndroid) {
      try {
        final posterFile = await _downloadPosterTempFile(
          tmdbId: tmdbId,
          mediaType: mediaType,
          posterPath: posterPath,
        );
        if (posterFile != null && await posterFile.exists()) {
          await _shareChannel.invokeMethod('shareImageWithText', {
            'filePath': posterFile.path,
            'text': shareText,
            'title': title,
          });
          return;
        }

        await _shareChannel.invokeMethod('shareText', {
          'text': shareText,
          'title': title,
        });
        return;
      } catch (e) {
        debugPrint('MediaShareService Android native share error: $e');
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.detailShareCopied),
          backgroundColor: AppColors.surfaceVariant,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
