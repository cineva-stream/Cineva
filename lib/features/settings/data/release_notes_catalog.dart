import '../../../../core/localization/app_language.dart';

/// Represents a single version entry in the Cineva Release Notes timeline,
/// containing concise core-feature titles (without long sentences) in
/// Indonesian (`id`), English (`en`), and Hindi (`hi`).
class ReleaseNoteEntry {
  final String version;
  final String dateId;
  final String dateEn;
  final String dateHi;
  final List<String> featuresId;
  final List<String> featuresEn;
  final List<String> featuresHi;

  const ReleaseNoteEntry({
    required this.version,
    required this.dateId,
    required this.dateEn,
    required this.dateHi,
    required this.featuresId,
    required this.featuresEn,
    required this.featuresHi,
  });

  String localizedDate(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.id:
        return dateId;
      case AppLanguage.en:
        return dateEn;
      case AppLanguage.hi:
        return dateHi;
    }
  }

  List<String> localizedFeatures(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.id:
        return featuresId;
      case AppLanguage.en:
        return featuresEn;
      case AppLanguage.hi:
        return featuresHi;
    }
  }
}

/// Curated trilingual catalog of Cineva release notes featuring concise core
/// feature highlights only (no verbose paragraphs).
class ReleaseNotesCatalog {
  ReleaseNotesCatalog._();

