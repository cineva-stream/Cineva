# Cineva v1.1.1 - Release Notes 🎬

Pembaruan Cineva versi 1.1.1 menghadirkan penambahan saluran TV Live terlengkap baik saluran nasional Indonesia (Indosiar, SCTV, Trans TV, Trans7, ANTV, Metro TV, Kompas TV, iNews, CNN Indonesia, CNBC Indonesia, dll.) maupun internasional (CNN News 18, BBC News, ABC News Live, CBS News 24/7, NBC News NOW, Al Jazeera English, Euronews, France 24, Bloomberg TV+, dll.) dengan logo resmi berlatar transparan, implementasi Custom UI Player terpadu dengan pelindung iklan (*Anti-Ad Touch Shield*) untuk server streaming non-direct (VidLink, MultiEmbed, VidSrc, dll.), serta redesain daftar episode serial TV tanpa card tebal menggunakan garis batas tipis elegan dan sinopsis berpemotongan teks profesional (*ellipsis*).

---

## Ringkasan Perubahan

### 1. Penambahan Saluran TV Live Nasional & Internasional Terlengkap
- **Katalog Saluran Nasional Indonesia Terlengkap**:
  - Menambahkan saluran televisi swasta dan nasional utama: **Indosiar HD**, **SCTV HD**, **Trans TV**, **Trans7 HD**, **ANTV HD**, **Metro TV HD**, **Kompas TV HD**, **iNews HD**, **CNN Indonesia**, **CNBC Indonesia**, **BTV Indonesia**, **Jawa Pos TV**, **JTV Surabaya**, **UGTV Gunadarma**, berdampingan dengan **TVRI Nasional**, **TVRI World**, **DAAI TV**, **Garuda TV**, **Indonesiana TV**, **Al-Bahjah TV**, **Ahsan TV**, dan **Ashiil TV**.
- **Katalog Berita & Hiburan Internasional Terverifikasi**:
  - Menghadirkan siaran berita global berkualitas tinggi: **CNN News 18**, **BBC News International**, **ABC News Live**, **CBS News 24/7**, **NBC News NOW**, **Al Jazeera English**, **DW News English**, **Bloomberg TV+**, **Euronews English**, **France 24 English**, **CNBC International**, serta siaran olahraga dan dokumenter seperti **BBC Earth & Studios**, **Red Bull TV**, **ACC Digital Network**, dan **NASA TV**.
- **Logo Resmi Berlatar Transparan & Header Dinamis**:
  - Setiap saluran dilengkapi logo resmi beresolusi tinggi yang terverifikasi aktif (HTTP 200 OK) dan menyatu natural dengan latar belakang gelap Cineva.
  - Pemutar TV Live secara otomatis menyematkan header HTTP khusus (`Referer` dan `Origin` seperti DensTV dan Detik) guna memastikan kelancaran pemutaran tanpa hambatan pemblokiran CDN atau proteksi tautan.

### 2. Custom UI Player Screen & Anti-Ad Shield untuk Server Non-Direct
- **Kontrol Penuh Cineva Custom UI di Semua Server**:
  - Ketika pengguna beralih ke server selain *Cineva Direct* (seperti VidLink HD, MultiEmbed VIP, VidSrc Ultra, 2Embed Prime, atau SmashyStream), layar pemutar kini tetap menampilkan antarmuka kustom Cineva (*Cineva Custom Cinema Controls*) secara penuh.
  - Mendukung kontrol Play/Pause, lompat mundur/maju 10 detik (*Replay 10s* & *Forward 10s*), linimasa scrubber slider durasi tontonan, tombol navigasi episode berikutnya, serta HUD kecerahan layar dan volume booster.
- **Perlindungan Terhadap Iklan (*Anti-Ad Transparent Touch Shield*)**:
  - Menempatkan lapisan pelindung gestur transparan di atas webview untuk menangkap ketukan dan geseran jari pengguna, sehingga pengguna dapat memunculkan kontrol dan mengatur volume/kecerahan tanpa pernah menyentuh langsung halaman web penyedia.
  - Mencegah terpicunya iklan popup liar, popunder, jendela baru, serta tautan pengalihan ke situs belanja maupun perjudian/kasino online.
- **Sinkronisasi Playback Realtime (`CinevaStreamBridge`)**:
  - Skrip injeksi stream menyinkronkan event video web (`timeupdate`, `durationchange`, `play`, `pause`, `waiting`, `playing`) secara instan ke notifikasi status pemutar Cineva untuk pengalaman menonton yang konsisten dengan pemutar native.

### 3. Redesain Daftar Episode TV Series Bergaya Garis Batas Tipis & Sinopsis Rapi
- **Tampilan Bersih Tanpa Card**:
  - Menghilangkan kontainer kotak *card* tebal berlatar abu-abu pada daftar episode di halaman detail Serial TV (`TvDetailScreen`).
  - Menggantinya dengan pembatas garis tipis minimalis (*subtle divider border* 0.8px) yang elegan, selaras dengan estetika penjelajahan saluran TV Live dan Watchlist.
- **Cuplikan Sinopsis Setiap Episode**:
  - Menampilkan ringkasan cerita (*overview*) pada setiap episode secara rapi di bawah judul dan durasi.
  - Dilengkapi pembatasan teks maksimal 2 baris dan pemotongan otomatis dengan tanda titik-titik (*ellipsis* `"..."`) di bagian akhir kalimat sehingga teks tidak meluber dan tampil profesional.
- **Tombol Aksi Intuitif**:
  - Menyediakan tombol unduhan (*Download Episode Modal*) dan tombol ikon putar melingkar bernuansa *primary orange* yang responsif.

---

## Riwayat Versi Sebelumnya

### Cineva v1.1.0
- **Navigasi Kembali TV Live & Animasi Slide-Up**: Pemulihan instan bottom navigation bar tanpa perlu menekan tombol back dua kali.
- **Kunci Otomatis Orientasi Lanskap Layar Penuh TV Live**: Rotasi instan ke lanskap saat tombol fullscreen ditekan.
- **Penyimpanan Permanen Pengaturan Subtitle**: Penyimpanan persistensi untuk stroke/outline, offset vertikal, dan warna font pada Hive settings.
- **Peralihan Resolusi Mulus (*Seamless Quality Switching*)**: Mempertahankan timestamp saat mengganti kualitas tanpa reset ke detik ke-0.

### Cineva v1.0.9
- **Pemisahan Katalog & Pemutar TV Live**: Katalog saluran terpisah dengan pemutar fullscreen (`LiveTvPlayerScreen`).
- **Perbaikan Unduhan Subtitle**: Penambahan header OpenSubtitles API dan pembersihan UTF-8 BOM pada parser SRT.
- **Notifikasi Pembaruan Dwibahasa**: Notifikasi pembaruan latar belakang berbahasa Indonesia dan Inggris.

### Cineva v1.0.8
- **Pembaruan Lisensi ke GPL-3.0**: Penyelarasan seluruh lisensi proyek menjadi GNU General Public License v3.0.
- **Penyempurnaan Total Unduhan Offline**: Pemutaran loopback HLS langsung (`LocalStreamServer`) dan *token-preserving URL resolution*.

---

## Informasi Versi

- Versi Aplikasi: 1.1.1
- Build: 12
- Target Sistem Operasi: Android 5.0 (API 21) ke atas
