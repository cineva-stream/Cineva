import 'app_language.dart';

/// Centralized, type-safe multi-language string repository for Cineva.
/// Supports 100% full interface localization across Indonesian, English, and Hindi (India).
class AppStrings {
  final AppLanguage language;

  const AppStrings(this.language);

  bool get isIndonesian => language == AppLanguage.id;
  bool get isEnglish => language == AppLanguage.en;
  bool get isHindi => language == AppLanguage.hi;

  /// Helper that selects the string matching the active [language].
  String tr(String id, String en, [String? hi]) {
    switch (language) {
      case AppLanguage.id:
        return id;
      case AppLanguage.en:
        return en;
      case AppLanguage.hi:
        return hi ?? en;
    }
  }

  // ── Navigation Bar ──
  String get navHome => tr('Beranda', 'Home', 'होम');
  String get navWatchlist => tr('Watchlist', 'Watchlist', 'वॉचलिस्ट');
  String get navSearch => tr('Cari', 'Search', 'खोजें');
  String get navHistory => tr('Riwayat', 'History', 'इतिहास');
  String get navSettings => tr('Pengaturan', 'Settings', 'सेटिंग्स');
  String get navDownloads => tr('Unduhan', 'Downloads', 'डाउनलोड');

  // ── Home Screen ──
  String get homePopularMovies =>
      tr('Film Populer', 'Popular Movies', 'लोकप्रिय फ़िल्में');
  String get homePopularTv =>
      tr('Serial TV Populer', 'Popular TV Shows', 'लोकप्रिय टीवी शो');
  String get homeTop10 => tr('Top 10 Hari Ini', 'Top 10 Today', 'आज के टॉप 10');
  String get homeTrending => tr('Sedang Tren', 'Trending Now', 'अभी ट्रेंडिंग');
  String get homeContinueWatching =>
      tr('Lanjutkan Menonton', 'Continue Watching', 'देखना जारी रखें');
  String get homeSeeAll => tr('Lihat Semua', 'See All', 'सभी देखें');
  String get homeWatchNow => tr('Tonton Sekarang', 'Watch Now', 'अभी देखें');
  String get homeDetail => tr('Detail', 'Details', 'विवरण');
  String get homeAllCategory => tr('Semua', 'All', 'सभी');
  String get homeSectionAnime =>
      tr('Anime', 'Anime', 'एनीमे');
  String get homeSectionKDrama =>
      tr('K-Drama', 'K-Drama', 'के-ड्रामा');
  String get homeSectionIndonesia =>
      tr('Indonesia', 'Indonesian', 'इंडोनेशियाई');
  String get homeSectionHollywood =>
      tr('Hollywood', 'Hollywood', 'हॉलीवुड');
  String get homeSectionBollywood =>
      tr('Bollywood', 'Bollywood', 'बॉलीवुड');
  String get homeTopRated =>
      tr('Rating Tertinggi', 'Top Rated', 'सर्वोच्च रेटेड');
  String get homeUpcoming => tr(
    'Segera Tayang di Bioskop',
    'Coming Soon in Theaters',
    'सिनेमाघरों में जल्द आ रहा है',
  );
  String get detailComingSoon =>
      tr('Segera Hadir', 'Coming Soon', 'जल्द आ रहा है');
  String get catalogReleaseYearLabel =>
      tr('Tahun Rilis', 'Release Year', 'रिलीज़ वर्ष');
  String get catalogLatestDefault =>
      tr('Terbaru', 'Latest', 'नवीनतम');
  String catalogEmptyForYear(String year) => tr(
    'Belum ada tayangan untuk tahun $year',
    'No titles available for year $year',
    'वर्ष $year के लिए कोई शीर्षक उपलब्ध नहीं है',
  );
  String get filterAndSortTitle =>
      tr('Filter & Urutkan', 'Filter & Sort', 'फ़िल्टर और क्रमबद्ध करें');
  String get filterAndSortSubtitle => tr(
    'Sesuaikan urutan, tahun rilis, dan genre tayangan',
    'Customize sort order, release year, and genre',
    'क्रम, रिलीज़ वर्ष और शैली अनुकूलित करें',
  );
  String get filterSortByLabel =>
      tr('Urutkan Berdasarkan', 'Sort By', 'इसके अनुसार क्रमबद्ध करें');
  String get filterSortLatest => tr('Terbaru', 'Latest', 'नवीनतम');
  String get filterSortPopular => tr('Populer', 'Popular', 'लोकप्रिय');
  String get filterSortTopRated =>
      tr('Rating Tertinggi', 'Top Rated', 'सर्वोच्च रेटेड');
  String get filterAllYears => tr('Semua Tahun', 'All Years', 'सभी वर्ष');
  String get filterApplyButton =>
      tr('Terapkan Filter', 'Apply Filters', 'फ़िल्टर लागू करें');
  String get filterResetButton => tr('Reset', 'Reset', 'रीसेट');
  String get filterButtonShort => tr('Filter', 'Filter', 'फ़िल्टर');

  // ── Search & Discover Screen ──
  String get searchTitle => tr('Cari', 'Search', 'खोजें');
  String searchPriority(String label) =>
      tr('Prioritas $label', 'Priority $label', 'प्राथमिकता $label');
  String get searchHint => tr(
    'Cari film atau serial TV...',
    'Search movies or TV shows...',
    'फ़िल्में या टीवी शो खोजें...',
  );
  String get searchGenres =>
      tr('Kategori & Genre', 'Categories & Genres', 'श्रेणियाँ और शैलियाँ');
  String get searchResults =>
      tr('Hasil Pencarian', 'Search Results', 'खोज परिणाम');
  String get searchTabAll => tr('Semua', 'All', 'सभी');
  String get searchTabMovies => tr('Film', 'Movies', 'फ़िल्में');
  String get searchTabTv => tr('Serial TV', 'TV Shows', 'टीवी शो');
  String searchNoResults(String q) => tr(
    'Tidak ada hasil ditemukan untuk "$q"',
    'No results found for "$q"',
    '"$q" के लिए कोई परिणाम नहीं मिला',
  );
  String searchNoMovies(String q) => tr(
    'Tidak ada film ditemukan untuk "$q"',
    'No movies found for "$q"',
    '"$q" के लिए कोई फ़िल्म नहीं मिली',
  );
  String searchNoTv(String q) => tr(
    'Tidak ada serial TV ditemukan untuk "$q"',
    'No TV shows found for "$q"',
    '"$q" के लिए कोई टीवी शो नहीं मिला',
  );
  String get searchFailed =>
      tr('Pencarian gagal', 'Search failed', 'खोज विफल रही');
  String get searchHistory =>
      tr('Riwayat Pencarian', 'Search History', 'खोज इतिहास');
  String get searchClearAll => tr('Hapus Semua', 'Clear All', 'सभी साफ़ करें');
  String get searchTrending =>
      tr('Trend Pencarian', 'Trending Searches', 'ट्रेंडिंग खोजें');
  String get searchTopSearched =>
      tr('Sering Dicari', 'Top Searches', 'शीर्ष खोजें');
  String get searchTopSearchedSub => tr(
    'Film & Serial TV terpopuler minggu ini',
    'Most popular movies & TV shows this week',
    'इस सप्ताह की सबसे लोकप्रिय फ़िल्में और टीवी शो',
  );
  String get searchBadgeMovie => tr('FILM', 'MOVIE', 'फ़िल्म');
  String get searchBadgeTv => tr('SERIAL', 'SERIES', 'सीरीज़');
  String searchGenreMovies(String g) =>
      tr('Film $g', '$g Movies', '$g फ़िल्में');
  String searchGenreTv(String g) =>
      tr('Serial TV $g', '$g TV Shows', '$g टीवी शो');
  String searchNoGenreMovies(String g) => tr(
    'Belum ada film untuk genre $g',
    'No movies available for genre $g',
    '$g शैली के लिए कोई फ़िल्म उपलब्ध नहीं है',
  );
  String searchNoGenreTv(String g) => tr(
    'Belum ada serial TV untuk genre $g',
    'No TV shows available for genre $g',
    '$g शैली के लिए कोई टीवी शो उपलब्ध नहीं है',
  );
  String get searchGenreErrorMovies => tr(
    'Gagal memuat film genre',
    'Failed to load movies',
    'फ़िल्में लोड करने में विफल',
  );
  String get searchGenreErrorTv => tr(
    'Gagal memuat serial TV genre',
    'Failed to load TV shows',
    'टीवी शो लोड करने में विफल',
  );

  // ── Detail Screen ──
  String get detailWatchNow => tr('Tonton Sekarang', 'Watch Now', 'अभी देखें');
  String detailWatchTv(int season, int episode) => tr(
    'Tonton S$season : E$episode',
    'Watch S$season : E$episode',
    'देखें S$season : E$episode',
  );
  String get detailTrailer => tr('Trailer', 'Trailer', 'ट्रेलर');
  String get detailDownload => tr('Unduh', 'Download', 'डाउनलोड');
  String get detailDownloadMovie =>
      tr('Unduh Film', 'Download Movie', 'फ़िल्म डाउनलोड करें');
  String detailDownloadEpisode(int ep) => tr(
    'Unduh Episode $ep',
    'Download Episode $ep',
    'एपिसोड $ep डाउनलोड करें',
  );
  String get detailWatchlistAdd => tr('Simpan', 'Watchlist', 'वॉचलिस्ट');
  String get detailWatchlistAdded => tr('Tersimpan', 'Saved', 'सहेजा गया');
  String get detailWatchlistAddTooltip =>
      tr('Tambahkan ke Watchlist', 'Add to Watchlist', 'वॉचलिस्ट में जोड़ें');
  String get detailWatchlistRemoveTooltip =>
      tr('Hapus dari Watchlist', 'Remove from Watchlist', 'वॉचलिस्ट से हटाएं');
  String get detailAddedToWatchlist => tr(
    'Ditambahkan ke Watchlist',
    'Added to Watchlist',
    'वॉचलिस्ट में जोड़ा गया',
  );
  String get detailRemovedFromWatchlist => tr(
    'Dihapus dari Watchlist',
    'Removed from Watchlist',
    'वॉचलिस्ट से हटाया गया',
  );
  String get detailSynopsis => tr('Sinopsis', 'Synopsis', 'सारांश');
  String get detailNoSynopsis => tr(
    'Belum ada sinopsis.',
    'No synopsis available.',
    'कोई सारांश उपलब्ध नहीं है।',
  );
  String get detailCast => tr('Pemeran', 'Cast', 'कलाकार');
  String get detailSeasons =>
      tr('Musim & Episode', 'Seasons & Episodes', 'सीज़न और एपिसोड');
  String get detailSelectEpisode =>
      tr('Pilih Episode', 'Select Episode', 'एपिसोड चुनें');
  String get detailSeason => tr('Musim', 'Season', 'सीज़न');
  String get detailEpisode => tr('Episode', 'Episode', 'एपिसोड');
  String detailSeasonEpisodes(int seasons, int episodes) => tr(
    '$seasons Season • $episodes Episode',
    '$seasons Season${seasons > 1 ? "s" : ""} • $episodes Episode${episodes > 1 ? "s" : ""}',
    '$seasons सीज़न • $episodes एपिसोड',
  );
  String get detailEpisodesUnavailable => tr(
    'Daftar episode tidak tersedia saat ini.',
    'Episode list is currently unavailable.',
    'एपिसोड सूची अभी उपलब्ध नहीं है।',
  );
  String detailNoEpisodesInSeason(int s) => tr(
    'Belum ada episode di Season $s',
    'No episodes in Season $s yet',
    'सीज़न $s में अभी कोई एपिसोड नहीं है',
  );
  String get detailSimilarMovies =>
      tr('Film Serupa', 'More Like This', 'इसी तरह की अन्य फ़िल्में');
  String get detailFailed => tr(
    'Gagal memuat detail',
    'Failed to load details',
    'विवरण लोड करने में विफल',
  );
  String get detailRetry => tr('Coba Lagi', 'Retry', 'पुनः प्रयास करें');
  String get detailRating => tr('Rating', 'Rating', 'रेटिंग');
  String get detailDuration => tr('Durasi', 'Duration', 'अवधि');
  String get detailReleaseDate => tr('Rilis', 'Release', 'रिलीज़');

  // ── Watchlist Screen ──
  String get watchlistTitle => tr('Watchlist', 'Watchlist', 'वॉचलिस्ट');
  String get watchlistEmptyTitle =>
      tr('Watchlist Kosong', 'Watchlist is Empty', 'वॉचलिस्ट खाली है');
  String get watchlistEmptyDesc => tr(
    'Film dan serial TV yang kamu simpan\nakan muncul di sini',
    'Movies and TV shows you save\nwill appear here',
    'आपके द्वारा सहेजी गई फ़िल्में और टीवी शो\nयहाँ दिखाई देंगे',
  );
  String get watchlistExploreButton =>
      tr('Jelajahi Film', 'Explore Movies', 'फ़िल्में खोजें');
  String watchlistRemoved(String title) => tr(
    '$title dihapus dari watchlist',
    '$title removed from watchlist',
    '$title को वॉचलिस्ट से हटाया गया',
  );
  String get watchlistUndo => tr('Batalkan', 'Undo', 'पूर्ववत करें');
  String watchlistAddedDate(String date) =>
      tr('Ditambahkan $date', 'Added $date', '$date को जोड़ा गया');

  // ── History Screen ──
  String get historyTitle =>
      tr('Riwayat Tontonan', 'Watch History', 'देखने का इतिहास');
  String get historyFilterAll => tr('Semua', 'All', 'सभी');
  String get historyFilterInProgress =>
      tr('Sedang Ditonton', 'In Progress', 'जारी है');
  String get historyFilterCompleted => tr('Selesai', 'Completed', 'पूरा हुआ');
  String get historyCompletedBadge =>
      tr('Selesai ditonton', 'Completed', 'पूरा देखा गया');
  String get historyClearConfirmTitle => tr(
    'Hapus Semua Riwayat?',
    'Clear All History?',
    'पूरा इतिहास साफ़ करें?',
  );
  String get historyClearConfirmDesc => tr(
    'Semua catatan tontonan dan titik akhir pemutaran akan dihapus secara permanen.',
    'All watch records and resume checkpoints will be permanently deleted.',
    'सभी देखने के रिकॉर्ड और प्लेबैक बिंदु स्थायी रूप से हटा दिए जाएंगे।',
  );
  String get historyClearedSuccess => tr(
    'Riwayat tontonan berhasil dibersihkan',
    'Watch history cleared successfully',
    'देखने का इतिहास सफलतापूर्वक साफ़ कर दिया गया',
  );
  String get historyEmptyTitle => tr(
    'Belum Ada Riwayat Tontonan',
    'No Watch History Yet',
    'अभी तक देखने का कोई इतिहास नहीं है',
  );
  String get historyEmptyDesc => tr(
    'Film dan serial yang Anda putar akan otomatis tercatat di sini sehingga Anda dapat melanjutkannya kapan saja.',
    'Movies and shows you watch will appear here so you can easily resume anytime.',
    'आपके द्वारा देखी जाने वाली फ़िल्में और शो यहाँ दिखाई देंगे ताकि आप कभी भी फिर से शुरू कर सकें।',
  );
  String get historyExplore =>
      tr('Jelajahi Film', 'Explore Movies', 'फ़िल्में खोजें');
  String get historyDeleteTooltip =>
      tr('Hapus dari riwayat', 'Remove from history', 'इतिहास से हटाएं');

  // ── Downloads Screen ──
  String get downloadTitle =>
      tr('Unduhan Offline', 'Offline Downloads', 'ऑफ़लाइन डाउनलोड');
  String get downloadTabInProgress =>
      tr('Sedang Diunduh', 'Downloading', 'डाउनलोड हो रहा है');
  String get downloadTabCompleted =>
      tr('Tersimpan Offline', 'Saved Offline', 'ऑफ़लाइन सहेजा गया');
  String get downloadEmptyInProgress => tr(
    'Tidak ada unduhan aktif',
    'No active downloads',
    'कोई सक्रिय डाउनलोड नहीं',
  );
  String get downloadEmptyCompleted => tr(
    'Belum ada media tersimpan',
    'No saved offline media',
    'कोई ऑफ़लाइन मीडिया सहेजा नहीं गया',
  );

