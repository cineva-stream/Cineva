import 'app_language.dart';

/// Centralized, type-safe multi-language string repository for Cineva.
/// Supports 100% full interface localization between Indonesian and English.
class AppStrings {
  final AppLanguage language;

  const AppStrings(this.language);

  bool get isIndonesian => language == AppLanguage.id;

  // ── Navigation Bar ──
  String get navHome => isIndonesian ? 'Beranda' : 'Home';
  String get navWatchlist => isIndonesian ? 'Watchlist' : 'Watchlist';
  String get navSearch => isIndonesian ? 'Cari' : 'Search';
  String get navHistory => isIndonesian ? 'Riwayat' : 'History';
  String get navSettings => isIndonesian ? 'Pengaturan' : 'Settings';
  String get navDownloads => isIndonesian ? 'Unduhan' : 'Downloads';

  // ── Home Screen ──
  String get homePopularMovies => isIndonesian ? 'Film Populer' : 'Popular Movies';
  String get homePopularTv => isIndonesian ? 'Serial TV Populer' : 'Popular TV Shows';
  String get homeTop10 => isIndonesian ? 'Top 10 Hari Ini' : 'Top 10 Today';
  String get homeTrending => isIndonesian ? 'Sedang Tren' : 'Trending Now';
  String get homeContinueWatching => isIndonesian ? 'Lanjutkan Menonton' : 'Continue Watching';
  String get homeSeeAll => isIndonesian ? 'Lihat Semua' : 'See All';
  String get homeWatchNow => isIndonesian ? 'Tonton Sekarang' : 'Watch Now';
  String get homeDetail => isIndonesian ? 'Detail' : 'Details';
  String get homeAllCategory => isIndonesian ? 'Semua' : 'All';

  // ── Search & Discover Screen ──
  String get searchTitle => isIndonesian ? 'Cari' : 'Search';
  String searchPriority(String label) => isIndonesian ? 'Prioritas $label' : 'Priority $label';
  String get searchHint => isIndonesian ? 'Cari film atau serial TV...' : 'Search movies or TV shows...';
  String get searchGenres => isIndonesian ? 'Kategori & Genre' : 'Categories & Genres';
  String get searchResults => isIndonesian ? 'Hasil Pencarian' : 'Search Results';
  String get searchTabMovies => isIndonesian ? 'Film' : 'Movies';
  String get searchTabTv => isIndonesian ? 'Serial TV' : 'TV Shows';
  String searchNoMovies(String q) => isIndonesian ? 'Tidak ada film ditemukan untuk "$q"' : 'No movies found for "$q"';
  String searchNoTv(String q) => isIndonesian ? 'Tidak ada serial TV ditemukan untuk "$q"' : 'No TV shows found for "$q"';
  String get searchFailed => isIndonesian ? 'Pencarian gagal' : 'Search failed';
  String get searchHistory => isIndonesian ? 'Riwayat Pencarian' : 'Search History';
  String get searchClearAll => isIndonesian ? 'Hapus Semua' : 'Clear All';
  String get searchTrending => isIndonesian ? 'Trend Pencarian' : 'Trending Searches';
  String get searchTopSearched => isIndonesian ? 'Sering Dicari' : 'Top Searches';
  String get searchTopSearchedSub => isIndonesian ? 'Film & Serial TV terpopuler minggu ini' : 'Most popular movies & TV shows this week';
  String get searchBadgeMovie => isIndonesian ? 'FILM' : 'MOVIE';
  String get searchBadgeTv => isIndonesian ? 'SERIAL' : 'SERIES';
  String searchGenreMovies(String g) => isIndonesian ? 'Film $g' : '$g Movies';
  String searchGenreTv(String g) => isIndonesian ? 'Serial TV $g' : '$g TV Shows';
  String searchNoGenreMovies(String g) => isIndonesian ? 'Belum ada film untuk genre $g' : 'No movies available for genre $g';
  String searchNoGenreTv(String g) => isIndonesian ? 'Belum ada serial TV untuk genre $g' : 'No TV shows available for genre $g';
  String get searchGenreErrorMovies => isIndonesian ? 'Gagal memuat film genre' : 'Failed to load movies';
  String get searchGenreErrorTv => isIndonesian ? 'Gagal memuat serial TV genre' : 'Failed to load TV shows';

