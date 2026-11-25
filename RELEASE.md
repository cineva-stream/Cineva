# Cineva v1.2.1 - Release Notes 🎬

Pembaruan Cineva versi **1.2.1 (Build 22)** menghadirkan ekspansi katalog konten global, personalisasi tontonan cerdas, serta lonjakan besar pada performa pengunduhan offline: dukungan penuh **Bahasa India (Hindi / हिन्दी)** di seluruh antarmuka (3 bahasa: Indonesia, English, dan Hindi), section rekomendasi personal **"Because You Watched..."** berdasarkan film atau serial TV yang ditonton, halaman **Cineva Insights & Statistik Tontonan** di menu Profil (lengkap dengan kartu identitas member bergaya ID / ATM Cineva), **Optimalisasi Mesin Unduhan Offline** (*Background Isolate* anti-lag dengan proses *finalizing* instan), penambahan 5 section regional baru (**Indonesia, Anime, K-Drama, Hollywood, dan Bollywood**) di layar utama lengkap dengan halaman katalog penuh *infinite scroll* (*See All*), serta pembaruan **Logika & Filter Pencarian** yang kini secara default menampilkan rilis terbaru terlebih dahulu.

---

## Ringkasan Fitur Baru & Peningkatan Utama (v1.2.1)

### 1. Dukungan Penuh Bahasa India / Hindi (*Full Trilingual Localization: Indonesia, English & Hindi*)
* **Ekspansi Lokalisasi 3 Bahasa Menyeluruh (`id`, `en`, `hi`)**:
  * Menambahkan bahasa **India (Hindi / हिन्दी)** sebagai bahasa resmi ketiga di Cineva mendampingi Bahasa Indonesia dan Bahasa Inggris.
  * Seluruh teks antarmuka aplikasi — mulai dari layar awal (*Splash Screen*), Beranda, Pencarian, Filter & Urutkan, Halaman Detail Film/Serial, Pemutar Video, Subtitle, Watch Party, Unduhan Offline, Profil, hingga Dokumen Legalitas & Halaman Info Aplikasi — telah diterjemahkan secara lengkap dan konsisten ke dalam 3 bahasa.
  * Dilengkapi pengayaan metadata episode TV cerdas (*automatic `en-US` fallback*) sehingga judul dan sinopsis setiap episode serial TV tetap tampil lengkap meskipun bahasa aplikasi diatur ke Bahasa Indonesia atau Hindi.

### 2. Rekomendasi Personal Berdasarkan Tontonan (*"Because You Watched..." Personalized Section*)
* **Saran Konten Cerdas dari Riwayat Tontonan**:
  * Menampilkan section dinamis **"Karena Anda Menonton [Judul]..."** (*"Because You Watched..."* / *"क्योंकि आपने ... देखा"*) secara otomatis di halaman Beranda berdasarkan film atau serial TV yang terakhir Anda tonton.
  * Mengkurasi judul-judul serupa yang relevan dan sudah tersedia untuk ditonton, dengan tampilan header rata kiri yang bersih dan minimalis.

### 3. Halaman Cineva Insights & Statistik di Menu Profil (*Watch Insights, Stats & Member Card Studio*)
* **Dasbor Analisis Aktivitas Menonton**:
  * Menambahkan halaman **Cineva Insights / Statistik Tontonan** yang dapat diakses langsung dari menu Profil.
  * Menampilkan ringkasan metrik tontonan personal secara visual: total durasi jam menonton, jumlah film dan episode serial TV yang telah diselesaikan, distribusi genre favorit, tren aktivitas harian/mingguan, serta pencapaian (*milestones*) penonton.
* **Studio Kartu Member Cineva (Gaya Kartu ID & Kartu ATM Premium)**:
  * Pengguna dapat melihat, menyesuaikan, dan membagikan kartu identitas anggota resmi Cineva (*Cineva Member Card*) dalam desain Kartu ID sinematik maupun kartu ATM modern lengkap dengan statistik tontonan pengguna.

### 4. Optimalisasi Mesin Unduhan Offline (*High-Speed Background Isolate Download Engine*)
* **Zero UI Lag dengan Background Isolate Murni**:
  * Memindahkan seluruh proses pengunduhan segmen HLS, dekripsi paralel `AES-128-CBC`, ekstraksi *wrapper* Gzip/PNG/WebP, dan penyelarasan paket MPEG-TS (`0x47`) ke dalam `Isolate.spawn` latar belakang khusus dengan 16 *worker* paralel.
  * Menjaga *frame rate* layar utama tetap mulus 60/120 FPS tanpa beban pada *main UI thread* meskipun sedang mengunduh video berkecepatan lebih dari 10 MB/s.
