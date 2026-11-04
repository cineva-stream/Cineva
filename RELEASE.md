# Cineva v1.1.3 - Release Notes 🎬

Pembaruan Cineva versi 1.1.3 menghadirkan paket pembaruan besar **Eksplorasi & Penemuan Konten (*Content Discovery Suite*)** yang membawa pengalaman menjelajah film dan serial TV setara platform streaming kelas dunia. Menghadirkan **Jadwal Rilis & Radar Rilis 2-Tab (*Airing Calendar & Coming Soon*)**, **Hub Semesta & Urutan Nonton Serial TV (*TV Universe & Watch Order Hub*)**, **Pemutar Trailer Resmi di Dalam Aplikasi (*In-App Official Trailer*)**, **Halaman Profil Aktor & Filmografi (*Person Detail & Filmography*)**, serta **Hub Waralaba Film (*Franchise Collection Hub*)** dengan kurva animasi transisi yang mulus (`Curves.easeOutCubic`) dan konsistensi warna tema **Pure OLED Black (`#000000`)**.

---

## Ringkasan Perubahan

### 1. Kalender Siaran & Radar Rilis 2-Tab (Airing Calendar & Coming Soon)
- **Desain Minimalis & Borderless**:
  - Menggantikan kartu-kartu tebal dengan daftar minimalis elegan bergaris batas halus (*smooth hairline divider*), memberikan ruang pandang yang lega, modern, dan konsisten dengan antarmuka Cineva lainnya.
- **Banner Beranda Sinematik dengan Rotasi Poster Otomatis**:
  - Ditempatkan presisi di halaman Beranda tepat di bawah *Hero Billboard Carousel* dan di atas *Lanjutkan Menonton*.
  - Dilengkapi animasi latar belakang poster berputar dinamis setiap 4 detik untuk menyajikan konten segar secara visual.
- **Dukungan 2 Tab Navigasi Atas**:
  - **Tab 1: Episode Mingguan (*Weekly Schedule*)**:
    - Pita tanggal horizontal 14 hari dengan tombol pintas *"Hari Ini / Today"*.
    - Filter kategori cepat: *Semua*, *Anime* (Jepang), *K-Drama* (Korea), *Barat* (US/UK), dan *Indonesia*.
  - **Tab 2: Segera Hadir (*Coming Soon / Release Radar*)**:
    - Radar rilisan film bioskop dan serial TV yang paling dinantikan di masa mendatang.
    - Filter kategori instan (*Semua*, *Film Bioskop*, *Serial TV & Anime*).
    - Lencana hitung mundur rilis dinamis: *"Rilis Hari Ini"*, *"Rilis Besok"*, atau *"X Hari Lagi"*.
    - Tombol pintas 1-sentuhan untuk langsung menyimpan judul mendatang ke *Watchlist*.

### 2. Hub Semesta & Panduan Urutan Nonton Serial TV (TV Universe Hub)
- **Pemisahan Khusus Antara Waralaba Serial TV dan Film**:
  - Berbeda dengan film bioskop yang dikelompokkan oleh TMDB Collection, serial TV memiliki semesta multi-seri yang kompleks. Cineva kini menghadirkan kurasi semesta serial TV tersendiri (*TV Universe Hub*).
- **Banner Semesta di Halaman Detail Serial**:
  - Jika serial TV memiliki keterkaitan dengan semesta cerita lain (misal *House of the Dragon*, *Better Call Saul*, *Naruto Shippuden*, *Gen V*, *Berlin*, *1923*), banner elegan langsung muncul di bawah sinopsis serial.