  static const List<ReleaseNoteEntry> entries = [
    ReleaseNoteEntry(
      version: '1.2.2',
      dateId: 'Nov 2026',
      dateEn: 'Nov 2026',
      dateHi: 'नवंबर 2026',
      featuresId: [
        'Deteksi pertandingan sepak bola Live via Real-Time EPG',
        'Modal turnamen sepak bola & pemetaan channel akurat',
        'Mesin TV Live DASH-to-HLS Bridge & 75 channel berlogo resmi',
        'Platform Vidio, WeTV & Viu dengan prioritas Preferensi Konten',
        'Halaman baru Preferensi Konten & Cadangan Otomatis lokal',
        'Bookmark Momen Adegan & Studio Kartu Kutipan Sinematik',
        'Bagikan Tayangan (Deep Link & Poster) & Watch Party 1.05x',
        'Layar Pembaruan Wajib & Lini Masa Catatan Rilis 3 bahasa',
      ],
      featuresEn: [
        'Real-Time EPG live football match & broadcaster detection',
        'Tournament-styled live football modal & channel switcher',
        'Live TV DASH-to-HLS fMP4 bridge & 75 verified channel logos',
        'Vidio, WeTV & Viu platforms with Content Preference priority',
        'Dedicated Content Preference page & local Auto Backup',
        'Scene Bookmarks & Cinematic Quote Card Studio',
        'Share Title Deep Link with poster & Watch Party 1.05x sync',
        'Mandatory Update screen & trilingual Release Notes timeline',
      ],
      featuresHi: [
        'रियल-टाइम EPG लाइव फुटबॉल मैच और प्रसारण चैनल पहचान',
        'टूर्नामेंट स्टाइल लाइव फुटबॉल मोडल और चैनल स्विचर',
        'लाइव टीवी DASH-to-HLS ब्रिज और 75 आधिकारिक चैनल लोगो',
        'कंटेंट प्राथमिकता के साथ Vidio, WeTV और Viu प्लेटफ़ॉर्म',
        'नया कंटेंट प्राथमिकता पेज और लोकल ऑटो बैकअप',
        'सीन बुकमार्क और सिनेमाई कोट कार्ड स्टूडियो',
        'पोस्टर डीप-लिंक शेयरिंग और Watch Party 1.05x स्मूथ सिंक',
        'अनिवार्य अपडेट स्क्रीन और 3 भाषाओं में रिलीज़ नोट्स टाइमलाइन',
      ],
    ),
    ReleaseNoteEntry(
      version: '1.2.1',
      dateId: 'Nov 2026',
      dateEn: 'Nov 2026',
      dateHi: 'नवंबर 2026',
      featuresId: [
        'Dukungan penuh 3 bahasa (Indonesia, English, Hindi)',
        'Rekomendasi personal "Karena Anda Menonton..."',
        'Cineva Insights & Studio Kartu ID / ATM Member',
        'Bookmark Momen Adegan & Kartu Kutipan Sinematik',
        'Bagikan Tayangan (Deep Link & Poster Otomatis)',
        'Watch Party 1.05x Smooth Micro-Speed Catch-Up',
        '5 katalog regional baru & filter rilis terbaru',
      ],
      featuresEn: [
        'Full trilingual interface (Indonesian, English, Hindi)',
        'Personalized "Because You Watched..." recommendations',
        'Cineva Insights & ID / ATM Member Card Studio',
        'Scene Bookmarks & Cinematic Quote Card',
        'Share Title Deep Link with auto-attached poster',
        'Watch Party 1.05x smooth micro-speed catch-up',
        '5 new regional catalogs & newest-first search filter',
      ],
      featuresHi: [
        '3 भाषाओं का पूर्ण समर्थन (इंडोनेशियाई, अंग्रेजी, हिंदी)',
        '"क्योंकि आपने देखा..." व्यक्तिगत सिफारिशें',
        'Cineva Insights और ID / ATM मेंबर कार्ड स्टूडियो',
        'सीन बुकमार्क और सिनेमाई कोट कार्ड',
        'पोस्टर के साथ शो डीप-लिंक शेयरिंग',
        'Watch Party 1.05x स्मूथ माइक्रो-स्पीड सिंक',
        '5 नए क्षेत्रीय कैटलॉग और नवीनतम खोज फ़िल्टर',
      ],
    ),
    ReleaseNoteEntry(
      version: '1.2.0',
      dateId: 'Nov 2026',
      dateEn: 'Nov 2026',
      dateHi: 'नवंबर 2026',
      featuresId: [
        'Notifikasi chat Watch Party bergaya Dynamic Island',
        'Mini preview 16:9 & indikator waktu pada seekbar',
        'Partikel reaksi emoji melayang real-time',
        'Proteksi PIN 4 digit & deep link ruangan Watch Party',
        'Desain baru halaman Info Aplikasi dengan mosaik poster',
      ],
      featuresEn: [
        'Dynamic Island style Watch Party chat notifications',
        '16:9 seekbar mini preview & floating timecode delta',
        'Real-time floating emoji reaction particles',
        '4-digit Room PIN protection & Watch Party deep links',
        'Redesigned App Info screen with borderless poster mosaic',
      ],
      featuresHi: [
        'Dynamic Island स्टाइल Watch Party चैट नोटिफिकेशन',
        '16:9 सीकबार मिनी प्रीव्यू और टाइमकोड इंडिकेटर',
        'रियल-टाइम फ़्लोटिंग इमोजी रिएक्शन एनिमेशन',
        '4-अंकीय रूम PIN सुरक्षा और Watch Party डीप लिंक',
        'पोस्टर मोज़ेक के साथ नया ऐप जानकारी पेज',
      ],
    ),
    ReleaseNoteEntry(
      version: '1.1.9',
      dateId: 'Okt 2026',
      dateEn: 'Oct 2026',
      dateHi: 'अक्टूबर 2026',
      featuresId: [
        'Lanjutkan menonton lintas perangkat (Device Hand-Off)',
        'Watch Party jarak jauh dengan sinkronisasi otomatis',
        'Panel Live Chat di samping pemutar video',
        'Mesin penerjemah subtitle sinematik alami (NLP)',
        'Sinkronisasi cloud real-time Watchlist & Riwayat',
      ],
      featuresEn: [
        'Cross-device playback continuation (Device Hand-Off)',
        'Remote Watch Party with latency-compensated sync',
        'Side-panel Live Chat inside video player',
        'Natural cinematic subtitle translation engine (NLP)',
        'Real-time cloud sync for Watchlist & Watch History',
      ],
      featuresHi: [
        'क्रॉस-डिवाइस प्लेबैक कंटिन्यूएशन (Device Hand-Off)',
        'ऑटो-सिंक के साथ रिमोट Watch Party',
        'वीडियो प्लेयर के अंदर साइड-पैनल लाइव चैट',
        'प्राकृतिक सिनेमाई सबटाइटल अनुवाद इंजन (NLP)',
        'वॉचलिस्ट और इतिहास के लिए रियल-टाइम क्लाउड सिंक',
      ],
    ),
    ReleaseNoteEntry(
      version: '1.1.8',
      dateId: 'Okt 2026',
      dateEn: 'Oct 2026',
      dateHi: 'अक्टूबर 2026',
      featuresId: [
        'Mesin unduhan offline HLS & perakitan MP4 mandiri',
        'Layout adaptif Tablet, Windows Desktop & Android TV',
        'Navigasi penuh remote D-Pad untuk Android TV',
        'Mode Picture-in-Picture (PiP) & Mini-Player melayang',
        'Skala subtitle otomatis 1080p/4K untuk layar TV',
      ],
      featuresEn: [
        'Offline HLS download engine & standalone MP4 builder',
        'Adaptive layout for Tablet, Windows Desktop & Android TV',
        'Full D-Pad remote navigation for Android TV',
        'Native Picture-in-Picture (PiP) & floating Mini-Player',
        'Automatic 1080p/4K subtitle scaling for TV screens',
      ],
      featuresHi: [
        'ऑफ़लाइन HLS डाउनलोड इंजन और MP4 बिल्डर',
        'टैबलेट, विंडोज डेस्कटॉप और Android TV के लिए अडैप्टिव लेआउट',
        'Android TV के लिए पूर्ण D-Pad रिमोट नेविगेशन',
        'नेटिव Picture-in-Picture (PiP) और फ़्लोटिंग मिनी-प्लेयर',
        'टीवी स्क्रीन के लिए ऑटोमैटिक 1080p/4K सबटाइटल स्केलिंग',
      ],
    ),
    ReleaseNoteEntry(
      version: '1.1.5',
      dateId: 'Sep 2026',
      dateEn: 'Sep 2026',
      dateHi: 'सितंबर 2026',
      featuresId: [
        'Kalender jadwal tayang (Airing Calendar) mingguan',
        'Halaman koleksi franchise & semesta serial TV',
        'Trailer resmi langsung di dalam aplikasi',
        'Penguat volume audio hingga 150% & Sleep Timer',
      ],
      featuresEn: [
        'Weekly Airing Calendar for upcoming releases',
        'Franchise collections & TV Universe hubs',
        'Built-in official trailer player modal',
        'Audio volume booster up to 150% & Sleep Timer',
      ],
      featuresHi: [
        'आगामी रिलीज़ के लिए साप्ताहिक एयरिंग कैलेंडर',
        'फ़्रैंचाइज़ी कलेक्शन और टीवी यूनिवर्स हब',
        'इन-ऐप आधिकारिक ट्रेलर प्लेयर',
        '150% तक ऑडियो वॉल्यूम बूस्टर और स्लीप टाइमर',
      ],
    ),
    ReleaseNoteEntry(
      version: '1.1.0',
      dateId: 'Agu 2026',
      dateEn: 'Aug 2026',
      dateHi: 'अगस्त 2026',
      featuresId: [
        'Multi-server streaming otomatis dengan failover cepat',
        'Kustomisasi ukuran, warna, latar & sinkronisasi subtitle',
        'Cadangkan & pulihkan data Watchlist ke berkas lokal',
        'Pembaruan aplikasi otomatis sesuai arsitektur CPU',
      ],
      featuresEn: [
        'Multi-server smart streaming with instant failover',
        'Custom subtitle size, color, background & time sync',
        'Local file backup & restore for Watchlist and History',
        'In-app auto updater with CPU ABI matching',
      ],
      featuresHi: [
        'त्वरित फ़ेलओवर के साथ मल्टी-सर्वर स्मार्ट स्ट्रीमिंग',
        'सबटाइटल आकार, रंग, बैकग्राउंड और समय सिंक कस्टमाइज़ेशन',
        'वॉचलिस्ट और इतिहास के लिए लोकल फ़ाइल बैकअप और रीस्टोर',
        'CPU आर्किटेक्चर मिलान के साथ इन-ऐप ऑटो अपडेटर',
      ],
    ),
    ReleaseNoteEntry(
      version: '1.0.0',
      dateId: 'Jul 2026',
      dateEn: 'Jul 2026',
      dateHi: 'जुलाई 2026',
      featuresId: [
        'Rilis perdana Cineva untuk Android & Windows Desktop',
        'Katalog film, serial TV, dan saluran Live TV',
        'Pemutar video sinema OLED dengan gestur kecerahan & volume',
        'Pencarian cepat, Watchlist, dan Riwayat Tontonan',
      ],
      featuresEn: [
        'Initial release of Cineva for Android & Windows Desktop',
        'Movies, TV Series, and Live TV channels catalog',
        'OLED cinema video player with brightness & volume gestures',
        'Instant search, Watchlist, and Watch History',
      ],
      featuresHi: [
        'Android और Windows डेस्कटॉप के लिए Cineva की पहली रिलीज़',
        'फ़िल्में, टीवी सीरीज़ और लाइव टीवी चैनल कैटलॉग',
        'ब्राइटनेस और वॉल्यूम जेस्चर के साथ OLED सिनेमा वीडियो प्लेयर',
        'त्वरित खोज, वॉचलिस्ट और देखने का इतिहास',
      ],
    ),
  ];
}
