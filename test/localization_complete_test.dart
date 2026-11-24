import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:cineva/core/localization/app_language.dart';
import 'package:cineva/core/localization/app_strings.dart';
import 'package:cineva/core/constants/content_preference.dart';
import 'package:cineva/core/constants/genre_constants.dart';
import 'package:cineva/core/utils/tmdb_genres.dart';
import 'package:cineva/features/history/data/models/watch_history_item.dart';
import 'package:cineva/features/home/data/datasources/tmdb_remote_datasource.dart';
import 'package:cineva/features/home/presentation/screens/section_catalog_screen.dart';
import 'package:cineva/features/player/data/services/provider_loader_service.dart';
import 'package:cineva/features/settings/data/legal_content.dart';

void main() {
  group('Localization Verification Tests', () {
    test('AppLanguage.hi displays "India" in Indonesian, "Hindi" in English, and "हिन्दी" in Hindi', () {
      expect(AppLanguage.hi.code, 'hi');
      expect(AppLanguage.hi.flagCountryCode, 'IN');
      expect(AppLanguage.hi.tmdbLanguageCode, 'hi-IN');
      expect(AppLanguage.id.tmdbLanguageCode, 'id-ID');
      expect(AppLanguage.en.tmdbLanguageCode, 'en-US');
      expect(AppLanguage.fromCode('hi'), AppLanguage.hi);

      // Dynamic localized label requirement:
      // "India" when active language is Indonesian, "Hindi" when English, "हिन्दी" when Hindi
      expect(AppLanguage.hi.localizedLabel(AppLanguage.id), 'India');
      expect(AppLanguage.hi.localizedLabel(AppLanguage.en), 'Hindi');
      expect(AppLanguage.hi.localizedLabel(AppLanguage.hi), 'हिन्दी');

      expect(AppLanguage.hi.localizedDisplayName(AppLanguage.id), 'India (हिन्दी)');
      expect(AppLanguage.hi.localizedDisplayName(AppLanguage.en), 'Hindi (हिन्दी)');
      expect(AppLanguage.hi.localizedDisplayName(AppLanguage.hi), 'हिन्दी (भारत)');
    });

    test('AppStrings provides full Hindi (hi) translations across all core modules', () {
      final sHi = const AppStrings(AppLanguage.hi);

      expect(sHi.isHindi, isTrue);
      expect(sHi.isIndonesian, isFalse);
      expect(sHi.isEnglish, isFalse);

      // Navigation & Home
      expect(sHi.navHome, 'होम');
      expect(sHi.navSearch, 'खोजें');
      expect(sHi.navWatchlist, 'वॉचलिस्ट');
      expect(sHi.navSettings, 'सेटिंग्स');
      expect(sHi.homeWatchNow, 'अभी देखें');
      expect(sHi.homeContinueWatching, 'देखना जारी रखें');
      expect(sHi.homeSeeAll, 'सभी देखें');

      // Watch Party & Airing Calendar
      expect(sHi.watchPartyBadgeTitle, 'वॉच पार्टी');
      expect(sHi.watchPartyJoinWatching, 'वॉच पार्टी में जुड़ें');
      expect(sHi.calendarBannerTitle, 'रिलीज़ कैलेंडर और एपिसोड शेड्यूल');
      expect(sHi.calendarTitle, 'रिलीज़ कैलेंडर');

      // Settings & Player & Download
      expect(sHi.settingsTitle, 'सेटिंग्स');
      expect(sHi.settingsAppLanguage, 'ऐप की भाषा');
      expect(sHi.playerQualityTitle, 'वीडियो गुणवत्ता');
      expect(sHi.playerTryingServer('Zeila'), 'Zeila आज़माया जा रहा है...');
      expect(const AppStrings(AppLanguage.en).playerTryingServer('Zeila'), 'Trying Zeila...');
      expect(const AppStrings(AppLanguage.id).playerTryingServer('Zeila'), 'Mencoba Zeila...');
      expect(sHi.downloadStatusFinalizing, 'पूर्ण हो रहा है');
    });

    test('ContentPreference, GenreConstants, TmdbGenres, and LegalContentRepository support Hindi', () {
      for (final pref in ContentPreference.values) {
        final labelHi = pref.getLocalizedLabel(false, AppLanguage.hi);
        final descHi = pref.getLocalizedDescription(false, AppLanguage.hi);
        expect(labelHi.isNotEmpty, isTrue);
        expect(descHi.isNotEmpty, isTrue);
      }
      expect(
        ContentPreference.bollywood.getLocalizedLabel(false, AppLanguage.hi),
        'बॉलीवुड (भारत)',
      );

      for (final genre in GenreConstants.filters) {
        final labelHi = genre.getLocalizedLabel(false, AppLanguage.hi);
        expect(labelHi.isNotEmpty, isTrue);
      }
      expect(TmdbGenres.getGenreName(28, language: AppLanguage.hi), 'एक्शन');
      expect(TmdbGenres.getGenreName(10749, language: AppLanguage.hi), 'रोमांस');
      expect(
        TmdbGenres.getFormattedGenres([28, 12], language: AppLanguage.hi),
        'एक्शन • एडवेंचर',
      );

      final privacyHi = LegalContentRepository.getDocument(
        LegalDocType.privacyPolicy,
        false,
        AppLanguage.hi,
      );
      expect(privacyHi.title, 'गोपनीयता नीति');
      expect(privacyHi.sections.isNotEmpty, isTrue);
    });

    test('AppStrings provides correct English translations for user-reported items', () {
      final sEn = const AppStrings(AppLanguage.en);
      final sId = const AppStrings(AppLanguage.id);

      // 1. Settings Subtitle & Disclaimer
      expect(sEn.settingsSubFontSize, 'Subtitle Font Size');
      expect(sEn.settingsSubBg, 'Subtitle Background');
      expect(sEn.settingsDisclaimerTitle, 'Disclaimer & Copyright');
      expect(sEn.settingsDisclaimerSubtitle, contains('Legal information'));
      expect(sEn.settingsDisclaimerDialogTitle, 'Legal Disclaimer');
      expect(sEn.settingsDisclaimerContent, contains('decentralized P2P'));
      expect(sEn.dialogUnderstood, 'Understood');

      expect(sId.settingsDisclaimerTitle, 'Disclaimer & Hak Cipta');
      expect(sId.dialogUnderstood, 'Mengerti');

      // 2. Home Continue Watching & See All
      expect(sEn.homeContinueWatching, 'Continue Watching');
      expect(sEn.homeSeeAll, 'See All');
      expect(sId.homeContinueWatching, 'Lanjutkan Menonton');
      expect(sId.homeSeeAll, 'Lihat Semua');

      // 3. Navigation downloads tooltip
      expect(sEn.navDownloads, 'Downloads');
      expect(sId.navDownloads, 'Unduhan');

      // 4. Player Upload Subtitle localization
      expect(sEn.playerUploadSubtitle, 'Upload Subtitle');
      expect(sId.playerUploadSubtitle, 'Upload Subtitle');
      expect(sEn.playerUploadSubtitleHint, contains('.srt or .vtt'));
      expect(sId.playerUploadSubtitleHint, contains('.srt atau .vtt'));
      expect(sEn.playerCustomSubtitleTag, 'Custom');
      expect(sId.playerCustomSubtitleTag, 'Kustom');
    });

    test('ContentPreference localized labels & descriptions for ID and EN', () {
      for (final pref in ContentPreference.values) {
        expect(pref.getLocalizedLabel(true).isNotEmpty, isTrue);
        expect(pref.getLocalizedLabel(false).isNotEmpty, isTrue);
        expect(pref.getLocalizedDescription(true).isNotEmpty, isTrue);
        expect(pref.getLocalizedDescription(false).isNotEmpty, isTrue);
      }

      expect(ContentPreference.korea.getLocalizedLabel(false), 'Korea (K-Drama)');
      expect(ContentPreference.anime.getLocalizedLabel(false), 'Anime');
      expect(ContentPreference.hollywood.getLocalizedLabel(false), 'Hollywood (Western)');
      expect(ContentPreference.korea.getLocalizedLabel(true), 'Korea (K-Drama)');
    });

    test('GenreConstants and TmdbGenres localized labels for ID and EN', () {
      for (final genre in GenreConstants.filters) {
        expect(genre.getLocalizedLabel(true).isNotEmpty, isTrue);
        expect(genre.getLocalizedLabel(false).isNotEmpty, isTrue);
      }

      // Check specific translations
      expect(TmdbGenres.getGenreName(28, isIndonesian: true), 'Aksi');
      expect(TmdbGenres.getGenreName(28, isIndonesian: false), 'Action');
      expect(TmdbGenres.getGenreName(878, isIndonesian: true), 'Sci-Fi');
      expect(TmdbGenres.getGenreName(878, isIndonesian: false), 'Sci-Fi');
      expect(TmdbGenres.getGenreName(10749, isIndonesian: true), 'Romantis');
      expect(TmdbGenres.getGenreName(10749, isIndonesian: false), 'Romance');
    });

    test('WatchHistoryItem localized progress subtitle adapts to language', () {
      final item = WatchHistoryItem(
        id: 123,
        mediaType: 'movie',
        title: 'Inception',
        positionMs: 1000 * 60 * 30, // 30 min watched
        durationMs: 1000 * 60 * 120, // 120 min total (90 min left = 1h 30m)
        lastWatchedAt: DateTime.now(),
      );

      final idSubtitle = item.localizedProgressSubtitle(isIndonesian: true);
      final enSubtitle = item.localizedProgressSubtitle(isIndonesian: false);

      expect(idSubtitle, contains('Sisa'));
      expect(enSubtitle, contains('left'));

      // If duration is 0
      final itemZero = WatchHistoryItem(
        id: 123,
        mediaType: 'movie',
        title: 'Inception',
        positionMs: 0,
        durationMs: 0,
        lastWatchedAt: DateTime.now(),
      );
      expect(itemZero.localizedProgressSubtitle(isIndonesian: true), 'Lanjutkan Menonton');
      expect(itemZero.localizedProgressSubtitle(isIndonesian: false), 'Continue Watching');
    });

    test('TmdbRemoteDatasource initializes with custom languageCode', () {
      final dio = Dio();
      final datasourceEn = TmdbRemoteDatasource(dio, languageCode: 'en-US');
      expect(datasourceEn.languageCode, 'en-US');

      final datasourceId = TmdbRemoteDatasource(dio, languageCode: 'id-ID');
      expect(datasourceId.languageCode, 'id-ID');
    });

    test('AppStrings provides comprehensive Player and Download modal localization for EN and ID', () {
      final sEn = const AppStrings(AppLanguage.en);
      final sId = const AppStrings(AppLanguage.id);

      // Player loading states
      expect(sEn.playerSearchingStream, 'Searching for high-speed stream...');
      expect(sEn.playerConnectingStream, 'Connecting video & audio stream...');
      expect(sEn.playerPreparingFastBuffer, contains('buffer'));
      expect(sEn.playerPreparingBackup, 'Preparing backup player...');
      expect(sEn.playerPreparingOffline, 'Preparing offline playback...');
      expect(sEn.playerPreparingEpisode(2), 'Preparing Episode 2...');

      expect(sId.playerSearchingStream, 'Mencari stream berkecepatan tinggi...');
      expect(sId.playerConnectingStream, 'Menghubungkan stream video & audio...');
      expect(sId.playerPreparingEpisode(2), 'Menyiapkan Episode 2...');

      // Player mini popups and controls
      expect(sEn.playerQualityTitle, 'Video Quality');
      expect(sEn.playerQualityAutoAdaptive, contains('Auto'));
      expect(sEn.playerVolumeTitle, 'Volume & Sound Boost');
      expect(sEn.playerSubtitleTrack, 'Select Subtitle');
      expect(sEn.playerSubSettingsTitle, 'Subtitle Settings');
      expect(sEn.playerTabSync, 'Timing (Sync)');
      expect(sEn.playerTabAppearance, 'Appearance');
      expect(sEn.playerNextEpisodePill(5), 'Next: Episode 5');
      expect(sEn.playerStreamNotFoundTitle, 'Stream Not Available');
      expect(sEn.playerStreamNotFoundChooseServer, 'Choose Another Server');

      expect(sId.playerQualityTitle, 'Kualitas Video');
      expect(sId.playerSubtitleTrack, 'Pilih Subtitle');
      expect(sId.playerTabAppearance, 'Tampilan');
      expect(sId.playerNextEpisodePill(5), 'Episode 5 Berikutnya');
      expect(sId.playerStreamNotFoundTitle, 'Sumber Video Belum Tersedia');
      expect(sId.playerStreamNotFoundChooseServer, 'Pilih Server Lain');

      // Download modal localization
      expect(sEn.downloadModalConnecting, 'Connecting stream & calculating sizes...');
      expect(sEn.downloadModalSelectResolution, 'Select Video Resolution');
      expect(sEn.downloadModalSelectSubtitle, 'Select Subtitle');
      expect(sEn.downloadModalStartDownload, 'Start Download');
      expect(sEn.downloadModalMovie, 'Movie');
      expect(sEn.downloadModalTv, 'TV Series');

      expect(sId.downloadModalConnecting, 'Menghubungkan stream & menghitung ukuran...');
      expect(sId.downloadModalSelectResolution, 'Pilih Resolusi Video');
      expect(sId.downloadModalStartDownload, 'Mulai Mengunduh');
      expect(sId.downloadModalMovie, 'Film');
      expect(sId.downloadModalTv, 'Serial TV');
    });

    test('3-language localization for Segera Hadir, 5 regional sections, and SectionCatalogScreen', () {
      const sId = AppStrings(AppLanguage.id);
      const sEn = AppStrings(AppLanguage.en);
      const sHi = AppStrings(AppLanguage.hi);

      // Segera Hadir / Coming Soon
      expect(sId.detailComingSoon, 'Segera Hadir');
      expect(sEn.detailComingSoon, 'Coming Soon');
      expect(sHi.detailComingSoon, 'जल्द आ रहा है');

      // 5 Curated Home Sections
      expect(sId.homeSectionAnime, 'Anime');
      expect(sEn.homeSectionAnime, 'Anime');
      expect(sHi.homeSectionAnime, 'एनीमे');

      expect(sId.homeSectionKDrama, 'K-Drama');
      expect(sEn.homeSectionKDrama, 'K-Drama');
      expect(sHi.homeSectionKDrama, 'के-ड्रामा');

      expect(sId.homeSectionIndonesia, 'Indonesia');
      expect(sEn.homeSectionIndonesia, 'Indonesian');
      expect(sHi.homeSectionIndonesia, 'इंडोनेशियाई');

      expect(sId.homeSectionHollywood, 'Hollywood');
      expect(sEn.homeSectionHollywood, 'Hollywood');
      expect(sHi.homeSectionHollywood, 'हॉलीवुड');

      expect(sId.homeSectionBollywood, 'Bollywood');
      expect(sEn.homeSectionBollywood, 'Bollywood');
      expect(sHi.homeSectionBollywood, 'बॉलीवुड');

      // SectionCatalogScreen release year filter strings
      expect(sId.catalogReleaseYearLabel, 'Tahun Rilis');
      expect(sEn.catalogReleaseYearLabel, 'Release Year');
      expect(sHi.catalogReleaseYearLabel, 'रिलीज़ वर्ष');

      expect(sId.catalogLatestDefault, 'Terbaru');
      expect(sEn.catalogLatestDefault, 'Latest');
      expect(sHi.catalogLatestDefault, 'नवीनतम');

      expect(HomeCatalogSection.fromKey('anime').localizedTitle(sId), 'Anime');
      expect(HomeCatalogSection.fromKey('kdrama').localizedTitle(sHi), 'के-ड्रामा');
      expect(HomeCatalogSection.fromKey('bollywood').localizedTitle(sHi), 'बॉलीवुड');

      // Filter & Sort 3-language strings
      expect(sId.filterAndSortTitle, 'Filter & Urutkan');
      expect(sEn.filterAndSortTitle, 'Filter & Sort');
      expect(sHi.filterAndSortTitle, 'फ़िल्टर और क्रमबद्ध करें');

      expect(sId.filterSortPopular, 'Populer');
      expect(sEn.filterSortPopular, 'Popular');
      expect(sHi.filterSortPopular, 'लोकप्रिय');

      expect(sId.filterAllYears, 'Semua Tahun');
      expect(sEn.filterAllYears, 'All Years');
      expect(sHi.filterAllYears, 'सभी वर्ष');

      // Official Telegram Channel strings in AboutInfoScreen (id, en, hi)
      expect(sId.aboutJoinTelegramTitle, 'Gabung Saluran Kami');
      expect(sEn.aboutJoinTelegramTitle, 'Join Our Channel');
      expect(sHi.aboutJoinTelegramTitle, 'हमारे चैनल से जुड़ें');
      expect(sId.aboutJoinTelegramDesc, isNotEmpty);
      expect(sEn.aboutJoinTelegramDesc, isNotEmpty);
      expect(sHi.aboutJoinTelegramDesc, isNotEmpty);
    });

    test('MediaReleaseGuard accurately distinguishes released vs unreleased titles with timezone grace buffer', () {
      final refNow = DateTime(2026, 6, 15, 10, 0);

      // 1. Past release date is always released (even if TMDB status is stale 'Post Production')
      expect(
        MediaReleaseGuard.isUnreleasedByMetadata(
          releaseDate: '2026-06-01',
          status: 'Post Production',
          nowOverride: refNow,
        ),
        isFalse,
      );

      // 2. Today or tomorrow (+24h timezone grace buffer) is treated as released
      expect(
        MediaReleaseGuard.isUnreleasedByMetadata(
          releaseDate: '2026-06-15',
          nowOverride: refNow,
        ),
        isFalse,
      );
      expect(
        MediaReleaseGuard.isUnreleasedByMetadata(
          releaseDate: '2026-06-16',
          nowOverride: refNow,
        ),
        isFalse,
      );

      // 3. Far-future release date is marked unreleased ("Segera Hadir")
      expect(
        MediaReleaseGuard.isUnreleasedByMetadata(
          releaseDate: '2026-12-25',
          nowOverride: refNow,
        ),
        isTrue,
      );

      // 4. Empty release date with 'In Production' or 'Planned' is marked unreleased
      expect(
        MediaReleaseGuard.isUnreleasedByMetadata(
          releaseDate: '',
          status: 'In Production',
          nowOverride: refNow,
        ),
        isTrue,
      );
    });
  });
}
