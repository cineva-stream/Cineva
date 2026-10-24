<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/images/logo_cineva.png" />
    <source media="(prefers-color-scheme: light)" srcset="assets/images/logo_cineva_light.png" />
    <img alt="Cineva Logo" src="assets/images/logo_cineva.png" width="240" />
  </picture>
</p>

<p align="center">
  <strong>Aplikasi Streaming & Unduhan Film dan Serial TV Modern Berbasis Flutter</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.12+-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Platform-Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Platform" />
  <img src="https://img.shields.io/badge/License-MIT-FFA000?style=for-the-badge" alt="License" />
</p>

---

## 🎬 Tentang Cineva

Cineva adalah aplikasi streaming dan pengunduh Film serta Serial TV modern yang dirancang untuk menghadirkan pengalaman sinematik premium langsung di perangkat Android. Dibangun dengan estetika *Deep Obsidian* dan aksen *Cinema Amber*, Cineva memadukan katalog metadata global dari The Movie Database (TMDB), pemutar video berkinerja tinggi berbasis hardware decoding, serta sistem pengunduhan multi-koneksi berkecepatan tinggi.

---

## ✨ Fitur Utama

- **Streaming Cepat & Adaptif**
  Mendukung streaming video multi-server dengan buffering adaptif untuk koneksi internet berkecepatan rendah hingga tinggi.

- **Pengunduh Multi-Worker Berkecepatan Tinggi**
  Sistem unduhan paralel berbasis multi-chunk worker yang memaksimalkan bandwidth jaringan pengguna, dilengkapi fitur jeda (*pause*), lanjutkan (*resume*), dan pembatalan unduhan.

- **Format Penamaan File Standar**
  File hasil unduhan disimpan langsung ke penyimpanan perangkat dengan struktur penamaan yang rapi:
  - Film: `{Nama Film} - {Tahun Rilis}.mp4`
  - Serial TV: `{Nama Serial} - S{Season} E{Episode}.mp4`

- **Pipeline Subtitle Cerdas & Terjemahan Otomatis**
  Pencarian subtitle otomatis dengan fallback cerdas. Apabila subtitle Bahasa Indonesia tidak tersedia, sistem akan mengunduh versi bahasa Inggris ke cache lokal, menerjemahkannya secara otomatis dengan penyesuaian kata ganti natural (*Kau*/*Aku*) serta penyeimbangan panjang baris agar pas di layar.

- **Preferensi Konten Personalisasi**
  Filter cerdas di beranda dan pencarian untuk memprioritaskan kategori favorit pengguna, seperti Indonesia, Anime, Hollywood, Korea, Jepang, maupun Bollywood.

- **Pemutar Media Sinematik Lengkap**
  Dilengkapi gestur kecerahan dan volume, pengatur kecepatan putar (0.5x - 2.0x), pemilihan trek audio, pergantian subtitle, tombol Skip Intro dan Skip Credit, serta pengingat posisi tontonan terakhir.

- **Penyimpanan Offline Lokal**
  Manajemen riwayat tontonan, daftar favorit, dan katalog unduhan tersimpan secara instan dan aman di perangkat menggunakan basis data lokal Hive NoSQL.

---

## 🏗 Arsitektur & Teknologi

Aplikasi ini dibangun menggunakan arsitektur modular berorientasi fitur (*Feature-First Clean Architecture*):

- **Framework**: Flutter SDK (Channel Stable)
- **State Management**: Flutter Riverpod
- **Routing**: GoRouter
- **Video Engine**: media_kit (libmpv hardware-accelerated video decoding)
- **Networking**: Dio dengan konfigurasi adapter HTTP connection pool
- **Local Database**: Hive Flutter
- **Tipografi & Ikon**: Google Fonts (Outfit, Inter, JetBrains Mono) & Iconsax Flutter

---

## 🚀 Panduan Memulai

### Prasyarat

Sebelum memulai proses instalasi, pastikan sistem Anda telah memiliki:

1. Flutter SDK versi 3.12.0 atau lebih baru.
2. Dart SDK versi 3.0.0 atau lebih baru.
3. Android SDK dengan target API 34.
4. Android Studio atau Visual Studio Code dengan ekstensi Flutter terpasang.

### Langkah Instalasi

1. **Clone repositori ini:**
   ```bash
   git clone https://github.com/username/cineva.git
   cd cineva
   ```

2. **Siapkan konfigurasi environment:**
   Salin file `.env.example` menjadi `.env`:
   ```bash
   cp .env.example .env
   ```
   Buka file `.env` dan masukkan API Key TMDB serta OpenSubtitles Anda.

3. **Unduh dependensi project:**
   ```bash
   flutter pub get
   ```

4. **Jalankan aplikasi di emulator atau perangkat fisik:**
   ```bash
   flutter run
   ```

---

## ⚙️ Konfigurasi Environment

Aplikasi Cineva memerlukan API Key dari pihak ketiga untuk mengambil data katalog film dan subtitle. Konfigurasi disimpan dalam file `.env`:

```env
# TMDB API Key & Read Access Token
TMDB_API_KEY=your_tmdb_api_key_here
TMDB_ACCESS_TOKEN=your_tmdb_read_access_token_here

# OpenSubtitles.com API Key
OPENSUBTITLES_API_KEY=your_opensubtitles_api_key_here
```

Daftarkan akun gratis untuk memperoleh kunci API melalui:
- TMDB: [https://www.themoviedb.org/settings/api](https://www.themoviedb.org/settings/api)
- OpenSubtitles: [https://www.opensubtitles.com/consumers](https://www.opensubtitles.com/consumers)

---

## 📦 Cara Build APK

Untuk mengompilasi APK rilis dengan optimasi performa tinggi, tree-shaking font, dan obfuskasi kode:

```bash
flutter build apk --release --obfuscate --split-debug-info=./debug-info
```

File APK rilis akan dihasilkan di direktori:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 🧪 Menjalankan Pengujian

Untuk memastikan seluruh modul, penamaan file, parser subtitle, dan model berjalan dengan benar:

```bash
flutter test
```

---

## 📄 Lisensi

Proyek ini dilisensikan di bawah lisensi **MIT License**. Hak Cipta (c) 2026 **Primadev Digital Technology**.  
Silakan merujuk ke file [LICENSE](LICENSE) untuk ketentuan lisensi selengkapnya.

---

## 👥 Pengembang

Dikembangkan dan dipelihara oleh **Primadev Digital Technology**.
