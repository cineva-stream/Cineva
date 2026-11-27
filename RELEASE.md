# Cineva v1.2.2 - Release Notes 🎬

Pembaruan Cineva versi **1.2.2 (Build 23)** menghadirkan perombakan besar pada pengalaman **TV Live & Siaran Sepak Bola Real-Time**, keandalan pemutaran seluruh saluran TV nasional maupun internasional, serta rangkaian fitur sinematik dan perlindungan data pengguna: sistem **Deteksi Pertandingan Sepak Bola Live Berbasis Real-Time EPG + Live Scoreboard** lengkap dengan **Modal Turnamen Sepak Bola**, mesin **Local Loopback DASH-to-HLS fMP4 Bridge** untuk memutar seluruh channel TV Live tanpa *stuck loading*, fitur **Cadangan Otomatis Lokal (*Auto Backup*)** langsung ke folder `Documents/Cineva`, **Bookmark Momen Adegan & Studio Kartu Kutipan (*Quote Card*)**, **Bagikan Tayangan 2 Baris dengan Deep Link Instan**, **Watch Party `1.05x` Smooth Micro-Speed Catch-Up**, serta **Layar Pembaruan Wajib (*Mandatory Update*)** dan **Lini Masa Catatan Rilis 3 Bahasa**.

---

## Ringkasan Fitur Baru & Peningkatan Utama (v1.2.2)

### 1. Deteksi Pertandingan Sepak Bola Real-Time EPG & Modal Turnamen (*Real-Time EPG Live Football Match & Tournament Modal*)
* **Verifikasi Silang Jadwal TV Real-Time (`XMLTV EPG`) & Live Scoreboard**:
  * Sistem deteksi pertandingan bola kini memverifikasi jadwal program TV yang sedang tayang saat itu juga (`start <= now < stop`) dari feed EPG real-time pada channel-channel olahraga dan nasional di Cineva (*SCTV HD, Indosiar HD, RCTI HD, MNCTV HD, GTV HD, iNews HD, Moji, TVRI Sport HD, TVRI Nasional, beIN Sports 1 HD, beIN Sports 2 HD, beIN Sports 3 HD, Soccer Channel HD, Sportstars HD, SPOTV 2 HD, A Spor HD*) dengan data skor langsung dari ESPN Scoreboard.
  * Bagian **"Tayang di" (*Broadcasting on* / *प्रसारण चैनल*)** kini **100% real-time dan akurat**: hanya menampilkan channel yang benar-benar sedang menayangkan pertandingan tersebut beserta judul program EPG asli dan jam tayangnya dalam WIB (contoh: `UEL 2026/27: OLY Vs MIL (L) • 00:40–02:55 WIB`).
  * Ketika beberapa pertandingan berlangsung serentak di channel berbeda (misalnya *beIN Sports 1 HD*, *beIN Sports 2 HD*, dan *SCTV HD / beIN Sports 3 HD*), setiap pertandingan dipisahkan secara presisi lengkap dengan daftar channel penayangnya masing-masing.
  * Secara otomatis menyaring pertandingan asing yang tidak ditayangkan di TV maupun program olahraga non-sepak bola (*Premier Padel, V-League Voli, Highlights, FTV*).
* **Desain Baru Modal Ala Turnamen Sepak Bola (*Tournament Matchday Arena UI*)**:
  * Tampilan modal **`LIVE FOOTBALL MATCH`** didesain ulang bergaya grafis siaran turnamen sepak bola modern tanpa tumpukan *badge* berlebihan: header kompetisi bersih dengan indikator titik merah *LIVE*, arena papan skor dengan lambang tim di dalam cincin lingkaran, kartu *official broadcaster* berlogo channel resmi, serta tombol **"Tonton Sekarang"** yang selalu tersemat (*pinned*) dan langsung membuka siaran channel terpilih.