  // ── Detail Screen ──
  String get detailWatchNow => isIndonesian ? 'Tonton Sekarang' : 'Watch Now';
  String detailWatchTv(int season, int episode) => isIndonesian ? 'Tonton S$season : E$episode' : 'Watch S$season : E$episode';
  String get detailTrailer => isIndonesian ? 'Trailer' : 'Trailer';
  String get detailDownload => isIndonesian ? 'Unduh' : 'Download';
  String get detailDownloadMovie => isIndonesian ? 'Unduh Film' : 'Download Movie';
  String detailDownloadEpisode(int ep) => isIndonesian ? 'Unduh Episode $ep' : 'Download Episode $ep';
  String get detailWatchlistAdd => isIndonesian ? 'Simpan' : 'Watchlist';
  String get detailWatchlistAdded => isIndonesian ? 'Tersimpan' : 'Saved';
  String get detailWatchlistAddTooltip => isIndonesian ? 'Tambahkan ke Watchlist' : 'Add to Watchlist';
  String get detailWatchlistRemoveTooltip => isIndonesian ? 'Hapus dari Watchlist' : 'Remove from Watchlist';
  String get detailAddedToWatchlist => isIndonesian ? 'Ditambahkan ke Watchlist' : 'Added to Watchlist';
  String get detailRemovedFromWatchlist => isIndonesian ? 'Dihapus dari Watchlist' : 'Removed from Watchlist';
  String get detailSynopsis => isIndonesian ? 'Sinopsis' : 'Synopsis';
  String get detailNoSynopsis => isIndonesian ? 'Belum ada sinopsis.' : 'No synopsis available.';
  String get detailCast => isIndonesian ? 'Pemeran' : 'Cast';
  String get detailSeasons => isIndonesian ? 'Musim & Episode' : 'Seasons & Episodes';
  String get detailSelectEpisode => isIndonesian ? 'Pilih Episode' : 'Select Episode';
  String get detailSeason => isIndonesian ? 'Musim' : 'Season';
  String get detailEpisode => isIndonesian ? 'Episode' : 'Episode';
  String detailSeasonEpisodes(int seasons, int episodes) => isIndonesian
      ? '$seasons Season • $episodes Episode'
      : '$seasons Season${seasons > 1 ? "s" : ""} • $episodes Episode${episodes > 1 ? "s" : ""}';
  String get detailEpisodesUnavailable => isIndonesian ? 'Daftar episode tidak tersedia saat ini.' : 'Episode list is currently unavailable.';
  String detailNoEpisodesInSeason(int s) => isIndonesian ? 'Belum ada episode di Season $s' : 'No episodes in Season $s yet';
  String get detailSimilarMovies => isIndonesian ? 'Film Serupa' : 'More Like This';
  String get detailFailed => isIndonesian ? 'Gagal memuat detail' : 'Failed to load details';
  String get detailRetry => isIndonesian ? 'Coba Lagi' : 'Retry';
  String get detailRating => isIndonesian ? 'Rating' : 'Rating';
  String get detailDuration => isIndonesian ? 'Durasi' : 'Duration';
  String get detailReleaseDate => isIndonesian ? 'Rilis' : 'Release';

  // ── Watchlist Screen ──
  String get watchlistTitle => isIndonesian ? 'Watchlist' : 'Watchlist';
  String get watchlistEmptyTitle => isIndonesian ? 'Watchlist Kosong' : 'Watchlist is Empty';
  String get watchlistEmptyDesc => isIndonesian
      ? 'Film dan serial TV yang kamu simpan\nakan muncul di sini'
      : 'Movies and TV shows you save\nwill appear here';
  String get watchlistExploreButton => isIndonesian ? 'Jelajahi Film' : 'Explore Movies';