  // ── Player Screen ──
  String get playerNextEpisode =>
      tr('Episode Berikutnya', 'Next Episode', 'अगला एपिसोड');
  String playerNextEpisodePill(int ep) =>
      tr('Episode $ep Berikutnya', 'Next: Episode $ep', 'अगला: एपिसोड $ep');
  String playerNextEpisodeInSecs(int ep, int secs) => tr(
    'Episode $ep dalam ${secs}d',
    'Episode $ep in ${secs}s',
    '$secsसे में एपिसोड $ep',
  );
  String get playerAutoPlayCancel => tr('Batal', 'Cancel', 'रद्द करें');
  String get playerAutoPlayCancelledToast => tr(
    'Putar otomatis episode berikutnya dibatalkan',
    'Auto-play next episode cancelled',
    'अगले एपिसोड का ऑटो-प्ले रद्द किया गया',
  );
  String playerNextEpShort(int ep) =>
      tr('Ep $ep Lanjut', 'Next Ep $ep', 'अगला एपिसोड $ep');
  String get playerHold2xSpeedBadge =>
      tr('2.0x Kecepatan Ganda', '2.0x Fast Forward', '2.0x तेज़ गति');
  String get playerLockScreen =>
      tr('Kunci Layar', 'Lock Screen', 'स्क्रीन लॉक करें');
  String get playerLockScreenToast => tr(
    'Layar dikunci • Sentuhan tidak sengaja dinonaktifkan',
    'Screen locked • Accidental touches disabled',
    'स्क्रीन लॉक • अनजाने स्पर्श निष्क्रिय',
  );
  String get playerUnlockScreenPill => tr(
    'Layar Terkunci • Ketuk untuk Buka',
    'Screen Locked • Tap to Unlock',
    'स्क्रीन लॉक है • अनलॉक करने के लिए टैप करें',
  );
  String get playerScreenLockedBadge =>
      tr('Layar Terkunci', 'Screen Locked', 'स्क्रीन लॉक है');
  String get playerUnlockTapHint => tr(
    'Ketuk untuk membuka kunci',
    'Tap to unlock controls',
    'नियंत्रण अनलॉक करने के लिए टैप करें',
  );
  String get playerFullscreenTooltip =>
      tr('Layar Penuh (F)', 'Full Screen (F)', 'फ़ुल स्क्रीन (F)');
  String get playerExitFullscreenTooltip => tr(
    'Keluar Layar Penuh (F)',
    'Exit Full Screen (F)',
    'फ़ुल स्क्रीन से बाहर निकलें (F)',
  );
  String get playerUnlockScreenToast =>
      tr('Kunci layar dibuka', 'Screen unlocked', 'स्क्रीन अनलॉक की गई');
  String get playerSleepTimerTitle =>
      tr('Pengatur Waktu Tidur', 'Sleep Timer', 'स्लीप टाइमर');
  String get playerSleepTimerOff => tr('Matikan Timer', 'Off', 'बंद करें');
  String playerSleepTimerMinutes(int min) =>
      tr('$min Menit', '$min Minutes', '$min मिनट');
  String get playerSleepTimerEndOfEpisode => tr(
    'Akhir Episode / Film',
    'End of Episode / Movie',
    'एपिसोड / फ़िल्म के अंत में',
  );
  String playerSleepTimerActiveToast(String label) => tr(
    'Sleep Timer aktif: $label',
    'Sleep Timer set: $label',
    'स्लीप टाइमर चालू: $label',
  );
  String get playerSleepTimerDisabledToast => tr(
    'Sleep Timer dimatikan',
    'Sleep Timer turned off',
    'स्लीप टाइमर बंद किया गया',
  );
  String get playerSleepTimerExpiredTitle =>
      tr('Waktu Tidur Selesai', 'Sleep Timer Ended', 'स्लीप टाइमर समाप्त');
  String get playerSleepTimerExpiredDesc => tr(
    'Pemutaran dijeda secara otomatis sesuai pengatur waktu tidur Anda.',
    'Playback has been automatically paused by your sleep timer.',
    'आपके स्लीप टाइमर के अनुसार प्लेबैक स्वचालित रूप से रोक दिया गया है।',
  );
  String get playerSleepTimerResumeBtn =>
      tr('Lanjutkan Menonton', 'Resume Watching', 'देखना जारी रखें');
  String get playerMiniPlayerTooltip =>
      tr('Pemutar Mini (PiP)', 'Mini Player (PiP)', 'मिनी प्लेयर (PiP)');
  String get playerFullscreenEnteredToast => tr(
    'Mode Layar Penuh (F)',
    'Full Screen Mode (F)',
    'फ़ुल स्क्रीन मोड (F)',
  );
  String get playerFullscreenExitedToast => tr(
    'Keluar Layar Penuh (F)',
    'Exited Full Screen (F)',
    'फ़ुल स्क्रीन से बाहर आए (F)',
  );
  String get playerMuteToast =>
      tr('Audio Dibisukan (M)', 'Audio Muted (M)', 'ऑडियो म्यूट (M)');
  String playerUnmuteToast(int vol) => tr(
    'Audio Aktif: $vol% (M)',
    'Audio Unmuted: $vol% (M)',
    'ऑडियो चालू: $vol% (M)',
  );
  String get playerFinishedPromptTitle => tr(
    'Apakah sudah selesai menonton?',
    'Finished watching?',
    'क्या आपने देखना पूरा कर लिया?',
  );
  String playerFinishedPromptDesc(String title) => tr(
    'Tandai status film "$title" di riwayat menonton Anda.',
    'Set the watch status for "$title" in your history.',
    'अपने इतिहास में "$title" की देखने की स्थिति सेट करें।',
  );
  String get playerFinishedOptionNo => tr('Belum', 'Not Yet', 'अभी नहीं');
  String get playerFinishedOptionYes => tr('Sudah', 'Done', 'हो गया');
  String get playerSubSettings =>
      tr('Atur Subtitle', 'Subtitle Settings', 'सबटाइटल सेटिंग्स');
  String get playerQuality => tr('Kualitas', 'Quality', 'गुणवत्ता');
  String get playerSpeed => tr('Kecepatan', 'Speed', 'गति');
  String get playerAudio => tr('Audio', 'Audio', 'ऑडियो');
  String get playerBrightness => tr('Kecerahan', 'Brightness', 'चमक');
  String get playerBuffering =>
      tr('Memuat video...', 'Buffering video...', 'वीडियो बफ़र हो रहा है...');
  String get playerConnecting => tr(
    'Menghubungkan ke stream...',
    'Connecting to stream...',
    'स्ट्रीम से जुड़ रहा है...',
  );
  String get playerSearchingStream => tr(
    'Mencari stream berkecepatan tinggi...',
    'Searching for high-speed stream...',
    'हाई-स्पीड स्ट्रीम खोजी जा रही है...',
  );
  String playerTryingServer(String serverName) => tr(
    'Mencoba $serverName...',
    'Trying $serverName...',
    '$serverName आज़माया जा रहा है...',
  );
  String get playerConnectingStream => tr(
    'Menghubungkan stream video & audio...',
    'Connecting video & audio stream...',
    'वीडियो और ऑडियो स्ट्रीम जोड़ी जा रही है...',
  );
  String get playerPreparingFastBuffer => tr(
    'Menyiapkan pemutaran cepat (buffer 7 detik)...',
    'Preparing fast playback (7s buffer)...',
    'तेज़ प्लेबैक तैयार हो रहा है (7 सेकंड बफ़र)...',
  );
  String get playerPreparingBackup => tr(
    'Menyiapkan pemutar cadangan...',
    'Preparing backup player...',
    'बैकअप प्लेयर तैयार किया जा रहा है...',
  );
  String get playerPreparingOffline => tr(
    'Menyiapkan pemutaran offline...',
    'Preparing offline playback...',
    'ऑफ़लाइन प्लेबैक तैयार किया जा रहा है...',
  );
  String get playerPreparingMp4 => tr(
    'Menyiapkan video MP4...',
    'Preparing MP4 video...',
    'MP4 वीडियो तैयार हो रहा है...',
  );
  String playerPreparingEpisode(int ep) => tr(
    'Menyiapkan Episode $ep...',
    'Preparing Episode $ep...',
    'एपिसोड $ep तैयार हो रहा है...',
  );

  String get playerInfoTitle => tr('Informasi', 'Information', 'जानकारी');
  String get playerSynopsisTitle => tr('Sinopsis', 'Synopsis', 'सारांश');
  String get playerNoSynopsis => tr(
    'Tidak Ada Sinopsis Untuk Film Ini atau Episode Ini',
    'No Synopsis Available for this Movie or Episode',
    'इस फ़िल्म या एपिसोड के लिए कोई सारांश उपलब्ध नहीं है',
  );

  String get playerQualityTitle =>
      tr('Kualitas Video', 'Video Quality', 'वीडियो गुणवत्ता');
  String get playerQualityAutoAdaptive =>
      tr('Auto (Adaptif FHD)', 'Auto (Adaptive FHD)', 'ऑटो (अनुकूली FHD)');
  String get playerQualityClear => tr('Jernih', 'Clear', 'स्पष्ट');
  String get playerQualityStandard => tr('Standar', 'Standard', 'मानक');
  String get playerQualityDataSaver =>
      tr('Hemat Kuota', 'Data Saver', 'डेटा सेवर');
  String get playerQualityLow => tr('Rendah', 'Low', 'कम');

  String get playerServerTitle =>
      tr('Server Streaming', 'Streaming Server', 'स्ट्रीमिंग सर्वर');
  String get playerServerDesc => tr(
    'Ganti server jika tayangan lambat, buffering, atau tidak dapat diputar',
    'Switch server if stream is buffering, slow, or fails to play',
    'यदि स्ट्रीम धीमी है, बफ़र हो रही है या चल नहीं रही है तो सर्वर बदलें',
  );
  String playerServerSwitched(String name) =>
      tr('Beralih ke $name', 'Switched to $name', '$name पर स्विच किया गया');
  String playerAutoSwitched(String name) => tr(
    'Otomatis dialihkan ke $name',
    'Auto-switched to $name',
    'स्वचालित रूप से $name पर स्विच किया गया',
  );

  String get playerVolumeTitle => tr(
    'Volume & Pengeras Suara',
    'Volume & Sound Boost',
    'वॉल्यूम और साउंड बूस्ट',
  );
  String get playerAudioBoost => 'Audio Boost';
  String get playerVolumeMute => 'Mute';

  String get playerSubtitleTrack =>
      tr('Pilih Subtitle', 'Select Subtitle', 'सबटाइटल चुनें');
  String get playerUploadSubtitle =>
      tr('Upload Subtitle', 'Upload Subtitle', 'सबटाइटल अपलोड करें');
  String get playerUploadSubtitleHint => tr(
    'Pilih file .srt atau .vtt dari perangkat',
    'Select .srt or .vtt file from device',
    'डिवाइस से .srt या .vtt फ़ाइल चुनें',
  );
  String get playerUploadSubtitleSuccess => tr(
    'Subtitle berhasil dimuat',
    'Subtitle loaded successfully',
    'सबटाइटल सफलतापूर्वक लोड हो गया',
  );
  String get playerUploadSubtitleEmpty => tr(
    'File subtitle kosong atau format tidak sesuai (.srt / .vtt)',
    'Subtitle file is empty or invalid (.srt / .vtt)',
    'सबटाइटल फ़ाइल खाली है या अमान्य है (.srt / .vtt)',
  );
  String get playerUploadSubtitleFailed => tr(
    'Gagal membaca file subtitle',
    'Failed to load subtitle file',
    'सबटाइटल फ़ाइल लोड करने में विफल',
  );
  String get playerCustomSubtitleTag => tr('Kustom', 'Custom', 'कस्टम');
  String get playerDisableSubtitle =>
      tr('Matikan Subtitle', 'Disable Subtitles', 'सबटाइटल बंद करें');
  String get playerNoSubtitleFound => tr(
    'Tidak ada subtitle ditemukan',
    'No subtitles found',
    'कोई सबटाइटल नहीं मिला',
  );
  String playerFailedDownloadSub(String lang) => tr(
    'Gagal mengunduh subtitle $lang',
    'Failed to download $lang subtitle',
    '$lang सबटाइटल डाउनलोड करने में विफल',
  );
  String playerTranslatingTo(String lang) => tr(
    'Menerjemahkan ke $lang...',
    'Translating to $lang...',
    '$lang में अनुवाद हो रहा है...',
  );
  String playerTranslateActive(String code) => tr(
    'Terjemahan $code Aktif ✓',
    '$code Translation Active ✓',
    '$code अनुवाद सक्रिय ✓',
  );
  String playerTranslateTo(String lang) =>
      tr('Terjemahkan ke $lang', 'Translate to $lang', '$lang में अनुवाद करें');

  String get playerSubSettingsTitle =>
      tr('Pengaturan Subtitle', 'Subtitle Settings', 'सबटाइटल सेटिंग्स');
  String get playerTabSync => tr('Waktu (Sync)', 'Timing (Sync)', 'समय (सिंक)');
  String get playerTabAppearance => tr('Tampilan', 'Appearance', 'दिखावट');
  String get playerSyncOnTime =>
      tr('Tepat Waktu (0.00s)', 'On Time (0.00s)', 'सही समय पर (0.00s)');
  String get playerSyncDefault => tr(
    'Sinkronisasi default',
    'Default synchronization',
    'डिफ़ॉल्ट सिंक्रनाइज़ेशन',
  );
  String get playerSyncDelayed => tr(
    'Subtitle ditunda (lebih lambat)',
    'Subtitle delayed (slower)',
    'सबटाइटल विलंबित (धीमा)',
  );
  String get playerSyncAdvanced => tr(
    'Subtitle dimajukan (lebih cepat)',
    'Subtitle advanced (faster)',
    'सबटाइटल आगे बढ़ाया गया (तेज़)',
  );
  String get playerReset => tr('Reset', 'Reset', 'रीसेट');

  String get playerSubBackground =>
      tr('Background Subtitle:', 'Subtitle Background:', 'सबटाइटल पृष्ठभूमि:');
  String get playerBgTransparent => tr('Transparan', 'Transparent', 'पारदर्शी');
  String get playerBgDark => tr('Gelap', 'Dark', 'गहरा');
  String get playerBgSolid => tr('Solid', 'Solid', 'ठोस');
  String get playerBgOpacity =>
      tr('Opasitas BG:', 'BG Opacity:', 'पृष्ठभूमि अपारदर्शिता:');
  String get playerFontSize => tr('Ukuran:', 'Size:', 'आकार:');
  String get playerStrokeWidth =>
      tr('Stroke Out:', 'Outline Stroke:', 'आउटलाइन स्ट्रोक:');
  String get playerSubPosition => tr('Posisi:', 'Position:', 'स्थिति:');
  String get playerSubColor => tr('Warna:', 'Color:', 'रंग:');

  String playerSubActiveToast(String lang) => tr(
    'Subtitle $lang aktif',
    '$lang subtitle active',
    '$lang सबटाइटल सक्रिय है',
  );
  String playerSubAutoTranslatedToast(String lang) => tr(
    'Subtitle otomatis diterjemahkan ke $lang',
    'Subtitle auto-translated to $lang',
    'सबटाइटल स्वचालित रूप से $lang में अनुवादित किया गया',
  );

  String get playerOfflineFailedTitle => tr(
    'Gagal Memutar Offline',
    'Offline Playback Failed',
    'ऑफ़लाइन प्लेबैक विफल',
  );
  String get playerOfflineFailedDesc => tr(
    'Terjadi kendala saat memutar file lokal.\nPastikan proses unduhan telah selesai 100%.',
    'An error occurred while playing local file.\nMake sure download has reached 100%.',
    'लोकल फ़ाइल चलाते समय समस्या हुई।\nसुनिश्चित करें कि डाउनलोड 100% पूरा हो गया है।',
  );
  String get playerBackToDownloads =>
      tr('Kembali ke Unduhan', 'Back to Downloads', 'डाउनलोड पर वापस जाएं');
  String get playerOfflineCorrupted => tr(
    'File unduhan rusak atau tidak dapat diputar. Silakan hapus lalu unduh ulang.',
    'The downloaded file is corrupted or cannot be played. Please delete it and download again.',
    'डाउनलोड की गई फ़ाइल खराब है या चलाई नहीं जा सकती। कृपया इसे हटाएं और पुनः डाउनलोड करें।',
  );
  String get playerDownloadNotFound => tr(
    'File unduhan tidak ditemukan di penyimpanan perangkat. Silakan unduh ulang.',
    'Downloaded file not found on device storage. Please download again.',
    'डिवाइस स्टोरेज में डाउनलोड फ़ाइल नहीं मिली। कृपया पुनः डाउनलोड करें।',
  );

