# Cineva v1.1.6 - Release Notes 🎬

Pembaruan Cineva versi 1.1.6 menghadirkan penyempurnaan besar pada **Eksplorasi Katalog Beranda (Full Catalog Grid & Top 8-10 Carousel)** untuk kategori Film dan Serial TV, serta pembaruan masif pada fitur **"Pilih Sesuai Platform" (Choose by Platform)** dengan pemulihan ribuan judul film/serial TV dan dukungan **Paginasi & Infinite Scroll Berkelanjutan**.

---

## Ringkasan Fitur Baru & Peningkatan Utama

### 1. Desain Ulang Filter Kategori Beranda: Full Grid Responsif & Top 8-10 Carousel
* **Filter "Film" (Movies)**:
  * **Top 8-10 Carousel Film Populer**: Bagian atas kini menyajikan 8 hingga 10 film terpopuler dengan transisi otomatis, cuplikan sinopsis, dan tombol tonton langsung.
  * **Full Grid SELURUH Film**: Menghilangkan section-section horizontal yang membatasi konten, digantikan dengan tampilan grid poster responsif (rasio 2:3) yang memuat seluruh katalog film.
  * **Infinite Scroll Berkelanjutan**: Film-film berikutnya akan termuat secara otomatis saat pengguna men-scroll ke bawah tanpa henti.
* **Filter "Serial TV" (TV Shows)**:
  * **Top 8-10 Carousel Serial TV Populer**: Menampilkan carousel khusus serial TV terpopuler lengkap dengan badge *POPULER TV* dan navigasi langsung ke episode serial TV.
  * **Full Grid SELURUH Serial TV**: Menampilkan seluruh serial TV secara utuh dalam format poster grid responsif dengan dukungan *infinite scroll* berkelanjutan.
* **Filter "Semua" (All)**:
  * Tetap mempertahankan susunan dashboard beranda klasik yang kaya (Hero Trending Carousel, Continue Watching, Airing Calendar Banner, Top 10 Netflix-style, Film Populer, Serial TV Populer, Rating Tertinggi, dan Segera Tayang di Bioskop).

### 2. Pembaruan Masif "Pilih Sesuai Platform" (Thousands of Titles & Infinite Scroll)
* **Perbaikan TMDB Watch Provider ID (Fix 0/Sedikit Hasil)**:
  * Memperbarui ID TMDB yang sebelumnya *obsolete* sehingga konten yang tampil kini berjumlah ribuan:
    * **Max / HBO Max**: Diperbarui ke ID resmi `1899|1825` (menghadirkan 2.000+ film dan 1.800+ serial TV dari sebelumnya 0 hasil).
    * **Paramount+**: Diperbarui ke multi-channel `582|2303|531` (menghadirkan 1.300+ film dan 800+ serial TV dari sebelumnya hanya 4 hasil).
    * **Peacock**: Diperbarui ke `386|387` (menghadirkan 1.200+ film dan 1.000+ serial TV Peacock).
    * **Amazon Prime Video**: Diperbarui ke `9|119` (menjangkau puluhan ribu judul).
* **Paginasi & Infinite Scrolling Penuh**:
  * Menghapus batasan lama yang hanya mengambil 1 halaman (20 item).
  * Pengguna kini dapat men-scroll ke bawah untuk terus memuat halaman 2, 3, 4, dst. secara mulus dengan indikator pemuatan halus.
* **Filter Chip Lengkap & Unified Grid (All, Movies, TV Shows)**:
  * Memudahkan pengguna memilah katalog platform streaming yang dipilih apakah ingin melihat Semua dalam satu grid utuh (*unified stream*), hanya Film, atau hanya Serial TV.

### 3. Peningkatan Pengalaman Streaming Windows Desktop (Auto-Hide Cursor & Anti-Jitter)
* **Kursor Mouse Auto-Hide Mengikuti Kontrol Player**:
  * Kursor mouse otomatis disembunyikan saat panel kontrol pemutar video menghilang, memberikan pengalaman menonton bebas distraksi.
* **Filter Getaran Akustik Meja (*Anti-Jitter Threshold 14px*)**:
  * Meredam pergeseran mikro akibat dentuman bass/subwoofer kencang atau getaran meja, sehingga kontrol dan kursor tidak muncul secara tidak sengaja.
* **Penyempurnaan Navigasi Multi-Tab & Lokalisasi Global**:
  * Memperbaiki navigasi antar-tab dari halaman katalog platform streaming ke Pengaturan (*Settings*), Beranda, dsb.
  * Lokalisasi dinamis badge tipe media (`MOVIE` dalam bahasa Inggris, `FILM` dalam bahasa Indonesia).

### 4. Penyempurnaan Penginstal Windows (Multilingual License Agreement & Tipografi Bersih)
* **Dukungan Multibahasa Dinamis pada Setup**:
  * Naskah Syarat dan Ketentuan (*License Agreement*) pada setup instalasi Inno Setup kini otomatis menyesuaikan bahasa instalasi yang dipilih pengguna (Bahasa Indonesia atau English).
* **Format Bersih Tanpa Garis Pembatas**:
  * Menghilangkan seluruh garis pembatas dekoratif, menyajikan dokumen legal dengan pemisah baris (*linebreak*) yang rapi dan ketebalan huruf judul (*bold typography*) yang nyaman dan mudah dipahami.

---

## Riwayat Versi Sebelumnya

### Cineva v1.1.5
* **Sinkronisasi Data & Profil Multi-Perangkat via QR Code (Zero-Config Hybrid Mode)**: Onboarding otomatis Android TV dan dual-mode pairing nirkabel lintas jaringan Wi-Fi dan seluler.
* **Modal Changelog Berbasis GitHub Markdown (GFM)**: Parser resmi GitHub Markdown di dalam aplikasi.
* **Pemisahan Build Khusus Android TV Super Ringan**: APK khusus 32-bit ARM berukuran hemat memori (~15-20 MB).
* **Otomasi Tanda Tangan Digital Windows**: Authenticode SHA-256 untuk installer Windows.

---

## Informasi Versi

* **Versi Aplikasi**: 1.1.6
* **Build**: 17
* **Target Sistem Operasi**: Android 5.0 (API 21) ke atas (Smartphone & Android TV / Google TV), Windows 10/11 (64-bit)
* **Daftar Varian File Rilis**:
  * `Cineva_setup_v1.1.6.exe` (Windows Desktop Installer Resmi)
  * `Cineva_v1.1.6-android-tv.apk` (Khusus Android TV & Smart TV - **Rekomendasi TV**)
  * `Cineva_v1.1.6-arm64-v8a.apk` (HP Android Modern 64-bit)
  * `Cineva_v1.1.6-armeabi-v7a.apk` (HP Android Lawas 32-bit)
  * `Cineva_v1.1.6-x86_64.apk` (Emulator PC & Android x86)
  * `Cineva_v1.1.6.apk` (Universal / Semua CPU, Kompatibel Penuh)
