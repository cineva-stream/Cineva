# Cineva v1.0.4 - Release Notes 🎬

Pembaruan Cineva versi 1.0.4 menghadirkan fitur pembaruan di dalam aplikasi (In-App Update) otomatis berbasis GitHub Releases API dengan tampilan banner pure smooth black berbatas halus di halaman Beranda, unduhan progresif langsung, pemicu installer paket bawaan Android, serta pembersihan otomatis cache berkas APK lama.

---

## Ringkasan Perubahan

### 1. Fitur Pembaruan Otomatis di Dalam Aplikasi (In-App Update)
- Menambahkan integrasi pemeriksaan versi rilis terbaru secara langsung melalui GitHub Releases API resmi Cineva.
- Memeriksa pembaruan secara otomatis saat aplikasi dibuka dengan perbandingan versi semantik (semver) yang akurat.

### 2. Desain Banner Pembaruan Halus di Halaman Beranda
- Menampilkan kartu banner pembaruan di atas Hero Section pada halaman Beranda saat rilis versi baru terdeteksi.
- Desain kartu dirancang menyatu dengan tema utama berlatar belakang hitam murni (pure smooth black OLED) dan diberi garis batas halus (smooth border) beraksen elegan.
- Menyediakan informasi nomor versi baru, ringkasan catatan pembaruan (changelog), tombol Perbarui Sekarang, serta tombol tutup untuk menyembunyikan notifikasi pada sesi berjalan.

### 3. Pengunduhan Progresif & Pemasangan Paket Android
- Mengunduh berkas APK pembaruan secara langsung di dalam aplikasi dengan indikator persentase kemajuan (progress bar) dan ukuran berkas secara real-time.
- Mendukung pembatalan unduhan secara instan kapan saja.
- Menjalankan modal penginstal paket aplikasi bawaan Android secara otomatis setelah unduhan selesai menggunakan FileProvider yang aman.
- Menyediakan modal dialog panduan jika aplikasi membutuhkan izin "Izinkan dari sumber ini" di Setelan Android.

### 4. Pembersihan Otomatis & Manual Berkas APK Cache
- Mengimplementasikan mekanisme pembersihan otomatis berkas instalasi APK yang tersimpan di direktori cache perangkat saat aplikasi berhasil diperbarui atau saat awal peluncuran.
- Mencegah penumpukan file APK berukuran besar di penyimpanan internal pengguna dan menjaga kapasitas ruang perangkat tetap lega.

---

## Informasi Versi

- Versi Aplikasi: 1.0.4
- Build: 5
- Target Sistem Operasi: Android 5.0 (API 21) ke atas