* **Finalisasi Instan (`< 0.5 Detik`) & Smart Download Queue**:
  * Perakitan berkas video dilakukan secara progresif selama pengunduhan berlangsung (*in-memory sliding-window progressive assembler*), sehingga tahap *Finalizing* selesai secara instan tanpa menyalin ulang ratusan segmen di akhir unduhan.
  * Dilengkapi sistem antrean unduhan cerdas (*Smart Concurrent Download Queue*, maksimal 2 unduhan aktif bersamaan dengan status *"Dalam antrean..."* otomatis) serta pembersihan segmen sementara secara asinkron di latar belakang.

### 5. Section Katalog Regional Baru di Beranda (*Indonesia, Anime, K-Drama, Hollywood & Bollywood*)
* **5 Kategori Kurasi Regional & Genre Populer**:
  * Menambahkan 5 section baru di halaman Beranda (**Home Screen**): **Anime**, **K-Drama**, **Indonesia**, **Hollywood**, dan **Bollywood** yang menampilkan tayangan terbaru yang sudah rilis dan siap ditonton.
* **Halaman Katalog Penuh Infinite Scroll (`See All`) & Immersive Edge-to-Edge**:
  * Setiap section dilengkapi tombol **"Lihat Semua" (*See All*)** yang membuka halaman katalog penuh dengan *infinite scroll* mulus, tampilan layar penuh *Immersive Edge-to-Edge* (tanpa bilah navigasi bawah yang menghalangi), serta filter tipe media (*Semua, Film, Serial TV*), urutan (*Terbaru, Populer, Rating Tertinggi*), Tahun Rilis, dan Genre.
* **Perlindungan Cerdas Tayangan Belum Rilis (*Smart "Segera Hadir" Guard*)**:
  * Film atau episode serial TV yang tanggal rilisnya masih di masa depan dan belum tersedia di server otomatis menonaktifkan tombol tonton menjadi **"Segera Hadir"** (*"Coming Soon"* / *"जल्द आ रहा है"*) serta menyembunyikan tombol unduh, namun tetap melakukan pengecekan latar belakang (*stream availability probe*) agar tayangan yang rilis lebih awal tetap langsung bisa diputar.

### 6. Logika Pencarian Terbaru & Bilah Filter Modern (*Newest-First Search & Unified Filter Bar*)
* **Urutan Default Hasil Pencarian dari Rilis Terbaru**:
  * Logika hasil pencarian kini diperbarui agar secara otomatis mengurutkan dan menampilkan film maupun serial TV dari **rilis terbaru terlebih dahulu** (*Newest First*), sambil tetap menjaga relevansi judul dan menyaring item tanpa poster yang tidak valid.
* **Desain Bilah Filter Satu Baris yang Rapi (*Single-Row Smart Filter Bar*)**:
  * Halaman hasil pencarian dan halaman katalog *See All* kini menggunakan bilah filter satu baris rata tengah dengan latar hitam khas Cineva dan *smooth border* elegan:
    * Chip cepat untuk tipe konten (**Semua / Film / Serial TV**).
    * Satu tombol **Filter & Urutkan** terpadu (dengan lencana indikator jumlah filter aktif) yang membuka panel *Bottom Sheet* modern untuk memilih **Urutkan Berdasarkan** (*Terbaru, Populer, Rating Tertinggi*), **Tahun Rilis**, dan **Genre**.

### 7. Integrasi Saluran Resmi Telegram & Deep Link Media (*Official Telegram Channel & "Watch on Cineva"*)
* **Menu "Join Our Channel" di Halaman Info Aplikasi**:
  * Menambahkan kartu menu **Gabung Saluran Kami (*Join Our Channel* / *हमारे चैनल से जुड़ें*)** lengkap dengan ikon vektor resmi Telegram (`https://t.me/cineva_platform`) di halaman Info Aplikasi sejajar dengan GitHub dan Email Pengembang.
* **Deep Link Langsung ke Halaman Film & Serial TV**:
  * Mendukung pembukaan tautan langsung `/Cineva/movie/:id`, `/Cineva/tv/:id`, `cineva://movie/:id`, dan `cineva://tv/:id` dari tombol aksi **Watch on Cineva** di saluran Telegram langsung menuju halaman detail tayangan di dalam aplikasi.

---

## Riwayat Versi Sebelumnya

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

* **Versi Aplikasi**: 1.2.1
* **Build**: 22
* **Target Sistem Operasi**: Android 5.0 (API 21) ke atas (Smartphone, Tablet & Android TV / Google TV), Windows 10/11 (64-bit)
* **Daftar Varian File Rilis**:
  * `Cineva_setup_v1.2.1.exe` (Windows Desktop Installer Resmi)
  * `Cineva_v1.2.1-android-tv.apk` (Khusus Android TV & Smart TV - **Rekomendasi TV**)
  * `Cineva_v1.2.1-arm64-v8a.apk` (HP & Tablet Android Modern 64-bit)
  * `Cineva_v1.2.1-armeabi-v7a.apk` (HP & Tablet Android Lawas 32-bit)
  * `Cineva_v1.2.1-x86_64.apk` (Emulator PC & Android x86)
  * `Cineva_v1.2.1.apk` (Universal / Semua CPU, Kompatibel Penuh)
