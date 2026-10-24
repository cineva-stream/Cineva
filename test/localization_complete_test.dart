import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:cineva/core/localization/app_language.dart';
import 'package:cineva/core/localization/app_strings.dart';
import 'package:cineva/core/constants/content_preference.dart';
import 'package:cineva/core/constants/genre_constants.dart';
import 'package:cineva/core/utils/tmdb_genres.dart';
import 'package:cineva/features/history/data/models/watch_history_item.dart';
import 'package:cineva/features/home/data/datasources/tmdb_remote_datasource.dart';

void main() {
  group('Localization Verification Tests', () {
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
      expect(sEn.playerTabAppearance, 'Appearance & Background');
      expect(sEn.playerNextEpisodePill(5), 'Next: Episode 5');

      expect(sId.playerQualityTitle, 'Kualitas Video');
      expect(sId.playerSubtitleTrack, 'Pilih Subtitle');
      expect(sId.playerNextEpisodePill(5), 'Episode 5 Berikutnya');

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
  });
}