  String get playerError => tr(
    'Gagal memutar video',
    'Failed to play video',
    'वीडियो चलाने में विफल',
  );
  String get playerRetry => tr('Coba Lagi', 'Retry', 'पुनः प्रयास करें');
  String get playerStreamNotFoundTitle => tr(
    'Sumber Video Belum Tersedia',
    'Stream Not Available',
    'स्ट्रीम उपलब्ध नहीं है',
  );
  String get playerStreamNotFoundMessage => tr(
    'Film ini mungkin masih tayang di bioskop atau belum memiliki rilis digital di server streaming.',
    'This title may still be in theaters or does not have a digital release available yet on streaming servers.',
    'यह फ़िल्म अभी भी सिनेमाघरों में हो सकती है या स्ट्रीमिंग सर्वर पर इसका डिजिटल रिलीज़ उपलब्ध नहीं है।',
  );
  String get playerStreamNotFoundChooseServer =>
      tr('Pilih Server Lain', 'Choose Another Server', 'दूसरा सर्वर चुनें');
  String get playerSubActive =>
      tr('Subtitle aktif', 'Subtitle active', 'सबटाइटल सक्रिय');
  String get playerSubAutoTranslated => tr(
    'Subtitle otomatis diterjemahkan',
    'Subtitle auto-translated',
    'सबटाइटल स्वचालित रूप से अनुवादित',
  );
  String get playerSubNotFound => tr(
    'Subtitle tidak ditemukan',
    'No subtitles found',
    'कोई सबटाइटल नहीं मिला',
  );
  String get playerAudioTrack => tr('Trek Audio', 'Audio Track', 'ऑडियो ट्रैक');
  String get downloadModalConnecting => tr(
    'Menghubungkan stream & menghitung ukuran...',
    'Connecting stream & calculating sizes...',
    'स्ट्रीम से जुड़ रहा है और आकार की गणना हो रही है...',
  );
  String get downloadModalSelectResolution => tr(
    'Pilih Resolusi Video',
    'Select Video Resolution',
    'वीडियो रेज़ोल्यूशन चुनें',
  );
  String get downloadModalSelectResolutionDesc => tr(
    'Pilih kualitas video sesuai ruang penyimpanan perangkat Anda',
    'Choose video quality based on your device storage',
    'अपने डिवाइस स्टोरेज के अनुसार वीडियो गुणवत्ता चुनें',
  );
  String get downloadModalSelectSubtitle =>
      tr('Pilih Subtitle', 'Select Subtitle', 'सबटाइटल चुनें');
  String downloadModalSelectedQuality(String label, String size) => tr(
    'Kualitas terpilih: $label ($size)',
    'Selected quality: $label ($size)',
    'चयनित गुणवत्ता: $label ($size)',
  );
  String get downloadModalIndonesianPriority => tr(
    'Bahasa Indonesia (Prioritas)',
    'Indonesian (Priority)',
    'इंडोनेशियाई (प्राथमिकता)',
  );
  String get downloadModalIndonesianPriorityDesc => tr(
    'Otomatis unduh teks Indonesia. Jika belum ada, sistem mengunduh teks English ke cache lalu otomatis menerjemahkannya secara gratis.',
    'Automatically download Indonesian subtitles. If unavailable, the system downloads English subtitles and auto-translates them for free.',
    'स्वचालित रूप से सबटाइटल डाउनलोड करें। यदि उपलब्ध नहीं है, तो सिस्टम अंग्रेज़ी सबटाइटल डाउनलोड करके उसका निःशुल्क अनुवाद करता है।',
  );
  String get downloadModalEnglishSub =>
      tr('English Subtitle', 'English Subtitle', 'अंग्रेज़ी सबटाइटल');
  String get downloadModalEnglishSubDesc => tr(
    'Unduh teks subtitle resmi Bahasa Inggris asli.',
    'Download official English subtitles.',
    'आधिकारिक अंग्रेज़ी सबटाइटल डाउनलोड करें।',
  );
  String get downloadModalNoSub =>
      tr('Tanpa Subtitle', 'No Subtitle', 'बिना सबटाइटल');
  String get downloadModalNoSubDesc => tr(
    'Hanya mengunduh file video saja tanpa file subtitle terpisah.',
    'Download video only without separate subtitle.',
    'अलग सबटाइटल फ़ाइल के बिना केवल वीडियो डाउनलोड करें।',
  );
  String get downloadModalStorageLocation =>
      tr('Lokasi Penyimpanan:', 'Storage Location:', 'स्टोरेज स्थान:');
  String get downloadModalStartDownload =>
      tr('Mulai Mengunduh', 'Start Download', 'डाउनलोड शुरू करें');
  String get downloadModalStartedToast => tr(
    'Unduhan dimulai! Ketuk ikon Unduhan di AppBar untuk melihat proses.',
    'Download started! Tap the Downloads icon in the AppBar to view progress.',
    'डाउनलोड शुरू हुआ! प्रगति देखने के लिए ऐपबार में डाउनलोड आइकन पर टैप करें।',
  );
  String get downloadModalViewToast => tr('Lihat', 'View', 'देखें');
  String get downloadModalNextSub => tr('Lanjut', 'Next', 'आगे');
  String get downloadModalMovie => tr('Film', 'Movie', 'फ़िल्म');
  String get downloadModalTv => tr('Serial TV', 'TV Series', 'टीवी सीरीज़');
  String get downloadSheetQualityTitle => tr(
    'Pilih Kualitas Unduhan',
    'Select Download Quality',
    'डाउनलोड गुणवत्ता चुनें',
  );
  String get downloadSheetSubtitleTitle =>
      tr('Pilih Subtitle', 'Select Subtitle', 'सबटाइटल चुनें');
  String get downloadSheetCancel => tr('Batal', 'Cancel', 'रद्द करें');
  String get downloadSheetNext => tr('Lanjut', 'Next', 'आगे');
  String get downloadSheetDownloadBtn => tr('Unduh', 'Download', 'डाउनलोड');
  String get downloadSheetLoadingSubtitles => tr(
    'Memuat subtitle yang tersedia...',
    'Loading available subtitles...',
    'उपलब्ध सबटाइटल लोड हो रहे हैं...',
  );
  String downloadSheetAutoTranslateTitle(String langName) => tr(
    'Auto Terjemah ke Subtitle Utama ($langName)',
    'Auto-Translate to Primary Subtitle ($langName)',
    'मुख्य सबटाइटल ($langName) में ऑटो-अनुवाद',
  );
  String downloadSheetAutoTranslateDesc(String langName) => tr(
    'Terjemahkan subtitle terpilih ke $langName secara otomatis',
    'Automatically translate selected subtitle to $langName',
    'चयनित सबटाइटल का स्वचालित रूप से $langName में अनुवाद करें',
  );
  String get downloadSheetSubSourceStream =>
      tr('Subtitle Stream', 'Stream Subtitle', 'स्ट्रीम सबटाइटल');
  String get downloadSheetSubSourceOpenSub =>
      tr('OpenSubtitles', 'OpenSubtitles', 'OpenSubtitles');
  String downloadQualityDesc(String label) {
    switch (label) {
      case '1080p':
        return tr(
          'Full HD • Kualitas terbaik & jernih',
          'Full HD • Best & sharpest quality',
          'Full HD • सर्वश्रेष्ठ और सबसे स्पष्ट गुणवत्ता',
        );
      case '720p':
        return tr(
          'HD • Tajam & hemat penyimpanan',
          'HD • Balanced clarity & storage',
          'HD • स्पष्टता और स्टोरेज का संतुलन',
        );
      case '480p':
        return tr(
          'SD • Hemat kuota & ruang memori',
          'SD • Data & storage saver',
          'SD • डेटा और मेमोरी की बचत',
        );
      case '360p':
        return tr(
          'Hemat • Ukuran terkecil & unduh tercepat',
          'Data Saver • Smallest size & fastest download',
          'डेटा सेवर • सबसे छोटा आकार और सबसे तेज़ डाउनलोड',
        );
      default:
        return label;
    }
  }

  // ── Settings Screen ──
  String get settingsTitle => tr('Pengaturan', 'Settings', 'सेटिंग्स');
  String get settingsGeneralSection =>
      tr('Preferensi Umum', 'General Preferences', 'सामान्य प्राथमिकताएं');
  String get settingsAppLanguage =>
      tr('Bahasa Aplikasi', 'App Language', 'ऐप की भाषा');
  String get settingsAppLanguageDesc => tr(
    'Pilih bahasa antarmuka aplikasi',
    'Choose app interface language',
    'ऐप इंटरफ़ेस की भाषा चुनें',
  );
  String get settingsContentPref =>
      tr('Preferensi Konten', 'Content Preference', 'सामग्री प्राथमिकता');
  String get settingsContentPrefDesc => tr(
    'Prioritas katalog di Beranda & Pencarian',
    'Catalog priority in Home & Search',
    'होम और खोज में कैटलॉग प्राथमिकता',
  );
  String get settingsVideoSection =>
      tr('Pemutaran & Video', 'Playback & Video', 'प्लेबैक और वीडियो');
  String get settingsDefaultQuality => tr(
    'Kualitas Streaming Default',
    'Default Streaming Quality',
    'डिफ़ॉल्ट स्ट्रीमिंग गुणवत्ता',
  );
  String get settingsHwAccel => tr(
    'Akselerasi Perangkat Keras',
    'Hardware Acceleration',
    'हार्डवेयर एक्सेलेरेशन',
  );
  String get settingsHwAccelDesc => tr(
    'Gunakan GPU decoder untuk pemutaran video 60fps tanpa patah-patah',
    'Use GPU decoder for smooth 60fps playback',
    'सुचारू 60fps प्लेबैक के लिए GPU डिकोडर का उपयोग करें',
  );
  String get settingsAutoPlayNextEpisode => tr(
    'Putar Otomatis Episode Berikutnya',
    'Auto-Play Next Episode',
    'अगला एपिसोड ऑटो-प्ले करें',
  );
  String get settingsAutoPlayNextEpisodeDesc => tr(
    'Otomatis lanjut ke episode serial TV berikutnya dengan hitung mundur 5 detik',
    'Automatically advance to the next TV series episode with a 5-second countdown',
    '5-सेकंड की उल्टी गिनती के साथ स्वचालित रूप से अगले टीवी एपिसोड पर जाएं',
  );
  String get settingsWifiOnly => tr(
    'Streaming Hemat Kuota (Wi-Fi Saja)',
    'Data Saver Streaming (Wi-Fi Only)',
    'डेटा सेवर स्ट्रीमिंग (केवल Wi-Fi)',
  );
  String get settingsWifiOnlyDesc => tr(
    'Mencegah buffering torrent berukuran besar di jaringan seluler',
    'Prevent large torrent buffering on mobile data',
    'मोबाइल डेटा पर बड़ी स्ट्रीम बफ़रिंग को रोकें',
  );
  String get settingsSubSection =>
      tr('Subtitle & Bahasa', 'Subtitles & Language', 'सबटाइटल और भाषा');
  String get settingsSubLanguage => tr(
    'Bahasa Subtitle Utama',
    'Primary Subtitle Language',
    'मुख्य सबटाइटल भाषा',
  );
  String settingsAutoTranslateTo(String langName) => tr(
    'Auto-Terjemah ke $langName',
    'Auto-Translate to $langName',
    '$langName में ऑटो-अनुवाद',
  );
  String get settingsAutoTranslateDesc => tr(
    'Otomatis terjemahkan subtitle asing ke bahasa pilihan jika tidak ada subtitle asli',
    'Automatically translate foreign subtitles to preferred language if native is unavailable',
    'मूल सबटाइटल उपलब्ध न होने पर विदेशी सबटाइटल का पसंदीदा भाषा में स्वतः अनुवाद करें',
  );
  String get settingsSubFontSize =>
      tr('Ukuran Huruf Subtitle', 'Subtitle Font Size', 'सबटाइटल फ़ॉन्ट आकार');
  String get settingsSubBg =>
      tr('Latar Belakang Subtitle', 'Subtitle Background', 'सबटाइटल पृष्ठभूमि');
  String get settingsStorageSection =>
      tr('Penyimpanan & Riwayat', 'Storage & History', 'स्टोरेज और इतिहास');
  String get settingsClearCache =>
      tr('Bersihkan Cache', 'Clear Cache', 'कैश साफ़ करें');
  String get settingsClearCacheDesc => tr(
    'Hapus file poster sementara dan buffering',
    'Remove temporary posters and buffering cache',
    'अस्थायी पोस्टर और बफ़रिंग कैश हटाएं',
  );
  String get settingsClearHistory => tr(
    'Hapus Riwayat Tontonan',
    'Clear Watch History',
    'देखने का इतिहास साफ़ करें',
  );
  String get settingsClearHistoryDesc => tr(
    'Semua daftar tontonan akan dihapus secara permanen',
    'Permanently remove all watch history records',
    'सभी देखने के इतिहास रिकॉर्ड स्थायी रूप से हटाएं',
  );
  String get settingsSearchLanguage =>
      tr('Cari bahasa...', 'Search language...', 'भाषा खोजें...');
  String get settingsNoLanguageFound =>
      tr('Bahasa tidak ditemukan', 'No language found', 'कोई भाषा नहीं मिली');
  String get settingsVersion => tr('Versi', 'Version', 'संस्करण');
  String get settingsAboutSection =>
      tr('Tentang & Lisensi', 'About & Licenses', 'जानकारी और लाइसेंस');
  String get settingsPrivacyPolicyTitle =>
      tr('Kebijakan Privasi', 'Privacy Policy', 'गोपनीयता नीति');
  String get settingsPrivacyPolicySubtitle => tr(
    'Transparansi perlindungan data pribadi dan privasi pengguna',
    'Personal data protection transparency and user privacy',
    'व्यक्तिगत डेटा सुरक्षा पारदर्शिता और उपयोगकर्ता गोपनीयता',
  );
  String get settingsTermsTitle =>
      tr('Syarat dan Ketentuan', 'Terms and Conditions', 'नियम और शर्तें');
  String get settingsTermsSubtitle => tr(
    'Ketentuan penggunaan, lisensi piranti lunak, dan batasan layanan',
    'Terms of use, software license, and service limitations',
    'उपयोग की शर्तें, सॉफ़्टवेयर लाइसेंस और सेवा सीमाएं',
  );
  String get settingsDisclaimerTitle => tr(
    'Disclaimer & Hak Cipta',
    'Disclaimer & Copyright',
    'अस्वीकरण और कॉपीराइट',
  );
  String get settingsDisclaimerMenuTitle =>
      tr('Disclaimer', 'Disclaimer', 'अस्वीकरण');
  String get settingsDisclaimerSubtitle => tr(
    'Informasi hukum penggunaan layanan streaming P2P',
    'Legal information regarding P2P streaming services',
    'P2P स्ट्रीमिंग सेवाओं के संबंध में कानूनी जानकारी',
  );
  String get settingsInfoTitle => tr('Info', 'Info', 'जानकारी');
  String get settingsInfoSubtitle => tr(
    'Tentang Cineva, arsitektur teknologi, dan versi aplikasi',
    'About Cineva, technology architecture, and app version',
    'Cineva, तकनीकी आर्किटेक्चर और ऐप संस्करण के बारे में',
  );
  String get settingsDisclaimerDialogTitle =>
      tr('Disclaimer Hukum', 'Legal Disclaimer', 'कानूनी अस्वीकरण');
  String get settingsDisclaimerContent => tr(
    'Cineva adalah pemutar media berbasis P2P terdesentralisasi yang mengakses konten publik yang tersedia di internet. Pengguna bertanggung jawab penuh atas media yang diakses sesuai peraturan perundang-undangan yang berlaku.',
    'Cineva is a decentralized P2P media player that accesses publicly available content on the internet. Users are fully responsible for the media accessed in compliance with applicable local laws.',
    'Cineva एक विकेंद्रीकृत P2P मीडिया प्लेयर है जो इंटरनेट पर सार्वजनिक रूप से उपलब्ध सामग्री तक पहुँचता है। लागू स्थानीय कानूनों के अनुसार एक्सेस किए गए मीडिया के लिए उपयोगकर्ता पूरी तरह से जिम्मेदार हैं।',
  );

