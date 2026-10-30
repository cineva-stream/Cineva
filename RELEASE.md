# Cineva v1.1.0 - Release Notes 🎬

Pembaruan Cineva versi 1.1.0 menghadirkan perbaikan alur navigasi kembali saat menonton TV Live dengan pemulihan menu navigasi bawah (*bottom navigation menu*) secara langsung dan animasi *slide-up* yang mulus, redesain daftar saluran TV Live yang konsisten tanpa *card* menggunakan garis batas (*border*) tipis yang halus, pemulihan seluruh logo saluran TV yang akurat dengan latar belakang transparan, serta penyimpanan permanen (*persistence*) untuk pengaturan *stroke/outline* dan posisi vertikal subtitle pada menu mini popup pemutar film dan serial TV.

---

## Ringkasan Perubahan

### 1. Perbaikan Navigasi Kembali dari TV Live & Animasi Slide-Up Bottom Navigation Bar
- **Pemulihan Menu Navigasi Bawah Secara Langsung**: Memperbaiki masalah di mana pengguna harus menekan tombol kembali (*back button*) dua kali agar *bottom navigation bar* muncul kembali setelah keluar dari pemutar TV Live.
- **Transisi Halus Slide-Up**: Status pemutar siaran TV disinkronkan dan direset secara instan saat navigasi kembali dipicu (baik melalui tombol navigasi Android maupun ikon *Chevron Left* Cineva), sehingga menu navigasi bawah langsung meluncur naik (*slide-up*) dengan animasi `easeInOutCubic` yang halus dan responsif.
- **Kunci Otomatis Orientasi Lanskap Layar Penuh**: Menekan ikon persegi putus-putus fullscreen (`Icons.fullscreen_rounded`) kini secara instan mengunci dan memutar orientasi layar ke lanskap (`landscapeLeft` / `landscapeRight`) meskipun pengguna mematikan fitur *Auto-Rotate* di pengaturan sistem Android, serta mengembalikan orientasi ke potret secara otomatis saat keluar dari mode layar penuh.
- **Pembersihan Logika PopScope**: Mencegah penahanan (*trapping*) tombol kembali pada rute cangkang utama (`MainShell`) ketika berada di halaman katalog saluran TV Live.

### 2. Redesain Daftar TV Live Bergaya Garis Tipis Minimalis & Pemulihan Logo Saluran
- **Konsistensi Tampilan Tanpa Card**: Mengubah tampilan daftar saluran pada katalog TV Live (`LiveTvScreen`) dan pemutar TV Live (`LiveTvPlayerScreen`) dari bentuk kontainer *Card* tebal berlatar abu-abu menjadi daftar minimalis dengan garis batas tipis halus (*subtle divider border* 0.8px) di setiap pemisah item, selaras dengan daftar Watchlist dan Riwayat Tontonan.
- **Logo Saluran Berlatar Transparan**: Menghilangkan kotak latar belakang berwarna di belakang logo saluran, sehingga logo setiap saluran tampil bersih, elegan, dan menyatu secara alami dengan latar belakang aplikasi.
- **Pemulihan 100% Logo Saluran TV**:
  - Memperbarui tautan logo untuk seluruh saluran siaran (seperti TVRI Nasional, TVRI World, DAAI TV, Garuda TV, Indonesiana TV, DW News, Bloomberg TV+, Golf Channel, Pluto TV Movies, dan NASA TV) dengan resolusi standar produksi yang diverifikasi aktif (HTTP 200 OK).
  - Menyematkan header User-Agent browser standar pada pemanggilan `CachedNetworkImage` agar tidak lagi diblokir atau menghasilkan galat 400/429 oleh CDN.

### 3. Penyimpanan Permanen Pengaturan Stroke / Outline & Posisi Subtitle (*Subtitle Persistence*)
- **Penyimpanan Nilai Kustomisasi Subtitle**: Memperbaiki bug di mana pengaturan *stroke/outline* dan posisi vertikal (*bottom offset*) pada menu mini popup pemutar film atau serial TV tidak tersimpan dan selalu ter-reset ke nilai bawaan saat berpindah episode atau mengganti judul film.
- **Sinkronisasi Menyeluruh dengan Hive Settings**: Menambahkan kunci penyimpanan permanen (`keySubtitleStrokeWidth`, `keySubtitleBottomOffset`, dan `keySubtitleTextColor`) pada `SettingsService`.
- **Inisialisasi Otomatis**: Memastikan `SubtitleStyleSettings.fromSettings()` dan fungsi `reloadFromSettings()` memuat kembali seluruh preferensi pengguna (ukuran huruf, latar belakang, tebal stroke, posisi, serta warna huruf) setiap kali pemutar dibuka.

### 4. Perbaikan Kualitas Streaming Default & Kelanjutan Posisi Pemutaran (*Seamless Quality Switching*)
- **Penerapan Otomatis Default Streaming Quality**: Memperbaiki bug di mana preferensi "Default Streaming Quality" (seperti 720p, 1080p, atau 480p) yang telah dipilih di menu pengaturan tidak diterapkan dan selalu kembali ke "Auto" saat memutar film atau serial TV. Sekarang pemutar secara otomatis membaca preferensi kualitas pengguna dan memilih *video track* yang sesuai dari master playlist HLS saat *stream* dimulai.
- **Peralihan Resolusi Mulus Tanpa Mengulang dari Awal**: Memperbaiki masalah di mana saat pengguna mengganti kualitas resolusi di mini popup saat streaming sedang berlangsung, video mendadak mengulang dari detik ke-0. Sekarang posisi tontonan saat ini disimpan secara presisi dan dipulihkan kembali (*seek*) seketika setelah *video track* baru dimuat, disertai penguncian *timeline* sementara agar slider dan waktu tontonan tidak melompat.

---

## Riwayat Versi Sebelumnya

### Cineva v1.0.9
- **Redesain Eksplorasi TV Live & Halaman Pemutar Terpisah**: Katalog saluran penuh tanpa pemutar di bagian atas dan pembukaan pemutar baru (`LiveTvPlayerScreen`) dengan transisi *slide* horizontal halus.
- **Perbaikan Masalah Pengunduhan Subtitle**: Penambahan header wajib `'Accept': 'application/json'` untuk OpenSubtitles API dan pembersihan UTF-8 BOM pada parser SRT.
- **Kustomisasi Pesan Notifikasi Pembaruan Dwibahasa**: Notifikasi pembaruan ramah pengguna dalam Bahasa Indonesia dan Bahasa Inggris pada pengecekan in-app dan latar belakang Android.

### Cineva v1.0.8
- **Perbaikan Navigasi & Animasi Watchlist**: Penyesuaian tab navigasi bawah dan animasi *slide-down* halus pada halaman Watchlist serta tombol Chevron Left.
- **Penyempurnaan Total Fitur Unduhan & Pemutaran Offline**: Pemutaran loopback HLS langsung (`LocalStreamServer`), *token-preserving URL resolution* (`HlsUrlResolver`), dan perlindungan berkas segmen.
- **Pembaruan Lisensi ke GPL-3.0**: Penyelarasan seluruh lisensi proyek menjadi GNU General Public License v3.0.

## Informasi Versi

- Versi Aplikasi: 1.1.0
- Build: 11
- Target Sistem Operasi: Android 5.0 (API 21) ke atas