  // ── History Screen ──
  String get historyTitle => isIndonesian ? 'Riwayat Tontonan' : 'Watch History';
  String get historyFilterAll => isIndonesian ? 'Semua' : 'All';
  String get historyFilterInProgress => isIndonesian ? 'Sedang Ditonton' : 'In Progress';
  String get historyFilterCompleted => isIndonesian ? 'Selesai' : 'Completed';
  String get historyCompletedBadge => isIndonesian ? 'Selesai ditonton' : 'Completed';
  String get historyClearConfirmTitle => isIndonesian ? 'Hapus Semua Riwayat?' : 'Clear All History?';
  String get historyClearConfirmDesc => isIndonesian
      ? 'Semua catatan tontonan dan titik akhir pemutaran akan dihapus secara permanen.'
      : 'All watch records and resume checkpoints will be permanently deleted.';
  String get historyClearedSuccess => isIndonesian ? 'Riwayat tontonan berhasil dibersihkan' : 'Watch history cleared successfully';
  String get historyEmptyTitle => isIndonesian ? 'Belum Ada Riwayat Tontonan' : 'No Watch History Yet';
  String get historyEmptyDesc => isIndonesian
      ? 'Film dan serial yang Anda putar akan otomatis tercatat di sini sehingga Anda dapat melanjutkannya kapan saja.'
      : 'Movies and shows you watch will appear here so you can easily resume anytime.';
  String get historyExplore => isIndonesian ? 'Jelajahi Film' : 'Explore Movies';
  String get historyDeleteTooltip => isIndonesian ? 'Hapus dari riwayat' : 'Remove from history';

  // ── Downloads Screen ──
  String get downloadTitle => isIndonesian ? 'Unduhan Offline' : 'Offline Downloads';
  String get downloadTabInProgress => isIndonesian ? 'Sedang Diunduh' : 'Downloading';
  String get downloadTabCompleted => isIndonesian ? 'Tersimpan Offline' : 'Saved Offline';
  String get downloadEmptyInProgress => isIndonesian ? 'Tidak ada unduhan aktif' : 'No active downloads';
  String get downloadEmptyCompleted => isIndonesian ? 'Belum ada media tersimpan' : 'No saved offline media';

  // ── Player Screen ──
  String get playerNextEpisode => isIndonesian ? 'Episode Berikutnya' : 'Next Episode';
  String playerNextEpisodePill(int ep) => isIndonesian ? 'Episode $ep Berikutnya' : 'Next: Episode $ep';
  String get playerSubSettings => isIndonesian ? 'Atur Subtitle' : 'Subtitle Settings';
  String get playerQuality => isIndonesian ? 'Kualitas' : 'Quality';
  String get playerSpeed => isIndonesian ? 'Kecepatan' : 'Speed';
  String get playerAudio => isIndonesian ? 'Audio' : 'Audio';
  String get playerBuffering => isIndonesian ? 'Memuat video...' : 'Buffering video...';
  String get playerConnecting => isIndonesian ? 'Menghubungkan ke stream...' : 'Connecting to stream...';
  String get playerSearchingStream => isIndonesian ? 'Mencari stream berkecepatan tinggi...' : 'Searching for high-speed stream...';
  String get playerConnectingStream => isIndonesian ? 'Menghubungkan stream video & audio...' : 'Connecting video & audio stream...';
  String get playerPreparingFastBuffer => isIndonesian ? 'Menyiapkan pemutaran cepat (buffer 7 detik)...' : 'Preparing fast playback (7s buffer)...';
  String get playerPreparingBackup => isIndonesian ? 'Menyiapkan pemutar cadangan...' : 'Preparing backup player...';
  String get playerPreparingOffline => isIndonesian ? 'Menyiapkan pemutaran offline...' : 'Preparing offline playback...';
  String get playerPreparingMp4 => isIndonesian ? 'Menyiapkan video MP4...' : 'Preparing MP4 video...';
  String playerPreparingEpisode(int ep) => isIndonesian ? 'Menyiapkan Episode $ep...' : 'Preparing Episode $ep...';

  String get playerQualityTitle => isIndonesian ? 'Kualitas Video' : 'Video Quality';
  String get playerQualityAutoAdaptive => isIndonesian ? 'Auto (Adaptif FHD)' : 'Auto (Adaptive FHD)';
  String get playerQualityClear => isIndonesian ? 'Jernih' : 'Clear';
  String get playerQualityStandard => isIndonesian ? 'Standar' : 'Standard';
  String get playerQualityDataSaver => isIndonesian ? 'Hemat Kuota' : 'Data Saver';
  String get playerQualityLow => isIndonesian ? 'Rendah' : 'Low';

