# Cineva v1.1.3 - Release Notes 🎬

Pembaruan Cineva versi 1.1.3 menghadirkan paket pembaruan besar **Eksplorasi & Penemuan Konten (*Content Discovery Suite*)** yang membawa pengalaman menjelajah film dan serial TV setara platform streaming kelas dunia. Menghadirkan **Jadwal Rilis & Kalender Episode (*Airing Calendar*)**, **Pemutar Trailer Resmi di Dalam Aplikasi (*In-App Official Trailer*)**, **Halaman Profil Aktor & Filmografi (*Person Detail & Filmography*)**, serta **Hub Waralaba / Koleksi Film (*Franchise Collection Hub*)** dengan kurva animasi transisi yang mulus (`Curves.easeOutCubic`) dan konsistensi warna tema **Pure OLED Black (`#000000`)**.

---

## Ringkasan Perubahan

### 1. Jadwal Rilis & Kalender Episode (Airing Calendar)
- **Kartu Banner Interaktif di Beranda**:
  - Pengguna dapat mengakses kalender rilis langsung melalui banner promosi interaktif yang elegan di halaman Beranda tepat di bawah *Hero Carousel / Trending*.
- **Pita Tanggal Horizontal (*Date Picker Ribbon*)**:
  - Menampilkan rentang 14 hari (3 hari lalu, hari ini, dan 10 hari ke depan) dengan highlight Cinema Amber pada tanggal yang dipilih dan tombol pintas *"Hari Ini / Today"*.
- **Filter Kategori Instan**:
  - Filter cepat sekali sentuh untuk:
    - **Semua**: Semua serial yang tayang di tanggal terpilih.
    - **Anime**: Serial animasi Jepang (`with_original_language=ja`, `with_genres=16`).
    - **K-Drama**: Drama Korea (`with_original_language=ko`).
    - **Barat**: Serial televisi Amerika & Inggris (`with_original_language=en`).
    - **Indonesia**: Serial lokal tanah air (`with_original_language=id`).
- **Kartu Episode Sinematik**:
  - Menampilkan poster beresolusi tinggi, badge kategori/negara (*ANIME*, *K-DRAMA*, *INDONESIA*, dll.), rating bintang, dan ringkasan episode.
  - Mengetuk kartu langsung membuka halaman detail serial TV secara *seamless*.

### 2. In-App Official Trailer
- **Modal Pemutar Video Sinematik Gelap**:
  - Membuka trailer resmi langsung di dalam aplikasi melalui modal bottom sheet berlatar hitam pekat OLED tanpa perlu beralih ke aplikasi pihak ketiga.
- **Teknologi YouTube No-Cookie Embed**:
  - Menggunakan komponen embed ringan `webview_flutter` yang bebas pelacak, tidak memerlukan login akun, dan hemat daya.
  - Dilengkapi tombol fallback untuk membuka langsung di aplikasi YouTube eksternal jika pengguna menginginkannya.
- **Pilihan Trailer Cerdas (*Smart Trailer Fallback*)**:
  - Algoritma secara otomatis memprioritaskan trailer resmi (*Official Trailer*), trailer standar, teaser, dan fallback ke bahasa Inggris jika server TMDB belum menandai trailer dalam bahasa lokal.
- **Tombol Aksi "Tonton Sekarang" Terintegrasi**:
  - Pengguna dapat langsung menekan tombol *"Tonton Sekarang / Watch Now"* dari dalam modal trailer untuk seketika beralih memutar film atau serial penuh.

### 3. Halaman Profil Aktor & Filmografi (Person Detail Screen)
- **Akses Langsung dari Daftar Pemeran**:
  - Mengetuk avatar aktor/aktris pada halaman detail film atau serial TV kini langsung membuka halaman profil aktor tersebut (`/person/:id`).
- **Avatar Sinematik dengan Amber Glow**:
  - Foto profil aktor berukuran besar dengan bingkai melingkar dan efek pencahayaan latar *Cinema Amber glow*.
- **Informasi Lengkap & Kalkulasi Usia Otomatis**:
  - Menampilkan departemen profesi (Pemeran/Sutradara), tanggal lahir beserta kalkulasi usia otomatis (*misal: 59 tahun*), dan tempat kelahiran.
- **Biografi Adaptif Beranimasi**:
  - Ringkasan biografi dengan tombol ekspansi animasi halus (*"Baca Selengkapnya / Sembunyikan"*).
- **Grid Filmografi Responsif**:
  - Menampilkan seluruh portofolio film dan serial TV yang dibintangi aktor tersebut yang diurutkan berdasarkan popularitas.
  - Dilengkapi filter tab (*Semua Karya*, *Film Saja*, *Serial TV Saja*).
  - Mengetuk poster karya langsung menavigasi ke halaman detail film atau serial TV terkait.

