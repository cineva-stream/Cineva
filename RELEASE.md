# Cineva v1.2.0 - Release Notes 🎬

Pembaruan besar Cineva versi 1.2.0 menghadirkan lompatan besar pada kenyamanan visual, interaktivitas, dan efisiensi performa: notifikasi pesan obrolan bergaya **Dynamic Island**, **Mini Preview & Digital Timecode** presisi tinggi pada timeline video (mendukung geser sentuh di Android dan kursor *hover* di Windows), partikel reaksi melayang **Floating Reactions ala TikTok Live**, sistem keamanan **PIN Ruangan Watch Party**, integrasi tautan langsung **Deep Linking** untuk berbagi ke media sosial, perombakan total **Halaman Info** dengan mosaik poster film dinamis, penyegaran tata letak kartu poster film & serial TV, standardisasi **Lokalisasi Penuh Dua Bahasa (Bilingual ID/EN)**, serta optimalisasi performa yang jauh lebih cepat, responsif, dan hemat daya.

---

## Ringkasan Fitur Baru & Peningkatan Utama (v1.2.0)

### 1. Pratinjau Pesan Obrolan Dynamic Island (*Dynamic Island Chat Message Preview*)
* **Kapsul Notifikasi Melayang yang Elegan**:
  * Saat ada pesan obrolan baru masuk pada sesi Watch Party ketika panel chat sedang ditutup, pratinjau pesan kini ditampilkan dalam bentuk kapsul hitam obsidian bergaya *Dynamic Island* di bagian atas layar pemutar video.
  * Dilengkapi animasi ekspansi halus, avatar atau inisial pengirim, nama pengguna dengan aksen warna, dan teks pesan ringkas.
  * Dirancang tanpa menghalangi pandangan video (*non-intrusive*), otomatis memudar dan menyusut kembali secara mulus setelah beberapa detik.

### 2. Mini Preview & Indikator Waktu Melayang pada Progress Bar (*Seekbar Scrubbing & Hover Preview*)
* **Dukungan Penuh Multi-Platform (Android Mobile/Tablet & Windows Desktop)**:
  * **Windows Desktop**: Kartu mini preview muncul secara otomatis mengikuti posisi kursor *mouse* saat melintasi atau mengarahkan kursor (*hover*) di atas bilah waktu (*progress bar*).
  * **Android (Ponsel & Tablet)**: Kartu mini preview muncul saat jari pengguna menyentuh dan menggeser (*drag/scrub*) penanda durasi video.
* **Fitur & Detail Kartu Mini Preview**:
  * **Rasio Aspek Sinematik 16:9 Glassmorphic**: Kartu mengambang dengan latar kaca gelap berkilau (*dark blur glass*), border tipis modern, dan panah penunjuk (*pointer beak*) yang mengarah tepat ke titik waktu yang dituju.
  * **Format Waktu Presisi Digital**: Menampilkan timecode target berformat `HH:MM:SS` (untuk video berdurasi lebih dari 1 jam) atau `MM:SS`.
  * **Kalkulasi Selisih Waktu Loncat (*Seek Delta Indicator*)**: Menampilkan indikator selisih durasi relatif terhadap posisi pemutaran saat ini (misal: `+05:30` saat maju ke depan, atau `-02:15` saat mundur ke belakang).
  * **Thumbnail Bayangan Vignette & Mini Progress Bar**: Dilengkapi ornamen vignette sinematik dengan ikon film serta progress bar sekunder bergradasi warna di bagian bawah kartu.
  * **Boundary Clamping Otomatis**: Posisi kartu dijaga agar selalu berada di dalam batas layar (*safe-area clamping*), tidak akan pernah terpotong di tepi kiri maupun kanan layar pemutar video.

### 3. Partikel Reaksi Melayang ala TikTok Live (*Floating Streaming Reactions*)
* **Aliran Reaksi Emoji Interaktif Real-Time**:
  * Pengguna dapat mengirim reaksi cepat (❤️, 😂, 😮, 👏, 🔥) saat streaming berlangsung.
  * Partikel emoji beranimasi melayang mengapung ke atas dari sudut kanan bawah layar dengan lintasan gelombang acak (*random sway & floating curves*), variasi rotasi dinamis, dan efek pemudaran (*fade-out*) bertingkat seperti siaran langsung TikTok Live.
  * Tersinkronisasi secara instan ke seluruh peserta di dalam ruangan Watch Party, menciptakan suasana menonton bersama yang meriah dan interaktif.