  String get playerServerTitle => isIndonesian ? 'Server Streaming' : 'Streaming Server';
  String get playerServerDesc => isIndonesian
      ? 'Ganti server jika tayangan lambat, buffering, atau tidak dapat diputar'
      : 'Switch server if stream is buffering, slow, or fails to play';
  String playerServerSwitched(String name) => isIndonesian
      ? 'Beralih ke $name'
      : 'Switched to $name';
  String playerAutoSwitched(String name) => isIndonesian
      ? 'Otomatis dialihkan ke $name'
      : 'Auto-switched to $name';

  String get playerVolumeTitle => isIndonesian ? 'Volume & Pengeras Suara' : 'Volume & Sound Boost';
  String get playerAudioBoost => 'Audio Boost';
  String get playerVolumeMute => 'Mute';

  String get playerSubtitleTrack => isIndonesian ? 'Pilih Subtitle' : 'Select Subtitle';
  String get playerDisableSubtitle => isIndonesian ? 'Matikan Subtitle' : 'Disable Subtitles';
  String get playerNoSubtitleFound => isIndonesian ? 'Tidak ada subtitle ditemukan' : 'No subtitles found';
  String playerFailedDownloadSub(String lang) => isIndonesian ? 'Gagal mengunduh subtitle $lang' : 'Failed to download $lang subtitle';
  String playerTranslatingTo(String lang) => isIndonesian ? 'Menerjemahkan ke $lang...' : 'Translating to $lang...';
  String playerTranslateActive(String code) => isIndonesian ? 'Terjemahan $code Aktif ✓' : '$code Translation Active ✓';
  String playerTranslateTo(String lang) => isIndonesian ? 'Terjemahkan ke $lang' : 'Translate to $lang';

  String get playerSubSettingsTitle => isIndonesian ? 'Pengaturan Subtitle' : 'Subtitle Settings';
  String get playerTabSync => isIndonesian ? 'Waktu (Sync)' : 'Timing (Sync)';
  String get playerTabAppearance => isIndonesian ? 'Tampilan & Background' : 'Appearance & Background';
  String get playerSyncOnTime => isIndonesian ? 'Tepat Waktu (0.00s)' : 'On Time (0.00s)';
  String get playerSyncDefault => isIndonesian ? 'Sinkronisasi default' : 'Default synchronization';
  String get playerSyncDelayed => isIndonesian ? 'Subtitle ditunda (lebih lambat)' : 'Subtitle delayed (slower)';
  String get playerSyncAdvanced => isIndonesian ? 'Subtitle dimajukan (lebih cepat)' : 'Subtitle advanced (faster)';
  String get playerReset => isIndonesian ? 'Reset' : 'Reset';

  String get playerSubBackground => isIndonesian ? 'Background Subtitle:' : 'Subtitle Background:';
  String get playerBgTransparent => isIndonesian ? 'Transparan' : 'Transparent';
  String get playerBgDark => isIndonesian ? 'Gelap' : 'Dark';
  String get playerBgSolid => isIndonesian ? 'Solid' : 'Solid';
  String get playerBgOpacity => isIndonesian ? 'Opasitas BG:' : 'BG Opacity:';
  String get playerFontSize => isIndonesian ? 'Ukuran:' : 'Size:';
  String get playerStrokeWidth => isIndonesian ? 'Stroke Out:' : 'Outline Stroke:';
  String get playerSubPosition => isIndonesian ? 'Posisi:' : 'Position:';
  String get playerSubColor => isIndonesian ? 'Warna:' : 'Color:';

  String playerSubActiveToast(String lang) => isIndonesian ? 'Subtitle $lang aktif' : '$lang subtitle active';
  String playerSubAutoTranslatedToast(String lang) => isIndonesian ? 'Subtitle otomatis diterjemahkan ke $lang' : 'Subtitle auto-translated to $lang';

