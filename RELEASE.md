# Cineva v1.0.9 - Release Notes 🎬

Pembaruan Cineva versi 1.0.9 menghadirkan redesain alur eksplorasi TV Live dengan halaman katalog saluran yang lebih luas dan bersih, pemisahan pemutar siaran ke halaman baru (*dedicated player screen*) dengan animasi *slide* yang halus, perbaikan tuntas masalah kegagalan pengunduhan subtitle (OpenSubtitles API & direct stream), serta kustomisasi pesan notifikasi pembaruan aplikasi dwibahasa (*bilingual update notice*).

---

## Ringkasan Perubahan

### 1. Redesain Eksplorasi TV Live & Halaman Pemutar Terpisah (*Dedicated Player Screen*)
- **Katalog Saluran TV Lebih Luas Tanpa Stream Card**: Saat membuka tab TV Live melalui menu navigasi bawah, halaman kini sepenuhnya menyajikan daftar saluran lengkap tanpa memunculkan pemutar atau *card stream* di bagian atas. Hal ini memberikan ruang pandang yang jauh lebih luas bagi pengguna untuk mencari dan menyaring saluran favorit.
- **Transisi Halus ke Halaman Pemutar (*Smooth Slide Transition*)**: Ketika pengguna memilih salah satu saluran, aplikasi akan membuka halaman pemutar baru (`LiveTvPlayerScreen`) dengan transisi geser horizontal (*slide transition*) yang mulus.
- **Kontrol Pemutar Siaran Lengkap**:
  - Pemutar 16:9 di bagian atas dengan tombol kembali (*Chevron Left*), penanda status *LIVE*, pengatur rasio aspek (16:9, Cover, Fill), tombol muat ulang, serta tombol putar/jeda.
  - Mode layar penuh (*fullscreen*) imersif dengan orientasi lanskap otomatis dan laci saluran cepat (*Quick Channel Drawer*).
  - Daftar pengganti saluran (*Channel Switcher*) di bawah pemutar memudahkan pengguna berpindah saluran secara instan tanpa perlu keluar dari layar pemutar.

### 2. Perbaikan Masalah Pengunduhan Subtitle (*Subtitle Download Fix*)
- **Perbaikan Galat HTTP 503 OpenSubtitles**: Menambahkan header wajib `'Accept': 'application/json'` pada permintaan API OpenSubtitles (`/download`), yang sebelumnya menyebabkan respons HTML *Service Temporarily Unavailable* (503) dan memicu peringatan *"Failed to Download Subtitle"*.
- **Pemanfaatan Direct Download URL**: Memperbaiki logika `_applySubtitle` pada `PlayerScreen` agar langsung memanfaatkan URL unduhan yang telah tersedia (`sub.downloadUrl`) dari stream VixSrc dan CDN lokal tanpa melakukan *round-trip* API tambahan.
- **Dukungan UTF-8 BOM pada Parser Subtitle**: Membersihkan *Byte Order Mark* (BOM `\uFEFF`) pada parser `SubtitleCue.parseSrt` untuk memastikan berkas subtitle hasil unduhan dapat dibaca dan disinkronkan secara sempurna tanpa galat format.

### 3. Kustomisasi Pesan Notifikasi Pembaruan Dwibahasa (*Bilingual Update Notice*)
- Menyesuaikan isi pesan (*notification body*) saat terdapat rilis baru agar tidak menampilkan teks mentah (*raw body*) changelog GitHub, melainkan pesan ramah pengguna:
  - **Bahasa Indonesia**: *"Update Tersedia, Segera update sekarang untuk menikmati layanan streaming dengan lebih baik."*
  - **English**: *"New version available, Update now to improve your streaming."*
- Pesan ini diterapkan secara konsisten baik pada notifikasi di dalam aplikasi (*in-app update checker*) maupun pada notifikasi latar belakang Android melalui WorkManager dan AlarmManager (`UpdateCheckWorker.kt`).

---

## Riwayat Versi Sebelumnya

### Cineva v1.0.8
- **Perbaikan Navigasi & Animasi Watchlist**: Penyesuaian tab navigasi bawah dan animasi *slide-down* halus pada halaman Watchlist serta tombol Chevron Left.
- **Penyempurnaan Total Fitur Unduhan & Pemutaran Offline**: Pemutaran loopback HLS langsung (`LocalStreamServer`), *token-preserving URL resolution* (`HlsUrlResolver`), dan perlindungan berkas segmen.
- **Pembaruan Lisensi ke GPL-3.0**: Penyelarasan seluruh lisensi proyek menjadi GNU General Public License v3.0.

### Cineva v1.0.7
- **Redesain Pemutar TV Live Bergaya YouTube**: Pemutar 16:9 di bagian atas dengan daftar saluran interaktif di bawahnya.
- **Mode Layar Penuh dengan Tombol Persegi Bawaan**: Tombol fullscreen persegi imersif dengan kontrol lengkap dan pengatur rasio aspek.
- **Perbaikan Force Close**: Penanganan eksepsi WorkManager dan aturan ProGuard R8 untuk mencegah cold-start crash.

### Cineva v1.0.6
- **Notifikasi Pembaruan Otomatis di Latar Belakang**: Pengecekan otomatis rilis GitHub dengan Jetpack WorkManager.
- **Perbaikan Riwayat Tontonan & Status Selesai**: Penanganan episode serial TV dan deduplikasi riwayat.
- **Redesain "Pilih Sesuai Platform"**: Pelat logo resmi platform streaming berlatar belakang putih bersih di halaman pencarian.

---

## Informasi Versi

- Versi Aplikasi: 1.0.9
- Build: 10
- Target Sistem Operasi: Android 5.0 (API 21) ke atas