### 4. Hub Waralaba / Koleksi Film (Franchise Collection Hub)
- **Banner Koleksi pada Halaman Detail Film**:
  - Jika sebuah film tergabung dalam semesta waralaba (misal *The Avengers*, *Harry Potter*, *Spider-Man*, *Fast & Furious*), muncul banner kartu horizontal eksklusif *"Bagian dari Waralaba"* yang menyajikan poster mini dan tautan *"Lihat Koleksi Lengkap →"*.
- **Halaman Hub Koleksi (`/collection/:id`)**:
  - Menampilkan backdrop megah semesta waralaba dengan gradasi hitam yang menyatu ke latar OLED Black.
  - Menyajikan sinopsis koleksi dan badge total jumlah film (*misal: "8 Film dalam Koleksi"*).
- **Urutan Kronologis Rilis (*Chronological Timeline*)**:
  - Daftar film disusun rapi secara kronologis dari film pertama hingga rilisan terbaru dengan lencana nomor urut (1, 2, 3...), tahun rilis, rating, sinopsis ringkas, dan tombol aksi tonton langsung.

### 5. Konsistensi UI/UX & Lokalisasi Penuh
- **Pure OLED Black (#000000)**: Seluruh layar baru, modal bottom sheet, dan banner menggunakan latar belakang hitam pekat murni yang hemat daya layar AMOLED dan nyaman di mata saat kondisi gelap.
- **Kurva Animasi Halus**: Transisi rute menggunakan `Curves.easeOutCubic` dengan staggered animation delay bergradasi 30ms pada daftar item.
- **100% Dukungan Dwibahasa**: Seluruh string baru terdaftar lengkap dalam Bahasa Indonesia dan English pada `AppStrings`.

---

## Riwayat Versi Sebelumnya

### Cineva v1.1.2
- **Distribusi Multi-Arsitektur APK (Split-per-ABI)**: 4 varian APK terpisah (`arm64-v8a`, `armeabi-v7a`, `x86_64`, dan `universal`) menghemat ukuran unduhan hingga 60% (~16 MB vs ~38 MB).
- **Deteksi Cerdas Arsitektur CPU Native Android**: Aplikasi otomatis memilih varian file unduhan yang paling sesuai dengan prosesor perangkat pengguna saat update.
- **Panel Informasi Film & Episode pada Pemutar Video**: Ikon info di bilah kontrol pemutar untuk membuka panel samping sinopsis dan detail episode bergaya YouTube tanpa menghentikan pemutaran video.
- **Modal Detail Pembaruan Aplikasi & Auto-Translasi**: Popup changelog interaktif dengan fitur auto-translasi dwibahasa untuk catatan rilis GitHub.

### Cineva v1.1.1
- **Sinkronisasi Cluster Scraper Flixquest (`scraper.flix.quest`)**: Akses ke 17+ upstream scrapers terverifikasi dan multi-instance failover.
- **Prioritas Provider Film Bioskop Indonesia & Asia**: Penempatan provider `movy` dan `moviepire` di urutan teratas untuk film bioskop Indonesia dan anime.
- **Native 404 Stream Unavailable Overlay**: Pencegahan pemutaran video iklan atau salah judul dengan overlay bertema *Cinema Amber & Deep Obsidian*.
- **Pembersihan Kontrol Ganda & Side Panel Border Tipis**: Redesain menu server, episode, kualitas, dan subtitle dengan *subtle border* 0.8px tanpa card tebal.
- **Katalog TV Live Terlengkap**: Saluran nasional (Indosiar HD, Moji HD, SCTV HD, Trans TV, Trans7 HD, dll.) dan internasional dengan *YouTube-Style Channel Drawer*.

### Cineva v1.1.0
- **Navigasi Kembali TV Live & Animasi Slide-Up**: Pemulihan instan bottom navigation bar tanpa perlu menekan tombol back dua kali.
- **Kunci Otomatis Orientasi Lanskap Layar Penuh TV Live**: Rotasi instan ke lanskap saat tombol fullscreen ditekan.
- **Penyimpanan Permanen Pengaturan Subtitle**: Penyimpanan persistensi untuk stroke/outline, offset vertikal, dan warna font pada Hive settings.

---

## Informasi Versi

- **Versi Aplikasi**: 1.1.3
- **Build**: 14
- **Target Sistem Operasi**: Android 5.0 (API 21) ke atas
- **Daftar Varian File APK**:
  - `Cineva_v1.1.3-arm64-v8a.apk` (HP Android Modern 64-bit, ~16 MB)
  - `Cineva_v1.1.3-armeabi-v7a.apk` (HP Android Lawas 32-bit, ~15 MB)
  - `Cineva_v1.1.3-x86_64.apk` (Emulator PC & Chromebook, ~18 MB)
  - `Cineva_v1.1.3.apk` (Universal / Semua CPU, Kompatibel Penuh, ~38 MB)