  String get playerOfflineFailedTitle => isIndonesian ? 'Gagal Memutar Offline' : 'Offline Playback Failed';
  String get playerOfflineFailedDesc => isIndonesian ? 'Terjadi kendala saat memutar file lokal.\nPastikan proses unduhan telah selesai 100%.' : 'An error occurred while playing local file.\nMake sure download has reached 100%.';
  String get playerBackToDownloads => isIndonesian ? 'Kembali ke Unduhan' : 'Back to Downloads';
  String get playerDownloadNotFound => isIndonesian ? 'File unduhan tidak ditemukan di penyimpanan perangkat. Silakan unduh ulang.' : 'Downloaded file not found on device storage. Please download again.';

  String get playerError => isIndonesian ? 'Gagal memutar video' : 'Failed to play video';
  String get playerRetry => isIndonesian ? 'Coba Lagi' : 'Retry';
  String get playerSubActive => isIndonesian ? 'Subtitle aktif' : 'Subtitle active';
  String get playerSubAutoTranslated => isIndonesian ? 'Subtitle otomatis diterjemahkan' : 'Subtitle auto-translated';
  String get playerSubNotFound => isIndonesian ? 'Subtitle tidak ditemukan' : 'No subtitles found';
  String get playerAudioTrack => isIndonesian ? 'Trek Audio' : 'Audio Track';
  String get downloadModalConnecting => isIndonesian ? 'Menghubungkan stream & menghitung ukuran...' : 'Connecting stream & calculating sizes...';
  String get downloadModalSelectResolution => isIndonesian ? 'Pilih Resolusi Video' : 'Select Video Resolution';
  String get downloadModalSelectResolutionDesc => isIndonesian ? 'Pilih kualitas video sesuai ruang penyimpanan perangkat Anda' : 'Choose video quality based on your device storage';
  String get downloadModalSelectSubtitle => isIndonesian ? 'Pilih Subtitle' : 'Select Subtitle';
  String downloadModalSelectedQuality(String label, String size) => isIndonesian ? 'Kualitas terpilih: $label ($size)' : 'Selected quality: $label ($size)';
  String get downloadModalIndonesianPriority => isIndonesian ? 'Bahasa Indonesia (Prioritas)' : 'Indonesian (Priority)';
  String get downloadModalIndonesianPriorityDesc => isIndonesian
      ? 'Otomatis unduh teks Indonesia. Jika belum ada, sistem mengunduh teks English ke cache lalu otomatis menerjemahkannya secara gratis.'
      : 'Automatically download Indonesian subtitles. If unavailable, the system downloads English subtitles and auto-translates them for free.';
  String get downloadModalEnglishSub => isIndonesian ? 'English Subtitle' : 'English Subtitle';
  String get downloadModalEnglishSubDesc => isIndonesian ? 'Unduh teks subtitle resmi Bahasa Inggris asli.' : 'Download official English subtitles.';
  String get downloadModalNoSub => isIndonesian ? 'Tanpa Subtitle' : 'No Subtitle';
  String get downloadModalNoSubDesc => isIndonesian ? 'Hanya mengunduh file video saja tanpa file subtitle terpisah.' : 'Download video only without separate subtitle.';
  String get downloadModalStorageLocation => isIndonesian ? 'Lokasi Penyimpanan:' : 'Storage Location:';
  String get downloadModalStartDownload => isIndonesian ? 'Mulai Mengunduh' : 'Start Download';
  String get downloadModalStartedToast => isIndonesian ? 'Unduhan dimulai! Ketuk ikon Unduhan di AppBar untuk melihat proses.' : 'Download started! Tap the Downloads icon in the AppBar to view progress.';
  String get downloadModalViewToast => isIndonesian ? 'Lihat' : 'View';
  String get downloadModalNextSub => isIndonesian ? 'Lanjut: Pilih Subtitle' : 'Next: Select Subtitle';
  String get downloadModalMovie => isIndonesian ? 'Film' : 'Movie';
  String get downloadModalTv => isIndonesian ? 'Serial TV' : 'TV Series';

