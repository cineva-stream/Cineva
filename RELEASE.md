# Cineva v1.1.7 - Release Notes 🎬

Pembaruan Cineva versi 1.1.7 menghadirkan fitur besar **Cadangan & Pemulihan Data (Backup & Restore)**, integrasi **Masuk & Sinkronisasi Cloud dengan Google (Sign in with Google & Firebase Realtime Database)**, perombakan antarmuka **Side Panel Streaming & Subtitle Setting Minimalis**, serta optimalisasi keamanan build **ProGuard & Obfuscation**.

---

## Ringkasan Fitur Baru & Peningkatan Utama

### 1. Fitur Cadangan & Pemulihan Data Mandiri (Backup & Restore System)
* **Ekspor Cadangan Lengkap Berkas `.cineva`**:
  * Pengguna kini dapat mencadangkan seluruh data aplikasi ke dalam satu file terenkripsi ringan (`.cineva` / `.json`).
  * Mencakup: **Daftar Watchlist**, **Riwayat Tontonan** (posisi menit pemutaran terakhir & status selesai tonton), **Pengaturan Subtitle** (ukuran font, latar belakang teks, bahasa default), **Kualitas Video Default**, **Preferensi Konten**, serta **Profil Pengguna** (Nama, Username, dan foto avatar galeri).
* **Pemulihan Universal Tanpa Hambatan (*Universal File Picker*)**:
  * Menggunakan pemilih berkas universal yang kompatibel penuh dengan berbagai penyimpanan perangkat (Folder Download, Memori Internal, Kartu SD, maupun Google Drive).
  * Dilengkapi validasi tanda tangan (*magic signature verification*) untuk mendeteksi file rusak atau tidak valid secara aman tanpa risiko crash.
* **Opsi Pemulihan Langsung di Layar Awal (*Splash Screen*)**:
  * Pengguna yang baru menginstal ulang aplikasi dapat langsung memilih opsi **"Pulihkan dari File Cadangan"** tepat setelah memilih bahasa aplikasi, lalu langsung masuk ke beranda dengan seluruh data yang telah pulih utuh.

### 2. Masuk dengan Google & Sinkronisasi Cloud (Google Sign-In & Realtime Database)
* **Sinkronisasi Multi-Perangkat Otomatis**:
  * Menghubungkan akun ke Google memungkinkan seluruh riwayat tontonan, watchlist, dan pengaturan profil tersinkronisasi secara instan di berbagai perangkat tanpa perlu ekspor/impor manual.
  * Menggunakan **Firebase Realtime Database** yang efisien, cepat, dan 100% bebas biaya (Spark Plan).
* **Auto-Populate Data Akun Google Cerdas**:
  * Saat masuk dengan Google, aplikasi secara otomatis mengisi **Nickname** dari nama profil Google (`displayName`), **Username** unik dari awalan email Google, serta mengunduh foto profil Google sebagai **Avatar** pengguna.
* **Integrasi Fleksibel pada Layar Selamat Datang & Edit Profil**:
  * Tersedia di layar awal (*Splash Screen*) untuk pengguna baru, serta di halaman **Edit Profil** bagi pengguna lama yang ingin menghubungkan akun Google kapan saja.

### 3. Desain Ulang Antarmuka: Side Panel Streaming & Subtitle Minimalis
* **Side Panel Streaming Video Latar Hitam Obsidian**:
  * Latar belakang panel samping kanan pada pemutar video (saat streaming Film & Serial TV) kini berwarna hitam pekat (`#0D0D12` / `#000000`), menyatu sempurna dengan estetika gelap sinematik Cineva.
* **Pengaturan Subtitle Bersih & Ringkas**:
  * Menghilangkan kotak pratinjau teks redundan karena hasil pengaturan gaya teks sudah langsung terlihat secara *real-time* di layar pemutaran video.
  * Tampilan kontrol ukuran font, bahasa subtitle, dan latar belakang menjadi jauh lebih ringkas, rapi, dan modern.
* **Penyegaran Tombol Google & Pembersihan Pengaturan**:
  * Tombol "Masuk dengan Google" di halaman Edit Profil kini berlatar belakang putih solid dengan teks hitam kontras tinggi dan ikon resmi Google (`google-icon.png`).
  * Menu di Halaman Pengaturan disederhanakan khusus untuk Cadangkan & Pulihkan berkas file lokal.

### 4. Keamanan Build, ProGuard & Obfuscation
* **Proteksi ProGuard Lengkap**:
  * Menambahkan aturan proteksi refleksi (`-keep`) pada `proguard-rules.pro` untuk Firebase Core, Firebase Analytics, Firebase Auth, Firebase Realtime Database, dan Google Sign-In.
  * Menjamin kestabilan 100% saat aplikasi dikompilasi dengan flag `--obfuscate`, `minifyEnabled true`, dan `shrinkResources true` tanpa risiko crash runtime.
* **Perlindungan Kredensial**:
  * Mengisolasi dan mengamankan berkas konfigurasi `google-services.json` dari repositori publik.

---

## Riwayat Versi Sebelumnya

### Cineva v1.1.6
* **Desain Ulang Filter Kategori Beranda**: Full Grid responsif dan Carousel Top 8-10 untuk Film dan Serial TV dengan *infinite scroll* berkelanjutan.
* **Pembaruan Masif "Pilih Sesuai Platform"**: Pemulihan ribuan judul film/serial TV (Max/HBO, Paramount+, Peacock, Prime Video) dengan paginasi berkelanjutan.
* **Kursor Mouse Auto-Hide Windows**: Auto-hide kursor mouse mengikuti kontrol player dengan filter anti-jitter getaran meja (14px).
* **Penyempurnaan Penginstal Windows**: Dokumen lisensi multibahasa (ID/EN) dengan tipografi bersih.

### Cineva v1.1.5
* **Sinkronisasi Data Multi-Perangkat via QR Code**: Onboarding otomatis Android TV dan dual-mode pairing nirkabel.
* **Modal Changelog Berbasis GitHub Markdown (GFM)**: Parser resmi GitHub Markdown di dalam aplikasi.
* **Pemisahan Build Khusus Android TV**: APK khusus 32-bit ARM berukuran hemat memori (~15-20 MB).

---

## Informasi Versi

* **Versi Aplikasi**: 1.1.7
* **Build**: 18
* **Target Sistem Operasi**: Android 5.0 (API 21) ke atas (Smartphone & Android TV / Google TV), Windows 10/11 (64-bit)
* **Daftar Varian File Rilis**:
  * `Cineva_setup_v1.1.7.exe` (Windows Desktop Installer Resmi)
  * `Cineva_v1.1.7-android-tv.apk` (Khusus Android TV & Smart TV - **Rekomendasi TV**)
  * `Cineva_v1.1.7-arm64-v8a.apk` (HP Android Modern 64-bit)
  * `Cineva_v1.1.7-armeabi-v7a.apk` (HP Android Lawas 32-bit)
  * `Cineva_v1.1.7-x86_64.apk` (Emulator PC & Android x86)
  * `Cineva_v1.1.7.apk` (Universal / Semua CPU, Kompatibel Penuh)