- **Halaman Hub Semesta TV (`/tv-universe/:id`)**:
  - Menyajikan backdrop megah semesta serial TV lengkap dengan deskripsi alur cerita.
  - **Panduan Urutan Cerita Rekomendasi (*Recommended Story Order*)**:
    - Menampilkan lencana nomor urut menonton (#1, #2, #3...).
    - Lencana taksonomi jenis serial yang jelas: **Serial Utama (*Main Series*)**, **Prekuel (*Prequel*)**, **Sekuel (*Sequel*)**, atau **Spin-off**.
    - Rentang tahun tayang dan catatan panduan cerita agar penonton tidak bingung memahami alur semesta serial tersebut.
    - Akses langsung sekali sentuh ke serial yang dituju.
  - Mendukung semesta populer: *Naruto & Boruto*, *Breaking Bad & Better Call Saul*, *Game of Thrones & House of the Dragon*, *The Walking Dead*, *The Boys & Gen V*, *Money Heist (La Casa de Papel)*, *Dragon Ball*, *Yellowstone*, dan banyak lagi.

### 3. In-App Official Trailer & Perbaikan Error 153
- **Modal Pemutar Video Sinematik Gelap**:
  - Membuka trailer resmi langsung di dalam aplikasi melalui modal bottom sheet berlatar hitam pekat OLED tanpa perlu beralih ke aplikasi pihak ketiga.
- **Resolusi Masalah YouTube Error 153 (*Video Player Configuration Error*)**:
  - Mengonfigurasi `baseUrl: 'https://www.youtube-nocookie.com'`, User-Agent peramban bergerak, dan header kebijakan rujukan `strict-origin-when-cross-origin` sehingga seluruh trailer YouTube dapat diputar secara lancar tanpa peringatan pemutar.
- **Pilihan Trailer Cerdas (*Smart Trailer Fallback*)**:
  - Algoritma secara otomatis memprioritaskan trailer resmi (*Official Trailer*), trailer standar, teaser, dan fallback ke bahasa Inggris jika server TMDB belum menandai trailer dalam bahasa lokal.
- **Tombol Aksi "Tonton Sekarang" Terintegrasi**:
  - Pengguna dapat langsung menekan tombol *"Tonton Sekarang / Watch Now"* dari dalam modal trailer untuk seketika beralih memutar film atau serial penuh.

### 4. Halaman Profil Aktor & Filmografi (Person Detail Screen)
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

### 5. Hub Waralaba / Koleksi Film Bioskop (Franchise Collection Hub)
- **Banner Koleksi pada Halaman Detail Film**:
  - Jika sebuah film tergabung dalam koleksi waralaba (misal *The Avengers*, *Harry Potter*, *Spider-Man*, *Fast & Furious*, *The Dark Knight*), muncul banner horizontal eksklusif *"Bagian dari Waralaba"* yang menyajikan poster mini dan tautan *"Lihat Koleksi Lengkap →"*.
- **Halaman Hub Koleksi (`/collection/:id`)**:
  - Menampilkan backdrop megah semesta waralaba film dengan gradasi hitam yang menyatu ke latar OLED Black.
  - Menyajikan sinopsis koleksi dan badge total jumlah film (*misal: "8 Film dalam Koleksi"*).
- **Urutan Kronologis Rilis (*Chronological Timeline*)**:
  - Daftar film disusun rapi secara kronologis dari film pertama hingga rilisan terbaru dengan lencana nomor urut, tahun rilis, rating, sinopsis ringkas, dan tombol aksi tonton langsung.

### 6. Konsistensi UI/UX & Lokalisasi Penuh
- **Pure OLED Black (#000000)**: Seluruh layar baru, modal bottom sheet, dan banner menggunakan latar belakang hitam pekat murni yang hemat daya layar AMOLED dan nyaman di mata saat kondisi gelap.
- **Garis Batas Halus (*Smooth Dividers*)**: Menghindari pemakaian card bertumpuk yang berlebih dengan memanfaatkan hairline dividers transparan `0.8px` untuk hierarki visual yang bersih dan modern.
- **Kurva Animasi Halus**: Transisi rute menggunakan `Curves.easeOutCubic` dengan staggered animation delay bergradasi 30ms pada daftar item.
- **100% Dukungan Dwibahasa**: Seluruh string baru terdaftar lengkap dalam Bahasa Indonesia dan English pada `AppStrings`.

---

## Riwayat Versi Sebelumnya

### Cineva v1.1.2
- **Distribusi Multi-Arsitektur APK (Split-per-ABI)**: 4 varian APK terpisah (`arm64-v8a`, `armeabi-v7a`, `x86_64`, dan `universal`) menghemat ukuran unduhan hingga 60% (~16 MB vs ~38 MB).
- **Deteksi Cerdas Arsitektur CPU Native Android**: Aplikasi otomatis memilih varian file unduhan yang paling sesuai dengan prosesor perangkat pengguna saat update.
- **Panel Informasi Film & Episode pada Pemutar Video**: Ikon info di bilah kontrol pemutar untuk membuka panel samping sinopsis dan detail episode bergaya YouTube tanpa menghentikan pemutaran video.
- **Modal Detail Pembaruan Aplikasi & Auto-Translasi**: Popup changelog interaktif dengan fitur auto-translasi dwibahasa untuk catatan rilis GitHub.

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