### 2. Optimalisasi Mesin Pemutar TV Live & 75 Saluran Berlogo Resmi (*DASH-to-HLS fMP4 Bridge & Verified Streams*)
* **Local Loopback DASH-to-HLS fMP4 Bridge (`127.0.0.1`)**:
  * Membangun jembatan konversi *in-app* yang menerjemahkan aliran MPD DASH dinamis (`index.mpd` dengan `<SegmentTimeline>` pada *SCTV HD, Indosiar HD, Moji, Metro TV, ANTV, tvOne, MDTV, RTV, BTV, TVRI*) menjadi aliran *live* HLS fMP4 (`#EXT-X-MAP`) secara *real-time*, mengatasi *crash* dan *stuck loading* demuxer `dashdec` pada FFmpeg / `libmpv`.
* **Smart Master Playlist & Cross-Domain Redirect Resolver**:
  * Resolusi langsung *child video playlist* 720p/1080p pada aliran dinamis Wurl/Xumo (*FIFA+ Live HD, NBC News NOW, ABC News Live*) serta *302 redirect* lintas domain (*RCTI HD, GTV HD, MNCTV HD, iNews HD*) dengan injeksi header `Referer` dan `User-Agent` tingkat native `libmpv` serta penonaktifan *subtitle track* kosong (`sid=no`).
* **Pembaruan Katalog 75 Saluran TV Live & Logo Resmi**:
  * Memperbarui seluruh aliran channel TV Live di semua kategori (*Olahraga, Nasional, Berita, Film, Anak, Musik, Dokumenter*) agar dapat diputar sepenuhnya dengan *multi-URL automatic failover* (`fallbackStreamUrls`) dan logo resmi beresolusi penuh pada seluruh 75 channel (termasuk perbaikan logo *Trans TV* dan *iNews HD*).

### 3. Cadangan Otomatis Lokal Tanpa Akun (*Local Auto Backup to `Documents/Cineva`*)
* **Pencadangan Terjadwal & Mandiri di Penyimpanan Perangkat**:
  * Menambahkan halaman **Cadangan Otomatis (*Auto Backup* / *ऑटो बैकअप*)** di menu Pengaturan yang secara otomatis mencadangkan riwayat tontonan, *watchlist*, profil, dan preferensi pengguna ke folder `Documents/Cineva` tanpa memerlukan login akun.
  * Mendukung pilihan frekuensi **Mingguan (7 hari)**, **Bulanan (30 hari)**, atau **Nonaktif**, dilengkapi tombol **Cadangkan Sekarang** serta daftar berkas cadangan tersimpan yang dapat dipulihkan (*Restore*) atau dihapus kapan saja.

### 4. Penanda Momen Adegan & Kartu Kutipan Sinematik (*Scene Bookmarks & Cinematic Quote Card Studio*)
* **Simpan Detik Adegan Favorit di Pemutar Video**:
  * Pengguna dapat menandai momen adegan favorit (*Scene Bookmark*) langsung saat menonton film atau episode serial TV, lengkap dengan *timestamp* presisi dan teks dialog *subtitle* yang sedang tampil.
* **Studio Kartu Kutipan Sinematik (*Cinematic Quote Card*)**:
  * Mengubah momen adegan atau dialog favorit menjadi gambar kartu kutipan bergaya poster sinema yang siap disimpan atau dibagikan ke media sosial.

### 5. Bagikan Tayangan dengan Poster & Deep Link Instan `0ms` (*Rich Media Share & Root Deep Links*)
* **Tata Letak Aksi Detail 2 Baris & Berbagi Poster Otomatis**:
  * Halaman detail Film dan Serial TV kini menampilkan tata letak tombol aksi 2 baris yang rapi dengan fitur **Bagikan (*Share*)** yang menyertakan gambar poster tayangan beserta tautan langsung (`https://cineva-stream.github.io/movie/:id` dan `/tv/:id`).
* **Prioritas Peluncuran Aplikasi Native Instan (`0ms`)**:
  * Halaman web *deep link* untuk Film, Serial TV, dan Ruangan Watch Party (`/party/:code`) kini langsung memicu pembukaan aplikasi native Cineva pada `0ms` dengan halaman *fallback* berbahasa Inggris yang responsif apabila aplikasi belum terpasang.

