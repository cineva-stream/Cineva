# Cineva v1.0.6 - Release Notes 🎬

Pembaruan Cineva versi 1.0.6 menghadirkan fitur notifikasi pembaruan otomatis di latar belakang (*background update notifications*) dengan pesan dinamis dari GitHub, perbaikan menyeluruh pada status riwayat tontonan dan *Continue Watching* untuk serial TV, serta redesain elegan pelat logo *pure smooth white* pada bagian "Pilih Sesuai Platform" di halaman Pencarian.

---

## Ringkasan Perubahan

### 1. Notifikasi Pembaruan Otomatis di Latar Belakang (Background Update Notifications)
- Menambahkan sistem notifikasi pembaruan otomatis yang berjalan di latar belakang menggunakan Android Jetpack WorkManager, bahkan saat aplikasi dalam kondisi ditutup atau dimatikan.
- Pesan notifikasi bersifat dinamis: menyajikan nomor versi rilis terbaru serta deskripsi lengkap (*changelog/release body*) langsung dari GitHub Releases API dalam format `BigTextStyle` yang dapat diperluas.
- Notifikasi terhubung langsung dengan `MainActivity` sehingga ketukan pada notifikasi akan membuka aplikasi dan memunculkan *In-App Update Banner* untuk penginstalan langsung.
- Mendukung izin `POST_NOTIFICATIONS` untuk Android 13 (API 33) ke atas.

### 2. Perbaikan Riwayat Tontonan & Status Selesai (Continue Watching Bug Fix)
- Memperbaiki bug duplikasi status riwayat tontonan pada serial TV (misalnya saat menonton The Rookie S1 E02 lalu menekan *Next Episode* yang sebelumnya memunculkan 2 entri: satu berstatus selesai dan satu berstatus dalam progres).
- Saat menekan *Next Episode*, episode sebelumnya kini langsung tercatat tuntas 100% (*completed*) dan entri usang/duplikat langsung dibersihkan dari basis data Hive.
- Memperbaiki *race condition* pada pendengar posisi pemutar media (*media_kit*) saat pergantian episode berlangsung sehingga status selesai tidak tertimpa kembali menjadi dalam progres.
- Mengonsolidasikan daftar "Lanjutkan Menonton" di layar Beranda agar hanya menampilkan episode aktif terbaru untuk setiap serial TV.
- Memperbaiki passing parameter `season` dan `episode` pada pemutar video unduhan (*offline playback*) di layar Download agar konsisten dengan riwayat pemutaran online.

### 3. Redesain "Pilih Sesuai Platform" (Pure Smooth White Logo Plates)
- Merancang ulang kartu platform streaming pada halaman Pencarian: menggunakan pelat berlatar belakang *pure smooth white* (`#FFFFFF`) dengan sudut melengkung halus (*smooth rounded corners*) dan bayangan lembut.
- Menghilangkan teks nama platform sehingga tampilan murni fokus menonjolkan logo resmi masing-masing platform streaming (Netflix, Amazon Prime Video, Disney+, Apple TV+, Max, Hulu, Paramount+, Peacock).
- Mempertahankan tata letak 2 baris (*two-row compact grid*) agar scrolling horizontal tetap hemat ruang dan nyaman diakses.
- Header halaman katalog platform streaming turut diperbarui menggunakan pelat logo putih yang bersih dan modern.

---

## Informasi Versi

- Versi Aplikasi: 1.0.6
- Build: 7
- Target Sistem Operasi: Android 5.0 (API 21) ke atas