  // ── Legal & About Screens ──
  String legalLastUpdated(String date) => tr(
    'Terakhir diperbarui: $date',
    'Last updated: $date',
    'अंतिम अपडेट: $date',
  );
  String get legalNoticeBadge => tr(
    'PEMBERITAHUAN HUKUM RESMI',
    'OFFICIAL LEGAL NOTICE',
    'आधिकारिक कानूनी सूचना',
  );
  String get legalJurisdictionNotice => tr(
    'Ketentuan ini berlaku mengikat bagi seluruh pengguna di seluruh yurisdiksi dunia.',
    'These terms are legally binding for all users across worldwide jurisdictions.',
    'ये शर्तें दुनिया भर के सभी अधिकार क्षेत्रों में सभी उपयोगकर्ताओं के लिए कानूनी रूप से बाध्यकारी हैं।',
  );
  String get aboutTagline => tr(
    'Modern Decentralized Media Player',
    'Modern Decentralized Media Player',
    'आधुनिक विकेंद्रीकृत मीडिया प्लेयर',
  );
  String get aboutBuildType => tr(
    'Edisi Publik Gratis',
    'Public Free Edition',
    'सार्वजनिक निःशुल्क संस्करण',
  );
  String get aboutDescription => tr(
    'Cineva adalah pemutar media terdesentralisasi generasi baru yang dirancang untuk menghadirkan pengalaman visual sinematik tanpa hambatan. Dengan memanfaatkan arsitektur streaming P2P cerdas dan mesin akselerasi pemutaran modern, Cineva memungkinkan penjelajahan katalog media publik global dengan kecepatan tinggi, antarmuka elegan, dan dukungan multi-bahasa lengkap tanpa biaya langganan dan tanpa pelacakan data pribadi.',
    'Cineva is a next-generation decentralized media player crafted to deliver cinema-grade viewing experiences without friction. Harnessing an intelligent P2P streaming architecture and modern hardware-accelerated playback engine, Cineva enables high-speed exploration of publicly indexed global media with an exquisite user interface, comprehensive world subtitles, zero subscription costs, and complete personal privacy.',
    'Cineva अगली पीढ़ी का विकेंद्रीकृत मीडिया प्लेयर है जिसे बिना किसी रुकावट के सिनेमा-स्तरीय देखने का अनुभव प्रदान करने के लिए डिज़ाइन किया गया है। स्मार्ट P2P स्ट्रीमिंग आर्किटेक्चर और आधुनिक हार्डवेयर-एक्सेलेरेटेड प्लेबैक इंजन के साथ, Cineva बिना किसी सदस्यता शुल्क और पूर्ण व्यक्तिगत गोपनीयता के साथ वैश्विक मीडिया कैटलॉग, आकर्षक इंटरफ़ेस और बहु-भाषा सबटाइटल प्रदान करता है।',
  );
  String get aboutFeatureP2PTitle => tr(
    'Streaming P2P Cerdas',
    'Smart P2P Streaming Engine',
    'स्मार्ट P2P स्ट्रीमिंग इंजन',
  );
  String get aboutFeatureP2PDesc => tr(
    'Teknologi streaming terdistribusi yang efisien tanpa ketergantungan pada server pusat tunggal.',
    'Efficient distributed streaming technology with zero reliance on single centralized servers.',
    'किसी एकल केंद्रीकृत सर्वर पर निर्भरता के बिना कुशल वितरित स्ट्रीमिंग तकनीक।',
  );
  String get aboutFeatureHwTitle => tr(
    'Akselerasi Perangkat Keras',
    'Hardware Acceleration',
    'हार्डवेयर एक्सेलेरेशन',
  );
  String get aboutFeatureHwDesc => tr(
    'Didukung oleh mesin pemutar MediaKit/MPV dengan decoding GPU hemat daya hingga resolusi 4K Ultra HD.',
    'Powered by MediaKit/MPV engine with power-efficient GPU decoding up to 4K Ultra HD.',
    '4K Ultra HD तक ऊर्जा-कुशल GPU डिकोडिंग के साथ MediaKit/MPV इंजन द्वारा संचालित।',
  );
  String get aboutFeatureSubTitle => tr(
    'Katalog 65+ Bahasa Subtitle',
    '65+ World Subtitle Languages',
    '65+ वैश्विक सबटाइटल भाषाएं',
  );
  String get aboutFeatureSubDesc => tr(
    'Pencarian subtitle otomatis dengan dukungan terjemahan instan ke bahasa pilihan Anda.',
    'Automated subtitle discovery with instant translation fallback to your preferred language.',
    'आपकी पसंदीदा भाषा में तत्काल अनुवाद समर्थन के साथ स्वचालित सबटाइटल खोज।',
  );
  String get aboutFeatureDownloadTitle => tr(
    'Manajer Unduhan Offline',
    'Offline Download Manager',
    'ऑफ़लाइन डाउनलोड प्रबंधक',
  );
  String get aboutFeatureDownloadDesc => tr(
    'Simpan tayangan favorit Anda langsung ke penyimpanan perangkat untuk dinikmati kapan saja tanpa internet.',
    'Save your favorite media directly to device storage to enjoy anytime without an internet connection.',
    'बिना इंटरनेट कनेक्शन के कभी भी आनंद लेने के लिए अपने पसंदीदा शो सीधे डिवाइस स्टोरेज में सहेजें।',
  );
  String get aboutFeatureFreeTitle => tr(
    'Non-Profit & Bebas Iklan',
    'Non-Profit & Zero Ads',
    'गैर-लाभकारी और विज्ञापन-मुक्त',
  );
  String get aboutFeatureFreeDesc => tr(
    'Proyek utilitas piranti lunak terbuka tanpa komersialisasi, tanpa iklan mengganggu, dan tanpa registrasi.',
    'Open software utility project with zero commercial monetization, no intrusive ads, and no registration required.',
    'बिना किसी व्यावसायिक मुद्रीकरण, बिना विज्ञापन और बिना पंजीकरण वाला ओपन सॉफ़्टवेयर प्रोजेक्ट।',
  );
  String get aboutCreditsTitle => tr(
    'Ekosistem & Kontributor Terbuka',
    'Open Ecosystem & Acknowledgements',
    'ओपन इकोसिस्टम और आभार',
  );
  String get aboutCreditsDesc => tr(
    'Cineva adalah perangkat lunak bebas dan sumber terbuka di bawah lisensi GNU General Public License v3.0 (GPL-3.0), dibangun dengan rasa hormat mendalam kepada ekosistem open-source dan API publik dunia: Flutter, MediaKit, Riverpod, The Movie Database (TMDB), OpenSubtitles, Hive, dan komunitas Torrentio.',
    'Cineva is free and open-source software under the GNU General Public License v3.0 (GPL-3.0), crafted with deep gratitude to the worldwide open-source ecosystem and public APIs: Flutter, MediaKit, Riverpod, The Movie Database (TMDB), OpenSubtitles, Hive, and the Torrentio community.',
    'Cineva GNU General Public License v3.0 (GPL-3.0) के तहत एक मुफ़्त और ओपन-सोर्स सॉफ़्टवेयर है, जिसे वैश्विक ओपन-सोर्स इकोसिस्टम और सार्वजनिक API के प्रति गहरे आभार के साथ बनाया गया है: Flutter, MediaKit, Riverpod, The Movie Database (TMDB), OpenSubtitles, Hive और Torrentio समुदाय।',
  );
  String get aboutJoinTelegramTitle => tr(
    'Gabung Saluran Kami',
    'Join Our Channel',
    'हमारे चैनल से जुड़ें',
  );
  String get aboutJoinTelegramDesc => tr(
    'Dapatkan info rilis film, serial & pembaruan fitur terbaru secara otomatis',
    'Get automatic updates on new movies, series & latest feature releases',
    'नई फ़िल्मों, सीरीज़ और नवीनतम फ़ीचर अपडेट की स्वचालित जानकारी प्राप्त करें',
  );

  // ── Dialogs & Actions ──
  String get dialogExitTitle =>
      tr('Konfirmasi Keluar', 'Exit Confirmation', 'बाहर निकलने की पुष्टि');
  String get dialogExitMessage => tr(
    'Apakah Anda yakin ingin keluar dari Cineva?',
    'Are you sure you want to exit Cineva?',
    'क्या आप वाकई Cineva से बाहर निकलना चाहते हैं?',
  );
  String get dialogCancel => tr('Batal', 'Cancel', 'रद्द करें');
  String get dialogUnderstood => tr('Mengerti', 'Understood', 'समझ गया');
  String get dialogExit => tr('Keluar', 'Exit', 'बाहर निकलें');
  String get dialogConfirm => tr('Konfirmasi', 'Confirm', 'पुष्टि करें');
  String get dialogClear => tr('Bersihkan', 'Clear', 'साफ़ करें');
  String get dialogDelete => tr('Hapus', 'Delete', 'हटाएं');
  String get dialogCacheCleaned => tr(
    'Cache berhasil dibersihkan',
    'Cache cleared successfully',
    'कैश सफलतापूर्वक साफ़ किया गया',
  );
  String get dialogHistoryCleared => tr(
    'Riwayat tontonan berhasil dihapus',
    'Watch history cleared successfully',
    'देखने का इतिहास सफलतापूर्वक साफ़ किया गया',
  );

  // ── Library / History / Downloads ──
  String get libraryTitle =>
      tr('Koleksi & Riwayat', 'Library & History', 'लाइब्रेरी और इतिहास');
  String get libraryTabHistory =>
      tr('Riwayat Tontonan', 'Watch History', 'देखने का इतिहास');
  String get libraryTabDownloads =>
      tr('Unduhan Offline', 'Offline Downloads', 'ऑफ़लाइन डाउनलोड');
  String get libraryEmptyHistory => tr(
    'Belum ada riwayat tontonan',
    'No watch history yet',
    'अभी तक देखने का कोई इतिहास नहीं',
  );
  String get libraryEmptyHistoryDesc => tr(
    'Film dan serial TV yang Anda tonton akan otomatis tersimpan di sini',
    'Movies and TV shows you watch will appear here',
    'आपके द्वारा देखी गई फ़िल्में और टीवी शो यहाँ दिखाई देंगे',
  );
  String get libraryEmptyDownloads => tr(
    'Belum ada film yang diunduh',
    'No downloaded media',
    'कोई डाउनलोड किया गया मीडिया नहीं',
  );
  String get libraryEmptyDownloadsDesc => tr(
    'Unduh film atau episode serial TV untuk diputar tanpa koneksi internet',
    'Download movies or episodes to enjoy without internet',
    'बिना इंटरनेट के आनंद लेने के लिए फ़िल्में या एपिसोड डाउनलोड करें',
  );
  String get libraryResume => tr('Lanjutkan', 'Resume', 'जारी रखें');
  String get libraryCompleted => tr('Selesai', 'Completed', 'पूरा हुआ');
  String get libraryDeleteConfirm => tr(
    'Hapus unduhan ini?',
    'Delete this download?',
    'क्या इस डाउनलोड को हटाना है?',
  );

  // ── Language Selection & Splash ──
  String get splashSelectLanguage =>
      tr('Pilih Bahasa', 'Select Language', 'भाषा चुनें');
  String get splashStartWatching =>
      tr('Mulai Menonton', 'Start Watching', 'देखना शुरू करें');

  // ── Profile & Onboarding ──
  String get profileCreateTitle => tr(
    'Buat Profil Cineva Anda',
    'Create Your Cineva Profile',
    'अपनी Cineva प्रोफ़ाइल बनाएं',
  );
  String get profileCreateSubtitle => tr(
    'Personalisasi pengalaman menonton Anda',
    'Personalize your streaming experience',
    'अपने स्ट्रीमिंग अनुभव को वैयक्तिकृत करें',
  );
  String get profileSkip => tr('Lewati', 'Skip', 'छोड़ें');
  String get profileChooseAvatar =>
      tr('PILIH AVATAR SINEMA', 'CHOOSE CINEMA AVATAR', 'सिनेमा अवतार चुनें');
  String get profileGallery => tr('Galeri', 'Gallery', 'गैलरी');
  String get profileNickname => tr('Nama Panggilan', 'Nickname', 'उपनाम');
  String get profileNicknameHint => tr(
    'Masukkan nama panggilan',
    'Enter your nickname',
    'अपना उपनाम दर्ज करें',
  );
  String get profileUsername => tr('Username', 'Username', 'यूज़रनेम');
  String get profileUsernameHint => tr('username', 'username', 'username');
  String get profileSaveAndEnter => tr('Lanjut', 'Continue', 'आगे बढ़ें');
  String get profileDefaultName =>
      tr('Penikmat Film', 'Movie Fan', 'फ़िल्म प्रेमी');

  // ── Avatar Crop Screen ──
  String get cropTitle =>
      tr('Sesuaikan Avatar', 'Adjust Avatar', 'अवतार समायोजित करें');
  String get cropRotateTooltip =>
      tr('Putar Gambar', 'Rotate Image', 'छवि घुमाएं');
  String get cropResetTooltip => tr('Reset', 'Reset', 'रीसेट');
  String get cropInstruction => tr(
    'Geser dan cubit gambar agar pas dengan lingkaran avatar',
    'Pan and pinch the image to fit inside the avatar circle',
    'अवतार घेरे में फ़िट करने के लिए छवि को खिसकाएं और ज़ूम करें',
  );
  String get cropCancel => tr('Batal', 'Cancel', 'रद्द करें');
  String get cropUseAvatar =>
      tr('Gunakan Avatar', 'Use Avatar', 'अवतार का उपयोग करें');
  String get cropFailed => tr(
    'Gagal memotong gambar',
    'Failed to crop image',
    'छवि क्रॉप करने में विफल',
  );

  // ── Edit Profile Sheet ──
  String get profileEditTitle =>
      tr('Ubah Profil', 'Edit Profile', 'प्रोफ़ाइल संपादित करें');
  String get profileChooseAvatarShort =>
      tr('PILIH AVATAR', 'CHOOSE AVATAR', 'अवतार चुनें');
  String get profileSaveChanges =>
      tr('Simpan Perubahan', 'Save Changes', 'परिवर्तन सहेजें');
  String get profileUpdatedSuccess => tr(
    'Profil berhasil diperbarui',
    'Profile updated successfully',
    'प्रोफ़ाइल सफलतापूर्वक अपडेट की गई',
  );
  String get profileGalleryError => tr(
    'Gagal memilih gambar dari galeri',
    'Failed to pick image from gallery',
    'गैलरी से छवि चुनने में विफल',
  );

  // ── Legal Agreement Screen ──
  String get legalAgreementTitle => tr(
    'Ketentuan Hukum & Privasi',
    'Terms & Privacy Policy',
    'कानूनी शर्तें और गोपनीयता नीति',
  );
  String get legalAgreementSubtitle => tr(
    'Harap baca dan pahami seluruh ketentuan hukum sebelum menggunakan Cineva.',
    'Please read and understand all legal terms and policies before using Cineva.',
    'Cineva का उपयोग करने से पहले कृपया सभी कानूनी शर्तों और नीतियों को पढ़ें और समझें।',
  );
  String get legalScrollHint => tr(
    'Gulir hingga paling bawah untuk menyetujui',
    'Scroll to the bottom to agree',
    'सहमत होने के लिए सबसे नीचे तक स्क्रॉल करें',
  );
  String get legalAgreeButton => tr('Setuju', 'Agree', 'सहमत हूँ');
  String get legalScrollToBottom =>
      tr('Gulir ke Bawah', 'Scroll Down', 'नीचे स्क्रॉल करें');
  String get legalFullyRead => tr(
    'Seluruh ketentuan telah dibaca',
    'All terms fully read',
    'सभी शर्तें पूरी तरह पढ़ ली गईं',
  );

  // ── In-App Updater ──
  String get updateAvailableTitle =>
      tr('Pembaruan Tersedia', 'Update Available', 'अपडेट उपलब्ध है');
  String updateNewVersionBadge(String ver) =>
      tr('Versi $ver', 'Version $ver', 'संस्करण $ver');
  String updateNewVersionSubtitle(String ver) => tr(
    'Versi $ver telah dirilis dengan peningkatan terbaru.',
    'Version $ver has been released with the latest improvements.',
    'नवीनतम सुधारों के साथ संस्करण $ver जारी किया गया है।',
  );
  String get updateAction =>
      tr('Perbarui Sekarang', 'Update Now', 'अभी अपडेट करें');
  String get updateInstallAction =>
      tr('Pasang Sekarang', 'Install Now', 'अभी इंस्टॉल करें');
  String get updateDownloading => tr(
    'Mengunduh Pembaruan...',
    'Downloading Update...',
    'अपडेट डाउनलोड हो रहा है...',
  );
  String get updateFailed => tr(
    'Gagal mengunduh berkas pembaruan.',
    'Failed to download update file.',
    'अपडेट फ़ाइल डाउनलोड करने में विफल।',
  );
  String get updateRetry => tr('Coba Lagi', 'Retry', 'पुनः प्रयास करें');
  String get updateCancel => tr('Batal', 'Cancel', 'रद्द करें');
  String get updateDismissTooltip =>
      tr('Tutup notifikasi', 'Dismiss notice', 'सूचना बंद करें');
  String get updatePermissionTitle => tr(
    'Izin Pemasangan Diperlukan',
    'Install Permission Required',
    'इंस्टॉल अनुमति आवश्यक है',
  );
  String get updatePermissionDesc => tr(
    'Untuk memasang pembaruan Cineva, aktifkan izin "Izinkan dari sumber ini" pada Setelan Android perangkat Anda.',
    'To install the Cineva update, please enable "Allow from this source" in your Android device settings.',
    'Cineva अपडेट इंस्टॉल करने के लिए, कृपया अपने Android डिवाइस की सेटिंग में "इस स्रोत से अनुमति दें" सक्षम करें।',
  );
  String get updateOpenSettings =>
      tr('Buka Setelan', 'Open Settings', 'सेटिंग्स खोलें');
  String get updateApkCleaned => tr(
    'Cache pembaruan lama telah dibersihkan',
    'Old update cache has been cleaned',
    'पुराना अपडेट कैश साफ़ कर दिया गया है',
  );
  String get updateNotificationBody => tr(
    'Update Tersedia, Segera update sekarang untuk menikmati layanan streaming dengan lebih baik.',
    'New version available, Update now to improve your streaming.',
    'नया संस्करण उपलब्ध है, बेहतर स्ट्रीमिंग अनुभव के लिए अभी अपडेट करें।',
  );
  String get updateSeeMore => tr('Lihat Detail', 'See More', 'विवरण देखें');
  String get updateChangelogTitle =>
      tr('Detail Pembaruan', 'Update Details', 'अपडेट विवरण');
  String get updateCloseModal => tr('Tutup', 'Close', 'बंद करें');
  String get updateTranslatingChangelog => tr(
    'Menerjemahkan catatan rilis...',
    'Translating release notes...',
    'रिलीज़ नोट्स का अनुवाद हो रहा है...',
  );
  String get updateOriginalText => tr('Teks Asli', 'Original Text', 'मूल पाठ');
  String get updateTranslatedText =>
      tr('Diterjemahkan', 'Translated', 'अनुवादित');
  String get updateNoChangelog => tr(
    'Tidak ada catatan rilis untuk versi ini.',
    'No release notes available for this version.',
    'इस संस्करण के लिए कोई रिलीज़ नोट्स उपलब्ध नहीं हैं।',
  );