### 6. Watch Party `1.05x` Smooth Micro-Speed Catch-Up
* **Sinkronisasi Halus Tanpa Jeda Buffering**:
  * Ketika posisi pemutaran peserta Watch Party tertinggal tipis (`0.8 – 3.5 detik`) dari *host*, pemutar video secara otomatis menerapkan percepatan mikro **`1.05x`** hingga kembali sejajar secara mulus tanpa melakukan *hard seek* yang memicu *loading* ulang.

### 7. Layar Pembaruan Wajib, Lini Masa Catatan Rilis 3 Bahasa & Balasan Email Feedback Otomatis
* **Perlindungan Pembaruan Wajib (*3-Missed-Updates Mandatory Update Screen*)**:
  * Menampilkan layar pembaruan penuh bergaya *Cinema Amber* secara otomatis apabila versi aplikasi pengguna tertinggal 3 rilis atau lebih di belakang versi terbaru.
* **Lini Masa Catatan Rilis (*Release Notes Timeline*) & Halaman Bahasa Aplikasi**:
  * Menambahkan halaman **Catatan Rilis** vertikal bergaya *timeline* yang merangkum fitur inti setiap versi dalam 3 bahasa (`id`, `en`, `hi`), serta halaman khusus pemilihan **Bahasa Aplikasi**.
* **Balasan Email Otomatis (*Plain-Text SMTP Auto-Reply*) pada Masukan Pengguna**:
  * Pengiriman masukan dan laporan bug (*Feedback*) kini dilengkapi sistem balasan email otomatis dengan cap waktu `Asia/Jakarta (WIB)`.

---

## Riwayat Versi Sebelumnya

### Cineva v1.2.1
* **Dukungan Penuh Bahasa India / Hindi (`id`, `en`, `hi`)**: Ekspansi lokalisasi 3 bahasa menyeluruh di seluruh antarmuka aplikasi beserta pengayaan metadata episode TV cerdas (*automatic `en-US` fallback*).
* **Rekomendasi Personal *"Because You Watched..."***: Saran konten cerdas di halaman Beranda berdasarkan film atau serial TV yang terakhir ditonton.
* **Halaman Cineva Insights & Studio Kartu Member**: Dasbor statistik jam menonton, genre favorit, dan pencapaian penonton di menu Profil, lengkap dengan kartu identitas member bergaya Kartu ID & Kartu ATM Cineva.
* **Optimalisasi Mesin Unduhan Offline (*Background Isolate*)**: Pengunduhan segmen HLS dan dekripsi `AES-128-CBC` 16 *worker* di `Isolate` latar belakang tanpa membebani UI (`< 0.5 detik` *finalizing*) serta *Smart Concurrent Download Queue*.
* **5 Section Katalog Regional Baru & Bilah Filter Modern**: Penambahan kategori **Anime, K-Drama, Indonesia, Hollywood, dan Bollywood** di Beranda dengan halaman *See All* *infinite scroll*, perlindungan tayangan *"Segera Hadir"*, urutan pencarian rilis terbaru (*Newest First*), serta integrasi saluran resmi Telegram (`https://t.me/cineva_platform`).

### Cineva v1.2.0
* **Pratinjau Pesan Obrolan Dynamic Island**: Kapsul notifikasi pesan chat melayang bergaya *Dynamic Island* saat panel obrolan Watch Party ditutup.
* **Mini Preview & Indikator Waktu Melayang pada Progress Bar**: Kartu pratinjau 16:9 glassmorphic dengan timecode digital presisi dan kalkulasi selisih waktu loncat (*seek delta*) saat *hover* di Windows maupun *scrubbing* sentuh di Android.
* **Partikel Reaksi Melayang ala TikTok Live**: Aliran emoji interaktif *real-time* yang tersinkronisasi ke seluruh peserta Watch Party.
* **Proteksi PIN Ruangan Watch Party & Deep Linking**: Keamanan opsional 4 digit PIN ruangan serta pembagian tautan langsung ruangan nobar via GitHub Pages.
* **Desain Ulang Halaman Info & Migrasi Paket Resmi**: Mosaik poster film tanpa batas pada halaman Info Aplikasi serta migrasi identitas paket ke `com.cinevagroup.cinevastream`.

