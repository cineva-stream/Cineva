# Cineva v1.1.2 - Release Notes 🎬

Pembaruan Cineva versi 1.1.2 menghadirkan lompatan besar dalam efisiensi distribusi aplikasi melalui **Distribusi Multi-Arsitektur APK (Split-per-ABI)** yang menghemat ukuran unduhan hingga lebih dari 60%, sistem **Deteksi Cerdas Arsitektur CPU Perangkat** saat melakukan pembaruan di dalam aplikasi (*In-App Update*), penambahan **Panel Informasi Media & Episode pada Kontrol Pemutar (*Player Info Side Panel*)**, **Modal Detail Pembaruan Aplikasi (*Changelog Popup*)** dengan fitur adaptasi penerjemahan dwibahasa otomatis (*Bilingual Auto-Translation*), serta kompatibilitas penuh dengan versi rilis sebelumnya.

---

## Ringkasan Perubahan

### 1. Distribusi Multi-Arsitektur APK (Split ABI) & Deteksi CPU Otomatis
- **Pengurangan Ukuran File Unduhan Drastis (~15–18 MB vs ~99 MB Universal)**:
  - Mengubah skema *build* aplikasi untuk mendukung pembuatan 4 varian APK terpisah:
    - `Cineva_v1.1.2-arm64-v8a.apk` (Khusus arsitektur 64-bit perangkat Android modern, ~16 MB).
    - `Cineva_v1.1.2-armeabi-v7a.apk` (Khusus arsitektur 32-bit perangkat Android lawas, ~15 MB).
    - `Cineva_v1.1.2-x86_64.apk` (Khusus emulator PC seperti LDPlayer/Bluestacks dan Chromebook, ~18 MB).
    - `Cineva_v1.1.2.apk` (Varian Universal standar tanpa imbuhan nama, kompatibel dengan seluruh perangkat Android).
  - Varian universal sengaja tetap menggunakan nama `Cineva_v{versi}.apk` demi menjaga kompatibilitas mundur (*backward compatibility*) agar perangkat pengguna versi lama tetap dapat mendeteksi pembaruan dan memperbarui aplikasi secara mulus.
- **Deteksi Cerdas Arsitektur CPU Native Android (`AppUpdateService`)**:
  - Menghubungkan platform channel native (`MethodChannel('com.primadev.cineva/device_info')`) ke `android.os.Build.SUPPORTED_ABIS`.
  - Ketika notifikasi atau banner pembaruan muncul di dalam aplikasi, sistem secara cerdas mencocokkan aset rilis GitHub yang sesuai dengan arsitektur CPU perangkat pengguna (misal: ponsel `arm64-v8a` akan otomatis mengunduh `Cineva_v1.1.2-arm64-v8a.apk`).
  - Menyediakan fallback otomatis ke varian universal jika varian arsitektur spesifik tidak ditemukan di rilis GitHub.
- **Otomatisasi Penamaan & Distribusi Gradle Hook (`android/app/build.gradle.kts`)**:
  - Menambahkan *task hook* otomatis setelah `assembleRelease` yang memetakan output build Flutter (`app-arm64-v8a-release.apk`, dll.) menjadi nama rilis final yang rapi dan siap didistribusikan ke GitHub Releases.

### 2. Panel Informasi Film & Episode pada Pemutar Video (Player Info Side Panel)
- **Ikon Info Interaktif pada Bar Kontrol Pemutar**:
  - Menambahkan ikon informasi (`Iconsax.info_circle`) di bilah atas pemutar video (*player controls*), tepat di samping kiri ikon pengaturan (*settings*).
  - Menekan ikon ini membuka panel samping kanan bergaya YouTube (*YouTube-Style Info Side Panel*) tanpa menghentikan pemutaran video yang sedang berlangsung.