  // ── TV Live ──
  String get navLiveTv => tr('TV Live', 'TV Live', 'लाइव टीवी');
  String get liveTvTitle => tr('TV Live', 'TV Live', 'लाइव टीवी');
  String get liveTvSearchHint => tr(
    'Cari saluran siaran TV...',
    'Search TV channels...',
    'टीवी चैनल खोजें...',
  );
  String get liveTvNoChannels => tr(
    'Tidak ada saluran TV ditemukan',
    'No TV channels found',
    'कोई टीवी चैनल नहीं मिला',
  );
  String get liveTvConnecting => tr(
    'Menghubungkan ke siaran live...',
    'Connecting to live stream...',
    'लाइव प्रसारण से जुड़ रहा है...',
  );
  String get liveTvFailed => tr(
    'Gagal Memuat Siaran Live',
    'Failed to Load Live Stream',
    'लाइव स्ट्रीम लोड करने में विफल',
  );
  String get liveTvConnectionError => tr(
    'Gagal terhubung ke siaran TV. Silakan muat ulang siaran.',
    'Failed to connect to TV stream. Please reload.',
    'टीवी प्रसारण से जुड़ने में विफल। कृपया स्ट्रीम रीलोड करें।',
  );
  String get liveTvReload =>
      tr('Muat Ulang Siaran', 'Reload Stream', 'स्ट्रीम रीलोड करें');
  String get liveTvRetry => tr('Coba Lagi', 'Retry', 'पुनः प्रयास करें');
  String get liveTvNowPlaying => tr('Diputar', 'Playing', 'चल रहा है');
  String get liveTvChannelList =>
      tr('Daftar Saluran', 'Channel List', 'चैनल सूची');
  String get liveTvFullscreen =>
      tr('Layar Penuh', 'Full Screen', 'फ़ुल स्क्रीन');
  String get liveTvExitFullscreen => tr(
    'Keluar Layar Penuh',
    'Exit Full Screen',
    'फ़ुल स्क्रीन से बाहर निकलें',
  );
  String get liveTvSelectChannel =>
      tr('Pilih Saluran', 'Select Channel', 'चैनल चुनें');
  String get liveTvSwitchChannel =>
      tr('Ganti Saluran', 'Change Channel', 'चैनल बदलें');
  String get liveTvClose => tr('Tutup', 'Close', 'बंद करें');
  String get liveTvBackToChannels =>
      tr('Kembali ke Saluran', 'Back to Channels', 'चैनलों पर वापस जाएं');
  String get liveTvNoFavorites => tr(
    'Belum ada saluran favorit',
    'No favorite channels yet',
    'अभी कोई पसंदीदा चैनल नहीं है',
  );
  String get liveTvAddFavorite =>
      tr('Simpan ke Favorit', 'Add to Favorites', 'पसंदीदा में जोड़ें');
  String get liveTvRemoveFavorite =>
      tr('Hapus dari Favorit', 'Remove from Favorites', 'पसंदीदा से हटाएं');
  String get liveTvChannelsCount => tr(
    'Saluran Siaran Langsung',
    'Live Broadcast Channels',
    'लाइव प्रसारण चैनल',
  );

  String liveTvCategoryLabel(String category) {
    if (isIndonesian) return category;
    switch (category) {
      case 'Semua':
        return isHindi ? 'सभी' : 'All';
      case 'Indonesia':
        return isHindi ? 'इंडोनेशिया' : 'Indonesia';
      case 'Olahraga':
        return isHindi ? 'खेल' : 'Sports';
      case 'Berita':
        return isHindi ? 'समाचार' : 'News';
      case 'Film & Hiburan':
        return isHindi ? 'फ़िल्में और मनोरंजन' : 'Movies & Entertainment';
      case 'Anak & Animasi':
        return isHindi ? 'बच्चे और एनिमेशन' : 'Kids & Animation';
      case 'Sains & Edukasi':
        return isHindi ? 'विज्ञान और शिक्षा' : 'Science & Education';
      case 'Musik':
        return isHindi ? 'संगीत' : 'Music';
      case 'Favorit':
        return isHindi ? 'पसंदीदा' : 'Favorites';
      default:
        return category;
    }
  }

  // ── Streaming Platforms ──
  String get searchPlatforms => tr(
    'Pilih Sesuai Platform',
    'Choose by Platform',
    'प्लेटफ़ॉर्म के अनुसार चुनें',
  );
  String get searchPlatformsSub => tr(
    'Jelajahi film & serial original pilihan',
    'Explore original movies & series',
    'मूल फ़िल्में और सीरीज़ खोजें',
  );

  // ── Airing Calendar ──
  String get calendarTitle =>
      tr('Jadwal Rilis', 'Airing Calendar', 'रिलीज़ कैलेंडर');
  String get calendarSubtitle => tr(
    'Jadwal tayang serial TV & Anime hari ini dan minggu ini',
    'TV series & anime release schedule for today and this week',
    'आज और इस सप्ताह के लिए टीवी सीरीज़ और एनीमे रिलीज़ शेड्यूल',
  );
  String get calendarToday => tr('Hari Ini', 'Today', 'आज');
  String get calendarTomorrow => tr('Besok', 'Tomorrow', 'कल (आने वाला)');
  String get calendarYesterday => tr('Kemarin', 'Yesterday', 'कल (बीता हुआ)');
  String get calendarFilterAll => tr('Semua', 'All', 'सभी');
  String get calendarFilterAnime => tr('Anime', 'Anime', 'एनीमे');
  String get calendarFilterKdrama => tr('K-Drama', 'K-Drama', 'के-ड्रामा');
  String get calendarFilterWestern => tr('Barat', 'Western', 'वेस्टर्न');
  String get calendarFilterIndonesian =>
      tr('Indonesia', 'Indonesia', 'इंडोनेशिया');
  String get calendarNoShows => tr(
    'Tidak ada episode tayang untuk tanggal ini',
    'No episodes scheduled for this date',
    'इस तिथि के लिए कोई एपिसोड निर्धारित नहीं है',
  );
  String get calendarNoShowsSub => tr(
    'Coba pilih tanggal lain atau ubah kategori filter',
    'Try selecting another date or changing category filter',
    'कोई अन्य तिथि चुनें या श्रेणी फ़िल्टर बदलें',
  );
  String get calendarEpisodesCount => tr('Episode', 'Episodes', 'एपिसोड');
  String get calendarBannerTitle => tr(
    'Jadwal Rilis & Kalender Episode',
    'Airing Calendar & Schedule',
    'रिलीज़ कैलेंडर और एपिसोड शेड्यूल',
  );
  String get calendarBannerSubtitle => tr(
    'Pantau jadwal tayang anime & serial favoritmu secara real-time',
    'Track your favorite anime & series release dates in real-time',
    'अपने पसंदीदा एनीमे और सीरीज़ के प्रसारण समय को रियल-टाइम में ट्रैक करें',
  );
  String get calendarBannerAction =>
      tr('Buka Kalender →', 'Open Calendar →', 'कैलेंडर खोलें →');

  // ── In-App Official Trailer ──
  String get trailerTitle =>
      tr('Trailer Resmi', 'Official Trailer', 'आधिकारिक ट्रेलर');
  String get trailerWatch =>
      tr('Tonton Trailer', 'Watch Trailer', 'ट्रेलर देखें');
  String get trailerUnavailable => tr(
    'Trailer resmi belum tersedia',
    'Official trailer not available',
    'आधिकारिक ट्रेलर उपलब्ध नहीं है',
  );
  String get trailerLoading =>
      tr('Memuat trailer...', 'Loading trailer...', 'ट्रेलर लोड हो रहा है...');
  String get trailerClose => tr('Tutup', 'Close', 'बंद करें');
  String get trailerWatchFullMedia =>
      tr('Tonton Sekarang', 'Watch Now', 'अभी देखें');

  // ── Person / Cast & Filmography ──
  String get personBiography => tr('Biografi', 'Biography', 'जीवनी');
  String get personNoBiography => tr(
    'Informasi biografi belum tersedia untuk aktor ini.',
    'Biography information is not available for this actor.',
    'इस कलाकार के लिए जीवनी की जानकारी उपलब्ध नहीं है।',
  );
  String get personReadMore => tr('Baca Selengkapnya', 'Read More', 'और पढ़ें');
  String get personReadLess => tr('Sembunyikan', 'Show Less', 'कम दिखाएं');
  String get personBorn => tr('Lahir', 'Born', 'जन्म');
  String get personDied => tr('Wafat', 'Died', 'निधन');
  String get personBirthPlace =>
      tr('Tempat Lahir', 'Place of Birth', 'जन्म स्थान');
  String get personKnownFor => tr('Dikenal Atas', 'Known For', 'प्रसिद्धि');
  String get personActing => tr('Pemeran / Akting', 'Acting', 'अभिनय');
  String get personDirecting => tr('Penyutradaraan', 'Directing', 'निर्देशन');
  String get personFilmography =>
      tr('Filmografi', 'Filmography', 'फ़िल्मोग्राफ़ी');
  String get personAllCredits => tr('Semua Karya', 'All Works', 'सभी कृतियाँ');
  String get personMoviesOnly =>
      tr('Film Saja', 'Movies Only', 'केवल फ़िल्में');
  String get personTvOnly =>
      tr('Serial TV Saja', 'TV Shows Only', 'केवल टीवी शो');
  String get personAgeYears => tr('tahun', 'years old', 'वर्ष');
  String get personNoCredits => tr(
    'Belum ada data filmografi yang ditemukan.',
    'No filmography records found.',
    'कोई फ़िल्मोग्राफ़ी रिकॉर्ड नहीं मिला।',
  );

  // ── Franchise / Movie Collection ──
  String get collectionPartOf =>
      tr('Bagian dari Waralaba', 'Part of Franchise', 'फ़्रैंचाइज़ी का हिस्सा');
  String get collectionViewFull => tr(
    'Lihat Koleksi Lengkap →',
    'View Full Collection →',
    'पूरा संग्रह देखें →',
  );
  String collectionCountMovies(int count) => tr(
    '$count Film dalam Koleksi',
    '$count Movies in Collection',
    'संग्रह में $count फ़िल्में',
  );
  String get collectionTimeline =>
      tr('Urutan Kronologis', 'Chronological Order', 'कालानुक्रमिक क्रम');
  String get collectionPart => tr('Bagian', 'Part', 'भाग');
  String get collectionWatchNow => tr('Tonton', 'Watch', 'देखें');

  // ── Airing Calendar Tabs ──
  String get calendarTabWeekly =>
      tr('Episode Mingguan', 'Weekly Schedule', 'साप्ताहिक शेड्यूल');
  String get calendarTabUpcoming =>
      tr('Segera Hadir', 'Coming Soon', 'जल्द आ रहा है');

  // ── Coming Soon / Release Radar ──
  String get upcomingTitle =>
      tr('Segera Hadir', 'Coming Soon', 'जल्द आ रहा है');
  String get upcomingSubtitle => tr(
    'Daftar film bioskop & serial TV yang paling dinantikan',
    'Most anticipated upcoming movies & TV shows',
    'सबसे प्रतीक्षित आगामी फ़िल्में और टीवी शो',
  );
  String get upcomingFilterAll => tr('Semua', 'All', 'सभी');
  String get upcomingFilterMovies => tr('Film Bioskop', 'Movies', 'फ़िल्में');
  String get upcomingFilterTv => tr('Serial TV & Anime', 'TV Shows', 'टीवी शो');
  String get upcomingReleasedToday =>
      tr('Rilis Hari Ini', 'Releases Today', 'आज रिलीज़');
  String get upcomingTomorrow =>
      tr('Rilis Besok', 'Releases Tomorrow', 'कल रिलीज़');
  String upcomingInDays(int days) =>
      tr('$days Hari Lagi', 'In $days Days', '$days दिनों में');
  String get upcomingNoMedia => tr(
    'Tidak ada film atau serial mendatang untuk filter ini',
    'No upcoming titles found for this filter',
    'इस फ़िल्टर के लिए कोई आगामी शीर्षक नहीं मिला',
  );
  String get upcomingNoMediaSub => tr(
    'Coba ubah kategori filter atau periksa kembali nanti',
    'Try changing category filter or check back later',
    'श्रेणी फ़िल्टर बदलने का प्रयास करें या बाद में पुनः जांचें',
  );

  // ── TV Franchise / Universe Hub ──
  String get tvUniversePartOf =>
      tr('Semesta Serial TV', 'TV Universe', 'टीवी यूनिवर्स');
  String get tvUniversePartOfFranchise =>
      tr('Bagian dari Semesta', 'Part of Universe', 'यूनिवर्स का हिस्सा');
  String get tvUniverseWatchOrder =>
      tr('Panduan Urutan Nonton', 'Watch Order Guide', 'देखने के क्रम की गाइड');
  String get tvUniverseViewGuide => tr(
    'Lihat Panduan Urutan Nonton →',
    'View Watch Order Guide →',
    'देखने के क्रम की गाइड देखें →',
  );
  String tvUniverseOrderNumber(int index, int total) => tr(
    'Urutan #$index dari $total Serial',
    'Watch Order #$index of $total Series',
    '$total सीरीज़ में से देखने का क्रम #$index',
  );
  String tvUniverseCountSeries(int count) => tr(
    '$count Serial dalam Semesta',
    '$count Series in Universe',
    'यूनिवर्स में $count सीरीज़',
  );
  String get tvUniverseMainSeries =>
      tr('Serial Utama', 'Main Series', 'मुख्य सीरीज़');
  String get tvUniversePrequel => tr('Prekuel', 'Prequel', 'प्रीक्वल');
  String get tvUniverseSequel => tr('Sekuel', 'Sequel', 'सीक्वल');
  String get tvUniverseSpinoff => tr('Spin-off', 'Spin-off', 'स्पिन-ऑफ़');
  String get tvUniverseViewSeries =>
      tr('Buka Serial', 'View Series', 'सीरीज़ देखें');
  String get tvUniverseChronologicalOrder => tr(
    'Urutan Cerita Rekomendasi',
    'Recommended Story Order',
    'अनुशंसित कहानी क्रम',
  );

  // ── TV / Desktop QR Profile Sync & Pairing ──
  String get tvSyncTitle => tr(
    'Tautkan Akun Cineva Anda',
    'Connect Your Cineva Account',
    'अपना Cineva खाता लिंक करें',
  );
  String get tvSyncSubtitle => tr(
    'Pindai QR code ini melalui aplikasi Cineva di handphone Anda. Bekerja otomatis baik di Wi-Fi rumah maupun paket data seluler (4G/5G).',
    'Scan this QR code from your Cineva smartphone app. Works seamlessly over home Wi-Fi and mobile cellular (4G/5G).',
    'अपने स्मार्टफ़ोन पर Cineva ऐप से इस QR कोड को स्कैन करें। होम Wi-Fi और मोबाइल डेटा (4G/5G) दोनों पर स्वचालित रूप से काम करता है।',
  );
  String get tvSyncStep1Title => tr(
    'Buka Cineva di Handphone',
    'Open Cineva on Smartphone',
    'स्मार्टफ़ोन पर Cineva खोलें',
  );
  String get tvSyncStep1Desc => tr(
    'Gunakan aplikasi Cineva di smartphone Android Anda',
    'Launch the Cineva Android app on your phone',
    'अपने फ़ोन पर Cineva Android ऐप लॉन्च करें',
  );
  String get tvSyncStep2Title => tr(
    'Pilih "Tautkan ke TV"',
    'Select "Connect to TV"',
    '"टीवी से कनेक्ट करें" चुनें',
  );
  String get tvSyncStep2Desc => tr(
    'Masuk ke Pengaturan ➔ Tautkan ke Android TV / PC',
    'Go to Settings ➔ Connect to Android TV / PC',
    'सेटिंग्स ➔ Android TV / PC से कनेक्ट करें पर जाएं',
  );
  String get tvSyncStep3Title => tr(
    'Pindai QR Code di Samping',
    'Scan the QR Code Beside',
    'बगल में दिए गए QR कोड को स्कैन करें',
  );
  String get tvSyncStep3Desc => tr(
    'Arahkan kamera ponsel Anda untuk sinkronisasi instan',
    'Aim your phone camera for instant transfer',
    'तुरंत सिंक के लिए अपने फ़ोन कैमरे को QR कोड पर रखें',
  );
  String get tvSyncContinueGuest => tr(
    'Masuk sebagai Tamu',
    'Continue as Guest',
    'अतिथि के रूप में जारी रखें',
  );
  String get tvSyncManualPcSetup =>
      tr('Setup Manual di PC', 'Manual PC Setup', 'PC पर मैनुअल सेटअप');
  String get tvSyncWaitingScan => tr(
    'Menunggu pemindaian ponsel...',
    'Waiting for smartphone scan...',
    'स्मार्टफ़ोन स्कैन की प्रतीक्षा हो रही है...',
  );
  String get tvSyncReceiving => tr(
    'Menerima profil dari ponsel...',
    'Receiving profile from phone...',
    'फ़ोन से प्रोफ़ाइल प्राप्त हो रही है...',
  );
  String tvSyncAlternativeCode(String code) => tr(
    'Kode Alternatif: $code',
    'Alternative Code: $code',
    'वैकल्पिक कोड: $code',
  );
  String get tvSyncSuccessTitle => tr(
    'Profil Berhasil Ditautkan!',
    'Profile Linked Successfully!',
    'प्रोफ़ाइल सफलतापूर्वक लिंक हो गई!',
  );
  String tvSyncWelcomeUser(String name) =>
      tr('Selamat Datang, $name', 'Welcome, $name', 'स्वागत है, $name');
  String get tvSyncDefaultUser =>
      tr('Pengguna Cineva', 'Cineva User', 'Cineva उपयोगकर्ता');
  String tvSyncSummaryText(int watchlist, int history) => tr(
    '$watchlist Watchlist • $history Riwayat Ditransfer',
    '$watchlist Watchlist • $history History Transferred',
    '$watchlist वॉचलिस्ट • $history इतिहास स्थानांतरित',
  );

