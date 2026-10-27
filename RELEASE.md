# Cineva v1.0.0 — Official Public Release 🎬✨

Selamat datang di **Cineva v1.0.0**, rilis publik resmi pertama dari aplikasi streaming film dan serial TV peer-to-peer (P2P) modern, terdesentralisasi, berfokus privasi, bebas iklan, dan berkinerja tinggi untuk perangkat Android.

---

## 🌟 Tentang Cineva

**Cineva** dirancang untuk memberikan pengalaman menonton sinematik premium kelas dunia di ponsel pintar Android. Dibangun dengan arsitektur modern (Flutter, Riverpod, MediaKit/MPV, Hive), Cineva menggabungkan kecepatan streaming terdistribusi P2P BitTorrent, mesin fallback pemutar cadangan, sistem profil lokal offline tanpa akun, hingga integrasi subtitle multibahasa otomatis.

---

## ⚠️ Tahap Pengembangan / Under Maintenance 🛠️

> **Pemberitahuan Fitur Unduhan (Downloads):**  
> **Fitur Download Film dan TV Series saat ini masih dalam perbaikan dan pengembangan aktif (*under maintenance*).**  
> File media hasil unduhan untuk sementara waktu **belum dapat diputar secara offline**. Tim pengembang sedang menyempurnakan dekripsi dan pemutar video offline agar dapat memutar seluruh format unduhan dengan lancar.  
> 💡 *Untuk saat ini, silakan nikmati seluruh film dan serial TV secara langsung melalui fitur **Streaming Online** berkecepatan tinggi.*

---

## 🚀 Fitur Utama & Pembaruan v1.0.0

### 1. 🎬 Mesin Pemutaran Sinematik Berkecepatan Tinggi
- **P2P BitTorrent Streaming Engine**: Memutar torrent video langsung tanpa harus menunggu unduhan selesai, dilengkapi *adaptive pre-buffering* 7 detik untuk pengalaman memutar instan.
- **Dukungan Multi-Stream & Multi-Resolusi**: Pilihan resolusi dinamis mulai dari adaptif Auto (FHD 1080p), 720p, hingga 480p hemat kuota.
- **Backup Web Player**: Fallback otomatis ke pemutar web tertanam jika seed torrent tidak mencukupi, memastikan video tetap dapat ditonton dalam kondisi apa pun.
- **Kontrol Gestur Responsif**: Geser kiri untuk kecerahan layar, geser kanan untuk volume, cubit (*pinch*) untuk zoom rasio layar, dan ketuk ganda untuk lompat 10 detik.

### 2. 👤 Profil Kustom Lokal & 10 Avatar Kartun Vektor
- **10 Karakter Avatar Kartun Sinematik**:
  1. *Popcorn Cine-Kid* — Anak laki-laki dengan kacamata 3D retro (lensa merah-cyan) dan senyum ceria.
  2. *The Director* — Sutradara dengan topi baret miring, kacamata hitam, dan janggut khas.
  3. *Cyberpunk Hacker* — Karakter futuristik dengan visor neon cyan dan earpiece mic.
  4. *Cosmic Explorer* — Astronaut dalam helm ruang angkasa bulat berrefleksi bintang.
  5. *Masked Superhero* — Pahlawan bertopeng domino merah dengan jambul heroik.
  6. *Film Noir Detective* — Detektif klasik bertopi fedora cokelat dan kerah mantel terangkat.
  7. *Anime Ninja* — Shinobi anime dengan ikat kepala plat logam dan masker ninja.
  8. *Retro 80s Cinephile* — Gadis kartun dengan kacamata neon bulat, bando cerah, dan rambut bob.
  9. *Cinema King* — Raja bioskop dengan mahkota emas berpermata dan kacamata selebriti.
  10. *Secret Agent 007* — Agen rahasia dengan kacamata hitam keren dan dasi kupu-kupu tuksedo.
- **Pemotong Foto Galeri (1:1 Aspect Ratio)**: Dukungan memilih foto dari galeri dengan alat potong interaktif (zoom, pan, rotate, dan circle mask).
- **Format Input Terstandarisasi**: Input Nickname dengan kapitalisasi otomatis pada huruf awal kata, dan input Username otomatis huruf kecil tanpa spasi.
- **100% Offline & Privat**: Seluruh data profil tersimpan aman di database lokal Hive pada perangkat pengguna tanpa memerlukan pendaftaran akun email atau nomor telepon.

