# Cineva v1.1.8 - Release Notes 🎬

Pembaruan Cineva versi 1.1.8 menghadirkan **Relayout Responsif Modern untuk Tablet, Windows Desktop & Android TV**, perombakan **Desain Antarmuka Sinematik (Obsidian & Crimson Cinema UI)** di seluruh halaman, serta **Perbaikan Total Navigasi Remote D-Pad & Orientasi Layar** pada perangkat Android TV dan Tablet.

---

## Ringkasan Fitur Baru & Peningkatan Utama

### 1. Relayout Responsif Modern untuk Tablet, Windows Desktop & Android TV
* **Mesin Deteksi Form-Factor & Grid Adaptif (`device_form_factor.dart`)**:
  * Deteksi cerdas untuk **Smartphone**, **Tablet** (`shortestSide >= 600px`), **Windows Desktop**, serta **Android TV** (mendukung penuh resolusi TV 720p dan 1080p/4K).
  * Perhitungan kolom grid poster otomatis (`adaptivePosterGridColumns`) dan grid kartu horizontal (`adaptiveHorizontalCardGridColumns`) dari 3 hingga 8 kolom sesuai lebar layar perangkat.
* **Navigasi Samping Widescreen (`AdaptiveNavRail` & `MainShell`)**:
  * Perangkat Tablet, Windows, dan Android TV kini secara konsisten menggunakan bilah navigasi samping (*Side Navigation Rail*) yang modern dengan indikator kapsul menyala, menggantikan bilah bawah smartphone agar ruang pandang horizontal lebih maksimal.
* **Tata Letak Multi-Kolom & Widescreen di Seluruh Halaman**:
  * **Beranda (Home)**: Banner Hero sinematik proporsional, kartu *Lanjutkan Menonton* lebih lebar di layar besar (`240px`), serta pemilih genre responsif.
  * **Pencarian & Katalog Platform**: Kartu *Hero Top Result* bersebelahan dengan daftar hasil, *Trending Bento Grid* adaptif, dan grid platform streaming 3–6 kolom.
  * **Live TV & Split-View Player**: Panel daftar saluran di sisi kiri (`340px–380px`) berdampingan dengan pemutar video langsung dan EPG di sisi kanan untuk Tablet, Windows, dan Android TV.
  * **Detail Film, Serial TV, Koleksi Franchise & TV Universe**: *Split Hero Banner* untuk layar lebar, grid daftar episode **2–3 kolom** pada layar widescreen/TV untuk meminimalkan *scrolling* vertikal, serta grid *Seasons* dan *Cast* yang proporsional.
  * **Watchlist, Riwayat Tontonan, Unduhan & Kalender Tayang**: Transformasi dari daftar satu kolom memanjang menjadi grid multi-kolom (2–3 kolom di Tablet/Windows/TV) lengkap dengan pembatas lebar proporsional (`maxWidth`) pada halaman Pengaturan, Edit Profil, dan Syarat & Ketentuan.

### 2. Perbaikan Total Kontroler D-Pad Android TV & Keyboard Navigasi
* **Engine Fokus `TvFocusable` Generasi Baru**:
  * Dilengkapi *focus ring* (`showFocusBorder`) bertepi `AppColors.primary` (`2px`), animasi skala halus, dukungan penuh tombol `Select`, `Enter`, `NumpadEnter`, `GameButtonA`, dan `Space`, serta *auto-scroll* aman (`Scrollable.ensureVisible`) saat item menerima fokus D-Pad.
* **Perbaikan Bug Fokus Terjebak di Pemutar Video (`PlayerScreen`)**:
  * Memperbaiki *handler* tombol D-Pad pada `PlayerScreen` yang sebelumnya mencegat seluruh arah panah untuk *seek* meskipun kontrol sedang tampil atau panel samping terbuka.
  * Kini saat kontrol video terlihat, Side Panel (Episode/Server/Subtitle) terbuka, *Mini Popup* tampil, atau *Error Overlay* muncul, tombol panah D-Pad dan `Enter` berpindah antar tombol secara normal.
  * Menambahkan `ExcludeFocus` saat kontrol video tersembunyi agar fokus D-Pad tidak lari ke tombol transparan di belakang layar.