  // Desktop Onboarding Mode Switcher
  String get desktopSyncTabQr => tr(
    'Tautkan via QR (dari HP)',
    'Link via QR (from Phone)',
    'QR द्वारा लिंक करें (फ़ोन से)',
  );
  String get desktopSyncTabManual => tr(
    'Setup Profil di PC',
    'Set Up Profile on PC',
    'PC पर प्रोफ़ाइल सेट करें',
  );

  // Mobile Scanner Screen
  String get scannerTitle =>
      tr('Pindai QR TV / PC', 'Scan TV / PC QR', 'TV / PC QR स्कैन करें');
  String get scannerInstructions => tr(
    'Arahkan kamera ke QR Code di layar Android TV atau Windows PC Anda.',
    'Point your camera at the QR code on your Android TV or Windows PC screen.',
    'अपने Android TV या Windows PC स्क्रीन पर दिख रहे QR कोड पर कैमरा रखें।',
  );
  String get scannerManualEntryBtn => tr(
    'Masukkan Kode Pairing Manual',
    'Enter Pairing Code Manually',
    'पेयरिंग कोड मैनुअल रूप से दर्ज करें',
  );
  String get scannerConnecting => tr(
    'Menghubungkan ke layar...',
    'Connecting to screen...',
    'स्क्रीन से जुड़ रहा है...',
  );
  String scannerSending(String name) => tr(
    'Mengirim profil $name...',
    'Sending profile $name...',
    '$name की प्रोफ़ाइल भेजी जा रही है...',
  );
  String scannerSendingData(String name, int watchlist, int history) => tr(
    'Mengirim profil $name ($watchlist watchlist, $history riwayat)...',
    'Sending profile $name ($watchlist watchlist, $history history)...',
    '$name की प्रोफ़ाइल ($watchlist वॉचलिस्ट, $history इतिहास) भेजी जा रही है...',
  );
  String scannerSuccessDetailed(int watchlist, int history) => tr(
    '$watchlist Watchlist dan $history Riwayat Tontonan berhasil ditautkan.',
    '$watchlist Watchlist and $history Watch History linked successfully.',
    '$watchlist वॉचलिस्ट और $history देखने का इतिहास सफलतापूर्वक लिंक किया गया।',
  );
  String get scannerFailed => tr(
    'Gagal menghubungkan ke TV/PC. Silakan coba lagi.',
    'Failed to connect to TV/PC. Please try again.',
    'TV/PC से जुड़ने में विफल। कृपया पुनः प्रयास करें।',
  );
  String get scannerSuccessViaCloud => tr(
    'Terkirim aman via End-to-End Encrypted Cloud Relay (Beda Jaringan / 4G/5G).',
    'Securely sent via End-to-End Encrypted Cloud Relay (Cross-Network / 4G/5G).',
    'एंड-टू-एंड एन्क्रिप्टेड क्लाउड रिले (क्रॉस-नेटवर्क / 4G/5G) के माध्यम से सुरक्षित रूप से भेजा गया।',
  );
  String get scannerSuccessViaLan => tr(
    'Terkirim langsung via Wi-Fi Lokal dalam hitungan milidetik.',
    'Sent directly via Local Wi-Fi in milliseconds.',
    'लोकल Wi-Fi के माध्यम से मिलीसेकंड में सीधे भेजा गया।',
  );
  String get scannerDone => tr('Selesai', 'Done', 'पूर्ण');
  String get scannerManualDialogTitle =>
      tr('Kode Pairing Manual', 'Manual Pairing Code', 'मैनुअल पेयरिंग कोड');
  String get scannerManualDialogDesc => tr(
    'Masukkan Topic ID dan Key yang tertera pada layar TV jika kamera bermasalah:',
    'Enter the Topic ID and Key displayed on the TV screen if your camera has issues:',
    'यदि कैमरे में समस्या है तो टीवी स्क्रीन पर प्रदर्शित Topic ID और Key दर्ज करें:',
  );
  String get scannerManualTopicLabel => tr(
    'Topic Sesi (contoh: cineva_sync_...)',
    'Session Topic (e.g. cineva_sync_...)',
    'सेशन टॉपिक (उदा: cineva_sync_...)',
  );
  String get scannerManualKeyLabel =>
      tr('Secret Key (Base64)', 'Secret Key (Base64)', 'सीक्रेट की (Base64)');
  String get scannerSendBtn => tr('Kirim', 'Send', 'भेजें');
  String get scannerCancelBtn => tr('Batal', 'Cancel', 'रद्द करें');
  String get scannerDoNotClose => tr(
    'Harap jangan menutup aplikasi',
    'Please do not close the app',
    'कृपया ऐप को बंद न करें',
  );

  // Settings Tile
  String get settingsSyncTvTitle => tr(
    'Tautkan ke Android TV / PC',
    'Connect to Android TV / PC',
    'Android TV / PC से कनेक्ट करें',
  );
  String get settingsSyncTvSubtitle => tr(
    'Pindai QR di layar TV atau PC untuk kirim profil (Wi-Fi / 4G)',
    'Scan QR on TV or PC screen to send profile (Wi-Fi / 4G)',
    'प्रोफ़ाइल भेजने के लिए TV या PC स्क्रीन पर QR स्कैन करें (Wi-Fi / 4G)',
  );
  String get badgeNew => tr('BARU', 'NEW', 'नया');
  String get retry => tr('Coba Lagi', 'Retry', 'पुनः प्रयास करें');

  // ── Backup, Restore & Google Cloud Sync ──
  String get backupSectionTitle =>
      tr('Cadangan & Sinkronisasi', 'Backup & Sync', 'बैकअप और सिंक');
  String get backupExportTitle => tr(
    'Cadangkan Data ke File',
    'Backup Data to File',
    'फ़ाइल में डेटा बैकअप करें',
  );
  String get backupExportDesc => tr(
    'Simpan riwayat, watchlist, & setelan ke file .cineva',
    'Export history, watchlist, & settings to a .cineva file',
    'इतिहास, वॉचलिस्ट और सेटिंग्स को .cineva फ़ाइल में निर्यात करें',
  );
  String get backupImportTitle => tr(
    'Pulihkan Data dari File',
    'Restore Data from File',
    'फ़ाइल से डेटा पुनर्स्थापित करें',
  );
  String get backupImportDesc => tr(
    'Impor & pulihkan data dari file .cineva sebelumnya',
    'Import & restore data from a previously saved .cineva file',
    'पहले से सहेजी गई .cineva फ़ाइल से डेटा आयात और पुनर्स्थापित करें',
  );
  String get backupCreating => tr(
    'Membuat file cadangan...',
    'Creating backup file...',
    'बैकअप फ़ाइल बनाई जा रही है...',
  );
  String get backupExportSuccess => tr(
    'Cadangan berhasil disimpan',
    'Backup saved successfully',
    'बैकअप सफलतापूर्वक सहेजा गया',
  );
  String get backupExportFailed => tr(
    'Gagal menyimpan file cadangan',
    'Failed to save backup file',
    'बैकअप फ़ाइल सहेजने में विफल',
  );
  String get backupImporting => tr(
    'Memulihkan data...',
    'Restoring data...',
    'डेटा पुनर्स्थापित हो रहा है...',
  );
  String backupImportSuccessSummary(int watchlist, int history) => tr(
    'Berhasil memulihkan $watchlist watchlist dan $history riwayat tontonan.',
    'Successfully restored $watchlist watchlist items and $history watch history records.',
    '$watchlist वॉचलिस्ट आइटम और $history देखने के इतिहास रिकॉर्ड सफलतापूर्वक पुनर्स्थापित किए गए।',
  );
  String get backupImportFailed => tr(
    'Gagal memulihkan file cadangan. Format tidak valid atau rusak.',
    'Failed to restore backup file. Invalid format or corrupted.',
    'बैकअप फ़ाइल पुनर्स्थापित करने में विफल। अमान्य प्रारूप या खराब फ़ाइल।',
  );
  String get backupConfirmRestoreTitle => tr(
    'Pulihkan Data Cadangan?',
    'Restore Backup Data?',
    'बैकअप डेटा पुनर्स्थापित करें?',
  );
  String backupConfirmRestoreDesc(int watchlist, int history) => tr(
    'Ditemukan $watchlist item watchlist dan $history riwayat tontonan. Terapkan data ini ke aplikasi?',
    'Found $watchlist watchlist items and $history watch history records. Apply this data to the app?',
    '$watchlist वॉचलिस्ट आइटम और $history देखने के इतिहास रिकॉर्ड मिले। क्या इस डेटा को ऐप में लागू करना है?',
  );
  String get backupApplyBtn => tr('Terapkan', 'Apply', 'लागू करें');

  // Google Cloud Sync
  String get googleSignInTitle => tr(
    'Masuk dengan Google',
    'Sign in with Google',
    'Google से साइन इन करें',
  );
  String get googleSignInSubtitle => tr(
    'Sinkronisasi otomatis riwayat & watchlist antar perangkat',
    'Automatic cloud sync for history & watchlist across devices',
    'सभी डिवाइस पर इतिहास और वॉचलिस्ट का स्वचालित क्लाउड सिंक',
  );
  String get googleConnectTitle => tr(
    'Hubungkan Akun Google',
    'Connect Google Account',
    'Google खाता कनेक्ट करें',
  );
  String get googleConnectDesc => tr(
    'Sinkronkan data profil, riwayat, dan watchlist otomatis ke Google Cloud',
    'Sync profile, watch history, and watchlist automatically to Google Cloud',
    'प्रोफ़ाइल, देखने का इतिहास और वॉचलिस्ट स्वचालित रूप से Google क्लाउड से सिंक करें',
  );
  String get googleConnectedStatus =>
      tr('Tersambung ke Google', 'Connected to Google', 'Google से जुड़ा हुआ');
  String googleConnectedAs(String email) => tr(
    'Tersinkronisasi sebagai $email',
    'Synced as $email',
    '$email के रूप में सिंक किया गया',
  );
  String get googleSyncNow =>
      tr('Sinkronkan Sekarang', 'Sync Now', 'अभी सिंक करें');
  String get googleDisconnect =>
      tr('Putuskan Sambungan', 'Disconnect', 'डिसकनेक्ट करें');
  String get googleSyncing => tr(
    'Menyinkronkan ke Google Cloud...',
    'Syncing to Google Cloud...',
    'Google क्लाउड से सिंक हो रहा है...',
  );
  String get googleSyncSuccess => tr(
    'Data berhasil disinkronkan ke Google Cloud',
    'Data synced successfully to Google Cloud',
    'डेटा सफलतापूर्वक Google क्लाउड से सिंक हो गया',
  );
  String get googleSyncFailed => tr(
    'Gagal menyinkronkan data ke Google Cloud',
    'Failed to sync data to Google Cloud',
    'Google क्लाउड से डेटा सिंक करने में विफल',
  );
  String get googleDisconnectConfirmTitle => tr(
    'Putuskan Akun Google?',
    'Disconnect Google Account?',
    'Google खाता डिसकनेक्ट करें?',
  );
  String get googleDisconnectConfirmDesc => tr(
    'Data lokal Anda tetap aman, namun sinkronisasi otomatis antar perangkat akan dinonaktifkan.',
    'Your local data remains intact, but automatic cross-device sync will be disabled.',
    'आपका लोकल डेटा सुरक्षित रहेगा, लेकिन डिवाइस के बीच स्वचालित सिंक बंद हो जाएगा।',
  );
  String get googleDisconnectBtn =>
      tr('Putuskan', 'Disconnect', 'डिसकनेक्ट करें');

  // Onboarding Start Phase
  String get onboardingRestoreFromFile => tr(
    'Pulihkan dari File Cadangan',
    'Restore from Backup File',
    'बैकअप फ़ाइल से पुनर्स्थापित करें',
  );
  String get onboardingRestoreFromFileDesc => tr(
    'Pilih file .cineva yang telah disimpan sebelumnya',
    'Select a previously saved .cineva backup file',
    'पहले से सहेजी गई .cineva बैकअप फ़ाइल चुनें',
  );
  String get onboardingOrDivider => tr('atau', 'or', 'या');
  String get onboardingContinueWithoutAccount => tr(
    'Mulai Menonton (Tanpa Akun)',
    'Start Watching (Guest Mode)',
    'देखना शुरू करें (अतिथि मोड)',
  );
  String get onboardingGoogleSyncSuccessGoHome => tr(
    'Akun Google terhubung! Memuat data Anda...',
    'Google Account linked! Loading your data...',
    'Google खाता जुड़ गया! आपका डेटा लोड हो रहा है...',
  );

  // ── Download Feature Announcement Modal ──
  String get downloadModalBadge => tr('FITUR BARU', 'NEW FEATURE', 'नया फ़ीचर');
  String get downloadModalPosterHeader => tr(
    'UNDUH & TONTON OFFLINE',
    'DOWNLOAD & WATCH OFFLINE',
    'डाउनलोड करें और ऑफ़लाइन देखें',
  );
  String get downloadModalPosterSubtitle => tr(
    'Tonton film & serial favorit tanpa kuota internet',
    'Watch movies & series anytime without internet',
    'बिना इंटरनेट के कभी भी पसंदीदा फ़िल्में और सीरीज़ देखें',
  );
  String get downloadModalTitle => tr(
    'Fitur Unduhan Offline Siap Dicoba!',
    'Offline Downloads Are Ready to Try!',
    'ऑफ़लाइन डाउनलोड आज़माने के लिए तैयार है!',
  );
  String get downloadModalDescription => tr(
    'Sekarang kamu bisa menyimpan film dan episode serial favorit langsung ke perangkatmu untuk dinikmati kapan saja secara offline.',
    'You can now save your favorite movies and TV episodes directly to your device to enjoy completely offline.',
    'अब आप अपनी पसंदीदा फ़िल्में और टीवी एपिसोड सीधे अपने डिवाइस में सहेज सकते हैं और कभी भी ऑफ़लाइन आनंद ले सकते हैं।',
  );
  String get downloadModalNote => tr(
    'Catatan: Kami tidak dapat memastikan untuk seluruh film maupun TV series dapat diunduh dikarenakan ketersediaan sumber server pihak ketiga.',
    'Note: We cannot guarantee that all movies or TV series can be downloaded due to third-party server and stream availability.',
    'नोट: तृतीय-पक्ष सर्वर और स्ट्रीम की उपलब्धता के कारण हम यह गारंटी नहीं दे सकते कि सभी फ़िल्में या टीवी सीरीज़ डाउनलोड की जा सकेंगी।',
  );
  String get downloadModalDontShowAgain =>
      tr('Jangan tampilkan lagi', "Don't show again", 'दोबारा न दिखाएं');
  String get downloadModalCta =>
      tr('Bagus, Coba Sekarang', 'Great, Try Now', 'बढ़िया, अभी आज़माएं');

  // ── Download Finalizing & Season Grouping ──
  String get downloadStatusFinalizing =>
      tr('FINALIZING', 'FINALIZING', 'पूर्ण हो रहा है');
  String get downloadFinalizingHint => tr(
    'Sedang menyatukan segmen offline, jangan tutup aplikasi...',
    'Merging offline media segments, please do not close the app...',
    'ऑफ़लाइन मीडिया सेगमेंट जोड़े जा रहे हैं, कृपया ऐप बंद न करें...',
  );
  String get downloadSelectSeason =>
      tr('Pilih Season:', 'Select Season:', 'सीज़न चुनें:');
  String downloadAllSeasons(int count) => tr(
    'Semua Season ($count Episode)',
    'All Seasons ($count Episodes)',
    'सभी सीज़न ($count एपिसोड)',
  );

