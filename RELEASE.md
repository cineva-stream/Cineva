# Cineva v1.0.8 - Release Notes 🎬

Pembaruan Cineva versi 1.0.8 menghadirkan perbaikan navigasi pada halaman Watchlist/Favorit dengan animasi transisi bottom navigation menu yang halus, penambahan tombol navigasi Chevron Left pada AppBar Watchlist, redesain alur pemutaran TV Live (eksplorasi manual tanpa auto-play, penutupan halus menu navigasi bawah saat siaran dimulai, dan pembersihan badge overlay), serta peningkatan keandalan notifikasi pembaruan latar belakang.

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
