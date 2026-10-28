import 'package:flutter/material.dart';

/// Supported streaming platforms with their corresponding TMDB watch provider IDs
/// and brand styling.
class StreamingPlatform {
  final String id;
  final String name;
  final int providerId;
  final Color brandColor;
  final String tagline;
  final IconData icon;

  const StreamingPlatform({
    required this.id,
    required this.name,
    required this.providerId,
    required this.brandColor,
    required this.tagline,
    required this.icon,
  });

  static const List<StreamingPlatform> supportedPlatforms = [
    StreamingPlatform(
      id: 'netflix',
      name: 'Netflix',
      providerId: 8,
      brandColor: Color(0xFFE50914),
      tagline: 'Netflix Originals & Populer',
      icon: Icons.movie_filter_rounded,
    ),
    StreamingPlatform(
      id: 'prime',
      name: 'Prime Video',
      providerId: 9,
      brandColor: Color(0xFF00A8E1),
      tagline: 'Amazon Originals & Blockbusters',
      icon: Icons.video_library_rounded,
    ),
    StreamingPlatform(
      id: 'disney',
      name: 'Disney+',
      providerId: 337,
      brandColor: Color(0xFF113CCF),
      tagline: 'Disney, Marvel, Pixar & Star Wars',
      icon: Icons.auto_awesome_rounded,
    ),
    StreamingPlatform(
      id: 'apple',
      name: 'Apple TV+',
      providerId: 350,
      brandColor: Color(0xFF9E9E9E),
      tagline: 'Apple Original Series & Film',
      icon: Icons.apple_rounded,
    ),
    StreamingPlatform(
      id: 'max',
      name: 'Max (HBO)',
      providerId: 384,
      brandColor: Color(0xFF002BE7),
      tagline: 'HBO Originals & Warner Bros',
      icon: Icons.theater_comedy_rounded,
    ),
    StreamingPlatform(
      id: 'hulu',
      name: 'Hulu',
      providerId: 15,
      brandColor: Color(0xFF1CE783),
      tagline: 'Exclusive TV Shows & Movies',
      icon: Icons.slideshow_rounded,
    ),
    StreamingPlatform(
      id: 'paramount',
      name: 'Paramount+',
      providerId: 531,
      brandColor: Color(0xFF0064FF),
      tagline: 'Paramount Pictures & CBS',
      icon: Icons.star_border_purple500_rounded,
    ),
    StreamingPlatform(
      id: 'peacock',
      name: 'Peacock',
      providerId: 387,
      brandColor: Color(0xFFF9C000),
      tagline: 'NBCUniversal & Live Sports',
      icon: Icons.live_tv_rounded,
    ),
  ];

  static StreamingPlatform fromId(String id) {
    return supportedPlatforms.firstWhere(
      (p) => p.id.toLowerCase() == id.toLowerCase(),
      orElse: () => supportedPlatforms.first,
    );
  }
}