  // ── Seamless Device Hand-Off ──
  String get handoffContinueWatching =>
      tr('Lanjutkan Menonton', 'Continue Watching', 'देखना जारी रखें');
  String handoffFromDevice(String device) =>
      tr('Sesi dari $device', 'Session from $device', '$device से सेशन');
  String handoffPrompt(String title, String time) => tr(
    'Lanjutkan menonton $title di menit $time?',
    'Continue watching $title at $time?',
    'क्या $title को $time से देखना जारी रखें?',
  );
  String get handoffContinueBtn => tr('Lanjutkan', 'Resume', 'जारी रखें');
  String get handoffDismiss => tr('Tutup', 'Dismiss', 'बंद करें');

  // ── Watch Party & Sync Play ──
  String get watchPartyTitle =>
      tr('Nonton Bareng', 'Watch Party', 'वॉच पार्टी');
  String get watchPartyCreateRoom =>
      tr('Buat Ruangan', 'Create Room', 'रूम बनाएं');
  String get watchPartyJoinRoom =>
      tr('Gabung Ruangan', 'Join Room', 'रूम में शामिल हों');
  String get watchPartyRoomCode => tr('Kode Ruangan', 'Room Code', 'रूम कोड');
  String get watchPartyRoomCodeHint =>
      tr('Contoh: CNV-8492', 'Example: CNV-8492', 'उदाहरण: CNV-8492');
  String get watchPartyNickname =>
      tr('Nama Panggilan', 'Display Name', 'प्रदर्शित नाम');
  String get watchPartyNicknameHint => tr(
    'Nama Anda di ruang tonton',
    'Your name in the room',
    'रूम में आपका नाम',
  );
  String get watchPartyAllowGuestControl => tr(
    'Izinkan partner/tamu mengontrol video',
    'Allow partner/guests to control video',
    'अतिथियों को वीडियो नियंत्रित करने की अनुमति दें',
  );
  String get watchPartyAllowGuestControlSubtitle => tr(
    'Peserta lain dapat menjeda, memutar, dan memajukan video',
    'Other members can play, pause, and seek video',
    'अन्य सदस्य वीडियो को चला, रोक और आगे-पीछे कर सकते हैं',
  );
  String get watchPartyHostOnlyControlNotice => tr(
    'Hanya Host yang dapat mengontrol video',
    'Only Host can control video playback',
    'केवल होस्ट ही वीडियो प्लेबैक नियंत्रित कर सकता है',
  );
  String get watchPartyCreateAndStart => tr(
    'Buat Ruangan & Mulai',
    'Create Room & Start',
    'रूम बनाएं और शुरू करें',
  );
  String get watchPartyJoinAndStart =>
      tr('Gabung & Tonton', 'Join & Watch', 'जुड़ें और देखें');
  String get watchPartyLiveChat =>
      tr('Obrolan Langsung', 'Live Chat', 'लाइव चैट');
  String watchPartyOnlineCount(int count) =>
      tr('$count Penonton', '$count Viewers', '$count दर्शक');
  String get watchPartyTypeMessage =>
      tr('Ketik pesan...', 'Type a message...', 'संदेश लिखें...');
  String get watchPartyCodeCopied =>
      tr('Kode ruangan disalin!', 'Room code copied!', 'रूम कोड कॉपी हो गया!');
  String get watchPartyLeaveConfirm =>
      tr('Keluar dari Ruangan?', 'Leave Room?', 'रूम छोड़ें?');
  String get watchPartyLeaveConfirmDesc => tr(
    'Anda akan keluar dari sesi Nonton Bareng ini.',
    'You will disconnect from this Watch Party session.',
    'आप इस वॉच पार्टी सेशन से बाहर हो जाएंगे।',
  );
  String get watchPartyLeaveBtn => tr('Keluar', 'Leave', 'छोड़ें');
  String get watchPartyGuestPrompt => tr(
    'Mode Tamu: Masukkan nama panggilan untuk nonton bersama teman',
    'Guest Mode: Enter a nickname to watch with friends',
    'अतिथि मोड: दोस्तों के साथ देखने के लिए उपनाम दर्ज करें',
  );
  String get watchPartyBannerTitle => tr(
    'Nonton Bareng Teman',
    'Watch Party with Friends',
    'दोस्तों के साथ वॉच पार्टी',
  );
  String get watchPartyBannerDesc => tr(
    'Punya kode ruangan? Gabung nobar dan tonton bersama secara realtime.',
    'Have a room code? Join and watch movies or series together in real-time.',
    'रूम कोड है? जुड़ें और रियल-टाइम में एक साथ फ़िल्में या सीरीज़ देखें।',
  );
  String get watchPartyBannerJoinBtn =>
      tr('Gabung Nobar', 'Join Party', 'पार्टी में जुड़ें');
  String get watchPartyAutoSearchDesc => tr(
    'Masukkan kode ruangan dari Host untuk langsung memutar tontonan yang sedang diputar Host.',
    'Enter the Host room code to automatically play whatever the Host is currently watching.',
    'होस्ट जो देख रहा है उसे तुरंत चलाने के लिए होस्ट का रूम कोड दर्ज करें।',
  );
  String get watchPartyUsePin => tr(
    'Kunci ruangan dengan PIN',
    'Lock room with PIN',
    'पिन से रूम लॉक करें',
  );
  String get watchPartyUsePinDesc => tr(
    'Hanya peserta dengan PIN yang dapat bergabung',
    'Only guests with the PIN can join',
    'केवल पिन वाले अतिथि ही शामिल हो सकते हैं',
  );
  String get watchPartyPin =>
      tr('PIN Ruangan (4 digit)', 'Room PIN (4 digits)', 'रूम पिन (4 अंक)');
  String get watchPartyPinHint => tr('Contoh: 1234', 'e.g. 1234', 'उदा. 1234');
  String get watchPartyPinRequired => tr(
    'Ruangan ini memerlukan PIN dari Host',
    'This room requires a PIN from Host',
    'इस रूम के लिए होस्ट से पिन आवश्यक है',
  );
  String get watchPartyPinIncorrect => tr(
    'PIN ruangan salah. Periksa kembali dengan Host.',
    'Incorrect room PIN. Please check with Host.',
    'गलत रूम पिन। कृपया होस्ट से जांचें।',
  );
  String get watchPartyPinCopied => tr(
    'Kode & PIN ruangan disalin!',
    'Room code & PIN copied!',
    'रूम कोड और पिन कॉपी हो गए!',
  );
  String get watchPartyRoomProtected =>
      tr('Ruangan Terkunci PIN', 'PIN Protected Room', 'पिन सुरक्षित रूम');
  String get watchPartyBetaBadge => 'BETA';
  String get watchPartyBetaNoticeTitle =>
      tr('Fitur Dalam Tahap Beta', 'Beta Feature Notice', 'बीटा फ़ीचर सूचना');
  String get watchPartyBetaNoticeDesc => tr(
    'Fitur Tonton Bersama masih dalam tahap beta. Jika menemukan kendala atau bug, mohon dimaklumi dan Anda dapat melapor di halaman Pengaturan melalui menu "Kirim Masukan".',
    'Watch Party is currently in beta. If you encounter any issues or bugs, please understand and feel free to report them in Settings via the "Share Your Thoughts" menu.',
    'वॉच पार्टी अभी बीटा चरण में है। यदि आपको कोई समस्या या बग मिलता है, तो कृपया सेटिंग्स में "सुझाव भेजें" मेनू के माध्यम से रिपोर्ट करें।',
  );

  // ── Watch Party Dynamic Actions & System Messages ──
  String watchPartyActionPause(String name, String time) => tr(
    '$name menjeda video di $time',
    '$name paused the video at $time',
    '$name ने $time पर वीडियो रोका',
  );
  String watchPartyActionPlay(String name, String time) => tr(
    '$name memutar video di $time',
    '$name resumed the video at $time',
    '$name ने $time पर वीडियो चलाया',
  );
  String watchPartyActionForward(String name, String time) => tr(
    '$name memajukan video ke $time',
    '$name forwarded the video to $time',
    '$name ने वीडियो को $time तक आगे बढ़ाया',
  );
  String watchPartyActionRewind(String name, String time) => tr(
    '$name memundurkan video ke $time',
    '$name rewound the video to $time',
    '$name ने वीडियो को $time तक पीछे किया',
  );
  String watchPartyActionSeek(String name, String time) => tr(
    '$name melompat ke $time',
    '$name jumped to $time',
    '$name ने $time पर जंप किया',
  );
  String watchPartyRoomCreated(String name) => tr(
    'Ruang Nonton Bareng dibuat oleh $name',
    'Watch Party room created by $name',
    '$name द्वारा वॉच पार्टी रूम बनाया गया',
  );
  String watchPartyMemberJoined(String name) => tr(
    '$name telah bergabung ke ruangan',
    '$name joined the room',
    '$name रूम में शामिल हुए',
  );
  String watchPartyMemberLeft(String name) => tr(
    '$name meninggalkan ruangan',
    '$name left the room',
    '$name ने रूम छोड़ दिया',
  );
  String get watchPartyControlUnlocked => tr(
    'Host mengizinkan peserta mengontrol video (Play/Pause/Seek)',
    'Host allowed guests to control video (Play/Pause/Seek)',
    'होस्ट ने अतिथियों को वीडियो नियंत्रित करने की अनुमति दी (Play/Pause/Seek)',
  );
  String get watchPartyControlLocked => tr(
    'Host mengunci kontrol video hanya untuk Host',
    'Host locked video controls to Host only',
    'होस्ट ने वीडियो नियंत्रण केवल होस्ट के लिए लॉक किया',
  );

  String get watchPartyGuest => tr('Tamu', 'Guest', 'अतिथि');
  String get watchPartyHost => 'Host';
  String get watchPartyCreatingRoom =>
      tr('Membuat Ruangan...', 'Creating Room...', 'रूम बनाया जा रहा है...');
  String get watchPartyJoiningRoom =>
      tr('Menghubungkan...', 'Connecting...', 'कनेक्ट हो रहा है...');
  String get watchPartySearchingRoom =>
      tr('Mencari Ruangan...', 'Searching Room...', 'रूम खोजा जा रहा है...');
  String get watchPartyEnterCodePrompt => tr(
    'Masukkan kode ruangan terlebih dahulu',
    'Please enter the room code first',
    'कृपया पहले रूम कोड दर्ज करें',
  );
  String get watchPartyRoomNotFound => tr(
    'Ruangan tidak ditemukan atau kode salah.',
    'Room not found or invalid code.',
    'रूम नहीं मिला या कोड अमान्य है।',
  );
  String get watchPartyRoomNotFoundOrNotReady => tr(
    'Ruangan tidak ditemukan. Pastikan kode benar dan Host telah membuat ruangan.',
    'Room not found. Make sure the code is correct and Host has created the room.',
    'रूम नहीं मिला। सुनिश्चित करें कि कोड सही है और होस्ट ने रूम बना लिया है।',
  );
  String get watchPartyCreateFailed => tr(
    'Gagal membuat ruangan. Silakan coba lagi.',
    'Failed to create room. Please try again.',
    'रूम बनाने में विफल। कृपया पुनः प्रयास करें।',
  );
  String get watchPartyJoinFailed => tr(
    'Gagal bergabung ke ruangan. Silakan coba lagi.',
    'Failed to join room. Please try again.',
    'रूम में शामिल होने में विफल। कृपया पुनः प्रयास करें।',
  );
  String get watchPartyPinDigitsRequirement => tr(
    'PIN harus terdiri dari 4 digit angka.',
    'PIN must be 4 numeric digits.',
    'पिन 4 अंकों का होना चाहिए।',
  );
  String get watchPartyPinOptional =>
      tr('(Jika dikunci PIN)', '(If PIN protected)', '(यदि पिन सुरक्षित है)');
  String get watchPartyOpenMediaFirst => tr(
    'Buka film atau episode yang ingin ditonton terlebih dahulu untuk membuat ruangan.',
    'Open a movie or episode first to create a watch party room.',
    'वॉच पार्टी रूम बनाने के लिए पहले कोई फ़िल्म या एपिसोड खोलें।',
  );
  String get watchPartySubheader => tr(
    'Tonton bersama teman secara realtime',
    'Watch together in real-time sync',
    'रियल-टाइम सिंक में दोस्तों के साथ देखें',
  );
  String get watchPartyGuestMode => tr('Mode Tamu', 'Guest Mode', 'अतिथि मोड');
  String watchPartyCodeWithPin(String code, String pin) => tr(
    'Kode: $code | PIN: $pin',
    'Code: $code | PIN: $pin',
    'कोड: $code | पिन: $pin',
  );
  String get watchPartyEndRoomConfirmTitle => tr(
    'Tutup Ruangan Nonton Bersama?',
    'End Watch Party Room?',
    'वॉच पार्टी रूम समाप्त करें?',
  );
  String get watchPartyEndRoomConfirmDesc => tr(
    'Sebagai Host, keluar dari ruangan akan otomatis menghapus ruangan, kode akses, dan seluruh data percakapan.',
    'As the Host, leaving will automatically delete the room, access code, and all conversation data.',
    'होस्ट के रूप में, बाहर निकलने पर रूम, एक्सेस कोड और सभी चैट डेटा स्वचालित रूप से हट जाएंगे।',
  );
  String get watchPartyDeleteAndLeave =>
      tr('Hapus & Keluar', 'Delete & Leave', 'हटाएं और बाहर निकलें');
  String get watchPartyTvSeries => tr('Serial TV', 'TV Show', 'टीवी शो');
  String get watchPartyMovie => tr('Film', 'Movie', 'फ़िल्म');
  String get watchPartyShare => tr('Bagikan', 'Share', 'शेयर करें');
  String get watchPartyShareLocked =>
      tr('Bagikan 🔒', 'Share 🔒', 'शेयर करें 🔒');
  String watchPartyShareCopied(String url, bool isProtected) => tr(
    isProtected
        ? 'Tautan Nobar 🔒 disalin: $url'
        : 'Tautan Nobar disalin: $url',
    isProtected
        ? 'Watch Party link 🔒 copied: $url'
        : 'Watch Party link copied: $url',
    isProtected
        ? 'वॉच पार्टी लिंक 🔒 कॉपी किया गया: $url'
        : 'वॉच पार्टी लिंक कॉपी किया गया: $url',
  );
  String watchPartyShareText(
    String url,
    bool isProtected, {
    String? roomCode,
  }) => tr(
    isProtected
        ? (roomCode != null
              ? '🍿 Nobar di Cineva!\nKode Room: $roomCode (Dilindungi PIN 🔒)\n\nTautan Langsung:\n$url'
              : 'Gabung nobar di Cineva: $url (Room dilindungi PIN, minta PIN ke host)')
        : (roomCode != null
              ? '🍿 Nobar di Cineva!\nKode Room: $roomCode\n\nTautan Langsung:\n$url'
              : 'Gabung nobar di Cineva: $url'),
    isProtected
        ? (roomCode != null
              ? '🍿 Watch Party on Cineva!\nRoom Code: $roomCode (PIN Protected 🔒)\n\nDirect Link:\n$url'
              : 'Join Watch Party on Cineva: $url (Room is protected by PIN, ask host for PIN)')
        : (roomCode != null
              ? '🍿 Watch Party on Cineva!\nRoom Code: $roomCode\n\nDirect Link:\n$url'
              : 'Join Watch Party on Cineva: $url'),
    isProtected
        ? (roomCode != null
              ? '🍿 Cineva पर वॉच पार्टी!\nरूम कोड: $roomCode (पिन सुरक्षित 🔒)\n\nसीधा लिंक:\n$url'
              : 'Cineva पर वॉच पार्टी में जुड़ें: $url (रूम पिन से सुरक्षित है, होस्ट से पिन मांगें)')
        : (roomCode != null
              ? '🍿 Cineva पर वॉच पार्टी!\nरूम कोड: $roomCode\n\nसीधा लिंक:\n$url'
              : 'Cineva पर वॉच पार्टी में जुड़ें: $url'),
  );
  String watchPartyConnectingToRoom(String code) => tr(
    'Menghubungkan ke Ruang Nobar $code...',
    'Connecting to Watch Party $code...',
    'वॉच पार्टी $code से जुड़ रहा है...',
  );
  String get watchPartyRoomNotFoundTitle =>
      tr('Ruang Tidak Ditemukan', 'Room Not Found', 'रूम नहीं मिला');
  String watchPartyRoomNotFoundDesc(String code) => tr(
    'Ruang dengan kode $code tidak aktif atau telah dibubarkan oleh host.',
    'Room with code $code is inactive or has been ended by the host.',
    'कोड $code वाला रूम निष्क्रिय है या होस्ट द्वारा समाप्त कर दिया गया है।',
  );
  String watchPartyFailedToLoadRoom(String error) => tr(
    'Gagal memuat ruang: $error',
    'Failed to load room: $error',
    'रूम लोड करने में विफल: $error',
  );
  String get watchPartyPinRequiredToJoin => tr(
    'PIN diperlukan untuk bergabung ke room ini.',
    'PIN is required to join this room.',
    'इस रूम में शामिल होने के लिए पिन आवश्यक है।',
  );
  String watchPartyPinIncorrectAttempt(int attempt, int maxAttempts) => tr(
    'PIN salah. Percobaan ke-$attempt dari $maxAttempts.',
    'Incorrect PIN. Attempt $attempt of $maxAttempts.',
    'गलत पिन। $maxAttempts में से प्रयास $attempt।',
  );
  String watchPartyPinLockout(int seconds) => tr(
    'Terlalu banyak percobaan PIN salah. Coba lagi dalam $seconds detik.',
    'Too many incorrect PIN attempts. Try again in $seconds seconds.',
    'बहुत अधिक गलत पिन प्रयास। $seconds सेकंड में पुनः प्रयास करें।',
  );
  String watchPartyLockedCountdown(int seconds) =>
      tr('Terkunci ($seconds s)', 'Locked ($seconds s)', 'लॉक ($seconds से)');
  String get watchPartyYourRoomName =>
      tr('Nama Anda di Ruangan', 'Your Name in Room', 'रूम में आपका नाम');
  String get watchPartyEnterYourNameHint => tr(
    'Masukkan nama Anda...',
    'Enter your name...',
    'अपना नाम दर्ज करें...',
  );
  String get watchPartyRoomPin4Digits =>
      tr('PIN Ruangan (4 Digit)', 'Room PIN (4 Digits)', 'रूम पिन (4 अंक)');
  String get watchPartyVerifyAndJoin =>
      tr('Verifikasi & Gabung', 'Verify & Join', 'सत्यापित करें और जुड़ें');
  String get watchPartyJoinWatching =>
      tr('Gabung Menonton', 'Join Watch Party', 'वॉच पार्टी में जुड़ें');
  String watchPartySpectators(int count) => tr(
    '$count Penonton',
    count == 1 ? '1 Viewer' : '$count Viewers',
    '$count दर्शक',
  );
  String get watchPartyBadgeTitle =>
      tr('NONTON BARENG', 'WATCH PARTY', 'वॉच पार्टी');
  String get watchPartyBackToHome =>
      tr('Kembali ke Beranda', 'Back to Home', 'होम पर वापस जाएं');
  String get watchPartyPartyGuest =>
      tr('Tamu Nobar', 'Party Guest', 'पार्टी अतिथि');
  String get watchPartyRoomNotFoundOrClosed => tr(
    'Ruang Nonton Bareng tidak ditemukan atau sudah dibubarkan.',
    'Watch Party room not found or has already ended.',
    'वॉच पार्टी रूम नहीं मिला या पहले ही समाप्त हो चुका है।',
  );
  String get playerRewind10Tooltip =>
      tr('Mundurkan 10 detik', 'Rewind 10 seconds', '10 सेकंड पीछे करें');
  String get playerForward10Tooltip =>
      tr('Majukan 10 detik', 'Forward 10 seconds', '10 सेकंड आगे करें');

