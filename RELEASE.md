# Cineva v1.1.1 - Release Notes 🎬

Pembaruan Cineva versi 1.1.1 menghadirkan penyempurnaan besar pada mesin *streaming* dengan sinkronisasi langsung ke cluster scraper produksi Flixquest (`scraper.flix.quest`), prioritas penyedia *direct* HLS untuk film bioskop Indonesia dan Asia (`movy`, `moviepire`, `vidup`, `reelix`), pencegahan pemutaran video iklan atau salah judul melalui *Native 404 Overlay*, redesain antarmuka *Side Panel* pemutar video dengan garis batas tipis (*subtle border* tanpa *card* tebal) dan pemisahan *timer auto-hide*, pembersihan kontrol ganda pada layar pemutar, redesain menu Pengaturan Subtitle, penyederhanaan tata letak halaman Pengaturan (*Settings Screen*), peningkatan keandalan unduhan *offline* dengan *multi-provider fallback*, serta katalog TV Live terlengkap dengan laci saluran bergaya YouTube (*smooth animated resizing*) dan perlindungan layar sentuh anti-iklan (*Anti-Ad Touch Shield*).

---

## Ringkasan Perubahan

### 1. Sinkronisasi Cluster Scraper Flixquest & Peningkatan Mesin Pemutar
- **Integrasi Production Scraper Cluster Flixquest (`https://scraper.flix.quest`)**:
  - Memperbarui endpoint scraper ke cluster aktif produksi yang mendukung 17+ upstream scrapers terverifikasi (`movy`, `moviepire`, `vidup`, `reelix`, `cinejoy`, `streamflix`, `showbox`, `asiaflix`, `animekai`, `animeyy`, `animepahe`, `kisskh`, `4khdhub`, `atlantic`, `aethoflix`, `viv`, `aether`).
  - Menambahkan arsitektur **Multi-Instance Failover** (`_getWithFallback`) yang secara otomatis beralih antar-kluster apabila salah satu instance mengalami latensi tinggi atau tidak dapat dijangkau.
- **Prioritas Provider Scraper untuk Film Bioskop Indonesia & Anime/Asia**:
  - Menempatkan provider **`movy`** dan **`moviepire`** di urutan prioritas teratas.
  - Judul film bioskop Indonesia (seperti *Jangan Buang Ibu* [TMDB 1519340]) kini dapat diputar dengan resolusi tinggi (1080p, 720p, 480p, Adaptive) lengkap dengan subtitle resmi Bahasa Indonesia dan Inggris.
  - Judul anime bioskop (seperti *Detective Conan: Fallen Angel of the Highway* [TMDB 1545621]) kini langsung terputar sesuai judul aslinya tanpa kesalahan pemutaran.
  - Memperluas daftar *fallback static providers* (`movy`, `moviepire`, `vidup`, `reelix`, `animekai`, dll.) untuk memastikan pemutaran tetap berjalan mulus meskipun endpoint remote discovery lambat merespons.
- **Pencegahan Pemutaran Video Iklan / Salah Judul & Native 404 Overlay**:
  - Menghilangkan *silent auto-failover* ke webview iklan saat link HLS direct tidak ditemukan.
  - Menerapkan **Native 404 Stream Unavailable Overlay** bertema *Cinema Amber & Deep Obsidian* jika sebuah judul film belum dirilis secara digital di server streaming, dilengkapi tombol "Pilih Server Lain", "Coba Lagi", dan navigasi kembali yang intuitif.
  - Menambahkan detektor domain iklan `SmartStreamService.isAdUrl` dan validasi durasi pada skrip sniffer video guna memblokir video iklan/trailer pendek (< 180 detik) dari server web pihak ketiga.
- **Perbaikan Notifikasi Pembaruan Ganda (*Single-Dispatch Policy*)**:
  - Memperbaiki bug di mana notifikasi pembaruan aplikasi muncul dua kali (notifikasi pertama di background saat aplikasi belum dibuka, dan notifikasi kedua muncul lagi saat aplikasi dibuka).
  - Menerapkan pencatatan versi notifikasi terpadu antara Android native SharedPreferences dan Flutter sehingga notifikasi pembaruan sistem hanya dikirim tepat 1 kali per versi rilis baru dan tidak akan dikirim ulang saat aplikasi dibuka.

