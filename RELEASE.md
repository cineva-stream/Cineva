# Cineva v1.1.4 - Release Notes 🎬

Pembaruan Cineva versi 1.1.4 menghadirkan lonjakan kapabilitas besar **Ekspansi Multiplatform: Android TV (10-Foot UI) & Windows Desktop**. Cineva kini dapat dinikmati di layar besar televisi pintar dengan navigasi remote control (D-Pad) serta sistem operasi desktop Windows dengan dukungan pintasan keyboard dan navigasi responsif, tanpa mengubah satu pun alur logika bisnis inti aplikasi (100% *unified architecture* berbasis Riverpod, Dio, Hive, dan media_kit).

---

## Ringkasan Perubahan

### 1. Dukungan Android TV & Pengalaman Layar Lebar 10-Kaki (10-Foot UI)
- **Banner Peluncur Leanback Android TV**:
  - Menyertakan banner 16:9 beresolusi tinggi (`tv_banner.png`) berlogo Cineva dengan gradasi sinematik untuk peluncur resmi Android TV / Google TV.
  - Konfigurasi `android.software.leanback` dan deklarasi launcher `LEANBACK_LAUNCHER` pada AndroidManifest tanpa mewajibkan sensor sentuh (`touchscreen: false`).
- **Deteksi Otomatis Mode Televisi**:
  - MethodChannel native (`com.primadev.cineva/device`) yang secara akurat mendeteksi apakah aplikasi sedang dijalankan di Android TV melalui `UiModeManager` dan `FEATURE_LEANBACK`.

### 2. Sistem Fokus D-Pad & Poster Zoom 1.11x dengan Smooth Glow
- **Efek Pembesaran Poster Sinematik**:
  - Saat navigasi menggunakan remote control D-Pad atau tombol panah keyboard diarahkan ke kartu film atau serial TV, poster membesar **1.11x lebih besar** secara proporsional dengan kurva animasi `Curves.easeOutCubic` (durasi 240ms).
- **Efek Smooth Ambient Amber Glow**:
  - Alih-alih garis batas (border) kaku, elemen yang sedang aktif dihiasi oleh pencahayaan pendaran lembut (*smooth ambient glow*) berwarna Cinema Amber di balik poster (`BoxShadow` bergradasi dengan blur radius 26px dan spread radius 3px).
- **Auto-Scroll ke Viewport**:
  - Poster dan kartu yang mendapatkan fokus otomatis terpusat di dalam layar pandang (`Scrollable.ensureVisible`) sehingga pengguna tidak perlu menggulir manual.

### 3. Bilah Navigasi Kiri Adaptif (Adaptive Navigation Rail)
- **Transisi Responsif Layar Lebar & Desktop**:
  - Pada layar lebar (Android TV atau Desktop Windows dengan lebar $\ge 960\text{ px}$), aplikasi secara cerdas beralih dari Bottom Navigation Bar ponsel ke **Adaptive Left Navigation Rail** yang modern dan minimalis.
- **Dukungan Hover & D-Pad Lengkap**:
  - Setiap menu navigasi (Beranda, Live TV, Pencarian, Watchlist, Riwayat, Pengaturan) mendukung kursor mouse, tombol keyboard, serta D-Pad remote dengan animasi indikator aktif Amber Glow.

### 4. Windows Desktop Runner, Frameless UI & Buttery-Smooth Mouse Scrolling
- **Runner Native Windows**:
  - Proyek kini menyertakan runner resmi Windows Desktop yang terintegrasi dengan pustaka video `media_kit_libs_windows_video`.
- **Smooth Mouse Wheel Scrolling Berkecepatan Tinggi**:
  - Mengeliminasi *choppy / stepped scrolling* bawaan Flutter Desktop melalui interpolasi eksponensial matematis (`SmoothMouseScrollBindingMixin` dan `SmoothMouseScrollHandler`) dengan refresh rate 60Hz/120Hz/144Hz yang mulus tanpa patah-patah.
  - Peredaman instan saat memutar roda mouse ke arah berlawanan tanpa *lag* serta pembatasan *buffer backlog* agar guliran roda mouse tidak meluncur berlebihan.
  - Dukungan *drag scrolling* dengan mouse dan trackpad (`CinevaScrollBehavior`) yang menyatu dengan *native desktop clamping physics*.