### Cineva v1.1.9
* **Lanjutkan Menonton Cerdas (Seamless Device Hand-Off)**: Pelacakan sesi pemutaran lintas perangkat cerdas via Cloud dengan kapsul notifikasi melanjutkan tontonan di detik yang tepat.
* **Nonton Bareng Jarak Jauh (Watch Party & Sync Play Engine)**: Pembuatan ruangan dengan kode 8 digit, dual-engine cloud relay (Firebase & Cloud Relay), integrasi side panel pemutar video, serta sinkronisasi play/pause/seek dengan kompensasi latensi.
* **Live Chat & Pesan Mengambang**: Panel obrolan di samping pemutar video, pratinjau pesan kaca, dan partikel reaksi emoji dasar.
* **Normalisasi Alami Singkatan & Akronim Subtitle**: Perbaikan pemisah titik tokenizer untuk singkatan berjarak/bertitik (`L.A.P.D.`, `T.O.`, `U.S.A.`) dan dukungan imbuhan bahasa Indonesia.
* **Cinematic NLP Post-Processing Engine**: Mesin penerjemah dialog alami lokal untuk mengubah terjemahan kaku menjadi bahasa sinematik khas bioskop secara gratis tanpa kuota API.
* **Sinkronisasi Cloud Real-Time**: Sinkronisasi otomatis tanpa tombol manual untuk Watchlist, Riwayat Tontonan, dan Profil pengguna akun Google.

### Cineva v1.1.8
* **Relayout Responsif Modern**: Grid adaptif dan bilah navigasi samping (*Side Navigation Rail*) untuk Tablet, Windows Desktop & Android TV.
* **Perbaikan Total Navigasi Remote D-Pad Android TV**: Mesin fokus `TvFocusable` baru, eliminasi bug fokus terjebak di pemutar video, serta dukungan D-Pad menyeluruh di Search, Detail, Watchlist, Riwayat, dan Unduhan.
* **Perbaikan Bug Orientasi Layar**: Memperbaiki penguncian paksa ke `portraitUp` saat keluar dari pemutar video di Tablet dan TV.
* **Rilis Fitur Unduhan Offline**: Parser HLS m3u8, dekripsi segmen TS terenkripsi AES-128, perakitan MP4 offline mandiri via `OfflineMp4Builder`, UI progress realtime saat *finalizing*, dan pengelompokan serial TV dengan poster resmi serta dropdown season.
* **Penyempurnaan Pemutar Video & Android PiP**: Urutan kontrol bilah atas yang ergonomis, pemisahan navigasi *Back* bersih dengan aktivasi PiP eksklusif via tombol Home / ikon PiP, serta skala subtitle otomatis 1080p/4K untuk sofa viewing di Windows dan Android TV.

---

## Informasi Versi

* **Versi Aplikasi**: 1.2.2
* **Build**: 23
* **Target Sistem Operasi**: Android 5.0 (API 21) ke atas (Smartphone, Tablet & Android TV / Google TV), Windows 10/11 (64-bit)
* **Daftar Varian File Rilis**:
  * `Cineva_setup_v1.2.2.exe` (Windows Desktop Installer Resmi)
  * `Cineva_v1.2.2-android-tv.apk` (Khusus Android TV & Smart TV - **Rekomendasi TV**)
  * `Cineva_v1.2.2-arm64-v8a.apk` (HP & Tablet Android Modern 64-bit)
  * `Cineva_v1.2.2-armeabi-v7a.apk` (HP & Tablet Android Lawas 32-bit)
  * `Cineva_v1.2.2-x86_64.apk` (Emulator PC & Android x86)
  * `Cineva_v1.2.2.apk` (Universal / Semua CPU, Kompatibel Penuh)