### 2. Penyempurnaan Antarmuka Player & Side Panel (Right Panel)
- **Side Panel Flat & Border Minimalis**:
  - Seluruh menu pada panel kanan (Server, Episode, Kualitas, Subtitle, Audio, Kecepatan Putar) dirombak dari kontainer *card* tebal menjadi tata letak datar yang elegan dengan garis batas tipis (*subtle border* 0.8px).
- **Pemisahan Timer Auto-Hide (Kontrol Layar vs Side Panel)**:
  - *Timer auto-hide* 4 detik kini secara ketat hanya menyembunyikan kontrol pemutar pada layar utama (*player screen controls*).
  - Side panel kanan tetap terbuka stabil tanpa tertutup otomatis (*no auto-close*), dan hanya tertutup saat pengguna menutupnya secara manual melalui tombol close atau *back gesture*.
- **Pembersihan Kontrol Ganda pada Layar Pemutar**:
  - Menghilangkan ikon-ikon duplikat pada kontrol pemutar utama (seperti tombol subtitle, audio, dan kualitas) yang telah dipindahkan dan dikelola penuh di side panel kanan.
  - Menghapus opsi *Aspect Ratio* dari side panel kanan karena telah tersedia langsung di samping indikator *progress bar* linimasa pemutar.
- **Redesain Menu Pengaturan Subtitle**:
  - Merapikan menu pengaturan subtitle ("Atur Timing Subtitle" dan "Tampilan" / "Appearance") dengan kontrol slider yang presisi, palet warna font, dan visualisasi pratinjau yang bersih.
- **Lokalisasi Dwibahasa Penuh (ID & EN)**:
  - Memperbaiki ketidakkonsistenan bahasa pada side panel kanan sehingga seluruh menu sepenuhnya mengikuti preferensi bahasa aplikasi aktif (misal: penyederhanaan teks menjadi *"Appearance"* dalam Bahasa Inggris dan *"Tampilan"* dalam Bahasa Indonesia).
- **Perbaikan Rute Navigasi TV Shows di Halaman Beranda**:
  - Memperbaiki bug di mana menekan serial TV pada section *Popular TV Shows* (seperti *Law & Order: Special Victims Unit*) secara keliru diarahkan ke rute film `/movie/:id` sehingga menampilkan film yang salah (contoh: *David (1997)*).
  - Kartu serial TV kini secara ketat diarahkan ke rute `/tv/:id` (*TvDetailScreen*) yang menampilkan daftar musim, episode, dan detail serial TV yang tepat.

### 3. Penyederhanaan & Relayout Halaman Pengaturan (*Settings Screen*)
- **Struktur Antarmuka Profesional & Bersih**:
  - Merestrukturisasi tata letak halaman Pengaturan dengan menyembunyikan elemen menu UI yang tidak esensial bagi pengguna akhir namun tetap menjaga keutuhan seluruh logika fungsional di latar belakang.
  - Mengelompokkan pengaturan preferensi konten, bahasa, pemutar, dan informasi aplikasi secara rapi dan ergonomis.

### 4. Multi-Provider Fallback & CDN Headers untuk Unduhan Offline
- **Ketahanan Unduhan Offline**:
  - Menambahkan mekanisme *multi-provider fallback* pada layanan unduhan sehingga aplikasi secara otomatis mencoba penyedia alternatif jika tautan unduhan utama kedaluwarsa atau terblokir.
  - Menyematkan header CDN kustom yang konsisten untuk memastikan proses pengunduhan film dan serial TV dapat diselesaikan hingga 100% dan dapat ditonton tanpa koneksi internet.

### 5. Penambahan Saluran TV Live Nasional & Internasional Terlengkap & Perbaikan Stabilitas Stream
- **Katalog Saluran Nasional Indonesia Terlengkap & Stabil**:
  - Menambahkan saluran televisi swasta dan nasional utama: **Indosiar HD** (diperbarui dengan stream HLS m3u8 live streaming stabil dan bebas gangguan freeze/stuck 2–5 detik), **Moji HD** (siaran Proliga & Premier League dengan logo resmi), **SCTV HD**, **Trans TV**, **Trans7 HD**, **ANTV HD**, **Metro TV HD**, **Kompas TV HD**, **iNews HD**, **CNN Indonesia**, **CNBC Indonesia**, **BTV Indonesia**, **Jawa Pos TV**, **JTV Surabaya**, **UGTV Gunadarma**, berdampingan dengan **TVRI Nasional**, **TVRI World**, **DAAI TV**, **Garuda TV**, **Indonesiana TV**, **Al-Bahjah TV**, **Ahsan TV**, dan **Ashiil TV**.