  // ── Settings Screen ──
  String get settingsTitle => isIndonesian ? 'Pengaturan' : 'Settings';
  String get settingsGeneralSection => isIndonesian ? 'Preferensi Umum' : 'General Preferences';
  String get settingsAppLanguage => isIndonesian ? 'Bahasa Aplikasi' : 'App Language';
  String get settingsAppLanguageDesc => isIndonesian ? 'Pilih bahasa antarmuka aplikasi' : 'Choose app interface language';
  String get settingsContentPref => isIndonesian ? 'Preferensi Konten' : 'Content Preference';
  String get settingsContentPrefDesc => isIndonesian ? 'Prioritas katalog di Beranda & Pencarian' : 'Catalog priority in Home & Search';
  String get settingsVideoSection => isIndonesian ? 'Pemutaran & Video' : 'Playback & Video';
  String get settingsDefaultQuality => isIndonesian ? 'Kualitas Streaming Default' : 'Default Streaming Quality';
  String get settingsHwAccel => isIndonesian ? 'Akselerasi Perangkat Keras' : 'Hardware Acceleration';
  String get settingsHwAccelDesc => isIndonesian ? 'Gunakan GPU decoder untuk pemutaran video 60fps tanpa patah-patah' : 'Use GPU decoder for smooth 60fps playback';
  String get settingsWifiOnly => isIndonesian ? 'Streaming Hemat Kuota (Wi-Fi Saja)' : 'Data Saver Streaming (Wi-Fi Only)';
  String get settingsWifiOnlyDesc => isIndonesian ? 'Mencegah buffering torrent berukuran besar di jaringan seluler' : 'Prevent large torrent buffering on mobile data';
  String get settingsSubSection => isIndonesian ? 'Subtitle & Bahasa' : 'Subtitles & Language';
  String get settingsSubLanguage => isIndonesian ? 'Bahasa Subtitle Utama' : 'Primary Subtitle Language';
  String settingsAutoTranslateTo(String langName) => isIndonesian
      ? 'Auto-Terjemah ke $langName'
      : 'Auto-Translate to $langName';
  String get settingsAutoTranslateDesc => isIndonesian
      ? 'Otomatis terjemahkan subtitle asing ke bahasa pilihan jika tidak ada subtitle asli'
      : 'Automatically translate foreign subtitles to preferred language if native is unavailable';
  String get settingsSubFontSize => isIndonesian ? 'Ukuran Huruf Subtitle' : 'Subtitle Font Size';
  String get settingsSubBg => isIndonesian ? 'Latar Belakang Subtitle' : 'Subtitle Background';
  String get settingsStorageSection => isIndonesian ? 'Penyimpanan & Riwayat' : 'Storage & History';
  String get settingsClearCache => isIndonesian ? 'Bersihkan Cache' : 'Clear Cache';
  String get settingsClearCacheDesc => isIndonesian ? 'Hapus file poster sementara dan buffering' : 'Remove temporary posters and buffering cache';
  String get settingsClearHistory => isIndonesian ? 'Hapus Riwayat Tontonan' : 'Clear Watch History';
  String get settingsClearHistoryDesc => isIndonesian ? 'Semua daftar tontonan akan dihapus secara permanen' : 'Permanently remove all watch history records';
  String get settingsSearchLanguage => isIndonesian ? 'Cari bahasa...' : 'Search language...';
  String get settingsNoLanguageFound => isIndonesian ? 'Bahasa tidak ditemukan' : 'No language found';
  String get settingsVersion => isIndonesian ? 'Versi' : 'Version';
  String get settingsAboutSection => isIndonesian ? 'Tentang & Lisensi' : 'About & Licenses';
  String get settingsPrivacyPolicyTitle => isIndonesian ? 'Kebijakan Privasi' : 'Privacy Policy';
  String get settingsPrivacyPolicySubtitle => isIndonesian
      ? 'Transparansi perlindungan data pribadi dan privasi pengguna'
      : 'Personal data protection transparency and user privacy';
  String get settingsTermsTitle => isIndonesian ? 'Syarat dan Ketentuan' : 'Terms and Conditions';
  String get settingsTermsSubtitle => isIndonesian
      ? 'Ketentuan penggunaan, lisensi piranti lunak, dan batasan layanan'
      : 'Terms of use, software license, and service limitations';
  String get settingsDisclaimerTitle => isIndonesian ? 'Disclaimer & Hak Cipta' : 'Disclaimer & Copyright';
  String get settingsDisclaimerMenuTitle => 'Disclaimer';
  String get settingsDisclaimerSubtitle => isIndonesian
      ? 'Informasi hukum penggunaan layanan streaming P2P'
      : 'Legal information regarding P2P streaming services';
  String get settingsInfoTitle => isIndonesian ? 'Info' : 'Info';
  String get settingsInfoSubtitle => isIndonesian
      ? 'Tentang Cineva, arsitektur teknologi, dan versi aplikasi'
      : 'About Cineva, technology architecture, and app version';
  String get settingsDisclaimerDialogTitle => isIndonesian ? 'Disclaimer Hukum' : 'Legal Disclaimer';
  String get settingsDisclaimerContent => isIndonesian
      ? 'Cineva adalah pemutar media berbasis P2P terdesentralisasi yang mengakses konten publik yang tersedia di internet. Pengguna bertanggung jawab penuh atas media yang diakses sesuai peraturan perundang-undangan yang berlaku.'
      : 'Cineva is a decentralized P2P media player that accesses publicly available content on the internet. Users are fully responsible for the media accessed in compliance with applicable local laws.';