### 4. Proteksi PIN Opsional untuk Ruangan Watch Party (*Optional Room PIN Protection*)
* **Keamanan & Privasi Sesi Menonton Bersama**:
  * Saat membuat ruangan (*Host Room*), pengguna kini dapat menyalakan toggle **Proteksi PIN** dan menentukan 4 digit PIN numerik keamanan.
  * Tamu (*Guests*) yang ingin bergabung ke ruangan terproteksi wajib memasukkan PIN yang sesuai sebelum diizinkan masuk ke ruang pemutaran.
  * Mencegah akses yang tidak diinginkan dan menjaga kenyamanan nobar privat bersama keluarga atau sahabat.

### 5. Tautan Langsung & Berbagi Ruangan ke Media Sosial (*Watch Party Deep Linking*)
* **Berbagi Sekali Sentuh ke Media Sosial**:
  * Host Watch Party dapat menyalin tautan ruangan atau membagikannya langsung ke aplikasi perpesanan dan media sosial (WhatsApp, Telegram, X/Twitter, Instagram, Facebook, dll.).
* **Integrasi Universal Deep Link via GitHub Pages**:
  * Menggunakan URL resmi `https://cineva-tv.github.io/web/join?room=...` yang ramah pratinjau tautan (*rich link preview*).
  * Saat tautan diklik di perangkat yang telah terpasang Cineva, aplikasi akan langsung terbuka secara otomatis, mengarahkan pengguna ke ruangan yang dimaksud, dan mengisi kode ruangan tanpa perlu mengetik manual.

### 6. Desain Ulang Halaman Info Aplikasi & Mosaik Poster Sinematik (*Redesigned Info Page*)
* **Mosaik Poster Film Tanpa Batas (*Seamless Poster Collage*)**:
  * Halaman Tentang Aplikasi (*About Cineva*) kini dihiasi mosaik poster film beresolusi tinggi dengan efek gradasi gelap elegan (*dark vignette fade*).
* **Detail Aplikasi Komprehensif**:
  * Informasi versi dan build dinormalisasi dengan tepat (`v1.2.0 (Build 21)`).
  * Ringkasan fitur unggulan terorganisir rapi dalam kartu kaca modern, dokumentasi teknologi inti (Flutter, Riverpod, MediaKit/MPV, Torrent Engine), informasi pengembang, dan tautan repositori serta situs resmi.

### 7. Tata Letak Poster Film & Serial TV Lebih Bersih dan Elegan (*Clean Poster & Card Layout*)
* **Estetika Minimalis & Rasio Bioskop Standar**:
  * Penyempurnaan rasio aspek kartu film dan serial TV agar seragam, bebas distorsi, dan nyaman dipandang di berbagai ukuran layar (layar ponsel kecil, tablet, hingga monitor PC ultrawide).
  * Penempatan badge informasi (seperti rating IMDb, tahun rilis, dan indikator resolusi HD/4K) ditata ulang secara rapi dan ergonomis dengan efek *frosted glass* halus tanpa menghalangi gambar poster utama.

### 8. Lokalisasi Penuh Dua Bahasa (*Full Bilingual Localization - ID & EN*)
* **Standardisasi Bahasa Menyeluruh**:
  * Memperbaiki dan melengkapi seluruh string antarmuka ke dalam Bahasa Indonesia dan Bahasa Inggris secara menyeluruh.
  * Tidak ada lagi teks yang terlewat, tercampur, atau gagal diterjemahkan saat berganti bahasa di Pengaturan, Beranda, Halaman Detail, Pemutar Video, Pengaturan Subtitle, Watch Party, hingga Halaman Info dan Syarat Ketentuan / Legalitas.

### 9. Performa Lebih Cepat, Ringan & Efisien (*Faster & More Efficient Performance*)
* **Optimalisasi Mesin Pemutar & Sinkronisasi**:
  * Pengurangan beban *thread* dan penggunaan memori RAM saat memutar video beresolusi tinggi dan *multi-stream*.
  * Efisiensi sinkronisasi status playback pada fitur Watch Party dan Google Cloud Sync, menghasilkan pengalaman menonton yang lebih mulus dengan jeda latensi minimal dan konsumsi daya baterai yang jauh lebih hemat.

### 10. Migrasi Identitas Aplikasi Mandiri (*Application ID Migration*)
* **Peralihan Bersih ke `com.cinevagroup.cinevastream`**:
  * Migrasi nama paket resmi untuk memastikan pembaruan jangka panjang yang stabil.
  * Dilengkapi deteksi cerdas instalasi versi terdahulu disertai aksi penghapusan versi lama secara mudah dan aman.