- **YouTube-Style Landscape Channel Drawer & Dynamic Resizing**:
  - Saat menonton TV Live dalam mode lanskap layar penuh (*fullscreen*), menekan tombol **"Ganti Saluran"** akan membuka laci pemilihan saluran di sisi kanan layaknya antarmuka YouTube.
  - Pemutar video di sisi kiri secara otomatis dan mulus menyesuaikan lebar serta proporsinya (*smooth animated resizing*) sehingga siaran yang sedang ditonton tidak tertutup sedikit pun oleh panel saluran.
  - Laci saluran di sisi kanan didesain bersih dan minimalis tanpa bentuk *card*, menggunakan garis pembatas tipis (*subtle border* 0.8px), logo saluran transparan, filter chip kategori horizontal ('Semua', 'Indonesia', 'Berita', ..., 'Favorit'), status saluran aktif ("DIPUTAR"), tombol penutup (X), serta integrasi tombol kembali (*hardware back / pop gesture*) yang otomatis menutup laci terlebih dahulu sebelum keluar dari fullscreen.
- **Katalog Berita & Hiburan Internasional Terverifikasi**:
  - Menghadirkan siaran berita global berkualitas tinggi: **CNN News 18**, **BBC News International**, **ABC News Live**, **CBS News 24/7**, **NBC News NOW**, **Al Jazeera English**, **DW News English**, **Bloomberg TV+**, **Euronews English**, **France 24 English**, **CNBC International**, serta siaran olahraga dan dokumenter seperti **BBC Earth & Studios**, **Red Bull TV**, **ACC Digital Network**, dan **NASA TV**.
- **Logo Resmi Berlatar Transparan & Header Dinamis**:
  - Setiap saluran dilengkapi logo resmi beresolusi tinggi yang terverifikasi aktif (HTTP 200 OK) dan menyatu natural dengan latar belakang gelap Cineva.
  - Pemutar TV Live secara otomatis menyematkan header HTTP khusus (`Referer` dan `Origin` seperti DensTV dan Detik) guna memastikan kelancaran pemutaran tanpa hambatan pemblokiran CDN atau proteksi tautan.

### 6. Custom UI Player Screen & Anti-Ad Shield untuk Server Non-Direct
- **Kontrol Penuh Cineva Custom UI di Semua Server**:
  - Ketika pengguna beralih ke server selain *Cineva Direct* (seperti VidLink HD, MultiEmbed VIP, VidSrc Ultra, 2Embed Prime, atau SmashyStream), layar pemutar kini tetap menampilkan antarmuka kustom Cineva (*Cineva Custom Cinema Controls*) secara penuh.
  - Mendukung kontrol Play/Pause, lompat mundur/maju 10 detik (*Replay 10s* & *Forward 10s*), linimasa scrubber slider durasi tontonan, tombol navigasi episode berikutnya, serta HUD kecerahan layar dan volume booster.
- **Perlindungan Terhadap Iklan (*Anti-Ad Transparent Touch Shield*)**:
  - Menempatkan lapisan pelindung gestur transparan di atas webview untuk menangkap ketukan dan geseran jari pengguna, sehingga pengguna dapat memunculkan kontrol dan mengatur volume/kecerahan tanpa pernah menyentuh langsung halaman web penyedia.
  - Mencegah terpicunya iklan popup liar, popunder, jendela baru, serta tautan pengalihan ke situs belanja maupun perjudian/kasino online.
- **Sinkronisasi Playback Realtime (`CinevaStreamBridge`)**:
  - Skrip injeksi stream menyinkronkan event video web (`timeupdate`, `durationchange`, `play`, `pause`, `waiting`, `playing`) secara instan ke notifikasi status pemutar Cineva untuk pengalaman menonton yang konsisten dengan pemutar native.

### 7. Redesain Daftar Episode TV Series Bergaya Garis Batas Tipis & Sinopsis Rapi
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