  // ── Legal & About Screens ──
  String get legalLastUpdated => isIndonesian ? 'Pembaruan Terakhir: Oktober 2026' : 'Last Updated: October 2026';
  String get legalNoticeBadge => isIndonesian ? 'PEMBERITAHUAN HUKUM RESMI' : 'OFFICIAL LEGAL NOTICE';
  String get legalJurisdictionNotice => isIndonesian
      ? 'Ketentuan ini berlaku mengikat bagi seluruh pengguna di seluruh yurisdiksi dunia.'
      : 'These terms are legally binding for all users across worldwide jurisdictions.';
  String get aboutTagline => isIndonesian ? 'Modern Decentralized Media Player' : 'Modern Decentralized Media Player';
  String get aboutBuildType => isIndonesian ? 'Edisi Publik Gratis' : 'Public Free Edition';
  String get aboutDescription => isIndonesian
      ? 'Cineva adalah pemutar media terdesentralisasi generasi baru yang dirancang untuk menghadirkan pengalaman visual sinematik tanpa hambatan. Dengan memanfaatkan arsitektur streaming P2P cerdas dan mesin akselerasi pemutaran modern, Cineva memungkinkan penjelajahan katalog media publik global dengan kecepatan tinggi, antarmuka elegan, dan dukungan multi-bahasa lengkap tanpa biaya langganan dan tanpa pelacakan data pribadi.'
      : 'Cineva is a next-generation decentralized media player crafted to deliver cinema-grade viewing experiences without friction. Harnessing an intelligent P2P streaming architecture and modern hardware-accelerated playback engine, Cineva enables high-speed exploration of publicly indexed global media with an exquisite user interface, comprehensive world subtitles, zero subscription costs, and complete personal privacy.';
  String get aboutFeatureP2PTitle => isIndonesian ? 'Streaming P2P Cerdas' : 'Smart P2P Streaming Engine';
  String get aboutFeatureP2PDesc => isIndonesian
      ? 'Teknologi streaming terdistribusi yang efisien tanpa ketergantungan pada server pusat tunggal.'
      : 'Efficient distributed streaming technology with zero reliance on single centralized servers.';
  String get aboutFeatureHwTitle => isIndonesian ? 'Akselerasi Perangkat Keras' : 'Hardware Acceleration';
  String get aboutFeatureHwDesc => isIndonesian
      ? 'Didukung oleh mesin pemutar MediaKit/MPV dengan decoding GPU hemat daya hingga resolusi 4K Ultra HD.'
      : 'Powered by MediaKit/MPV engine with power-efficient GPU decoding up to 4K Ultra HD.';
  String get aboutFeatureSubTitle => isIndonesian ? 'Katalog 65+ Bahasa Subtitle' : '65+ World Subtitle Languages';
  String get aboutFeatureSubDesc => isIndonesian
      ? 'Pencarian subtitle otomatis dengan dukungan terjemahan instan ke bahasa pilihan Anda.'
      : 'Automated subtitle discovery with instant translation fallback to your preferred language.';
  String get aboutFeatureDownloadTitle => isIndonesian ? 'Manajer Unduhan Offline' : 'Offline Download Manager';
  String get aboutFeatureDownloadDesc => isIndonesian
      ? 'Simpan tayangan favorit Anda langsung ke penyimpanan perangkat untuk dinikmati kapan saja tanpa internet.'
      : 'Save your favorite media directly to device storage to enjoy anytime without an internet connection.';
  String get aboutFeatureFreeTitle => isIndonesian ? 'Non-Profit & Bebas Iklan' : 'Non-Profit & Zero Ads';
  String get aboutFeatureFreeDesc => isIndonesian
      ? 'Proyek utilitas piranti lunak terbuka tanpa komersialisasi, tanpa iklan mengganggu, dan tanpa registrasi.'
      : 'Open software utility project with zero commercial monetization, no intrusive ads, and no registration required.';
  String get aboutCreditsTitle => isIndonesian ? 'Ekosistem & Kontributor Terbuka' : 'Open Ecosystem & Acknowledgements';
  String get aboutCreditsDesc => isIndonesian
      ? 'Cineva dibangun dengan rasa hormat mendalam kepada ekosistem open-source dan API publik dunia: Flutter, MediaKit, Riverpod, The Movie Database (TMDB), OpenSubtitles, Hive, dan komunitas Torrentio.'
      : 'Cineva is crafted with deep gratitude to the worldwide open-source ecosystem and public APIs: Flutter, MediaKit, Riverpod, The Movie Database (TMDB), OpenSubtitles, Hive, and the Torrentio community.';