### 3. 📜 Ketentuan Hukum & Transparansi Privasi Terbuka
- **Layar Persetujuan Dokumen Legal**: Memuat 3 dokumen hukum internasional resmi:
  1. *Syarat & Ketentuan Penggunaan* (*Terms of Service*)
  2. *Kebijakan Privasi Global* (*Privacy Policy*)
  3. *Pernyataan Sangkalan DMCA & Hak Cipta* (*DMCA & Content Disclaimer*)
- **Mekanisme Penguncian Scroll**: Tombol persetujuan (*Setuju* / *Agree*) dinonaktifkan hingga pengguna menggulir dokumen hingga ke bagian paling bawah, dilengkapi bar progres pembacaan *real-time*.

### 4. 📥 Unduhan Offline (Tahap Perbaikan / Under Maintenance)
- **Status Fitur**: Modul pengunduhan latar belakang (*background downloader*) telah tersedia, namun pemutaran media hasil unduhan (*offline playback*) saat ini masih dalam perbaikan dan belum dapat diputar.
- **Penyempurnaan Mendatang**: Integrasi pemutaran offline penuh sedang diselesaikan dan akan diaktifkan secara optimal pada pembaruan rilis selanjutnya. Untuk saat ini, nikmati konten via streaming online.

### 5. 🌐 Antarmuka Multibahasa (Bilingual)
- **Pilihan Bahasa Langsung di Splash Screen**: Pilih antara **Bahasa Indonesia** atau **English** saat pertama kali membuka aplikasi dengan tampilan *smooth border* minimalis.
- **Preferensi Konten Regional**: Filter konten khusus film Indonesia, Anime Jepang, Drama Korea, Hollywood, hingga Bollywood di Pengaturan.
- **Lencana Bendera Vektor**: Menampilkan bendera negara berformat vektor modern dan tajam di seluruh menu bahasa.

### 6. 💬 Mesin Subtitle Cerdas & Terjemahan Otomatis
- **Penyedia Subtitle Global**: Integrasi pencarian subtitle multi-bahasa terotomatisasi.
- **Auto-Translate ke Bahasa Indonesia**: Otomatis menerjemahkan subtitle bahasa Inggris ke Bahasa Indonesia jika subtitle native belum tersedia.
- **Kustomisasi Gaya Subtitle**: Pengaturan ukuran font teks (Kecil, Sedang, Besar, Ekstra Besar), warna teks, serta transparansi latar belakang subtitle.

### 7. 🎨 Desain Obsidian Cinema & Animasi Halus
- **Palet Warna Sinematik**: Latar belakang Obsidian Black (`#0A0A0C`) dengan aksen Cinema Amber (`#FF9500`).
- **Smooth Micro-Animations**: Transisi antar layar yang elegan (*curved cubic transitions*), marquee poster berputar halus di splash screen, serta respon sentuhan interaktif.

---

## 📱 Informasi Teknis Rilis

| Parameter | Keterangan |
| :--- | :--- |
| **Nama Aplikasi** | Cineva |
| **Package ID** | `com.primadev.cineva` |
| **Versi Rilis** | `1.0.0` |
| **Build Number** | `1` |
| **Target OS** | Android 5.0 (Lollipop, API 21) ke atas |
| **Arsitektur CPU** | `arm64-v8a`, `armeabi-v7a`, `x86_64` (Universal) |
| **Ukuran File APK** | ~96.9 MB |
| **Nama File APK** | `Cineva_v1.0.0.apk` |

---

## 📥 Panduan Instalasi

### Metode 1: Instalasi Manual via ADB (Komputer)
Jika ponsel Android Anda terhubung ke komputer via USB Debugging:
```bash
adb install -r Cineva_v1.0.0.apk
```

### Metode 2: Instalasi Langsung di Android
1. Unduh file `Cineva_v1.0.0.apk` dari tab [Releases](../../releases).
2. Buka file APK melalui File Manager atau notifikasi unduhan di perangkat Android Anda.
3. Jika diminta, izinkan instalasi dari *Sumber Tidak Dikenal* (*Install Unknown Apps*).
4. Tekan **Install** dan buka Cineva setelah proses selesai.

---

## ⚖️ Pernyataan Hukum (Disclaimer)

Cineva tidak menyimpan, mengunggah, atau meng-host konten video, film, atau media apa pun di server kami. Cineva berfungsi secara independen sebagai antarmuka pencarian dan pemutar media untuk tautan dan jaringan peer-to-peer (P2P) yang tersedia secara publik di internet. Pengguna bertanggung jawab penuh atas penggunaan aplikasi ini sesuai dengan hukum dan peraturan yang berlaku di wilayah yurisdiksi masing-masing.

---

*Dikembangkan dengan penuh dedikasi oleh Cineva Group.*
