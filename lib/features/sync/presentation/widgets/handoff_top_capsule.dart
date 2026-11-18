import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/localization/app_language_provider.dart';
import '../../data/services/device_handoff_service.dart';
import '../../domain/models/device_playback_session.dart';

/// Modern floating glass capsule card shown at the top of the Home Screen
/// when an active playback session is detected from another device (Seamless Hand-Off).
class HandOffTopCapsule extends ConsumerWidget {
  const HandOffTopCapsule({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(deviceHandoffProvider);
    if (session == null || !session.isValidForHandOff) {
      return const SizedBox.shrink();
    }

    final s = ref.watch(appStringsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF141419).withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.45),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  blurRadius: 18,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // 1. Poster thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 36,
                    height: 52,
                    child: (session.posterPath != null &&
                            session.posterPath!.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl:
                                '${ApiConstants.tmdbImageBaseUrl}${session.posterPath}',
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => _buildPosterPlaceholder(
                                session.formFactor),
                          )
                        : _buildPosterPlaceholder(session.formFactor),
                  ),
                ),
                const SizedBox(width: 12),

                // 2. Titles & Device info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getDeviceIcon(session.formFactor),
                            size: 13,
                            color: const Color(0xFFFFD54F),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              s.handoffFromDevice(session.deviceName),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFFFD54F),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      RichText(
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            height: 1.25,
                          ),
                          children: [
                            TextSpan(
                              text: s.isIndonesian
                                  ? 'Lanjutkan menonton '
                                  : 'Continue watching ',
                            ),
                            TextSpan(
                              text: session.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (session.episode != null)
                              TextSpan(
                                text: ' (S${session.season ?? 1} E${session.episode})',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            TextSpan(
                              text: s.isIndonesian
                                  ? ' di menit '
                                  : ' at ',
                            ),
                            TextSpan(
                              text: session.formattedPosition,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64B5F6),
                              ),
                            ),
                            const TextSpan(text: '?'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // 3. Action Buttons: [Lanjutkan] & [Tutup (X)]
                ElevatedButton.icon(
                  onPressed: () => _resumePlayback(context, ref, session),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    shadowColor: AppColors.primary.withValues(alpha: 0.5),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: Text(
                    s.handoffContinueBtn,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                IconButton(
                  onPressed: () {
                    ref
                        .read(deviceHandoffProvider.notifier)
                        .dismissCurrentHandOff();
                  },
                  tooltip: s.handoffDismiss,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _resumePlayback(
      BuildContext context, WidgetRef ref, DevicePlaybackSession session) {
    ref.read(deviceHandoffProvider.notifier).dismissCurrentHandOff();

    context.push(
      '/player',
      extra: {
        'title': session.title,
        'tmdbId': session.tmdbId,
        'imdbId': session.imdbId,
        'mediaType': session.mediaType,
        'season': session.season,
        'episode': session.episode,
        'episodeTitle': session.episodeTitle,
        'posterPath': session.posterPath,
        'backdropPath': session.backdropPath,
        'initialPositionMs': session.positionSeconds * 1000,
      },
    );
  }

  Widget _buildPosterPlaceholder(String formFactor) {
    return Container(
      color: AppColors.surfaceVariant,
      child: Center(
        child: Icon(
          _getDeviceIcon(formFactor),
          size: 20,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  IconData _getDeviceIcon(String formFactor) {
    switch (formFactor.toLowerCase()) {
      case 'tv':
        return Icons.tv_rounded;
      case 'desktop':
        return Icons.laptop_rounded;
      case 'tablet':
        return Icons.tablet_rounded;
      case 'mobile':
      default:
        return Icons.phone_android_rounded;
    }
  }
}