* **Dukungan D-Pad Menyeluruh di Halaman yang Sebelumnya Terkunci**:
  * **Pencarian (`SearchScreen`)**: Fokus D-Pad penuh pada bilah cari, tombol hapus, chip riwayat pencarian, *Quick Categories*, kartu platform streaming, hingga kartu hasil pencarian.
  * **Detail Film & Serial TV**: Seluruh tombol aksi (*Play*, *Download*, *Trailer*, *Watchlist*), chip *Season*, kartu *Episode*, kartu *Cast*, serta banner *Franchise/Universe* kini dapat dinavigasi dengan D-Pad.
  * **Watchlist, Riwayat, Unduhan & Kalender Tayang**: Kartu item, tab filter, tanggal kalender, serta tombol hapus/aksi kini sepenuhnya mendukung fokus D-Pad & keyboard.
  * **Syarat & Ketentuan (`LegalAgreementScreen`)**: Menambahkan *scroll* dokumen menggunakan D-Pad Atas/Bawah serta pembungkus `TvFocusable` pada tombol *Scroll ke Bawah* dan *Setuju & Lanjutkan*.
  * **Dialog Konfirmasi Keluar (`ExitConfirmationBottomSheet`)**: Ditampilkan sebagai dialog tengah (*centered modal*) pada Tablet/Windows/TV dengan tombol *Batal* (autofocus) dan *Keluar* yang dapat dipilih via remote TV.

### 3. Perbaikan Bug Orientasi Layar (Tablet & Android TV)
* **Eliminasi Penguncian Paksa ke Portrait (`portraitUp`)**:
  * Memperbaiki bug di mana keluar dari pemutar video (`PlayerScreen` & `LiveTvPlayerScreen`) mengunci layar kembali ke mode `portraitUp` yang merusak tampilan di Tablet landscape dan Android TV.
  * Menghadirkan fungsi terpusat `restoreSystemUiAndOrientations` yang mengembalikan orientasi sesuai form-factor perangkat (bebas rotasi untuk Tablet, landscape untuk TV, dan portrait untuk Smartphone).

### 4. Penyegaran Visual Obsidian & Crimson Cinema UI
* Pembaruan palet warna gelap sinematik (`AppColors` & `AppTheme`), peningkatan kontras tipografi, kartu kaca (*glassmorphism*), serta penyempurnaan *Splash Screen* dan modal opsi unduhan agar tampil lebih tegas, rapi, dan modern di segala ukuran layar.

### 5. Desain Ulang Setup Installer Windows (Dark Obsidian & Animasi Poster Film)
* **Cinema Poster Wall Marquee (~35 FPS)**: Header beranimasi mulus menggunakan deretan poster film miring dengan gradasi hitam Obsidian dan aksen *Cinema Amber* (`#FF9500`).
* **Modern Dark Step-by-Step Wizard**: Indikator progres 4 langkah interaktif (`1. Lisensi ➔ 2. Lokasi ➔ 3. Instalasi ➔ 4. Selesai`), tema gelap penuh (`WizardStyle=modern dark`), dokumen Syarat & Ketentuan bertema gelap, serta dialog *Uninstall* bergaya Obsidian.

