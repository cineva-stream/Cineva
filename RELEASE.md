# Cineva v1.0.7 - Release Notes 🎬

Pembaruan Cineva versi 1.0.7 menghadirkan perombakan antarmuka TV Live Stream bergaya YouTube (pemutar 16:9 di bagian atas dengan daftar saluran interaktif di bawahnya), kontrol layar penuh dengan tombol persegi bawaan, persistensi bottom navigation menu, perbaikan masalah *cold-start crash* (force close), serta pembaruan ikon notifikasi sistem dengan latar belakang transparan.

---

## Ringkasan Perubahan

### 1. Redesain Pemutar TV Live Bergaya YouTube (In-Place 16:9 Player)
- Saat membuka tab TV Live, siaran langsung pertama langsung diputar di bagian atas layar dengan rasio 16:9 responsif layaknya antarmuka YouTube.
- Bagian bawah pemutar menyajikan informasi siaran aktif (logo saluran, nama saluran, badge *LIVE* merah berkedip, kategori, dan tombol favorit).
- Dilengkapi bilah pencarian instan (*quick search*) dan filter chip kategori saluran (Semua, Olahraga, Berita, Film & Hiburan, Indonesia, Anak & Animasi, Sains & Edukasi, Musik) yang dapat digeser secara horizontal.
- Memilih saluran mana pun dari daftar di bawah langsung memperbarui siaran di pemutar atas secara instan, lengkap dengan penanda saluran aktif (*Now Playing*) dan bingkai aksen amber menyala.

### 2. Mode Layar Penuh dengan Tombol Persegi Bawaan (Square Fullscreen Control)
- Menyediakan tombol persegi bawaan (`fullscreen_rounded`) pada kontrol pemutar langsung untuk memperluas siaran menjadi mode layar penuh imersif (*landscape*).
- Status bar dan kontrol sistem secara otomatis disembunyikan dalam mode layar penuh untuk kenyamanan menonton tanpa distraksi.
- Kontrol layar penuh dilengkapi tombol persegi keluar (`fullscreen_exit_rounded`), pengatur rasio aspek (contain, cover, fill), tombol muat ulang, serta tombol laci cepat (*Quick Channel Drawer*) agar pengguna dapat berganti saluran tanpa perlu keluar dari layar penuh.
- Tombol kembali fisik/gestur pada mode layar penuh ditangani dengan cerdas untuk keluar ke mode potret normal tanpa keluar dari tab TV Live.

### 3. Persistensi Bottom Navigation Menu
- Bottom navigation menu (Beranda, TV Live, Cari, Favorit, Profil) tetap tampil konsisten di bagian bawah layar seperti pada halaman lainnya saat menonton TV Live dalam mode potret.
- Bottom navigation menu secara otomatis disembunyikan hanya ketika pengguna masuk ke dalam mode layar penuh (*fullscreen*).

### 4. Perbaikan Bug Force Close / Cold-Start Crash
- Memperbaiki masalah aplikasi tertutup tiba-tiba (*crash/force close*) saat pertama kali dibuka setelah pembaruan atau unduhan versi baru.
- Menambahkan penanganan eksepsi (*try-catch*) yang kokoh pada penjadwalan `UpdateCheckWorker` di `MainActivity.kt` dan eksekusi background worker di `UpdateCheckWorker.kt`.
- Menambahkan aturan ProGuard `-keep` untuk WorkManager pada `android/app/proguard-rules.pro` agar kelas worker tidak terhapus atau ter-obfuscate oleh optimasi R8 pada build release.

### 5. Ikon Notifikasi Sistem Berlatar Belakang Transparan
- Memperbarui ikon notifikasi pembaruan latar belakang menggunakan aset `logo_cineva.png` transparan di seluruh variasi resolusi (`drawable`, `mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`).
- Menghilangkan kotak putih solid (*white square box*) yang sebelumnya muncul pada bilah status Android dan panel notifikasi.

---

## Riwayat Versi Sebelumnya

### Cineva v1.0.6
- **Notifikasi Pembaruan Otomatis di Latar Belakang**: Pengecekan pembaruan otomatis di latar belakang dengan Jetpack WorkManager dan notifikasi dinamis dari GitHub Releases.
- **Perbaikan Riwayat Tontonan & Status Selesai**: Memperbaiki bug duplikasi status pada serial TV, pembersihan entri usang saat beralih episode, dan perbaikan penanganan race condition di *Continue Watching*.
- **Redesain "Pilih Sesuai Platform"**: Pelat logo *pure smooth white* pada halaman Pencarian untuk logo resmi Netflix, Disney+, Prime Video, Apple TV+, Max, Hulu, Paramount+, dan Peacock.

---

## Informasi Versi

- Versi Aplikasi: 1.0.7
- Build: 8
- Target Sistem Operasi: Android 5.0 (API 21) ke atas