  // ── Dialogs & Actions ──
  String get dialogExitTitle => isIndonesian ? 'Konfirmasi Keluar' : 'Exit Confirmation';
  String get dialogExitMessage => isIndonesian ? 'Apakah Anda yakin ingin keluar dari Cineva?' : 'Are you sure you want to exit Cineva?';
  String get dialogCancel => isIndonesian ? 'Batal' : 'Cancel';
  String get dialogUnderstood => isIndonesian ? 'Mengerti' : 'Understood';
  String get dialogExit => isIndonesian ? 'Keluar' : 'Exit';
  String get dialogConfirm => isIndonesian ? 'Konfirmasi' : 'Confirm';
  String get dialogClear => isIndonesian ? 'Bersihkan' : 'Clear';
  String get dialogDelete => isIndonesian ? 'Hapus' : 'Delete';
  String get dialogCacheCleaned => isIndonesian ? 'Cache berhasil dibersihkan' : 'Cache cleared successfully';
  String get dialogHistoryCleared => isIndonesian ? 'Riwayat tontonan berhasil dihapus' : 'Watch history cleared successfully';

  // ── Library / History / Downloads ──
  String get libraryTitle => isIndonesian ? 'Koleksi & Riwayat' : 'Library & History';
  String get libraryTabHistory => isIndonesian ? 'Riwayat Tontonan' : 'Watch History';
  String get libraryTabDownloads => isIndonesian ? 'Unduhan Offline' : 'Offline Downloads';
  String get libraryEmptyHistory => isIndonesian ? 'Belum ada riwayat tontonan' : 'No watch history yet';
  String get libraryEmptyHistoryDesc => isIndonesian ? 'Film dan serial TV yang Anda tonton akan otomatis tersimpan di sini' : 'Movies and TV shows you watch will appear here';
  String get libraryEmptyDownloads => isIndonesian ? 'Belum ada film yang diunduh' : 'No downloaded media';
  String get libraryEmptyDownloadsDesc => isIndonesian ? 'Unduh film atau episode serial TV untuk diputar tanpa koneksi internet' : 'Download movies or episodes to enjoy without internet';
  String get libraryResume => isIndonesian ? 'Lanjutkan' : 'Resume';
  String get libraryCompleted => isIndonesian ? 'Selesai' : 'Completed';
  String get libraryDeleteConfirm => isIndonesian ? 'Hapus unduhan ini?' : 'Delete this download?';
}