---

## Riwayat Versi Sebelumnya

### Cineva v1.1.9
* **Lanjutkan Menonton Cerdas (Seamless Device Hand-Off)**: Pelacakan sesi pemutaran lintas perangkat cerdas via Cloud dengan kapsul notifikasi melanjutkan tontonan di detik yang tepat.
* **Nonton Bareng Jarak Jauh (Watch Party & Sync Play Engine)**: Pembuatan ruangan dengan kode 8 digit, dual-engine cloud relay (Firebase & Cloud Relay), integrasi side panel pemutar video, serta sinkronisasi play/pause/seek dengan kompensasi latensi.
* **Live Chat & Pesan Mengambang**: Panel obrolan di samping pemutar video, pratinjau pesan kaca, dan partikel reaksi emoji dasar.
* **Normalisasi Alami Singkatan & Akronim Subtitle**: Perbaikan pemisah titik tokenizer untuk singkatan berjarak/bertitik (`L.A.P.D.`, `T.O.`, `U.S.A.`) dan dukungan imbuhan bahasa Indonesia.
* **Cinematic NLP Post-Processing Engine**: Mesin penerjemah dialog alami lokal untuk mengubah terjemahan kaku menjadi bahasa sinematik khas bioskop secara gratis tanpa kuota API.
* **Sinkronisasi Cloud Real-Time**: Sinkronisasi otomatis tanpa tombol manual untuk Watchlist, Riwayat Tontonan, dan Profil pengguna akun Google.

### Cineva v1.1.8
* **Relayout Responsif Modern**: Grid adaptif dan bilah navigasi samping (*Side Navigation Rail*) untuk Tablet, Windows Desktop & Android TV.
* **Perbaikan Total Navigasi Remote D-Pad Android TV**: Mesin fokus `TvFocusable` baru, eliminasi bug fokus terjebak di pemutar video, serta dukungan D-Pad menyeluruh di Search, Detail, Watchlist, Riwayat, dan Unduhan.
* **Perbaikan Bug Orientasi Layar**: Memperbaiki penguncian paksa ke `portraitUp` saat keluar dari pemutar video di Tablet dan TV.
* **Rilis Fitur Unduhan Offline**: Parser HLS m3u8, dekripsi segmen TS terenkripsi AES-128, perakitan MP4 offline mandiri via `OfflineMp4Builder`, UI progress realtime saat *finalizing*, dan pengelompokan serial TV dengan poster resmi serta dropdown season.
* **Penyempurnaan Pemutar Video & Android PiP**: Urutan kontrol bilah atas yang ergonomis, pemisahan navigasi *Back* bersih dengan aktivasi PiP eksklusif via tombol Home / ikon PiP, serta skala subtitle otomatis 1080p/4K untuk sofa viewing di Windows dan Android TV.

### Cineva v1.1.7
* **Fitur Cadangan & Pemulihan Data Mandiri (Backup & Restore System)**: Ekspor & impor seluruh data aplikasi ke dalam berkas `.cineva` beserta opsi pemulihan langsung di layar awal (*Splash Screen*).
* **Masuk dengan Google & Sinkronisasi Cloud**: Integrasi Google Sign-In & Firebase Realtime Database untuk sinkronisasi multi-perangkat otomatis dan pengisian profil cerdas.
* **Desain Ulang Side Panel Streaming & Subtitle Minimalis**: Panel samping hitam obsidian pada pemutar video dan pengaturan subtitle *real-time* yang ringkas.

---

## Informasi Versi

* **Versi Aplikasi**: 1.2.0
* **Build**: 21
* **Target Sistem Operasi**: Android 5.0 (API 21) ke atas (Smartphone, Tablet & Android TV / Google TV), Windows 10/11 (64-bit)
* **Daftar Varian File Rilis**:
  * `Cineva_setup_v1.2.0.exe` (Windows Desktop Installer Resmi)
  * `Cineva_v1.2.0-android-tv.apk` (Khusus Android TV & Smart TV - **Rekomendasi TV**)
  * `Cineva_v1.2.0-arm64-v8a.apk` (HP & Tablet Android Modern 64-bit)
  * `Cineva_v1.2.0-armeabi-v7a.apk` (HP & Tablet Android Lawas 32-bit)
  * `Cineva_v1.2.0-x86_64.apk` (Emulator PC & Android x86)
  * `Cineva_v1.2.0.apk` (Universal / Semua CPU, Kompatibel Penuh)
