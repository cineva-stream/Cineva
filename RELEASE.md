# Cineva v1.1.9 - Release Notes 🎬

Pembaruan besar Cineva versi 1.1.9 menghadirkan **Lanjutkan Menonton Cerdas (Seamless Device Hand-Off)** lintas perangkat, fitur **Nonton Bareng Jarak Jauh (Watch Party & Sync Play)** lengkap dengan Live Chat & kontrol Host, **Sinkronisasi Cloud Real-Time Otomatis** untuk akun Google, serta perombakan revolusioner pada subtitle melalui **Cinematic NLP Post-Processing Engine** dan **Normalisasi Alami Singkatan & Akronim Subtitle**.

---

## Ringkasan Fitur Baru & Peningkatan Utama

### 1. Lanjutkan Menonton Cerdas (Seamless Device Hand-Off)
* **Pelacakan Sesi Playback Lintas Perangkat (`DeviceHandoffService` & `DevicePlaybackSession`)**:
  * Cineva kini melacak sesi menonton terakhir secara cerdas di Cloud.
  * Jika pengguna berhenti menonton di satu perangkat (misalnya di Android TV pada menit ke-45), saat membuka Cineva di Smartphone atau Windows Desktop akan muncul kartu kapsul kaca modern (*Floating Glass Capsule*) di bagian atas layar:
    > *"Lanjutkan menonton Interstellar di menit 45:12?"*
  * Dilengkapi tombol aksi *"Lanjutkan"* yang langsung membuka pemutar video pada detik yang tepat dan tombol tutup (*Dismiss*) instan.

### 2. Nonton Bareng Jarak Jauh (Watch Party / Sync Play Engine) dengan Live Chat
* **Kamar Nobar Berbasis Room Code (`WatchPartyService` & `WatchPartyRoom`)**:
  * Pengguna dapat membuat Room Code 8 digit unik (contoh: `CNV-XXXX`) atau bergabung ke ruangan teman untuk menonton film dan serial TV yang sama secara bersamaan dari jarak jauh.
  * **Arsitektur Dual-Engine Cloud Relay**: Didukung integrasi Firebase Realtime Database dan otomatis failover ke zero-config Cloud Relay, menjamin pembuatan room 100% berhasil di semua perangkat (Desktop, Android, Smart TV) dan mode Guest tanpa hambatan perizinan.
* **Integrasi Side Panel Pemutar Video & Cover Media Asli**:
  * Pembuatan dan pencarian room kini hadir dalam Side Panel sisi kanan yang elegan dan responsif—aliran pemutaran video menyusut mulus tanpa jeda (*no freeze/dim*).
  * Menampilkan cover poster asli dan format judul episode serial TV yang rapi: `Season X - Episode Y (Judul Episode)`.
* **Sinkronisasi Playback Presisi (*Play, Pause, & Seek*)**:
  * Seluruh aksi pemutaran video, jeda, maupun pergeseran durasi tersinkronisasi secara *real-time*.
  * Dilengkapi algoritma **Kompensasi Latensi Jaringan (*Clock Skew Compensation*)** sehingga perbedaan koneksi antar pengguna tidak membuat video terputus atau tidak sinkron.
* **Banner Minimalis Gabung Nobar di Beranda (*Home Quick Join Banner*)**:
  * Pengguna yang ingin bergabung tidak perlu lagi mencari judul film atau serial TV secara manual. Cukup menekan banner **"Gabung Nobar"** di layar utama, memasukkan Kode Ruangan (contoh: `CNV-8492`), dan sistem akan secara otomatis melacak media Host serta langsung membuka pemutar video pada judul yang tepat.
* **Preview Pesan Melayang & Badge Pesan Belum Dibaca (*Message Preview & Unread Counter*)**:
  * Balon preview pesan kaca (*Floating Glass Preview*) muncul otomatis di bawah ikon chat saat ada pesan masuk dan menghilang sendiri setelah 5 detik tanpa mengganggu jalannya video.
  * Dilengkapi lencana (*Badge Counter*) angka merah di pojok ikon yang menghitung jumlah pesan belum dibaca secara presisi dan mereset saat panel dibuka.
* **Eliminasi Bug Pesan Duplikat**:
  * Menerapkan deduplikasi ID deterministik di seluruh lapisan (domain model, cloud sync service, dan UI builder) sehingga pesan chat yang baru dikirim tidak pernah lagi muncul ganda.
* **Pengaturan Otoritas Host (*Allow Guest Control*)**:
  * Terdapat panel pengaturan di sisi kanan bagi Host dengan opsi checkbox apakah mengizinkan partner/tamu ikut mengontrol video (Play/Pause/Seek) atau mengunci kontrol video khusus untuk Host saja.