### 6. Rilis Fitur Unduhan Offline (Status Under Maintenance Selesai)
* **Mesin Unduhan Offline & HLS TS Segment Decryption**:
  * Fitur unduhan offline yang sebelumnya berstatus *Under Maintenance* kini telah resmi diperbaiki dan dapat langsung dicoba (*Available to Try*).
  * Dukungan engine `VideoDownloadService` baru: parser m3u8 HLS adaptif, dekripsi segmen TS terenkripsi AES-128, dan perakitan berkas MP4 offline mandiri melalui `OfflineMp4Builder`.
  * Pipeline download subtitle otomatis (`DownloadSubtitlePipeline`) yang mengunduh dan menyinkronkan subtitle film/serial secara independen.
  * Modal opsi download baru (`DownloadOptionsModal`) dengan pemilih kualitas resolusi, estimasi ukuran berkas, serta pemilihan track audio dan subtitle multibahasa.
  * **Catatan Penting**: *Kami tidak dapat memastikan untuk seluruh film maupun TV series dapat diunduh*, dikarenakan variasi proteksi DRM serta ketersediaan sumber dan server pihak ketiga di internet.
  * **Modal Pengumuman Fitur Unduhan Offline Modern**: Menampilkan modal pop-up sinematik Dark Obsidian dengan poster banner dwibahasa (ID & EN), tombol "Good Work! (Mengerti)", opsi checkbox "Jangan tampilkan lagi" / "Don't show again", serta pembatasan frekuensi cerdas maksimal 1x per 12 jam (*throttling*) saat membuka aplikasi.
  * **UI Progress Real-Time Saat Finalizing Unduhan**: Memberikan indikator status dan progress bar realtime saat tahap penggabungan segmen video/audio dan perakitan MP4 offline (`DownloadStatus.finalizing`), lengkap dengan badge spinning `FINALIZING`, detail segmen (misal: "Menyatukan segmen video 45/300"), pesan penjelas ramah, serta persentase yang terus bergerak sehingga pengguna tahu proses berjalan aktif.
  * **Pengelompokan TV Series & Dropdown Season**: Pengelompokan unduhan serial TV kini secara konsisten menggunakan poster resmi judul TV series (bukan thumbnail cuplikan episode awal), serta dilengkapi Dropdown Season yang memungkinkan pemilihan season secara cepat tanpa harus melakukan scrolling panjang.

### 7. Peningkatan Pemutar Video (In-App Mini Player, Android PiP & Tata Letak Kontrol)
* **Penataan Ulang Ikon Bilah Atas Pemutar Video (`PlayerScreen`)**:
  * Menyelaraskan urutan ikon bilah atas saat memutar film atau serial TV menjadi lebih ergonomis: **Icon PiP ➔ Icon Sleep Timer ➔ Icon Lock ➔ Icon Settings ➔ Icon Info**.
* **Floating In-App Mini-Player & Android Native PiP**:
  * Dukungan `MiniPlayerOverlay` yang memungkinkan video terus berputar dalam jendela melayang (*floating mini-player*) di sudut layar saat pengguna menjelajahi halaman lain di dalam aplikasi.
  * Integrasi *Picture-in-Picture* (PiP) bawaan Android untuk menonton video saat beralih ke aplikasi lain.

---

## Riwayat Versi Sebelumnya

### Cineva v1.1.7
* **Fitur Cadangan & Pemulihan Data Mandiri (Backup & Restore System)**: Ekspor & impor seluruh data aplikasi ke dalam berkas `.cineva` beserta opsi pemulihan langsung di layar awal (*Splash Screen*).
* **Masuk dengan Google & Sinkronisasi Cloud**: Integrasi Google Sign-In & Firebase Realtime Database untuk sinkronisasi multi-perangkat otomatis dan pengisian profil cerdas.
* **Desain Ulang Side Panel Streaming & Subtitle Minimalis**: Panel samping hitam obsidian pada pemutar video dan pengaturan subtitle *real-time* yang ringkas.
* **Keamanan Build, ProGuard & Obfuscation**: Aturan proteksi refleksi penuh pada `proguard-rules.pro` dan pengamanan endpoint runtime.

---

## Informasi Versi

* **Versi Aplikasi**: 1.1.8
* **Build**: 19
* **Target Sistem Operasi**: Android 5.0 (API 21) ke atas (Smartphone, Tablet & Android TV / Google TV), Windows 10/11 (64-bit)
* **Daftar Varian File Rilis**:
  * `Cineva_setup_v1.1.8.exe` (Windows Desktop Installer Resmi)
  * `Cineva_v1.1.8-android-tv.apk` (Khusus Android TV & Smart TV - **Rekomendasi TV**)
  * `Cineva_v1.1.8-arm64-v8a.apk` (HP & Tablet Android Modern 64-bit)
  * `Cineva_v1.1.8-armeabi-v7a.apk` (HP & Tablet Android Lawas 32-bit)
  * `Cineva_v1.1.8-x86_64.apk` (Emulator PC & Android x86)
  * `Cineva_v1.1.8.apk` (Universal / Semua CPU, Kompatibel Penuh)