- **Frameless Window & Tombol Kontrol Kustom Native**:
  - Membuka aplikasi secara *maximized* sejak awal peluncuran dengan bilah judul Windows bawaan disembunyikan (*TitleBarStyle.hidden*).
  - Dilengkapi tombol kendali jendela terpadu (Minimize, Maximize / Restore, dan Close) bergaya modern minimalis yang menyatu rapi dengan tema gelap Cineva.
- **Penyempurnaan Tampilan Desktop**:
  - Logo resmi `logo_cineva.png` tersemat rapi di pucuk Navigation Rail kiri.
  - Efek *amber glow* saat kursor hover disesuaikan menjadi lembut (*blur radius 10px*, *opacity 0.32*) agar terlihat rapi dan elegan.
  - Avatar profil pengguna pada halaman Akun diposisikan rata tengah (*centered*).
- **Installer Tunggal Windows (`Cineva_setup_v1.1.4.exe`)**:
  - Menggunakan Inno Setup dengan ikon resmi Cineva, konfirmasi Syarat & Ketentuan Lisensi (Perjanjian Pengguna), pemilihan folder target pemasangan, serta pembuatan shortcut Desktop dan Taskbar.
- **Pintasan Kontrol Keyboard & Remote pada Pemutar**:
  - **Panah Kiri / Kanan**: Mundur / maju cepat 10 detik (*relative seek*).
  - **Panah Atas / Bawah**: Menaikkan / menurunkan volume secara instan dengan kurva boost hingga 150%.
  - **Enter / Space / Tombol OK / Gamepad A**: Putar atau jeda video (*play/pause toggle*).
  - **Tombol M**: Mematikan atau mengaktifkan suara (*mute/unmute*).
  - **Escape / Tombol Back**: Menutup panel samping atau keluar dari pemutar dengan aman.
- **Proteksi Server WebView di Desktop**:
  - Menangani isolasi arsitektur agar server WebView Android tidak memicu *unsupported platform crash* pada Windows Desktop.

### 5. Strategi Distribusi Berkas APK Ringan (Split-per-ABI)
- Tetap mempertahankan pembagian berkas APK terpisah per arsitektur CPU agar ukuran unduhan tetap sangat ramping (~16 MB) untuk perangkat TV dan TV Box yang memiliki kapasitas memori terbatas.

---

## Riwayat Versi Sebelumnya

### Cineva v1.1.3
- **Kalender Siaran & Radar Rilis 2-Tab (*Airing Calendar & Coming Soon*)**: Jadwal rilis mingguan anime, k-drama, serial barat dan film bioskop dengan filter kategori cepat.
- **Hub Semesta & Urutan Nonton Serial TV (*TV Universe Hub*)**: Panduan urutan nonton serial TV waralaba (*Main Series, Prequel, Sequel, Spin-off*).
- **Pemutar Trailer Resmi di Dalam Aplikasi (*In-App Official Trailer*)**: Pemutar trailer YouTube gelap dengan resolusi error 153.
- **Halaman Profil Aktor & Filmografi (*Person Detail Screen*)**: Portofolio karya aktor/aktris dengan kalkulasi usia otomatis.
- **Hub Waralaba / Koleksi Film (*Franchise Collection Hub*)**: Timeline kronologis koleksi film bioskop.

---

## Informasi Versi

- **Versi Aplikasi**: 1.1.4
- **Build**: 15
- **Target Sistem Operasi**: Android 5.0 (API 21) ke atas (Smartphone & Android TV / Google TV), Windows 10/11 (64-bit)
- **Daftar Varian File APK**:
  - `Cineva_v1.1.4-arm64-v8a.apk` (HP Android Modern 64-bit & TV Box Modern, ~16 MB)
  - `Cineva_v1.1.4-armeabi-v7a.apk` (HP Android Lawas 32-bit & Sebagian Besar Android TV, ~15 MB)
  - `Cineva_v1.1.4-x86_64.apk` (Emulator PC & Android x86, ~18 MB)
  - `Cineva_v1.1.4.apk` (Universal / Semua CPU, Kompatibel Penuh, ~38 MB)
- **Varian Desktop**:
  - Windows Desktop Runner (x64)