* **Panel Live Chat & Floating Animated Emojis**:
  * Panel percakapan interaktif di sisi kanan pemutar video untuk saling berkirim pesan teks secara langsung saat menonton.
  * Tombol reaksi emoji cepat (❤️, 😂, 😮, 👏, 🔥) yang memunculkan partikel animasi emoji melayang (*Floating Emoji Particles*) di atas layar.
* **Dukungan Guest Mode**:
  * Pengguna yang belum atau tidak ingin masuk ke akun Google tetap dapat membuat dan bergabung ke dalam Watch Party cukup dengan memasukkan nama panggilan (*Display Name*).

### 3. Konsistensi Desain AppBar & Perapian Navigasi
* **Penyelarasan AppBar Seluruh Halaman**:
  * Menyeragamkan tipografi judul menggunakan **Google Fonts Outfit** (bobot 700/800, ukuran proporsional 20–22px, `letterSpacing: -0.3`), ikon kembali yang ergonomis (*rounded*), dan latar transparan bebas artefak elevasi di Watchlist, Unduhan, Profil, Legal, Kalender, dsb.
* **Penyempurnaan AppBar Riwayat Tontonan**:
  * Menghilangkan ikon *chevron left* pada halaman Riwayat Tontonan sesuai kaidah layar tab utama.

### 3. Sinkronisasi Cloud Otomatis Real-Time (Google Account)
* **Sinkronisasi Otomatis Tanpa Perlu Menekan Tombol Sync**:
  * Pengguna yang telah masuk dengan akun Google kini menikmati sinkronisasi riwayat tontonan (*Watch History*), daftar tontonan (*Watchlist*), dan profil secara otomatis di latar belakang (*auto-push debounced* 5 detik).
  * Dilengkapi pendengar jarak jauh (*Realtime Remote Listener*) yang mendeteksi perubahan data dari perangkat lain dan menyinkronkannya ke perangkat lokal secara instan.

### 4. Normalisasi Alami Singkatan & Akronim Subtitle (*Natural Abbreviation & Acronym Normalization*)
* **Perbaikan Cacat Tokenizer Pemisah Titik**:
  * Memperbaiki masalah pemisahan tanda titik pada tokenizer yang sebelumnya merusak singkatan bertitik di tengah kalimat menjadi huruf kecil campur besar yang aneh (seperti `l.A.P.D`, `i.A`, dan `t.O` pada serial seperti *The Rookie*).
  * Seluruh singkatan bertitik kini otomatis dinormalisasi secara utuh menjadi huruf besar bersih: **`L.A.P.D.`**, **`I.A.`**, **`T.O.`**, **`D.A.`**, **`U.S.A.`**, dsb.
* **Dukungan Imbuhan & Klitis Bahasa Indonesia**:
  * Mengakomodasi singkatan berimbuhan secara rapi: **`T.O.-ku`**, **`L.A.P.D.-nya`**, **`I.A.-mu`** (bagian singkatan huruf kapital, imbuhan huruf kecil).
* **Intelligent Sentence Continuation Guard**:
  * Tanda titik di akhir singkatan (misalnya: *"Petugas L.A.P.D. itu sedang bertugas..."*) tidak lagi salah mengkapitalisasi kata sambung atau kata tunjuk berikutnya (`itu`, `ini`, `yang`, `sedang`, `adalah`), namun tetap menjaga huruf kapital jika singkatan benar-benar berada di akhir kalimat.
* **Normalisasi Singkatan Berjarak (*Spaced Abbreviations*)**:
  * Pola singkatan berjarak hasil pemindaian OCR subtitle (seperti `l. a. p. d.` atau `t. o.`) otomatis dirapatkan menjadi **`L.A.P.D.`** dan **`T.O.`**.
* **Perlindungan Kata Asli Bahasa Indonesia**:
  * Kata ganti orang ketiga bahasa Indonesia **`"ia"`** (dia) dan kata **`"doa"`** (berdoa) tetap dipertahankan huruf kecil di tengah kalimat dan tidak diubah paksa menjadi akronim tanpa titik.

### 5. Cinematic NLP Post-Processing Engine untuk Auto-Translate Subtitle
* **Penyempurnaan Subtitle Mesin Menjadi Bahasa Dialog Sinematik**:
  * Menerapkan mesin pemrosesan bahasa alami sinematik di sisi klien (*Client-Side NLP*) yang mengubah terjemahan kaku dan ambigu dari Google GTX menjadi terjemahan dialog percakapan yang hidup dan natural layaknya dikerjakan oleh penerjemah film profesional (*Netflix ID / Lebah Ganteng style*), **tetap 100% gratis, tanpa kuota, dan tanpa API Key**.