- **Header Poster & Cuplikan Visual dengan Gradien Obsidian**:
  - Bagian atas panel samping menampilkan *banner* thumbnail/backdrop film atau episode yang sedang diputar.
  - Dilapisi gradien hitam pekat (*pure black gradient overlay*) di bagian atas dan bawah gambar agar menyatu sempurna ke dalam latar belakang *Deep Obsidian* (`AppColors.background`).
  - Dilengkapi badge kategori ('MOVIE' atau 'TV SHOW') dan indikator nomor musim & episode untuk serial televisi.
- **Judul Lengkap & Sinopsis Adaptif**:
  - Menampilkan judul film atau judul episode lengkap dengan format tipografi yang jelas dan nyaman dibaca.
  - Menampilkan ringkasan cerita (*synopsis / overview*) lengkap dengan pengambilan data otomatis dari endpoint TMDB (`/movie/{id}` atau `/tv/{id}/season/{s}/episode/{e}`) apabila data sinopsis belum tersedia di memori.
  - Jika sebuah film atau episode tidak memiliki sinopsis di server, panel menampilkan kartu fallback dwibahasa yang rapi:
    - *"Tidak Ada Sinopsis Untuk Film Ini atau Episode Ini"* (Bahasa Indonesia).
    - *"No Synopsis Available for this Movie or Episode"* (English).

### 3. Modal Detail Pembaruan Aplikasi & Auto-Translasi Catatan Rilis
- **Tombol "Lihat Detail" / "See More" pada Banner Beranda**:
  - Pada kartu pembaruan aplikasi (`InAppUpdateBanner`) di halaman Beranda, kini tersedia tombol interaktif **"Lihat Detail"** (ID) atau **"See More"** (EN).
- **Modal Changelog Popup Interaktif (`UpdateDetailModal`)**:
  - Menampilkan modal popup elegan berlatar kaca gelap (*frosted glass effect*) yang menyajikan nomor versi, judul rilis, tanggal publikasi, dan seluruh isi catatan rilis (*release notes / body*) yang diambil langsung dari GitHub API.
- **Penerjemahan Bahasa Otomatis (*Bilingual Auto-Adaptation*)**:
  - Sistem mendeteksi bahasa teks rilis dari GitHub dan secara cerdas menyesuaikannya dengan bahasa aplikasi yang sedang aktif:
    - Jika aplikasi menggunakan Bahasa Inggris sedangkan teks rilis berbahasa Indonesia, sistem secara otomatis menerjemahkan catatan rilis ke Bahasa Inggris.
    - Jika aplikasi menggunakan Bahasa Indonesia sedangkan teks rilis berbahasa Inggris, sistem menerjemahkannya ke Bahasa Indonesia.
    - Jika rilis menyediakan blok bagian bahasa ganda, sistem langsung mengekstrak bagian yang sesuai.
- **Tombol Toggle Terjemahan & Unduh Langsung**:
  - Dilengkapi tombol *toggle pill* interaktif: `[ 🌐 Diterjemahkan | Teks Asli ]` atau `[ 🌐 Translated | Original ]` sehingga pengguna dapat bebas melihat teks terjemahan maupun teks asli dari pengembang.
  - Menyediakan tombol aksi langsung **"Unduh & Pasang Sekarang"** di dalam modal dengan indikator progres unduhan terintegrasi.

### 4. Peningkatan Integrasi Rute Navigasi & Fallback TMDB
- **Parameter `overview` pada Rute Pemutar (`/player`)**:
  - Memperbarui `GoRouter` untuk menyertakan parameter `overview` dari halaman `MovieDetailScreen` dan `TvDetailScreen`.
  - Memastikan sinopsis langsung tersedia seketika pemutar dibuka tanpa jeda tunggu koneksi jaringan.
- **Pembaruan Otomatis Sinopsis Saat Berpindah Episode**:
  - Ketika pengguna menekan tombol "Episode Berikutnya" (*Next Episode*), panel informasi secara otomatis memperbarui nomor episode, judul episode, dan sinopsis episode baru yang sedang diputar.

