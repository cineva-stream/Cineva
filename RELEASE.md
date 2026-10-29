# Cineva v1.0.8 - Release Notes 🎬

Pembaruan Cineva versi 1.0.8 menghadirkan perbaikan navigasi pada halaman Watchlist/Favorit dengan animasi transisi bottom navigation menu yang halus, penambahan tombol navigasi Chevron Left pada AppBar Watchlist, redesain alur pemutaran TV Live (eksplorasi manual tanpa auto-play, penutupan halus menu navigasi bawah saat siaran dimulai, dan pembersihan badge overlay), peningkatan keandalan notifikasi pembaruan latar belakang, penyempurnaan total fitur Unduhan & Pemutaran Offline (In-App Offline Playback), serta pembaruan lisensi proyek menjadi GNU General Public License v3.0 (GPL-3.0).

---

## Ringkasan Perubahan

### 1. Perbaikan Navigasi & Animasi Watchlist / Favorit
- **Penyelesaian Bug Tab Selection**: Memperbaiki masalah di mana menekan ikon Watchlist/Favorit pada AppBar menyebabkan tab bottom navigation berpindah dan menyorot tab TV Live. Tab navigasi kini tidak lagi salah menyorot tab lain.
- **Animasi Slide-Down Halus**: Bottom navigation menu kini disembunyikan secara halus dengan animasi geser ke bawah (*slide down*) dan transisi *fade out* menggunakan `AnimatedSlide` dan `AnimatedOpacity` saat pengguna berada di halaman Watchlist.
- **Tombol Chevron Left pada AppBar**: Menambahkan tombol kembali (*Chevron Left*) berikon `Icons.chevron_left_rounded` di sisi kiri AppBar Watchlist, memudahkan pengguna untuk kembali ke halaman sebelumnya atau ke Beranda secara intuitif.

### 2. Redesain Alur Pemutaran TV Live (Manual Selection & Clean Controls)
- **Eksplorasi Manual Tanpa Auto-Play**: Tab TV Live tidak lagi otomatis memutar saluran pertama saat baru dibuka. Pengguna disajikan tampilan *placeholder* elegan dengan bilah pencarian, filter kategori, dan daftar saluran lengkap agar dapat mencari dan memilih siaran sesuai keinginan.
- **Transisi Halus Saat Menonton**: Begitu pengguna menekan saluran pilihan, siaran langsung akan dimulai dan bottom navigation menu secara otomatis meluncur turun (*slide down*) secara halus untuk memaksimalkan area tontonan.
- **Pembersihan Kontrol Pemutar**: Badge teks "TV Live" di pojok kiri atas kontrol *overlay* pemutar telah dihilangkan sehingga tampilan video lebih bersih dan leluasa.
- **Tombol Tutup / Stop Siaran**: Tersedia tombol tutup (*Close/Stop*) untuk menghentikan pemutaran saluran kapan saja, yang mengembalikan layar ke mode penjelajahan saluran dan menampilkan kembali bottom navigation menu.

### 3. Peningkatan Keandalan Notifikasi Pembaruan Latar Belakang
- Menambahkan fallback penjadwalan `AlarmManager` melalui `UpdateAlarmReceiver` guna mendukung pengecekan rilis GitHub saat aplikasi tidak aktif atau setelah perangkat dinyalakan ulang (*boot completed*).
- Memastikan permintaan izin runtime `POST_NOTIFICATIONS` pada Android 13 (API 33) ke atas agar notifikasi pembaruan dapat ditampilkan tanpa hambatan.

