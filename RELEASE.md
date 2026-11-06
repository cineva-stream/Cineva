# Cineva v1.1.5 - Release Notes 🎬

Pembaruan Cineva versi 1.1.5 menghadirkan lompatan besar pada **Sinkronisasi Multi-Perangkat (HP, TV, & Windows)**, penyempurnaan **Tampilan Pembaruan Berbasis GitHub Markdown**, pengemasan **Build Khusus Android TV Super Ringan**, serta **Otomasi Tanda Tangan Digital Windows** dan **Retensi Data Pengguna pada Installer**.

---

## Ringkasan Fitur Baru & Peningkatan Utama

### 1. Sinkronisasi Data & Profil Multi-Perangkat via QR Code (Zero-Config Hybrid Mode)
* **Onboarding Otomatis Android TV**:
  * Pengguna Android TV tidak perlu lagi repot mengetik nama profil menggunakan remote kontrol.
  * Halaman onboarding Android TV langsung menyajikan QR Code sinematik untuk dipindai oleh ponsel Android.
* **Dual-Mode Fleksibel di Windows Desktop**:
  * Pada Windows Desktop, pengguna bebas memilih: memindai QR Code dari ponsel untuk menyamakan data, atau membuat profil baru secara manual.
* **Sinkronisasi Dataset Lengkap (Full-Sync)**:
  * Tidak hanya profil pengguna (nama & avatar), proses pairing QR Code kini mentransfer seluruh **Watchlist**, **Riwayat Tontonan (Watch History)** lengkap dengan resolusi konflik progress terbaru, serta **Preferensi Pengguna**.
* **Zero-Config Hybrid Network (Lintas Jaringan)**:
  * Berjalan mulus di jaringan lokal Wi-Fi yang sama (P2P WebSocket) maupun jaringan berbeda (misal TV menggunakan Wi-Fi rumah dan HP menggunakan paket data 4G/5G) melalui *Zero-Config End-to-End Encrypted Relay*.
* **Dukungan Dwibahasa Penuh (ID & EN)**:
  * Seluruh teks panduan pairing, status koneksi, dan tombol beralih mode disajikan dalam Bahasa Indonesia dan English yang rapi.

### 2. Tampilan Pembaruan In-App & Modal Changelog GitHub-Flavored Markdown
* **Widescreen Balanced Update Banner**:
  * Banner pembaruan pada Android TV dan Windows Desktop kini tersusun dalam format *horizontal widescreen card* yang elegan dan dapat difokuskan langsung menggunakan remote D-Pad maupun tombol panah keyboard.
* **Modal Changelog Berbasis GitHub Markdown (GFM)**:
  * Modal detail pembaruan ditenagai oleh `flutter_markdown` dengan parser GitHub-Flavored Markdown resmi.
  * Menampilkan catatan rilis persis 100% seperti di GitHub: heading berhirarki, daftar poin dengan aksen emas, blok kode berlatar gelap khas Cineva, kutipan (*blockquotes*), serta tautan aktif yang dapat diklik langsung.

### 3. Pemisahan Build Khusus Android TV Super Ringan & Otomasi 1 Perintah
* **Artefak Resmi Khusus Android TV (`Cineva_v1.1.5-android-tv.apk`)**:
  * Dibangun secara khusus menggunakan arsitektur 32-bit ARM (`armeabi-v7a`), menghasilkan ukuran file yang sangat kecil dan ringan (**hanya ~15-20 MB**, hemat memori hingga >60%).
  * Sangat ramah untuk kapasitas penyimpanan Android TV, Xiaomi Mi Box / TV Stick, Google TV, dan Smart TV yang terbatas.
* **Skrip Otomasi Build 1 Perintah (`scripts/build_android.ps1`)**:
  * `.\scripts\build_android.ps1 -Tv` $\rightarrow$ Mengompilasi khusus Android TV super ringan.
  * `.\scripts\build_android.ps1 -Mobile` $\rightarrow$ Mengompilasi khusus ponsel Android modern (64-bit ARM).
  * `.\scripts\build_android.ps1 -All` $\rightarrow$ Mengompilasi seluruh varian CPU sekaligus dalam 1 kali jalan.
