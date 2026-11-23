import '../../../core/localization/app_language.dart';

/// Enumeration of supported legal documents in Cineva.
enum LegalDocType {
  privacyPolicy,
  termsAndConditions,
  disclaimer,
}

/// Represents a numbered legal section within a document.
class LegalSection {
  final String number;
  final String title;
  final String body;
  final List<String> bulletPoints;

  const LegalSection({
    required this.number,
    required this.title,
    required this.body,
    this.bulletPoints = const [],
  });
}

/// Full data model for a legal document.
class LegalDocumentData {
  final String title;
  final String subtitle;
  final String lastUpdated;
  final String calloutSummary;
  final List<LegalSection> sections;
  final String concludingNotice;

  const LegalDocumentData({
    required this.title,
    required this.subtitle,
    required this.lastUpdated,
    required this.calloutSummary,
    required this.sections,
    required this.concludingNotice,
  });
}

/// Centralized repository containing full international legal text in Indonesian, English, and Hindi.
class LegalContentRepository {
  /// Nomor versi dokumen legal. Harus sama dengan `LEGAL_VERSION` di cineva-web (lib/legal.ts).
  /// Naikkan setiap kali isi dokumen berubah secara material.
  static const int currentVersion = 2;

  static LegalDocumentData getDocument(
    LegalDocType type,
    bool isIndonesian, [
    AppLanguage? language,
  ]) {
    final lang =
        language ?? (isIndonesian ? AppLanguage.id : AppLanguage.en);
    switch (type) {
      case LegalDocType.privacyPolicy:
        return _getPrivacyPolicy(lang);
      case LegalDocType.termsAndConditions:
        return _getTermsAndConditions(lang);
      case LegalDocType.disclaimer:
        return _getDisclaimer(lang);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. KEBIJAKAN PRIVASI / PRIVACY POLICY
  // ─────────────────────────────────────────────────────────────────────────────
  static LegalDocumentData _getPrivacyPolicy(AppLanguage lang) {
    if (lang.isHindi) {
      return const LegalDocumentData(
        title: 'गोपनीयता नीति',
        subtitle: 'वैश्विक उपयोगकर्ता गोपनीयता और व्यक्तिगत डेटा सुरक्षा ढांचा',
        lastUpdated: '20 नवंबर 2026',
        calloutSummary:
            'Cineva लोकल-फ़र्स्ट और न्यूनतम-डेटा सिद्धांत का पालन करता है: आपका डेटा डिफ़ॉल्ट रूप से आपके डिवाइस पर रहता है और खाते की आवश्यकता नहीं होती है। Google से साइन इन करें, देखना जारी रखें, वॉच पार्टी, फ़ीडबैक भेजें और प्रदर्शन विश्लेषण जैसी वैकल्पिक सुविधाएं इस दस्तावेज़ में वर्णित तृतीय-पक्ष सेवाओं के माध्यम से विशिष्ट डेटा को संसाधित करती हैं। हम आपका व्यक्तिगत डेटा नहीं बेचते हैं।',
        sections: [
          LegalSection(
            number: '1',
            title: 'लोकल-फ़र्स्ट दर्शन: खाता वैकल्पिक और न्यूनतम डेटा',
            body:
                'Cineva का उपयोग खाता, ईमेल पता या फ़ोन नंबर पंजीकृत किए बिना किया जा सकता है। डिफ़ॉल्ट रूप से, आपका डेटा आपके डिवाइस पर ही रहता है। कुछ वैकल्पिक सुविधाओं (धारा 3 से 5 में वर्णित) के लिए तृतीय-पक्ष सेवाओं के माध्यम से डेटा प्रसंस्करण की आवश्यकता होती है। हम केवल उन सुविधाओं को चलाने और ऐप की गुणवत्ता बनाए रखने के लिए आवश्यक डेटा को संसाधित करते हैं, और हम आपका व्यक्तिगत डेटा नहीं बेचते हैं।',
          ),
          LegalSection(
            number: '2',
            title: 'स्थानीय डिवाइस स्टोरेज',
            body:
                'उपयोगकर्ता कॉन्फ़िगरेशन, प्राथमिकताएं और गतिविधि डेटा एक एम्बेडेड डेटाबेस (Hive) का उपयोग करके आपके डिवाइस के स्थानीय स्टोरेज में संग्रहीत किए जाते हैं। इसमें शामिल हैं:',
            bulletPoints: [
              'आपकी व्यक्तिगत वॉचलिस्ट में सहेजे गए शीर्षक।',
              'देखने का इतिहास और प्लेबैक प्रगति।',
              'हाल के स्थानीय खोज शब्द।',
              'ऐप दृश्य प्राथमिकताएं: इंटरफ़ेस भाषा, सबटाइटल स्टाइलिंग और स्ट्रीमिंग गुणवत्ता विकल्प।',
              'डाउनलोड मैनेजर के माध्यम से स्थानीय रूप से सहेजी गई मीडिया फ़ाइलें और सबटाइटल।',
            ],
          ),
          LegalSection(
            number: '3',
            title: 'वैकल्पिक क्लाउड सेवाएं: Google से साइन इन करें और देखना जारी रखें',
            body:
                'यदि आप Google से साइन इन करना चुनते हैं, तो Cineva आपको प्रमाणित करने और आपके डिवाइसों में डेटा सिंक करने के लिए Google Sign-In और Firebase (Google LLC) का उपयोग करता है। यह सुविधा पूरी तरह से वैकल्पिक है।',
            bulletPoints: [
              'Google खाता डेटा: ईमेल पता, प्रदर्शन नाम और प्रोफ़ाइल फ़ोटो।',
              'सिंक बैकअप डेटा: आपकी प्रोफ़ाइल, वॉचलिस्ट और देखने का इतिहास Firebase Realtime Database में आपके खाते के विशिष्ट पथ के अंतर्गत संग्रहीत किया जाता है।',
              'क्रॉस-डिवाइस देखना जारी रखें: आप जो शीर्षक देख रहे हैं, प्लेबैक स्थिति और डिवाइस का नाम एक सक्रिय सत्र के रूप में सहेजा जाता है ताकि आप दूसरे डिवाइस पर देखना जारी रख सकें।',
              'आप सेटिंग्स में कभी भी अपना Google खाता डिस्कनेक्ट कर सकते हैं; आपके क्लाउड डेटा को हटाने के लिए cineva.dev@gmail.com पर हमसे संपर्क करें।',
            ],
          ),
          LegalSection(
            number: '4',
            title: 'वॉच पार्टी (Watch Party): बीटा सुविधा',
            body:
                'जब आप वॉच पार्टी रूम बनाते हैं या उसमें शामिल होते हैं, तो निम्नलिखित डेटा सभी रूम प्रतिभागियों के साथ साझा किया जाता है:',
            bulletPoints: [
              'प्रदर्शन नाम, सदस्य आईडी, होस्ट स्थिति और अंतिम सक्रिय समय।',
              'चैट संदेश, इमोजी प्रतिक्रियाएं और सिस्टम संदेश।',
              'देखने की जानकारी: शीर्षक, मीडिया प्रकार, TMDB/IMDb ID, सीज़न और एपिसोड, पोस्टर और प्लेबैक स्थिति (प्ले, पॉज़ और समय)।',
              'रूम कोड (जैसे CNV-8492) और वैकल्पिक 4-अंकीय पिन।',
              'रूम डेटा Firebase Realtime Database (या बैकअप के रूप में ntfy.sh सार्वजनिक रिले) में संग्रहीत किया जाता है।',
              'रूम निष्क्रिय होने या समाप्त होने के बाद रूम डेटा हटा दिया जाता है। चैट में संवेदनशील जानकारी साझा न करें।',
            ],
          ),
          LegalSection(
            number: '5',
            title: 'प्रदर्शन विश्लेषण, फ़ीडबैक और अपडेट जांच',
            body:
                'Cineva विभिन्न डिवाइसों पर ऐप की गुणवत्ता और प्रदर्शन बनाए रखने के लिए कुछ तकनीकी डेटा संसाधित करता है:',
            bulletPoints: [
              'Google Analytics for Firebase: स्थिरता और प्रदर्शन की निगरानी के लिए तकनीकी उपयोग और प्रदर्शन डेटा एकत्र करता है।',
              'फ़ीडबैक भेजें: यदि आप फ़ीडबैक सबमिट करते हैं, तो आपका संदेश, नाम (वैकल्पिक), श्रेणी, डिवाइस जानकारी और ऐप संस्करण डेवलपर को भेजे जाते हैं।',
              'अपडेट जांच: ऐप GitHub से नवीनतम रिलीज़ जानकारी का अनुरोध करता है।',
              'आधिकारिक Cineva वेबसाइट समग्र विज़िट आंकड़ों के लिए Vercel Web Analytics का उपयोग करती है।',
            ],
          ),
          LegalSection(
            number: '6',
            title: 'P2P नेटवर्किंग प्रकृति और IP दृश्यता',
            body:
                'विकेंद्रीकृत पीयर-टू-पीयर (BitTorrent) प्रोटोकॉल का उपयोग करने वाले मीडिया प्लेयर के रूप में:',
            bulletPoints: [
              'P2P नेटवर्क के माध्यम से स्ट्रीमिंग या डाउनलोड करते समय, आपके डिवाइस का सार्वजनिक IP पता स्वार्म पीयर्स को दिखाई दे सकता है। यह वैश्विक स्तर पर P2P नेटवर्किंग की मूल विशेषता है।',
              'Cineva ज़ीरो-लॉग नीति पर काम करता है और आपके IP पते को रिकॉर्ड या संग्रहीत नहीं करता है।',
              'उन्नत नेटवर्क गोपनीयता चाहने वाले उपयोगकर्ताओं को विश्वसनीय तृतीय-पक्ष VPN का उपयोग करने की सलाह दी जाती है।',
            ],
          ),
          LegalSection(
            number: '7',
            title: 'तृतीय-पक्ष सेवाएं और सार्वजनिक API',
            body:
                'सिनेमा पोस्टर, मेटाडेटा और सबटाइटल प्रदर्शित करने के लिए, Cineva सीधे आपके डिवाइस से तृतीय-पक्ष सेवाओं के साथ संचार करता है:',
            bulletPoints: [
              'The Movie Database (TMDB): पोस्टर, रेटिंग, सारांश और शैली मेटाडेटा के लिए।',
              'OpenSubtitles: बहुभाषी सबटाइटल फ़ाइलें खोजने और डाउनलोड करने के लिए।',
              'सार्वजनिक ट्रैकर इंडेक्स (Torrentio): सार्वजनिक मीडिया उपलब्धता के लिए।',
              'Google (Firebase, Analytics, Apps Script), ntfy.sh, Telegram और GitHub।',
            ],
          ),
          LegalSection(
            number: '8',
            title: 'उपयोगकर्ता अधिकार, नियंत्रण और नियामक अनुपालन',
            body:
                'आप सेटिंग्स के माध्यम से कभी भी सभी स्थानीय डेटा हटा सकते हैं और अपना Google खाता डिस्कनेक्ट कर सकते हैं। क्लाउड डेटा हटाने के अनुरोधों के लिए cineva.dev@gmail.com पर संपर्क करें।',
          ),
          LegalSection(
            number: '9',
            title: 'संशोधन और नीति अपडेट',
            body:
                'ऐप के विकसित होने के साथ इस गोपनीयता नीति को समय-समय पर संशोधित किया जा सकता है। अंतिम अपडेट की तिथि इस दस्तावेज़ के शीर्ष पर दिखाई जाती है।',
          ),
        ],
        concludingNotice:
            'यदि आपके पास गोपनीयता के बारे में कोई प्रश्न हैं, तो आप Cineva के ओपन-सोर्स कोड की समीक्षा कर सकते हैं या cineva.dev@gmail.com पर डेवलपर से संपर्क कर सकते हैं।',
      );
    }
    if (lang.isIndonesian) {
      return const LegalDocumentData(
        title: 'Kebijakan Privasi',
        subtitle: 'Prinsip Perlindungan Data Pribadi & Privasi Pengguna Global',
        lastUpdated: '20 November 2026',
        calloutSummary:
            'Cineva menganut prinsip Local-first, data minimal: data Anda disimpan di perangkat secara bawaan dan akun tidak wajib. Fitur opsional seperti Masuk dengan Google, Lanjutkan Menonton, Nonton Bareng, Kirim Masukan, serta analitik performa memproses data tertentu melalui layanan pihak ketiga yang dijelaskan di dokumen ini. Kami tidak menjual data pribadi Anda.',
        sections: [
          LegalSection(
            number: '1',
            title: 'Filosofi Local-First: Akun Tidak Wajib & Data Minimal',
            body:
                'Cineva dapat digunakan tanpa mendaftar akun, tanpa alamat surel, dan tanpa nomor telepon. Secara bawaan, data Anda hanya tersimpan di perangkat. Beberapa fitur opsional (dijelaskan pada pasal 3 sampai 5) memerlukan pemrosesan data melalui layanan pihak ketiga. Kami hanya memproses data yang diperlukan untuk menjalankan fitur dan menjaga kualitas aplikasi, dan kami tidak menjual data pribadi Anda.',
          ),
          LegalSection(
            number: '2',
            title: 'Penyimpanan Data Lokal di Perangkat Pengguna',
            body:
                'Preferensi konfigurasi dan data interaksi pengguna disimpan pada penyimpanan lokal perangkat Anda menggunakan basis data tertanam (Hive). Data yang tersimpan meliputi:',
            bulletPoints: [
              'Daftar film dan serial yang Anda simpan ke dalam Watchlist.',
              'Riwayat tontonan dan posisi pemutaran terakhir (resume position).',
              'Riwayat kata kunci pencarian lokal.',
              'Preferensi tampilan: bahasa aplikasi, ukuran dan latar subtitle, serta preferensi kualitas pemutaran.',
              'File film dan subtitle yang Anda unduh melalui Manajer Unduhan.',
            ],
          ),
          LegalSection(
            number: '3',
            title: 'Layanan Cloud Opsional: Masuk dengan Google & Lanjutkan Menonton',
            body:
                'Jika Anda memilih Masuk dengan Google, Cineva menggunakan Google Sign-In dan Firebase (Google LLC) untuk mengautentikasi Anda dan menyinkronkan data antar perangkat. Fitur ini sepenuhnya opsional; Anda tetap dapat memakai Cineva tanpa akun.',
            bulletPoints: [
              'Data akun dari Google: alamat surel, nama tampilan, dan foto profil. Data ini digunakan untuk mengisi profil dan mengidentifikasi akun sinkronisasi Anda.',
              'Data cadangan sinkronisasi: profil, Watchlist, dan riwayat tontonan disimpan di Firebase Realtime Database pada jalur khusus akun Anda dan disinkronkan otomatis di latar belakang.',
              'Lanjutkan Menonton lintas perangkat: judul yang sedang ditonton, posisi pemutaran, serta jenis dan nama perangkat disimpan sebagai sesi aktif agar dapat dilanjutkan di perangkat lain. Sesi dihapus ketika tontonan selesai.',
              'Anda dapat memutuskan akun Google kapan saja melalui Pengaturan; data lokal di perangkat tidak dihapus. Untuk menghapus data cloud Anda, hubungi kami di cineva.dev@gmail.com.',
            ],
          ),
          LegalSection(
            number: '4',
            title: 'Nonton Bareng (Watch Party): Fitur Beta',
            body:
                'Saat Anda membuat atau bergabung ke ruangan Nonton Bareng, data berikut dibagikan kepada seluruh peserta ruangan dan diproses melalui infrastruktur pihak ketiga:',
            bulletPoints: [
              'Nama panggilan, ID anggota (ID akun Firebase jika Anda masuk, atau ID tamu acak), status Host, dan waktu terakhir aktif.',
              'Pesan obrolan, reaksi emoji, serta pesan sistem (misalnya anggota bergabung atau keluar).',
              'Informasi tontonan: judul, jenis media, ID TMDB/IMDb, musim dan episode, poster, serta status pemutaran (play, pause, dan posisi) agar tetap sinkron.',
              'Kode ruangan (contoh CNV-8492) dan PIN 4 digit opsional. PIN hanya membatasi akses ruangan secara sederhana dan bukan mekanisme keamanan tingkat tinggi; siapa pun yang memegang kode dan PIN dapat bergabung dan melihat isi ruangan.',
              'Data ruangan disimpan di Firebase Realtime Database. Jika koneksi Firebase gagal, Cineva otomatis memakai layanan relay publik pihak ketiga (ntfy.sh) sebagai jalur cadangan, sehingga data ruangan dapat melewati dan tersimpan sementara pada layanan tersebut sesuai kebijakan penyedianya.',
              'Data ruangan dirancang untuk dihapus ketika ruangan tidak aktif atau telah berakhir. Mekanisme penghapusan otomatis ini masih disempurnakan selama masa beta, sehingga jangka waktu penyimpanan dapat berubah. Jangan membagikan informasi sensitif di dalam obrolan.',
            ],
          ),
          LegalSection(
            number: '5',
            title: 'Analitik Performa, Kirim Masukan & Pemeriksaan Pembaruan',
            body:
                'Cineva memproses data teknis tertentu untuk menjaga kualitas dan performa aplikasi di berbagai perangkat:',
            bulletPoints: [
              'Google Analytics for Firebase: Cineva mengumpulkan data penggunaan dan performa yang bersifat teknis, seperti pembukaan aplikasi dan tampilan layar, beserta informasi perangkat dan aplikasi (misalnya model perangkat, versi sistem operasi, versi aplikasi, perkiraan wilayah, dan pengenal instalasi aplikasi) untuk memantau stabilitas dan performa. Data ini diproses oleh Google. Pengumpulan analitik aktif secara bawaan dan belum tersedia opsi untuk menonaktifkannya di dalam aplikasi pada versi ini.',
              'Kirim Masukan: jika Anda mengirim masukan, isi pesan, nama (opsional), kategori, informasi perangkat dan sistem operasi, serta versi aplikasi dikirim melalui Google Apps Script kepada pengembang, dicatat di Google Sheets, dan diteruskan ke Telegram. Jangan menyertakan data sensitif dalam masukan.',
              'Pemeriksaan pembaruan: aplikasi meminta informasi rilis terbaru ke GitHub, sehingga alamat IP Anda terlihat oleh GitHub sesuai kebijakan privasi GitHub.',
              'Situs web resmi Cineva menggunakan Vercel Web Analytics dan Speed Insights untuk statistik kunjungan dan performa halaman secara agregat.',
            ],
          ),
          LegalSection(
            number: '6',
            title: 'Karakteristik Jaringan P2P & Alamat Protokol Internet (IP)',
            body:
                'Sebagai pemutar media yang mendukung protokol terdistribusi (Peer-to-Peer / BitTorrent):',
            bulletPoints: [
              'Saat Anda melakukan streaming atau mengunduh konten melalui protokol P2P, alamat IP publik perangkat Anda secara inheren dapat terlihat oleh peers (peserta jaringan) lain dalam kelompok distribusi (swarm). Ini merupakan karakteristik dasar arsitektur P2P di seluruh dunia, bukan tindakan pengumpulan data oleh Cineva.',
              'Cineva sama sekali tidak mencatat (no logs), tidak merekam, dan tidak mengarsipkan alamat IP Anda.',
              'Bagi pengguna yang membutuhkan privasi transmisi jaringan tingkat lanjut, Anda disarankan untuk menggunakan Virtual Private Network (VPN) terenkripsi dari pihak ketiga.',
            ],
          ),
          LegalSection(
            number: '7',
            title: 'Interaksi dengan Layanan & API Pihak Ketiga',
            body:
                'Untuk menampilkan poster sinematik, sinopsis resmi, subtitle, serta menjalankan fitur opsional, Cineva berkomunikasi langsung dari perangkat Anda ke layanan pihak ketiga:',
            bulletPoints: [
              'The Movie Database (TMDB): Digunakan untuk mengambil metadata poster, judul, tahun rilis, dan ringkasan alur cerita.',
              'OpenSubtitles: Digunakan untuk mengunduh berkas teks subtitle multibahasa secara publik.',
              'Indeks Pelacak Publik (Torrentio / Addon Scraper): Digunakan untuk mencocokkan ketersediaan data media terdistribusi.',
              'Google (Firebase Authentication, Realtime Database, Analytics, Apps Script, dan Sheets): untuk Masuk dengan Google, sinkronisasi, Lanjutkan Menonton, Nonton Bareng, analitik, dan Kirim Masukan.',
              'ntfy.sh: relay publik cadangan untuk Nonton Bareng ketika Firebase tidak dapat dijangkau.',
              'Telegram: penerima notifikasi masukan pengguna oleh pengembang.',
              'GitHub: sumber informasi rilis untuk pemeriksaan pembaruan.',
              'Interaksi dengan layanan pihak ketiga ini tunduk pada kebijakan privasi dan ketentuan layanan dari masing-masing penyedia layanan tersebut.',
            ],
          ),
          LegalSection(
            number: '8',
            title: 'Hak & Kontrol Pengguna serta Kepatuhan Regulasi',
            body:
                'Anda dapat menghapus seluruh data lokal kapan saja melalui menu Pengaturan, memutuskan akun Google, dan keluar dari ruangan Nonton Bareng kapan pun. Untuk permintaan akses atau penghapusan data yang tersimpan di layanan cloud (akun, cadangan sinkronisasi, ruangan Nonton Bareng, atau masukan), hubungi kami di cineva.dev@gmail.com. Kami berupaya menyelaraskan praktik data dengan prinsip perlindungan data global seperti General Data Protection Regulation (GDPR) dan California Consumer Privacy Act (CCPA), termasuk prinsip minimalisasi data.',
          ),
          LegalSection(
            number: '9',
            title: 'Pembaruan Dokumen Kebijakan',
            body:
                'Kebijakan Privasi ini dapat diperbarui sewaktu-waktu seiring dengan evolusi fitur aplikasi. Tanggal pembaruan terakhir tercantum di bagian atas dokumen, dan versi terbaru selalu tersedia di dalam aplikasi serta di situs resmi Cineva.',
          ),
        ],
        concludingNotice:
            'Jika Anda memiliki pertanyaan terkait privasi, Anda dapat meninjau kode sumber terbuka Cineva atau menghubungi pengembang di cineva.dev@gmail.com.',
      );
    } else {
      return const LegalDocumentData(
        title: 'Privacy Policy',
        subtitle: 'Global User Privacy & Personal Data Protection Framework',
        lastUpdated: 'November 20, 2026',
        calloutSummary:
            'Cineva follows a Local-first, minimal-data principle: your data stays on your device by default and an account is not required. Optional features such as Sign in with Google, Continue Watching, Watch Party, Send Feedback, and performance analytics process specific data through third-party services described in this document. We do not sell your personal data.',
        sections: [
          LegalSection(
            number: '1',
            title: 'Local-First Philosophy: Account Optional & Minimal Data',
            body:
                'Cineva can be used without registering an account, email address, or phone number. By default, your data stays on your device. Some optional features (described in sections 3 to 5) require data processing through third-party services. We only process data needed to run those features and to maintain app quality, and we do not sell your personal data.',
          ),
          LegalSection(
            number: '2',
            title: 'Local Device Storage',
            body:
                'User configurations, preferences, and activity data are stored in your device\'s local storage using an embedded database (Hive). This includes:',
            bulletPoints: [
              'Titles saved to your personal Watchlist.',
              'Watch history records and playback progress resume markers.',
              'Recent local search queries.',
              'App visual preferences: interface language, subtitle styling, and streaming quality choices.',
              'Locally saved media files and subtitles managed through the Download Manager.',
            ],
          ),
          LegalSection(
            number: '3',
            title: 'Optional Cloud Services: Sign in with Google & Continue Watching',
            body:
                'If you choose to Sign in with Google, Cineva uses Google Sign-In and Firebase (Google LLC) to authenticate you and sync data across your devices. This feature is entirely optional; you can use Cineva without an account.',
            bulletPoints: [
              'Google account data: email address, display name, and profile photo. This is used to fill in your profile and identify your sync account.',
              'Sync backup data: your profile, Watchlist, and watch history are stored in Firebase Realtime Database under a path specific to your account and synced automatically in the background.',
              'Cross-device Continue Watching: the title you are watching, playback position, and device type and name are stored as an active session so you can resume on another device. The session is cleared when playback completes.',
              'You can disconnect your Google account at any time in Settings; local data on your device is not deleted. To delete your cloud data, contact us at cineva.dev@gmail.com.',
            ],
          ),
          LegalSection(
            number: '4',
            title: 'Watch Party: Beta Feature',
            body:
                'When you create or join a Watch Party room, the following data is shared with all room participants and processed through third-party infrastructure:',
            bulletPoints: [
              'Display name, member ID (your Firebase account ID if signed in, or a random guest ID), Host status, and last-active time.',
              'Chat messages, emoji reactions, and system messages (for example, a member joining or leaving).',
              'Viewing information: title, media type, TMDB/IMDb ID, season and episode, poster, and playback state (play, pause, and position) to keep everyone in sync.',
              'The room code (for example CNV-8492) and an optional 4-digit PIN. The PIN only provides simple access restriction and is not a high-grade security mechanism; anyone holding the code and PIN can join and see the room contents.',
              'Room data is stored in Firebase Realtime Database. If the Firebase connection fails, Cineva automatically uses a third-party public relay service (ntfy.sh) as a fallback channel, so room data may pass through and be temporarily stored on that service under its provider\'s policies.',
              'Room data is designed to be deleted once a room becomes inactive or has ended. This automatic deletion is still being refined during the beta, so retention periods may change. Do not share sensitive information in chat.',
            ],
          ),
          LegalSection(
            number: '5',
            title: 'Performance Analytics, Feedback & Update Checks',
            body:
                'Cineva processes certain technical data to maintain app quality and performance across devices:',
            bulletPoints: [
              'Google Analytics for Firebase: Cineva collects technical usage and performance data, such as app opens and screen views, along with device and app information (for example device model, operating system version, app version, approximate region, and an app-instance identifier) to monitor stability and performance. This data is processed by Google. Analytics collection is enabled by default and an in-app option to disable it is not available in this version.',
              'Send Feedback: if you submit feedback, your message, name (optional), category, device and operating system information, and app version are sent through Google Apps Script to the developer, logged in Google Sheets, and forwarded to Telegram. Do not include sensitive data in feedback.',
              'Update checks: the app requests the latest release information from GitHub, so your IP address is visible to GitHub under GitHub\'s privacy policy.',
              'The official Cineva website uses Vercel Web Analytics and Speed Insights for aggregated visit and page performance statistics.',
            ],
          ),
          LegalSection(
            number: '6',
            title: 'P2P Networking Nature & Internet Protocol (IP) Visibility',
            body:
                'As a modern media player leveraging decentralized Peer-to-Peer (BitTorrent) protocols:',
            bulletPoints: [
              'When streaming or downloading via P2P networks, your device\'s public IP address is inherently visible to fellow swarm peers to facilitate packet exchanges. This is an architectural characteristic of distributed networking globally, not data collection by Cineva.',
              'Cineva operates a zero-logs policy and maintains no telemetry, tracking databases, or connection archives.',
              'Users seeking heightened network privacy are encouraged to employ a trusted third-party Virtual Private Network (VPN).',
            ],
          ),
          LegalSection(
            number: '7',
            title: 'Third-Party Services & Public APIs',
            body:
                'To render cinema posters, metadata, and subtitles, and to run optional features, Cineva communicates directly from your device with third-party services:',
            bulletPoints: [
              'The Movie Database (TMDB): Queried for movie/show posters, ratings, plot synopses, and genre taxonomy.',
              'OpenSubtitles: Queried to locate and download community-provided subtitle text tracks.',
              'Public Tracker Scrapers (Torrentio community endpoints): Queried to resolve public swarm availability.',
              'Google (Firebase Authentication, Realtime Database, Analytics, Apps Script, and Sheets): for Sign in with Google, sync, Continue Watching, Watch Party, analytics, and Send Feedback.',
              'ntfy.sh: a public fallback relay for Watch Party when Firebase is unreachable.',
              'Telegram: receives user feedback notifications for the developer.',
              'GitHub: source of release information for update checks.',
              'Such external communications remain subject to the respective privacy policies of those independent providers.',
            ],
          ),
          LegalSection(
            number: '8',
            title: 'User Rights, Controls & Regulatory Alignment',
            body:
                'You can delete all local data at any time via Settings, disconnect your Google account, and leave a Watch Party room whenever you like. For access or deletion requests for data stored in cloud services (account, sync backup, Watch Party rooms, or feedback), contact us at cineva.dev@gmail.com. We strive to align our data practices with global data protection principles such as the EU General Data Protection Regulation (GDPR) and the California Consumer Privacy Act (CCPA), including data minimization.',
          ),
          LegalSection(
            number: '9',
            title: 'Amendments & Policy Updates',
            body:
                'This Privacy Policy may be revised from time to time as the app evolves. The last-updated date is shown at the top of this document, and the latest version is always available in the app and on the official Cineva website.',
          ),
        ],
        concludingNotice:
            'If you have any questions about privacy, you may review Cineva\'s open-source code or contact the developer at cineva.dev@gmail.com.',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. SYARAT DAN KETENTUAN / TERMS AND CONDITIONS
  // ─────────────────────────────────────────────────────────────────────────────
  static LegalDocumentData _getTermsAndConditions(AppLanguage lang) {
    if (lang.isHindi) {
      return const LegalDocumentData(
        title: 'नियम और शर्तें',
        subtitle: 'Cineva सॉफ़्टवेयर उपयोग के लिए वैश्विक कानूनी समझौता',
        lastUpdated: '20 नवंबर 2026',
        calloutSummary:
            'महत्वपूर्ण: Cineva बिना किसी वारंटी के "जैसा है" (as-is) प्रदान किया जाता है। सभी फ़िल्में और टीवी सीरीज़ उनके संबंधित स्वामियों की हैं। Cineva पूरी तरह से गैर-व्यावसायिक है और लाइसेंस प्राप्त व्यावसायिक स्ट्रीमिंग सेवाओं का विकल्प नहीं है।',
        sections: [
          LegalSection(
            number: '1',
            title: 'कानूनी शर्तों की स्वीकृति',
            body:
                'किसी भी डिवाइस पर Cineva एप्लिकेशन को डाउनलोड, इंस्टॉल या उपयोग करके, आप इन नियमों और शर्तों से कानूनी रूप से बंधे होने के लिए सहमत होते हैं। यदि आप इनमें से किसी भी शर्त से सहमत नहीं हैं, तो आपको तुरंत उपयोग बंद कर देना चाहिए और ऐप को अनइंस्टॉल कर देना चाहिए।',
          ),
          LegalSection(
            number: '2',
            title: 'ओपन सोर्स लाइसेंसिंग (GPL-3.0) और "जैसा है" प्रावधान',
            body:
                'Cineva सॉफ़्टवेयर GNU General Public License v3.0 (GPL-3.0) के तहत मुफ़्त और ओपन-सोर्स सॉफ़्टवेयर के रूप में वितरित किया जाता है। यह बिना किसी प्रत्यक्ष या अप्रत्यक्ष वारंटी के "जैसा है" ("AS IS") और "जैसा उपलब्ध है" ("AS AVAILABLE") के आधार पर प्रदान किया जाता है।',
          ),
          LegalSection(
            number: '3',
            title: 'तृतीय-पक्ष सामग्री स्वामित्व और बौद्धिक संपदा',
            body:
                'उपयोगकर्ता स्पष्ट रूप से स्वीकार करता है और सहमत है कि:',
            bulletPoints: [
              'सभी फ़िल्में, टीवी शो, सीरीज़, ट्रेलर, ऑडियो ट्रैक, पोस्टर और सबटाइटल Cineva या इसके निर्माताओं की संपत्ति नहीं हैं।',
              'Cineva किसी भी मल्टीमीडिया फ़ाइल का निर्माण, होस्ट, प्रबंधन, अपलोड या नियंत्रण नहीं करता है।',
              'सभी कॉपीराइट, ट्रेडमार्क और बौद्धिक संपदा अधिकार विशेष रूप से उनके संबंधित स्टूडियो, कॉपीराइट धारकों और अधिकृत वितरकों के हैं।',
            ],
          ),
          LegalSection(
            number: '4',
            title: 'गैर-व्यावसायिक उपयोगिता और आधिकारिक स्ट्रीमिंग का विकल्प नहीं',
            body:
                'Cineva को बिना किसी व्यावसायिक मुद्रीकरण के ओपन-सोर्स सॉफ़्टवेयर उपयोगिता के रूप में विकसित किया गया है:',
            bulletPoints: [
              'यह एप्लिकेशन 100% गैर-व्यावसायिक है और सदस्यता शुल्क से मुक्त है।',
              'Cineva लाइसेंस प्राप्त व्यावसायिक स्ट्रीमिंग प्रदाताओं (जैसे Netflix, Disney+, Amazon Prime Video, HBO Max या सिनेमाघरों) का विकल्प नहीं है।',
              'हम उपयोगकर्ताओं से आग्रह करते हैं कि वे आधिकारिक लाइसेंस प्राप्त प्लेटफ़ॉर्म के माध्यम से सदस्यता और टिकट खरीदकर कलाकारों और फ़िल्म निर्माताओं का समर्थन करें।',
            ],
          ),
          LegalSection(
            number: '5',
            title: 'मीडिया उपलब्धता और प्लेबैक क्षमता का अस्वीकरण',
            body:
                'हम स्पष्ट रूप से घोषित करते हैं कि सभी फ़िल्मों या टीवी सीरीज़ के उपलब्ध या चलने योग्य होने की गारंटी नहीं है:',
            bulletPoints: [
              'Cineva केवल तृतीय-पक्ष विकेंद्रीकृत सार्वजनिक इंडेक्स और मेटाडेटा को पार्स करके कार्य करता है।',
              'स्ट्रीमिंग गति और वीडियो गुणवत्ता पूरी तरह से सार्वजनिक इंटरनेट पर बाहरी तृतीय-पक्ष सीडर्स और पीयर्स की उपलब्धता पर निर्भर करती है।',
              'डेवलपर्स किसी भी शीर्षक की उपलब्धता या गुणवत्ता के संबंध में कोई गारंटी नहीं देते हैं।',
            ],
          ),
          LegalSection(
            number: '6',
            title: 'उपयोगकर्ता की कानूनी जिम्मेदारी',
            body:
                'इस सॉफ़्टवेयर के उपयोग के लिए उपयोगकर्ता स्वयं पूरी तरह से जिम्मेदार है। यह सुनिश्चित करना आपकी जिम्मेदारी है कि P2P नेटवर्क प्रोटोकॉल का आपका उपयोग आपके देश या क्षेत्राधिकार के कॉपीराइट कानूनों और स्थानीय नियमों का पालन करता है।',
          ),
          LegalSection(
            number: '7',
            title: 'सामुदायिक सुविधाएं: वॉच पार्टी, खाते और फ़ीडबैक',
            body:
                'यदि आप अन्य उपयोगकर्ताओं या ऑनलाइन सेवाओं से जुड़ी सुविधाओं का उपयोग करते हैं, तो आप निम्नलिखित अतिरिक्त शर्तों से सहमत होते हैं:',
            bulletPoints: [
              'होस्ट अपने द्वारा बनाए गए रूम और चलाए जा रहे शीर्षक के लिए जिम्मेदार है; प्रत्येक प्रतिभागी अपने द्वारा भेजे गए संदेशों और प्रतिक्रियाओं के लिए जिम्मेदार है।',
              'उत्पीड़न, नफ़रत फैलाने वाले भाषण, स्पैम, धोखाधड़ी या गैरकानूनी सामग्री के लिए चैट का उपयोग करना प्रतिबंधित है।',
              'रूम कोड और पिन आपकी जिम्मेदारी हैं।',
              'वॉच पार्टी बीटा में है और इसकी उपलब्धता की गारंटी नहीं है।',
            ],
          ),
        ],
        concludingNotice:
            'Cineva का निरंतर उपयोग इन नियमों और शर्तों में निहित सभी कानूनी प्रावधानों के प्रति आपकी पूर्ण सहमति दर्शाता है।',
      );
    }
    if (lang.isIndonesian) {
      return const LegalDocumentData(
        title: 'Syarat dan Ketentuan',
        subtitle: 'Perjanjian Hukum Penggunaan Piranti Lunak Cineva Secara Global',
        lastUpdated: '20 November 2026',
        calloutSummary:
            'PENTING: Aplikasi Cineva disediakan "sebagaimana adanya" tanpa jaminan apa pun. Seluruh film dan serial TV bukan milik Cineva. Cineva BUKAN layanan komersial dan BUKAN pengganti platform streaming berbayar resmi.',
        sections: [
          LegalSection(
            number: '1',
            title: 'Penerimaan Ketentuan Penggunaan',
            body:
                'Dengan mengunduh, memasang, menyalin, atau menggunakan piranti lunak Cineva pada perangkat apa pun di seluruh dunia, Anda menyatakan telah membaca, memahami, dan menyetujui secara mengikat seluruh Syarat dan Ketentuan ini. Apabila Anda tidak menyetujui salah satu butir ketentuan, Anda wajib segera menghentikan penggunaan dan menghapus aplikasi dari perangkat Anda.',
          ),
          LegalSection(
            number: '2',
            title: 'Lisensi Sumber Terbuka (GPL-3.0) & Penyediaan "Sebagaimana Adanya" (As-Is Provision)',
            body:
                'Piranti lunak Cineva didistribusikan sebagai perangkat lunak bebas dan sumber terbuka di bawah lisensi GNU General Public License v3.0 (GPL-3.0). Aplikasi Cineva disediakan secara mutlak atas dasar "SEBAGAIMANA ADANYA" ("AS IS") dan "SEBAGAIMANA TERSEDIA" ("AS AVAILABLE"), tanpa jaminan dalam bentuk apa pun, baik tersurat maupun tersirat, termasuk namun tidak terbatas pada jaminan tersirat atas kelayakan untuk diperdagangkan (merchantability), kesesuaian untuk tujuan tertentu (fitness for a particular purpose), ketiadaan pelanggaran hak pihak ketiga, serta kebebasan dari cacat, galat, atau gangguan operasional.',
          ),
          LegalSection(
            number: '3',
            title: 'Kepemilikan Pihak Ketiga & Penafian Konten Media',
            body:
                'Pengguna mengakui dan menyepakati secara tegas bahwa:',
            bulletPoints: [
              'Seluruh konten Film, Serial TV, Trailer, Audio, Gambar Poster, dan Subtitle BUKAN merupakan milik aplikasi Cineva maupun pengembangnya.',
              'Cineva tidak memproduksi, tidak menerbitkan, tidak mengunggah, tidak menghosting, dan tidak mengendalikan file media apa pun.',
              'Hak cipta, merek dagang, paten, dan hak kekayaan intelektual atas seluruh film dan serial TV adalah milik penuh dan eksklusif dari masing-masing pemegang hak cipta, studio produksi, dan distributor resmi yang bersangkutan.',
            ],
          ),
          LegalSection(
            number: '4',
            title: 'Bukan Pengganti Layanan Streaming Resmi & Sifat Non-Komersial',
            body:
                'Cineva dikembangkan secara murni sebagai piranti lunak utilitas pribadi sumber terbuka (open utility software) tanpa orientasi komersial:',
            bulletPoints: [
              'Aplikasi ini 100% NON-KOMERSIAL, bebas biaya langganan, dan tidak menghasilkan pendapatan dari penjualan konten berhak cipta.',
              'Cineva sama sekali BUKAN merupakan pengganti layanan streaming resmi berbayar (seperti Netflix, Disney+, Amazon Prime Video, HBO Max, bioskop, atau gerai distribusi resmi lainnya).',
              'Kami secara aktif mengimbau seluruh pengguna untuk menghargai para sineas, aktor, dan produser film dengan cara berlangganan dan membeli tiket/karya pada platform resmi berlisensi.',
            ],
          ),
          LegalSection(
            number: '5',
            title: 'Penafian Ketersediaan & Kemampuan Pemutaran Konten',
            body:
                'Kami menyatakan secara tegas bahwa TIDAK SELURUH film atau serial TV dijamin tersedia, lengkap, atau dapat diputar:',
            bulletPoints: [
              'Cineva beroperasi dengan mem-parsing indeks publik P2P dan metadata internet secara dinamis.',
              'Keberhasilan streaming, kecepatan unduhan, dan resolusi video sepenuhnya bergantung pada ketersediaan seeders/peers publik aktif dan sumber pihak ketiga di internet.',
              'Pengembang Cineva tidak menjamin ketersediaan berkelanjutan atas judul media tertentu, kelancaran pemutaran, maupun kualitas tayangan.',
            ],
          ),
          LegalSection(
            number: '6',
            title: 'Tanggung Jawab Hukum Pengguna di Seluruh Yurisdiksi',
            body:
                'Pengguna memikul tanggung jawab hukum tunggal dan mutlak atas cara penggunaan aplikasi ini. Anda bertanggung jawab penuh untuk memastikan bahwa penggunaan protokol P2P dan akses terhadap konten publik selaras dengan peraturan perundang-undangan dan undang-undang hak cipta yang berlaku di negara tempat Anda berdomisili. Pengembang dibebaskan secara penuh dari setiap tuntutan atau sengketa hukum yang melibatkan pengguna.',
          ),
          LegalSection(
            number: '7',
            title: 'Fitur Komunitas: Nonton Bareng, Akun & Masukan',
            body:
                'Jika Anda menggunakan fitur yang melibatkan pengguna lain atau layanan daring, Anda menyetujui ketentuan tambahan berikut:',
            bulletPoints: [
              'Host bertanggung jawab atas ruangan yang dibuat dan judul yang diputar; setiap peserta bertanggung jawab atas pesan, nama panggilan, dan reaksi yang dikirimnya.',
              'Dilarang menggunakan obrolan untuk pelecehan, ujaran kebencian, spam, penipuan, penyebaran data pribadi orang lain, atau konten yang melanggar hukum.',
              'Kode ruangan dan PIN adalah tanggung jawab Anda. Cineva tidak menjamin kerahasiaan ruangan dari pihak yang mengetahui kode atau PIN tersebut.',
              'Nonton Bareng berstatus beta. Sinkronisasi, ketersediaan ruangan, dan layanan pendukungnya tidak dijamin serta dapat berubah atau dihentikan sewaktu-waktu.',
              'Cineva berhak membatasi atau menghapus ruangan maupun akses yang menyalahgunakan layanan.',
              'Pemrosesan data pada fitur-fitur ini diatur dalam Kebijakan Privasi.',
            ],
          ),
        ],
        concludingNotice:
            'Penggunaan berkelanjutan atas aplikasi Cineva merupakan bentuk kesepakatan abadi Anda terhadap seluruh klausul hukum dalam Syarat dan Ketentuan ini.',
      );
    } else {
      return const LegalDocumentData(
        title: 'Terms and Conditions',
        subtitle: 'Global Legal Agreement for Cineva Software Usage',
        lastUpdated: 'November 20, 2026',
        calloutSummary:
            'CRITICAL: Cineva is provided strictly "as-is" without warranties of any kind. All movies and TV series belong exclusively to their respective owners. Cineva is strictly non-commercial and is NOT a substitute for licensed commercial streaming services.',
        sections: [
          LegalSection(
            number: '1',
            title: 'Acceptance of Legal Terms',
            body:
                'By downloading, installing, accessing, or utilizing the Cineva application on any device across global jurisdictions, you enter into a legally binding agreement governed by these Terms and Conditions. If you do not irrevocably agree to every term contained herein, you must immediately cease usage and uninstall the application.',
          ),
          LegalSection(
            number: '2',
            title: 'Open Source Licensing (GPL-3.0) & "As-Is" Provision',
            body:
                'Cineva software is distributed as free and open-source software under the GNU General Public License v3.0 (GPL-3.0). Cineva is provided strictly on an "AS IS" and "AS AVAILABLE" basis, devoid of any warranties whatsoever, express, statutory, or implied. To the maximum extent permitted under applicable worldwide law, the developers disclaim all warranties including, without limitation, merchantability, fitness for a particular purpose, non-infringement, reliability, uptime, uninterrupted functionality, or error-free execution.',
          ),
          LegalSection(
            number: '3',
            title: 'Third-Party Content Ownership & Intellectual Property',
            body:
                'The user expressly acknowledges, agrees, and covenants that:',
            bulletPoints: [
              'All Movies, TV Shows, Series, Trailers, Audio tracks, Posters, and Subtitles accessed are NOT the property of Cineva or its creators.',
              'Cineva does not author, produce, host, manage, upload, or control any multimedia files.',
              'All copyrights, trademarks, industrial designs, and intellectual property rights belong exclusively to their respective studio houses, copyright proprietors, and authorized distributors.',
            ],
          ),
          LegalSection(
            number: '4',
            title: 'Non-Commercial Utility & Not a Commercial Streaming Substitute',
            body:
                'Cineva is developed exclusively as a decentralized software research utility without commercial monetization:',
            bulletPoints: [
              'The application is 100% NON-COMMERCIAL, free of subscription fees, paywalls, and commercial exploitation.',
              'Cineva is explicitly NOT a substitute or alternative for licensed commercial streaming providers (such as Netflix, Disney+, Amazon Prime Video, HBO Max, physical theatrical releases, or authorized digital retailers).',
              'We proactively urge users to support artists, filmmakers, and distributors by purchasing genuine subscriptions and theatrical tickets through licensed platforms.',
            ],
          ),
          LegalSection(
            number: '5',
            title: 'Disclaimer of Media Availability & Playback Capability',
            body:
                'We categorically declare that NOT ALL movies or TV series are guaranteed to be discoverable, accessible, or playable:',
            bulletPoints: [
              'Cineva functions purely by dynamically parsing third-party decentralized public indexers and DHT networks.',
              'Streaming velocity, file completion, and playback integrity rely wholly upon the voluntary availability of external third-party seeders and peers across the public internet.',
              'The developers offer zero representation or warranty regarding the availability, longevity, audio-visual fidelity, or completeness of any title.',
            ],
          ),
          LegalSection(
            number: '6',
            title: 'User Sovereignty & Worldwide Regulatory Compliance',
            body:
                'The user assumes sole, individual, and exclusive liability for their utilization of this software. You are individually responsible for verifying that your use of P2P network protocols adheres fully with the copyright legislation and local regulations of your respective geographic jurisdiction. The software authors and maintainers are completely indemnified and held harmless from any claims, damages, or disputes arising from user conduct.',
          ),
          LegalSection(
            number: '7',
            title: 'Community Features: Watch Party, Accounts & Feedback',
            body:
                'If you use features that involve other users or online services, you agree to the following additional terms:',
            bulletPoints: [
              'The Host is responsible for the room they create and the title being played; each participant is responsible for the messages, display names, and reactions they send.',
              'Chat must not be used for harassment, hate speech, spam, fraud, disclosure of other people\'s personal data, or unlawful content.',
              'Room codes and PINs are your responsibility. Cineva does not guarantee room confidentiality from anyone who knows the code or PIN.',
              'Watch Party is in beta. Synchronization, room availability, and supporting services are not guaranteed and may change or be discontinued at any time.',
              'Cineva may restrict or remove rooms and access that abuse the service.',
              'Data processing for these features is governed by the Privacy Policy.',
            ],
          ),
        ],
        concludingNotice:
            'Continued engagement with Cineva constitutes your definitive and enduring assent to all clauses embodied within these Terms and Conditions.',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. DISCLAIMER / LEGAL DISCLAIMER & COPYRIGHT NOTICE
  // ─────────────────────────────────────────────────────────────────────────────
  static LegalDocumentData _getDisclaimer(AppLanguage lang) {
    if (lang.isHindi) {
      return const LegalDocumentData(
        title: 'अस्वीकरण (Disclaimer)',
        subtitle: 'आधिकारिक कॉपीराइट सूचना, DMCA ढांचा और दायित्व सीमाएं',
        lastUpdated: '20 नवंबर 2026',
        calloutSummary:
            'Cineva एक विकेंद्रीकृत मीडिया प्लेयर इंटरफ़ेस है। Cineva अपने किसी भी सर्वर पर कोई वीडियो मीडिया होस्ट नहीं करता है। सभी कॉपीराइट कार्य उनके वैध स्वामियों की विशेष संपत्ति बने रहते हैं।',
        sections: [
          LegalSection(
            number: '1',
            title: 'नॉन-होस्टिंग और मीडिया स्टोरेज अस्वीकरण',
            body:
                'Cineva अपने नियंत्रण वाले किसी भी सर्वर से किसी भी कॉपीराइट मल्टीमीडिया फ़ाइल को होस्ट, संग्रहीत, संग्रह, स्ट्रीम या प्रसारित नहीं करता है। यह सॉफ़्टवेयर पूरी तरह से क्लाइंट-साइड मीडिया प्लेबैक इंटरफ़ेस के रूप में कार्य करता है।',
          ),
          LegalSection(
            number: '2',
            title: 'कॉपीराइट सम्मान, WIPO संधियां और DMCA सूचनाएं',
            body:
                'Cineva के निर्माता डिजिटल मिलेनियम कॉपीराइट एक्ट (DMCA), बर्न कन्वेंशन और अंतर्राष्ट्रीय WIPO दिशानिर्देशों के तहत बौद्धिक संपदा अधिकारों का सम्मान करते हैं:',
            bulletPoints: [
              'यदि आप कॉपीराइट धारक या अधिकृत एजेंट हैं, तो कृपया ध्यान दें कि विकेंद्रीकृत नोड्स, तृतीय-पक्ष होस्टिंग प्रदाताओं या सार्वजनिक स्वार्म पर Cineva का कोई नियंत्रण नहीं है।',
              'टेकडाउन नोटिस सीधे डेटा ट्रांसफर करने वाले तृतीय-पक्ष वेब होस्ट या सार्वजनिक ट्रैकिंग सर्वर को भेजे जाने चाहिए।',
              'Cineva के पास कोई केंद्रीकृत डेटाबेस या सामग्री रिपॉजिटरी नहीं है जिसे हम अपने सर्वर से हटा सकें।',
            ],
          ),
          LegalSection(
            number: '3',
            title: 'कैटलॉग उपलब्धता या प्लेबैक पर शून्य गारंटी',
            body:
                'यह एप्लिकेशन कोई आश्वासन नहीं देता है कि कोई विशिष्ट फ़िल्म, टेलीविज़न सीज़न या एपिसोड लगातार उपलब्ध या चलने योग्य होगा। सार्वजनिक नेटवर्क पर सक्रिय सीडर्स की अनुपस्थिति के परिणामस्वरूप मीडिया अनुपलब्धता या बफरिंग होगी, जो Cineva के नियंत्रण से बाहर है।',
          ),
          LegalSection(
            number: '4',
            title: 'गैर-व्यावसायिक घोषणा और मूल मीडिया के लिए समर्थन',
            body:
                'Cineva दोहराता है कि यह एक व्यावसायिक उद्यम नहीं है और इसका उद्देश्य कभी भी अधिकृत सदस्यता सेवाओं को प्रतिस्थापित करना नहीं है। हम उपयोगकर्ताओं को लाइसेंस प्राप्त सिनेमाघरों और आधिकारिक स्ट्रीमिंग नेटवर्क की सदस्यता लेने के लिए प्रोत्साहित करते हैं।',
          ),
          LegalSection(
            number: '5',
            title: 'दायित्व की व्यापक सीमा (Limitation of Liability)',
            body:
                'लागू कानून द्वारा अनुमत अधिकतम सीमा तक, Cineva के डेवलपर्स या योगदानकर्ता इस सॉफ़्टवेयर के उपयोग या उपयोग करने में असमर्थता से उत्पन्न होने वाले किसी भी प्रत्यक्ष, अप्रत्यक्ष, आकस्मिक या परिणामी नुकसान के लिए उत्तरदायी नहीं होंगे।',
          ),
          LegalSection(
            number: '6',
            title: 'वॉच पार्टी और उपयोगकर्ता-जनित सामग्री',
            body:
                'वॉच पार्टी केवल प्रतिभागियों के बीच प्लेबैक स्थिति (प्ले, पॉज़ और समय) और चैट को सिंक्रनाइज़ करती है। Cineva इस सुविधा के माध्यम से वीडियो होस्ट, पुनः प्रसारित या वितरित नहीं करता है।',
            bulletPoints: [
              'प्रत्येक प्रतिभागी अपने डिवाइस पर ऐप के माध्यम से अपना स्वयं का मीडिया स्रोत चलाता है।',
              'Cineva उपयोगकर्ताओं द्वारा बनाए गए संदेशों, नामों या प्रतिक्रियाओं की सामग्री के लिए जिम्मेदार नहीं है।',
              'दुरुपयोग या कॉपीराइट उल्लंघन की रिपोर्ट cineva.dev@gmail.com पर भेजी जा सकती है।',
            ],
          ),
        ],
        concludingNotice:
            'Cineva का उपयोग करके, आप एक स्वतंत्र मीडिया प्लेयर के रूप में Cineva की भूमिका को स्वीकार करते हैं और आपके द्वारा एक्सेस की जाने वाली सामग्री के संबंध में इसके निर्माताओं को सभी दायित्वों से मुक्त करते हैं।',
      );
    }
    if (lang.isIndonesian) {
      return const LegalDocumentData(
        title: 'Disclaimer',
        subtitle: 'Pernyataan Penafian Hak Cipta, DMCA, & Batasan Tanggung Jawab',
        lastUpdated: '20 November 2026',
        calloutSummary:
            'Cineva adalah antarmuka pemutar media terdesentralisasi. Cineva tidak meng-host file video apa pun di server kami sendiri. Seluruh materi hak cipta adalah milik pemilik resminya masing-masing.',
        sections: [
          LegalSection(
            number: '1',
            title: 'Pernyataan Penafian Hosting & Penyimpanan Konten',
            body:
                'Cineva TIDAK meng-host, TIDAK menyimpan, TIDAK mengarsipkan, dan TIDAK mentransmisikan konten video berhak cipta apa pun dari server internal milik Cineva. Aplikasi ini bekerja murni sebagai antarmuka pemutar media (media player client) sisi-klien yang mem-parsing informasi publik yang tersedia secara bebas di internet dan jaringan terdistribusi global.',
          ),
          LegalSection(
            number: '2',
            title: 'Kepatuhan Hak Cipta, WIPO, & Pemberitahuan DMCA',
            body:
                'Pengembang Cineva sangat menjunjung tinggi hak kekayaan intelektual global sesuai Digital Millennium Copyright Act (DMCA), Berne Convention, dan traktat World Intellectual Property Organization (WIPO):',
            bulletPoints: [
              'Jika Anda adalah pemegang hak cipta atau agen resminya dan menemukan materi Anda terindeks oleh pelacak publik, mohon dipahami bahwa Cineva tidak memiliki kontrol atas server atau seeders pihak ketiga tempat file tersebut berada.',
              'Penghapusan tautan atau penghentian distribusi harus diajukan langsung kepada penyedia hosting web pihak ketiga atau swarm pelacak publik yang mendistribusikan berkas tersebut.',
              'Cineva tidak menyimpan repositori file apa pun yang dapat kami hapus dari server kami.',
            ],
          ),
          LegalSection(
            number: '3',
            title: 'Penafian Ketiadaan Jaminan Ketersediaan Film & Serial TV',
            body:
                'Aplikasi ini tidak memberikan jaminan bahwa suatu judul film, musim serial, atau episode tertentu akan selalu tersedia atau dapat diputar dengan lancar. Ketiadaan seeders aktif pada jaringan publik akan menyebabkan konten tidak dapat dimuat atau mengalami buffering. Hal ini berada di luar kendali teknis piranti lunak Cineva.',
          ),
          LegalSection(
            number: '4',
            title: 'Penafian Komersialisasi & Imbauan Mendukung Karya Orisinal',
            body:
                'Cineva menegaskan kembali bahwa aplikasi ini bukan platform komersial dan tidak didesain untuk menggantikan layanan hiburan berlisensi. Kami mendorong setiap pengguna untuk menikmati film dan serial TV favorit melalui saluran bioskop resmi serta layanan streaming legal berlangganan guna mendukung keberlanjutan industri perfilman internasional.',
          ),
          LegalSection(
            number: '5',
            title: 'Pembatasan Tanggung Jawab Hukum (Limitation of Liability)',
            body:
                'Sejauh diizinkan oleh hukum yang berlaku, pengembang, kontributor, dan pihak terkait Cineva tidak bertanggung jawab atas kerugian langsung, tidak langsung, insidental, khusus, atau konsekuensial dalam bentuk apa pun (termasuk kehilangan data, penggunaan bandwidth, atau tuntutan pihak ketiga) yang timbul dari pengunduhan, pemasangan, atau pengoperasian aplikasi ini oleh pengguna.',
          ),
          LegalSection(
            number: '6',
            title: 'Nonton Bareng & Konten Buatan Pengguna',
            body:
                'Nonton Bareng hanya menyinkronkan status pemutaran (play, pause, dan posisi) serta obrolan antar peserta. Cineva tidak meng-host, tidak menyiarkan ulang, dan tidak mendistribusikan video melalui fitur ini.',
            bulletPoints: [
              'Setiap peserta memutar sumber medianya sendiri melalui aplikasi di perangkatnya; ketersediaan dan kualitas dapat berbeda antar peserta.',
              'Cineva tidak memantau dan tidak bertanggung jawab atas isi pesan, nama panggilan, atau reaksi yang dibuat pengguna.',
              'Laporan penyalahgunaan atau pelanggaran hak cipta dapat dikirim ke cineva.dev@gmail.com.',
            ],
          ),
        ],
        concludingNotice:
            'Dengan menggunakan Cineva, Anda menegaskan pemahaman Anda bahwa Cineva adalah alat pemutar piranti lunak mandiri dan membebaskan pengembang dari segala tanggung jawab atas konten yang Anda akses.',
      );
    } else {
      return const LegalDocumentData(
        title: 'Disclaimer',
        subtitle: 'Official Copyright Notice, DMCA Framework, & Liability Limitations',
        lastUpdated: 'November 20, 2026',
        calloutSummary:
            'Cineva is a decentralized media player interface. Cineva does not host any video media on our own servers. All copyrighted works remain the exclusive property of their rightful owners.',
        sections: [
          LegalSection(
            number: '1',
            title: 'Non-Hosting & Media Storage Disclaimer',
            body:
                'Cineva DOES NOT host, store, archive, stream, or transmit any copyrighted multimedia files from any servers under the control of Cineva. The software operates strictly as a client-side media playback interface that renders publicly available indexes, DHT metadata, and external APIs dispersed across the open decentralized internet.',
          ),
          LegalSection(
            number: '2',
            title: 'Copyright Respect, WIPO Treaties, & DMCA Notices',
            body:
                'The authors of Cineva maintain strict respect for intellectual property rights under the Digital Millennium Copyright Act (DMCA), the Berne Convention, and international World Intellectual Property Organization (WIPO) guidelines:',
            bulletPoints: [
              'If you are a copyright holder or designated agent seeking copyright enforcement, please note that Cineva holds no custody over the decentralized nodes, third-party hosting providers, or public swarms.',
              'Takedown notices and copyright inquiries must be directed to the third-party web hosts or public tracking servers originating the data transfer.',
              'Cineva maintains no centralized database or content repository capable of unilateral removal.',
            ],
          ),
          LegalSection(
            number: '3',
            title: 'Zero Guarantee on Catalog Availability or Playback',
            body:
                'The application provides zero assurance that any specific film, television season, or episode will be continuously discoverable or playable. The absence of healthy seeders on public networks will result in media unavailability or buffering. This phenomenon is an inherent trait of distributed networks outside Cineva\'s control.',
          ),
          LegalSection(
            number: '4',
            title: 'Non-Commercial Declaration & Support for Original Media',
            body:
                'Cineva reiterates that it is not a commercial enterprise and is never intended to replace authorized subscription services. We champion the creative arts and strongly advocate that users frequent licensed cinemas and subscribe to authorized streaming networks to sustain the global creative community.',
          ),
          LegalSection(
            number: '5',
            title: 'Comprehensive Limitation of Liability',
            body:
                'Under no circumstances shall the developers, contributors, or associates of Cineva be liable for any direct, indirect, incidental, special, exemplary, or consequential damages (including, but not limited to, data consumption, network costs, loss of use, or legal controversies) arising out of the use or inability to use this software utility.',
          ),
          LegalSection(
            number: '6',
            title: 'Watch Party & User-Generated Content',
            body:
                'Watch Party only synchronizes playback state (play, pause, and position) and chat between participants. Cineva does not host, rebroadcast, or distribute video through this feature.',
            bulletPoints: [
              'Each participant plays their own media source through the app on their device; availability and quality may differ between participants.',
              'Cineva does not monitor and is not responsible for the content of messages, display names, or reactions created by users.',
              'Reports of abuse or copyright infringement can be sent to cineva.dev@gmail.com.',
            ],
          ),
        ],
        concludingNotice:
            'By engaging with Cineva, you affirmatively validate your understanding of Cineva\'s role as an independent media player and release its creators from all liability concerning content you elect to inspect.',
      );
    }
  }
}