### 5. Sinkronisasi Web Companion (Cineva-Web)
- **Selektor Arsitektur CPU Modern & Minimalis**:
  - Tombol unduh pada *Hero*, *Install*, dan *CTA* section di portal web Cineva kini terintegrasi dengan pemilih arsitektur CPU bergaya *split button* kapsul tunggal yang elegan.
  - Menampilkan rekomendasi arsitektur perangkat pengunjung secara otomatis (`arm64-v8a`, `x86_64`, `armeabi-v7a`, `universal`).
  - Menghilangkan *glitch overlap* teks perks dan merapikan tipografi menggunakan font *Plus Jakarta Sans*.

---

## Riwayat Versi Sebelumnya

### Cineva v1.1.1
- **Sinkronisasi Cluster Scraper Flixquest (`scraper.flix.quest`)**: Akses ke 17+ upstream scrapers terverifikasi dan multi-instance failover.
- **Prioritas Provider Film Bioskop Indonesia & Asia**: Penempatan provider `movy` dan `moviepire` di urutan teratas untuk film bioskop Indonesia dan anime.
- **Native 404 Stream Unavailable Overlay**: Pencegahan pemutaran video iklan atau salah judul dengan overlay bertema *Cinema Amber & Deep Obsidian*.
- **Pembersihan Kontrol Ganda & Side Panel Border Tipis**: Redesain menu server, episode, kualitas, dan subtitle dengan *subtle border* 0.8px tanpa card tebal.
- **Katalog TV Live Terlengkap**: Saluran nasional (Indosiar HD, Moji HD, SCTV HD, Trans TV, Trans7 HD, dll.) dan internasional dengan *YouTube-Style Channel Drawer*.
- **Cineva Custom UI & Anti-Ad Shield**: Kontrol kustom Cineva lengkap di semua server streaming dengan perlindungan gestur sentuh anti-iklan.

### Cineva v1.1.0
- **Navigasi Kembali TV Live & Animasi Slide-Up**: Pemulihan instan bottom navigation bar tanpa perlu menekan tombol back dua kali.
- **Kunci Otomatis Orientasi Lanskap Layar Penuh TV Live**: Rotasi instan ke lanskap saat tombol fullscreen ditekan.
- **Penyimpanan Permanen Pengaturan Subtitle**: Penyimpanan persistensi untuk stroke/outline, offset vertikal, dan warna font pada Hive settings.
- **Peralihan Resolusi Mulus (*Seamless Quality Switching*)**: Mempertahankan timestamp saat mengganti kualitas tanpa reset ke detik ke-0.

### Cineva v1.0.9
- **Pemisahan Katalog & Pemutar TV Live**: Katalog saluran terpisah dengan pemutar fullscreen (`LiveTvPlayerScreen`).
- **Perbaikan Unduhan Subtitle**: Penambahan header OpenSubtitles API dan pembersihan UTF-8 BOM pada parser SRT.
- **Notifikasi Pembaruan Dwibahasa**: Notifikasi pembaruan latar belakang berbahasa Indonesia dan Inggris.

### Cineva v1.0.8
- **Pembaruan Lisensi ke GPL-3.0**: Penyelarasan seluruh lisensi proyek menjadi GNU General Public License v3.0.
- **Penyempurnaan Total Unduhan Offline**: Pemutaran loopback HLS langsung (`LocalStreamServer`) dan *token-preserving URL resolution*.

---

## Informasi Versi

- **Versi Aplikasi**: 1.1.2
- **Build**: 13
- **Target Sistem Operasi**: Android 5.0 (API 21) ke atas
- **Daftar Varian File APK**:
  - `Cineva_v1.1.2-arm64-v8a.apk` (HP Android Modern 64-bit, ~16 MB)
  - `Cineva_v1.1.2-armeabi-v7a.apk` (HP Android Lawas 32-bit, ~15 MB)
  - `Cineva_v1.1.2-x86_64.apk` (Emulator PC & Chromebook, ~18 MB)
  - `Cineva_v1.1.2.apk` (Universal / Semua CPU, Kompatibel Penuh, ~38 MB)