  // ── Package Identity & Legacy Migration Modal ──
  String get migrationDialogBadge =>
      tr('IDENTITAS RESMI', 'OFFICIAL IDENTITY', 'आधिकारिक पहचान');
  String get migrationDialogTitle => tr(
    'Pembaruan Identitas & Keamanan Resmi',
    'Official Identity & Security Update',
    'आधिकारिक पहचान और सुरक्षा अपडेट',
  );
  String get migrationDialogDesc => tr(
    'Aplikasi Cineva telah berganti identitas paket dan tanda tangan keamanan baru. Kami sarankan uninstall aplikasi lama dan gunakan terbaru, seluruh data akan otomatis migrasi pada aplikasi terbaru.',
    'Cineva has been updated with a new official package identity and security signing key. We recommend uninstalling the previous version and using this latest one, all your data will automatically migrate to this version.',
    'Cineva को नई आधिकारिक पैकेज पहचान और सुरक्षा कुंजी के साथ अपडेट किया गया है। हम पुराने संस्करण को अनइंस्टॉल करने और इस नवीनतम संस्करण का उपयोग करने की सलाह देते हैं, आपका सारा डेटा स्वचालित रूप से माइग्रेट हो जाएगा।',
  );
  String get migrationDataPreservedNotice => tr(
    'Seluruh data riwayat tontonan, watchlist, dan profil Anda otomatis termigrasi pada versi terbaru ini.',
    'All your watch history, watchlist, and profile data are automatically preserved in this new version.',
    'आपका सारा देखने का इतिहास, वॉचलिस्ट और प्रोफ़ाइल डेटा इस नए संस्करण में स्वचालित रूप से सुरक्षित है।',
  );
  String get migrationFeature1Title => tr(
    'Migrasi Data Otomatis',
    'Automatic Data Migration',
    'स्वचालित डेटा माइग्रेशन',
  );
  String get migrationFeature1Desc => tr(
    'Riwayat tontonan, watchlist, dan profil Anda tetap aman dan terhubung',
    'Your watch history, watchlist, and profile remain completely intact',
    'आपका देखने का इतिहास, वॉचलिस्ट और प्रोफ़ाइल पूरी तरह सुरक्षित रहते हैं',
  );
  String get migrationFeature2Title =>
      tr('Bebas Aplikasi Ganda', 'No Duplicate Apps', 'कोई डुप्लिकेट ऐप नहीं');
  String get migrationFeature2Desc => tr(
    'Copot aplikasi versi lama agar tidak memakan ruang memori HP',
    'Uninstall the previous version to free up device storage',
    'डिवाइस स्टोरेज खाली करने के लिए पिछला संस्करण अनइंस्टॉल करें',
  );
  String get migrationFeature3Title => tr(
    'Tanda Tangan Terverifikasi',
    'Official Verified Key',
    'आधिकारिक सत्यापित कुंजी',
  );
  String get migrationFeature3Desc => tr(
    'Bebas peringatan keamanan dan pembaruan masa depan lebih cepat',
    'Protected against security warnings with seamless future updates',
    'सुरक्षा चेतावनियों से सुरक्षित और भविष्य में तेज़ अपडेट',
  );
  String get migrationUninstallBtn => tr(
    'Copot Versi Lama Sekarang',
    'Uninstall Previous Version',
    'पुराना संस्करण अभी अनइंस्टॉल करें',
  );
  String get migrationDismissBtn => tr(
    'Gunakan Versi Ini',
    'Continue with This Version',
    'इस संस्करण के साथ जारी रखें',
  );

  // ── Old App -> New App Transition Strings ──
  String get migrationOldAppBadge => tr(
    'VERSI RESMI TERPASANG',
    'OFFICIAL APP INSTALLED',
    'आधिकारिक ऐप इंस्टॉल है',
  );
  String get migrationOldAppTitle => tr(
    'Aplikasi Cineva Terbaru Telah Terpasang',
    'Latest Cineva App is Already Installed',
    'नवीनतम Cineva ऐप पहले से इंस्टॉल है',
  );
  String get migrationOldAppDesc => tr(
    'Cineva dengan identitas resmi baru telah terpasang di perangkat Anda. Seluruh riwayat dan profil otomatis aman. Buka aplikasi terbaru dan copot versi lama ini agar tidak memakan ruang memori.',
    'Cineva with the new official identity is already installed on your device. All your history and profile are safe. Open the latest app and uninstall this legacy version to free up storage.',
    'नई आधिकारिक पहचान वाला Cineva आपके डिवाइस पर पहले से इंस्टॉल है। आपका सारा इतिहास और प्रोफ़ाइल सुरक्षित है। नवीनतम ऐप खोलें और स्टोरेज खाली करने के लिए इस पुराने संस्करण को अनइंस्टॉल करें।',
  );
  String get migrationOpenNewAppBtn =>
      tr('Buka Cineva Terbaru', 'Open Latest Cineva', 'नवीनतम Cineva खोलें');
  String get migrationUninstallThisAppBtn => tr(
    'Copot Versi Lama Ini',
    'Uninstall This Legacy Version',
    'इस पुराने संस्करण को अनइंस्टॉल करें',
  );
  String get migrationDismissLaterBtn => tr('Nanti Saja', 'Later', 'बाद में');

  // ── Feedback & Bug Report Strings ──
  String get feedbackMenuTitle =>
      tr('Kirim Masukan', 'Share Your Thoughts', 'सुझाव भेजें');
  String get feedbackMenuSubtitle => tr(
    'Beri saran fitur, laporkan kendala, atau ulasan tayangan',
    'Submit suggestions, report bugs, or media issues',
    'फ़ीचर सुझाव दें, बग या मीडिया समस्या की रिपोर्ट करें',
  );
  String get feedbackScreenTitle =>
      tr('Kirim Masukan', 'Share Your Thoughts', 'सुझाव भेजें');
  String get feedbackScreenSubtitle => tr(
    'Pendapat dan laporan Anda sangat berharga untuk membuat Cineva semakin baik.',
    'Your voice and reports directly help make Cineva better for everyone.',
    'आपकी राय और रिपोर्ट Cineva को सभी के लिए बेहतर बनाने में सीधे मदद करती हैं।',
  );
  String get feedbackNameLabel =>
      tr('Nama / Panggilan', 'Your Name / Nickname', 'आपका नाम / उपनाम');
  String get feedbackNameHint => tr(
    'Masukkan nama atau anonim',
    'Enter name or leave anonymous',
    'नाम दर्ज करें या अज्ञात छोड़ें',
  );
  String get feedbackCategoryLabel =>
      tr('Kategori Masukan', 'Feedback Category', 'प्रतिक्रिया श्रेणी');
  String get feedbackCategoryBugs => tr(
    'Bug & Masalah Teknis',
    'Bugs & Technical Issues',
    'बग और तकनीकी समस्याएं',
  );
  String get feedbackCategoryFeatures =>
      tr('Saran Fitur Baru', 'Feature Suggestions', 'नए फ़ीचर के सुझाव');
  String get feedbackCategoryReport => tr(
    'Lapor Konten / Tayangan',
    'Report Media / Subtitles',
    'मीडिया / सबटाइटल की रिपोर्ट करें',
  );
  String get feedbackCategoryGeneral =>
      tr('Lainnya / Umum', 'General & Other', 'सामान्य और अन्य');
  String get feedbackTitleLabel =>
      tr('Judul Masukan', 'Subject / Title', 'विषय / शीर्षक');
  String get feedbackTitleHint => tr(
    'Contoh: Subtitle film delay di menit 14',
    'E.g., Subtitle out of sync on episode 2',
    'उदा., एपिसोड 2 में सबटाइटल सिंक में नहीं है',
  );
  String get feedbackDescLabel =>
      tr('Deskripsi Lengkap', 'Detailed Description', 'विस्तृत विवरण');
  String get feedbackDescHint => tr(
    'Jelaskan kendala atau saran Anda secara rinci...',
    'Describe what happened or your suggestion in detail...',
    'अपनी समस्या या सुझाव का विस्तार से वर्णन करें...',
  );
  String get feedbackIncludeDeviceInfo => tr(
    'Sertakan info teknis perangkat (membantu perbaikan bug)',
    'Include technical device info (helps diagnose issues)',
    'तकनीकी डिवाइस जानकारी शामिल करें (बग ठीक करने में सहायक)',
  );
  String get feedbackSubmitBtn =>
      tr('Kirim Masukan', 'Send Feedback', 'सुझाव भेजें');
  String get feedbackSendingBtn =>
      tr('Mengirim Masukan...', 'Sending...', 'भेजा जा रहा है...');
  String get feedbackSuccessTitle => tr(
    'Masukan Berhasil Terkirim!',
    'Feedback Sent!',
    'सुझाव सफलतापूर्वक भेजा गया!',
  );
  String get feedbackSuccessDesc => tr(
    'Terima kasih banyak atas partisipasi Anda. Laporan Anda telah kami terima untuk ditindaklanjuti.',
    'Thank you for your feedback! Your report has been submitted to the Cineva team.',
    'आपकी प्रतिक्रिया के लिए बहुत धन्यवाद! आपकी रिपोर्ट Cineva टीम को प्राप्त हो गई है।',
  );
  String get feedbackErrorTitle =>
      tr('Gagal Mengirim', 'Submission Failed', 'भेजने में विफल');
  String get feedbackErrorDesc => tr(
    'Terjadi kendala saat mengirim masukan. Pastikan koneksi internet stabil dan coba lagi.',
    'Could not send feedback. Please check your internet connection and try again.',
    'सुझाव नहीं भेजा जा सका। कृपया अपना इंटरनेट कनेक्शन जांचें और पुनः प्रयास करें।',
  );
  String get feedbackValidationTitleRequired => tr(
    'Mohon masukkan judul masukan terlebih dahulu',
    'Please enter a subject title',
    'कृपया पहले विषय शीर्षक दर्ज करें',
  );
  String get feedbackValidationDescRequired => tr(
    'Mohon tuliskan deskripsi masukan Anda',
    'Please enter a description',
    'कृपया अपना विवरण लिखें',
  );

  // ── 17. PERSONALIZED RECOMMENDATIONS ("BECAUSE YOU WATCHED...") ──
  String homeBecauseYouWatched(String title) => tr(
    'Karena Anda Menonton $title',
    'Because You Watched $title',
    'क्योंकि आपने $title देखा',
  );
  String homeBecauseYouSaved(String title) => tr(
    'Karena Anda Menyimpan $title',
    'Because You Saved $title',
    'क्योंकि आपने $title सहेजा',
  );
  String get homePersonalizedBadge => tr(
    'REKOMENDASI PERSONAL',
    'FOR YOU',
    'आपके लिए विशेष',
  );

  // ── 18. CINEVA INSIGHTS / WRAPPED & KTP / ATM MEMBER CARD ──
  String get settingsAccountSection =>
      tr('Akun', 'Account', 'खाता');
  String get settingsAccountProfileDesc => tr(
    'Ubah profil & avatar',
    'Edit profile & avatar',
    'प्रोफ़ाइल और अवतार संपादित करें',
  );
  String get settingsAccountViewStatsTitle => tr(
    'Statistik Tontonan',
    'View Stats',
    'देखने के आँकड़े',
  );
  String get settingsAccountViewStatsDesc => tr(
    'Ringkasan aktivitas menonton & kartu member',
    'Watch activity summary & member card',
    'देखने की गतिविधि का सारांश और मेंबर कार्ड',
  );
  String get settingsAccountQrScanTitle => tr(
    'Pindai QR TV / Windows',
    'QR Scan',
    'QR स्कैन',
  );
  String get settingsAccountQrScanDesc => tr(
    'Tautkan akun ke Android TV atau Windows',
    'Link account to Android TV or Windows',
    'Android TV या Windows से खाता लिंक करें',
  );
  String get insightsScreenTitle => tr(
    'Statistik Tontonan',
    'Watch Statistics',
    'देखने के आँकड़े',
  );
  String get insightsScreenSubtitle => tr(
    'Ringkasan aktivitas menonton & kartu identitas member Anda',
    'Your watch activity summary & member identity card',
    'आपकी देखने की गतिविधि और मेंबर पहचान पत्र',
  );
  String get insightsProfileBannerTitle => tr(
    'Statistik Tontonan',
    'View Stats',
    'देखने के आँकड़े',
  );
  String get insightsProfileBannerSubtitle => tr(
    'Lihat total jam menonton & bagikan Kartu Member Anda',
    'View your watch hours & share your Member Card',
    'अपने देखने के घंटे देखें और अपना मेंबर कार्ड साझा करें',
  );
  String get insightsCardModeKtp => tr(
    'Member ID',
    'Member ID',
    'मेंबर ID',
  );
  String get insightsCardModeAtm => tr(
    'Metal Card',
    'Metal Card',
    'मेटल कार्ड',
  );
  String get insightsShareCardBtn => tr(
    'Bagikan Kartu',
    'Share Card',
    'कार्ड साझा करें',
  );
  String get insightsSaveCardBtn => tr(
    'Simpan Gambar',
    'Save Image',
    'छवि सहेजें',
  );
  String get insightsShuffleCaptionBtn => tr(
    'Acak Caption',
    'Shuffle',
    'बदलें',
  );
  String get insightsCopyCaptionBtn => tr(
    'Salin',
    'Copy',
    'कॉपी',
  );
  String get insightsCaptionCopied => tr(
    'Caption berhasil disalin ke clipboard',
    'Caption copied to clipboard',
    'कैप्शन क्लिपबोर्ड पर कॉपी हो गया',
  );
  String get insightsCardSaved => tr(
    'Kartu Member berhasil disimpan',
    'Member Card saved successfully',
    'मेंबर कार्ड सफलतापूर्वक सहेजा गया',
  );
}