* **Proteksi Kode Penuh (*Obfuscation & Size Optimization*)**:
  * Skrip build secara otomatis menyertakan `--release`, `--split-per-abi`, serta proteksi `--obfuscate` dan pemisahan simbol debug (`--split-debug-info`) secara *default* untuk melindungi biner dari *reverse engineering* sekaligus merampingkan ukuran file.
* **In-App Updater Cerdas**:
  * Aplikasi yang berjalan di Android TV secara otomatis memprioritaskan aset `-android-tv.apk` saat mendeteksi rilis baru di GitHub.

### 4. Otomasi Tanda Tangan Digital Windows (Code Signing) & Retensi Data Uninstall
* **Otomasi Script Penandatanganan (`scripts/sign_windows_installer.ps1`)**:
  * Menyediakan otomasi penandatanganan Authenticode SHA-256 dan RFC 3161 Timestamp resmi untuk biner `cineva.exe` dan `Cineva_setup_v1.1.5.exe` guna mengatasi peringatan *Microsoft Defender SmartScreen* ("Unknown Publisher").
* **Opsi Retensi Data Profil Saat Uninstall**:
  * Pada jendela pencopotan pemasangan Windows (`uninstall.exe`), kini tersedia kotak centang *"Simpan data saya"* (Bahasa Indonesia) atau *"Keep my data"* (English).
  * Jika dicentang, seluruh data profil, watchlist, riwayat tontonan, dan pengaturan pengguna akan tetap aman tersimpan di komputer dan tidak ikut terhapus.

### 5. Perbaikan Bug & Stabilitas Windows
* Memperbaiki masalah tampilan layar putih kosong (*white blank screen*) saat peluncuran awal aplikasi di Windows Desktop.
* Memastikan transisi frameless window dan kontrol jendela berjalan mulus sejak frame pertama.

---

## Riwayat Versi Sebelumnya

### Cineva v1.1.4
* **Ekspansi Multiplatform**: Rilis perdana resmi untuk Android TV (10-Foot UI Leanback) dan Windows Desktop Runner.
* **Sistem Fokus D-Pad & Poster Zoom 1.11x**: Efek pembesaran poster dan pendaran cahaya lembut (*ambient amber glow*).
* **Bilah Navigasi Kiri Adaptif (*Adaptive Navigation Rail*)**: Layout samping rata tengah yang simetris untuk layar lebar.
* **Windows Frameless UI & Buttery-Smooth Mouse Scrolling**: Scroll roda mouse berkecepatan tinggi tanpa patah-patah.
* **Fitur Unggah Subtitle Mandiri (.srt, .vtt, .sub, .ass)**: Langsung dari penyimpanan lokal dengan dukungan 1-Tap AI Translator.

### Cineva v1.1.3
* **Kalender Siaran & Radar Rilis (*Airing Calendar & Coming Soon*)**: Jadwal rilis mingguan anime, k-drama, serial TV, dan film.
* **Hub Semesta & Urutan Nonton Serial TV (*TV Universe Hub*)**: Panduan urutan tontonan waralaba serial TV.
* **Pemutar Trailer Resmi di Dalam Aplikasi**: Pemutar YouTube gelap sinematik.
* **Halaman Profil Aktor & Filmografi**: Portofolio karya aktor/aktris dengan kalkulasi usia otomatis.
* **Hub Waralaba / Koleksi Film (*Franchise Collection Hub*)**: Timeline kronologis koleksi film bioskop.

---

## Informasi Versi

* **Versi Aplikasi**: 1.1.5
* **Build**: 16
* **Target Sistem Operasi**: Android 5.0 (API 21) ke atas (Smartphone & Android TV / Google TV), Windows 10/11 (64-bit)
* **Daftar Varian File Rilis**:
  * `Cineva_setup_v1.1.5.exe` (Windows Desktop Installer Resmi, ~35-45 MB)
  * `Cineva_v1.1.5-android-tv.apk` (Khusus Android TV & Smart TV, ~15 MB - **Rekomendasi TV**)
  * `Cineva_v1.1.5-arm64-v8a.apk` (HP Android Modern 64-bit, ~16 MB)
  * `Cineva_v1.1.5-armeabi-v7a.apk` (HP Android Lawas 32-bit, ~15 MB)
  * `Cineva_v1.1.5-x86_64.apk` (Emulator PC & Android x86, ~18 MB)
  * `Cineva_v1.1.5.apk` (Universal / Semua CPU, Kompatibel Penuh, ~38 MB)