### 4. Penyempurnaan Total Fitur Unduhan & Pemutaran Offline (In-App Offline Playback)
- **Perbaikan Masalah Layar Hitam & Modal Popup Galat**: Mengeliminasi timeout artifisial durasi pada pemutar offline yang sebelumnya memicu modal popup peringatan unduhan belum selesai. Pemutar kini langsung membuka berkas lokal dan memulai pemutaran seketika (*instant start*).
- **Perbaikan Opsi Protokol MPV (`demuxer-lavf-o`)**: Menghapus opsi pembatas protokol yang tidak valid yang sebelumnya memblokir koneksi server loopback lokal `http://127.0.0.1` pada FFmpeg libavformat, memulihkan pemutaran HLS offline seutuhnya.
- **Pemutaran HLS Loopback Langsung (`LocalStreamServer`)**: Berkas paket unduhan HLS (`master.m3u8` dan segmen MPEG-TS) diputar secara langsung melalui server loopback tersemat dengan sinkronisasi audio-video akurat, dukungan pencarian durasi (*seeking*), dan mode jeda (*pause/resume*).
- **Perlindungan Berkas Segmen & Self-Healing Manifest**: Berkas segmen asli tidak lagi dihapus jika muxing MP4 gagal. Ditambahkan mekanisme *self-healing* otomatis untuk menyusun playlist HLS sintetis jika berkas tersimpan dalam bentuk kontainer TS terpisah.
- **Token-Preserving HLS URL Resolution (`HlsUrlResolver`)**: Mengatasi masalah kegagalan unduhan segmen dan kunci enkripsi AES-128 pada stream VixSrc dan CDN modern yang menggunakan query parameter bertanda tangan (`?token=...&expires=...`).
- **Segment Unwrapping & Auto-Padding (`unwrapDisguisedSegment`)**: Mendeteksi dan mengupas header gambar palsu (PNG/JPEG/GIF fake prefixes) serta menyelaraskan padding 188-byte MPEG-TS secara otomatis.
- **Dukungan Subtitle Offline Lengkap**: Subtitle lokal (`.srt` maupun `.vtt`) dimuat otomatis dan ditampilkan di menu pilihan subtitle pemutar.

### 5. Pembaruan Lisensi ke GNU General Public License v3.0 (GPL-3.0)
- **Migrasi Lisensi ke GPL-3.0**: Menyelaraskan seluruh lisensi proyek Cineva dari MIT License menjadi GNU General Public License v3.0 (GPL-3.0) demi keseragaman ekosistem Cineva (seperti pada repositori `cineva-web`).
- **Pembaruan Dokumen & Komponen Aplikasi**: Memperbarui berkas `LICENSE` resmi GPL-3.0, badge lisensi di `README.md` dan menu Tentang Aplikasi (`AboutInfoScreen`), teks Syarat & Ketentuan hukum pada `legal_content.dart` (Bahasa Indonesia & English), serta deskripsi kredit pada lokalisasi `app_strings.dart`.


---

## Riwayat Versi Sebelumnya

### Cineva v1.0.7
- **Redesain Pemutar TV Live Bergaya YouTube**: Pemutar 16:9 di bagian atas dengan daftar saluran interaktif di bawahnya.
- **Mode Layar Penuh dengan Tombol Persegi Bawaan**: Tombol fullscreen persegi imersif dengan kontrol lengkap dan pengatur rasio aspek.
- **Perbaikan Force Close**: Penanganan eksepsi WorkManager dan aturan ProGuard R8 untuk mencegah cold-start crash pada rilis release.
- **Ikon Notifikasi Transparan**: Aset `logo_cineva.png` transparan tanpa kotak putih solid di status bar Android.

### Cineva v1.0.6
- **Notifikasi Pembaruan Otomatis di Latar Belakang**: Pengecekan otomatis rilis GitHub dengan Jetpack WorkManager.
- **Perbaikan Riwayat Tontonan & Status Selesai**: Penanganan episode serial TV dan deduplikasi riwayat.
- **Redesain "Pilih Sesuai Platform"**: Pelat logo resmi platform streaming berlatar belakang putih bersih di halaman pencarian.

---

## Informasi Versi

- Versi Aplikasi: 1.0.8
- Build: 9
- Target Sistem Operasi: Android 5.0 (API 21) ke atas
