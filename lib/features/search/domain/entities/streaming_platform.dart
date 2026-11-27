import 'package:flutter/material.dart';

import '../../../../core/localization/app_language.dart';

/// Supported streaming platforms with their corresponding TMDB watch provider IDs,
/// broadcast network IDs, production studio IDs, and trilingual brand styling.
class StreamingPlatform {
  final String id;
  final String name;
  final int providerId;
  final String? customProviderIds;
  final String watchRegion;
  final List<String> extraWatchRegions;
  final String? primaryNetworkIds;
  final String? secondaryNetworkIds;
  final String? companyIds;
  final Color brandColor;
  final String tagline;
  final String taglineEn;
  final String taglineHi;
  final IconData icon;
  final String logoAsset;

  const StreamingPlatform({
    required this.id,
    required this.name,
    required this.providerId,
    this.customProviderIds,
    this.watchRegion = 'US',
    this.extraWatchRegions = const [],
    this.primaryNetworkIds,
    this.secondaryNetworkIds,
    this.companyIds,
    required this.brandColor,
    required this.tagline,
    required this.taglineEn,
    required this.taglineHi,
    required this.icon,
    required this.logoAsset,
  });

  /// String query passed to TMDB's `with_watch_providers` (supports pipe '|' for OR conditions).
  String get watchProviderQuery => customProviderIds ?? providerId.toString();

  /// Returns the platform's tagline localized in Indonesian (`id`), English (`en`), or Hindi (`hi`).
  String localizedTagline(AppLanguage language) {
    switch (language) {
      case AppLanguage.id:
        return tagline;
      case AppLanguage.en:
        return taglineEn;
      case AppLanguage.hi:
        return taglineHi;
    }
  }

