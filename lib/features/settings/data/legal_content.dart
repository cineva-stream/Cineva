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
  final String calloutSummary;
  final List<LegalSection> sections;
  final String concludingNotice;

  const LegalDocumentData({
    required this.title,
    required this.subtitle,
    required this.calloutSummary,
    required this.sections,
    required this.concludingNotice,
  });
}

/// Centralized repository containing full international legal text in Indonesian and English.
class LegalContentRepository {
  static LegalDocumentData getDocument(LegalDocType type, bool isIndonesian) {
    switch (type) {
      case LegalDocType.privacyPolicy:
        return _getPrivacyPolicy(isIndonesian);
      case LegalDocType.termsAndConditions:
        return _getTermsAndConditions(isIndonesian);
      case LegalDocType.disclaimer:
        return _getDisclaimer(isIndonesian);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. KEBIJAKAN PRIVASI / PRIVACY POLICY
  // ─────────────────────────────────────────────────────────────────────────────
  static LegalDocumentData _getPrivacyPolicy(bool isIndonesian) {
    if (isIndonesian) {
      return const LegalDocumentData(
        title: 'Kebijakan Privasi',
        subtitle: 'Prinsip Perlindungan Data Pribadi & Privasi Pengguna Global',
        calloutSummary:
            'Cineva dirancang dengan arsitektur privasi nol-pelacakan (Zero Data Collection). Kami tidak mengumpulkan, tidak menjual, dan tidak mentransmisikan data identitas pribadi Anda ke server mana pun.',
        sections: [
          LegalSection(
            number: '1',
            title: 'Filosofi Privasi Tanpa Akun & Tanpa Registrasi',
            body:
                'Cineva beroperasi tanpa memerlukan pendaftaran akun, alamat surel, nomor telepon, maupun informasi identitas pribadi (PII). Seluruh fitur aplikasi dapat diakses langsung tanpa autentikasi ke server terpusat milik Cineva. Kami meyakini bahwa akses terhadap piranti lunak pemutar media harus menjunjung tinggi privasi mutlak pengguna di seluruh dunia.',
          ),
          LegalSection(
            number: '2',
            title: 'Penyimpanan Data Lokal di Perangkat Pengguna',
            body:
                'Seluruh preferensi konfigurasi dan data interaksi pengguna disimpan secara eksklusif pada penyimpanan lokal perangkat Anda menggunakan basis data tertanam terenkripsi (Hive). Data yang tersimpan meliputi:',
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
            number: '4',
            title: 'Interaksi dengan Layanan & API Pihak Ketiga',
            body:
                'Untuk menampilkan poster sinematik, sinopsis resmi, dan subtitle, Cineva berkomunikasi langsung dari perangkat Anda ke antarmuka pemrograman aplikasi (API) publik pihak ketiga:',
            bulletPoints: [
              'The Movie Database (TMDB): Digunakan untuk mengambil metadata poster, judul, tahun rilis, dan ringkasan alur cerita.',
              'OpenSubtitles: Digunakan untuk mengunduh berkas teks subtitle multibahasa secara publik.',
              'Indeks Pelacak Publik (Torrentio / Addon Scraper): Digunakan untuk mencocokkan ketersediaan data media terdistribusi.',
              'Interaksi dengan layanan pihak ketiga ini tunduk pada kebijakan privasi dan ketentuan layanan dari masing-masing penyedia layanan tersebut.',
            ],
          ),
          LegalSection(
            number: '5',
            title: 'Kepatuhan Regulasi Privasi Internasional',
            body:
                'Meskipun Cineva tidak mengumpulkan data pribadi di server mana pun, arsitektur aplikasi ini selaras dengan prinsip-prinsip perlindungan data global, termasuk General Data Protection Regulation (GDPR) Uni Eropa, California Consumer Privacy Act (CCPA), dan standar privasi internasional lainnya yang menjamin hak pengguna untuk menghapus seluruh data lokal kapan saja melalui menu Pengaturan.',
          ),
          LegalSection(
            number: '6',
            title: 'Pembaruan Dokumen Kebijakan',
            body:
                'Kebijakan Privasi ini dapat diperbarui sewaktu-waktu seiring dengan evolusi fitur teknis aplikasi. Pembaruan akan selalu tercermin secara transparan pada dokumen ini.',
          ),
        ],
        concludingNotice:
            'Jika Anda memiliki pertanyaan terkait privasi aplikasi atau arsitektur penyimpanan data lokal, Anda dapat meninjau kode sumber terbuka Cineva atau menghubungi pengembang.',
      );
    } else {
      return const LegalDocumentData(
        title: 'Privacy Policy',
        subtitle: 'Global User Privacy & Personal Data Protection Framework',
        calloutSummary:
            'Cineva is engineered with a strict Zero-Data-Collection architecture. We do not harvest, track, sell, or transmit any personal identifiable information to any central server.',
        sections: [
          LegalSection(
            number: '1',
            title: 'Account-Free & Zero Registration Philosophy',
            body:
                'Cineva operates completely free of user registration, email addresses, phone numbers, or Personal Identifiable Information (PII). All app capabilities are immediately available without any authentication against centralized Cineva servers. We believe privacy is a fundamental human right for users worldwide.',
          ),
          LegalSection(
            number: '2',
            title: 'Exclusive Local-Only Device Storage',
            body:
                'All user configurations, preferences, and activity data remain strictly within your device\'s local encrypted storage sandbox (Hive). This includes:',
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
            number: '4',
            title: 'Third-Party Public API Integrations',
            body:
                'To render cinema posters, metadata, and subtitles, Cineva communicates directly from your device to third-party public API endpoints:',
            bulletPoints: [
              'The Movie Database (TMDB): Queried for movie/show posters, ratings, plot synopses, and genre taxonomy.',
              'OpenSubtitles: Queried to locate and download community-provided subtitle text tracks.',
              'Public Tracker Scrapers (Torrentio community endpoints): Queried to resolve public swarm availability.',
              'Such external communications remain subject to the respective privacy policies of those independent providers.',
            ],
          ),
          LegalSection(
            number: '5',
            title: 'Worldwide Privacy Compliance',
            body:
                'Because Cineva stores no data on remote servers, its decentralized design naturally respects international data sovereignty standards, including the EU General Data Protection Regulation (GDPR), the California Consumer Privacy Act (CCPA), and global frameworks granting users full custody to purge their local data at any time via Settings.',
          ),
          LegalSection(
            number: '6',
            title: 'Amendments & Policy Updates',
            body:
                'This Privacy Policy may be revised periodically to reflect application enhancements. All modifications will be published transparently within this view.',
          ),
        ],
        concludingNotice:
            'Should you have any inquiries regarding Cineva\'s zero-collection architecture or local storage mechanics, you are invited to inspect Cineva\'s open documentation and repository.',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. SYARAT DAN KETENTUAN / TERMS AND CONDITIONS
  // ─────────────────────────────────────────────────────────────────────────────
  static LegalDocumentData _getTermsAndConditions(bool isIndonesian) {
    if (isIndonesian) {
      return const LegalDocumentData(
        title: 'Syarat dan Ketentuan',
        subtitle: 'Perjanjian Hukum Penggunaan Piranti Lunak Cineva Secara Global',
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
        ],
        concludingNotice:
            'Penggunaan berkelanjutan atas aplikasi Cineva merupakan bentuk kesepakatan abadi Anda terhadap seluruh klausul hukum dalam Syarat dan Ketentuan ini.',
      );
    } else {
      return const LegalDocumentData(
        title: 'Terms and Conditions',
        subtitle: 'Global Legal Agreement for Cineva Software Usage',
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
        ],
        concludingNotice:
            'Continued engagement with Cineva constitutes your definitive and enduring assent to all clauses embodied within these Terms and Conditions.',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. DISCLAIMER / LEGAL DISCLAIMER & COPYRIGHT NOTICE
  // ─────────────────────────────────────────────────────────────────────────────
  static LegalDocumentData _getDisclaimer(bool isIndonesian) {
    if (isIndonesian) {
      return const LegalDocumentData(
        title: 'Disclaimer',
        subtitle: 'Pernyataan Penafian Hak Cipta, DMCA, & Batasan Tanggung Jawab',
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
        ],
        concludingNotice:
            'Dengan menggunakan Cineva, Anda menegaskan pemahaman Anda bahwa Cineva adalah alat pemutar piranti lunak mandiri dan membebaskan pengembang dari segala tanggung jawab atas konten yang Anda akses.',
      );
    } else {
      return const LegalDocumentData(
        title: 'Disclaimer',
        subtitle: 'Official Copyright Notice, DMCA Framework, & Liability Limitations',
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
        ],
        concludingNotice:
            'By engaging with Cineva, you affirmatively validate your understanding of Cineva\'s role as an independent media player and release its creators from all liability concerning content you elect to inspect.',
      );
    }
  }
}