* **Pembersihan Idiom Harfiah Bahasa Inggris**:
  * *"Aku punya punggungmu"* $\rightarrow$ **`Aku melindungimu`** (*I got your back*)
  * *"Beri aku istirahat"* $\rightarrow$ **`Yang benar saja`** (*Give me a break*)
  * *"Kepala ke atas!"* $\rightarrow$ **`Awas!`** (*Heads up*)
  * *"Sebut itu sehari"* $\rightarrow$ **`Cukup untuk hari ini`** (*Call it a day*)
  * *"Bukan sepotong kue"* $\rightarrow$ **`Tidak mudah`** (*Not a piece of cake*)
  * *"Berada di kapal yang sama"* $\rightarrow$ **`Senasib`** (*In the same boat*)
  * *"Di bawah cuaca"* $\rightarrow$ **`Kurang enak badan`** (*Under the weather*)
  * *"Tarik kakimu"* $\rightarrow$ **`Hanya bercanda`** (*Pulling your leg*)
  * *"Keluar dari pertanyaan"* $\rightarrow$ **`Mustahil`** (*Out of the question*)
* **Istilah Kriminal, Kepolisian & Aksi (*The Rookie, SWAT, FBI*)**:
  * *"Salin itu"* $\rightarrow$ **`Dimengerti`** (*Copy that*)
  * *"Pegang apimu / Tahan apimu"* $\rightarrow$ **`Tahan tembakan`** (*Hold your fire*)
  * *"Tembakan dilepaskan"* $\rightarrow$ **`Ada tembakan`** (*Shots fired*)
  * *"Tersangka dalam tahanan"* $\rightarrow$ **`Tersangka sudah diamankan`** (*Suspect in custody*)
  * *"Butuh cadangan"* $\rightarrow$ **`Butuh bantuan`** (*Need backup*)
  * *"Dalam perjalanan saya"* $\rightarrow$ **`Aku segera ke sana`** (*On my way*)
  * *"Semua bersih"* $\rightarrow$ **`Area aman`** (*All clear*)
  * *"Adegan kejahatan"* $\rightarrow$ **`TKP`** (*Crime scene*)
  * *"Tiarap di lantai"* $\rightarrow$ **`Tiarap`** (*On the floor*)
* **Penghalusan Frasa Kaku (Conversational Dialogue Smoothing)**:
  * *"Aku tidak berpikir begitu"* $\rightarrow$ **`Kurasa tidak`** (*I don't think so*)
  * *"Aku pikir kita harus..."* $\rightarrow$ **`Kurasa kita harus...`**
  * *"Itu masuk akal"* $\rightarrow$ **`Masuk akal`**
  * *"Itu tidak apa-apa / Tidak apa-apa"* $\rightarrow$ **`Tak apa`**
  * *"Apa yang sedang kau bicarakan?"* $\rightarrow$ **`Kau bicara apa?`**
  * *"Apa yang kau tunggu?"* $\rightarrow$ **`Tunggu apa lagi?`**
  * *"Di sanalah kau berada"* $\rightarrow$ **`Rupanya kau di sana`** (*There you are*)
  * *"Kau dipersilakan"* $\rightarrow$ **`Sama-sama`** (*You're welcome*)
  * *"Jangan khawatir tentang itu"* $\rightarrow$ **`Jangan khawatir`**

---

## Riwayat Versi Sebelumnya

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

* **Versi Aplikasi**: 1.1.9
* **Build**: 20
* **Target Sistem Operasi**: Android 5.0 (API 21) ke atas (Smartphone, Tablet & Android TV / Google TV), Windows 10/11 (64-bit)
* **Daftar Varian File Rilis**:
  * `Cineva_setup_v1.1.9.exe` (Windows Desktop Installer Resmi)
  * `Cineva_v1.1.9-android-tv.apk` (Khusus Android TV & Smart TV - **Rekomendasi TV**)
  * `Cineva_v1.1.9-arm64-v8a.apk` (HP & Tablet Android Modern 64-bit)
  * `Cineva_v1.1.9-armeabi-v7a.apk` (HP & Tablet Android Lawas 32-bit)
  * `Cineva_v1.1.9-x86_64.apk` (Emulator PC & Android x86)
  * `Cineva_v1.1.9.apk` (Universal / Semua CPU, Kompatibel Penuh)