  static const List<StreamingPlatform> supportedPlatforms = [
    StreamingPlatform(
      id: 'netflix',
      name: 'Netflix',
      providerId: 8,
      customProviderIds: '8',
      brandColor: Color(0xFFE50914),
      tagline: 'Netflix Originals & Populer',
      taglineEn: 'Netflix Originals & Popular Hits',
      taglineHi: 'नेटफ्लिक्स ओरिजिनल्स और लोकप्रिय शो',
      icon: Icons.movie_filter_rounded,
      logoAsset: 'assets/images/platforms/netflix.png',
    ),
    StreamingPlatform(
      id: 'prime',
      name: 'Prime Video',
      providerId: 9,
      customProviderIds: '9|119',
      brandColor: Color(0xFF00A8E1),
      tagline: 'Amazon Originals & Blockbusters',
      taglineEn: 'Amazon Originals & Blockbusters',
      taglineHi: 'अमेज़न ओरिजिनल्स और ब्लॉकबस्टर फ़िल्में',
      icon: Icons.video_library_rounded,
      logoAsset: 'assets/images/platforms/amazon_prime.png',
    ),
    StreamingPlatform(
      id: 'disney',
      name: 'Disney+',
      providerId: 337,
      customProviderIds: '337|122',
      brandColor: Color(0xFF113CCF),
      tagline: 'Disney, Marvel, Pixar & Star Wars',
      taglineEn: 'Disney, Marvel, Pixar & Star Wars',
      taglineHi: 'डिज़्नी, मार्वल, पिक्सार और स्टार वॉर्स',
      icon: Icons.auto_awesome_rounded,
      logoAsset: 'assets/images/platforms/disney_plus.png',
    ),
    StreamingPlatform(
      id: 'apple',
      name: 'Apple TV+',
      providerId: 350,
      customProviderIds: '350',
      brandColor: Color(0xFF9E9E9E),
      tagline: 'Apple Original Series & Film',
      taglineEn: 'Apple Original Series & Films',
      taglineHi: 'एप्पल ओरिजिनल सीरीज़ और फ़िल्में',
      icon: Icons.apple_rounded,
      logoAsset: 'assets/images/platforms/apple_tv.png',
    ),
    StreamingPlatform(
      id: 'max',
      name: 'Max',
      providerId: 1899,
      customProviderIds: '1899|1825|384',
      brandColor: Color(0xFF002BE7),
      tagline: 'HBO Originals & Warner Bros',
      taglineEn: 'HBO Originals & Warner Bros',
      taglineHi: 'एचबीओ ओरिजिनल्स और वार्नर ब्रदर्स',
      icon: Icons.theater_comedy_rounded,
      logoAsset: 'assets/images/platforms/hbo_max.png',
    ),
    StreamingPlatform(
      id: 'hulu',
      name: 'Hulu',
      providerId: 15,
      customProviderIds: '15',
      brandColor: Color(0xFF1CE783),
      tagline: 'Serial TV Eksklusif & Film Populer',
      taglineEn: 'Exclusive TV Shows & Hit Movies',
      taglineHi: 'एक्सक्लूसिव टीवी शो और हिट फ़िल्में',
      icon: Icons.slideshow_rounded,
      logoAsset: 'assets/images/platforms/hulu.png',
    ),
    StreamingPlatform(
      id: 'paramount',
      name: 'Paramount+',
      providerId: 531,
      customProviderIds: '582|2303|531',
      brandColor: Color(0xFF0064FF),
      tagline: 'Paramount Pictures & Serial CBS',
      taglineEn: 'Paramount Pictures & CBS Originals',
      taglineHi: 'पैरामाउंट पिक्चर्स और सीबीएस शो',
      icon: Icons.star_border_purple500_rounded,
      logoAsset: 'assets/images/platforms/paramount.png',
    ),
    StreamingPlatform(
      id: 'peacock',
      name: 'Peacock',
      providerId: 387,
      customProviderIds: '386|387',
      brandColor: Color(0xFFF9C000),
      tagline: 'NBCUniversal, Film & Serial Pilihan',
      taglineEn: 'NBCUniversal, Hit Movies & Series',
      taglineHi: 'एनबीसी यूनिवर्सल, फ़िल्में और सीरीज़',
      icon: Icons.live_tv_rounded,
      logoAsset: 'assets/images/platforms/peacock.png',
    ),
    StreamingPlatform(
      id: 'vidio',
      name: 'Vidio',
      providerId: 489,
      customProviderIds: '489',
      watchRegion: 'ID',
      primaryNetworkIds: '3579',
      companyIds: '147819|78913',
      brandColor: Color(0xFFED1C24),
      tagline: 'Vidio Originals, Serial & Film Indonesia',
      taglineEn: 'Vidio Originals, Indonesian Series & Movies',
      taglineHi: 'विडियो ओरिजिनल्स, इंडोनेशियाई सीरीज़ और फ़िल्में',
      icon: Icons.play_circle_fill_rounded,
      logoAsset: 'assets/images/platforms/vidio.png',
    ),
    StreamingPlatform(
      id: 'wetv',
      name: 'WeTV',
      providerId: 623,
      customProviderIds: '623|160',
      watchRegion: 'ID',
      primaryNetworkIds: '3732|2224',
      secondaryNetworkIds: '2007',
      companyIds: '174410|74457|84946|81620',
      brandColor: Color(0xFFFF6000),
      tagline: 'WeTV Originals, Drama Asia & Anime',
      taglineEn: 'WeTV Originals, Asian Dramas & Anime',
      taglineHi: 'वीटीवी ओरिजिनल्स, एशियाई ड्रामा और एनीमे',
      icon: Icons.ondemand_video_rounded,
      logoAsset: 'assets/images/platforms/wetv.png',
    ),
    StreamingPlatform(
      id: 'viu',
      name: 'Viu',
      providerId: 158,
      customProviderIds: '158',
      watchRegion: 'ID',
      extraWatchRegions: ['SG', 'MY', 'HK'],
      primaryNetworkIds: '7237|2980',
      companyIds: '270347|203362|223630|223631|286105',
      brandColor: Color(0xFFFFB800),
      tagline: 'Viu Originals, K-Drama & Tayangan Asia',
      taglineEn: 'Viu Originals, K-Dramas & Asian Shows',
      taglineHi: 'वियू ओरिजिनल्स, के-ड्रामा और एशियाई शो',
      icon: Icons.smart_display_rounded,
      logoAsset: 'assets/images/platforms/viu.png',
    ),
  ];

  static StreamingPlatform fromId(String id) {
    return supportedPlatforms.firstWhere(
      (p) => p.id.toLowerCase() == id.toLowerCase(),
      orElse: () => supportedPlatforms.first,
    );
  }

  /// Resolves a [StreamingPlatform] by its `id`, `providerId`, or `watchProviderQuery`.
  static StreamingPlatform? tryFromQueryOrId(String queryOrId) {
    final clean = queryOrId.trim().toLowerCase();
    if (clean.isEmpty) return null;
    for (final p in supportedPlatforms) {
      if (p.id.toLowerCase() == clean ||
          p.providerId.toString() == clean ||
          p.watchProviderQuery.toLowerCase() == clean) {
        return p;
      }
    }
    return null;
  }
}
