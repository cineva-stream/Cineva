# Reliable Video Downloader in Flutter

Repositori ini berisi panduan dan implementasi untuk melakukan *download* file berukuran besar seperti film dan serial TV tanpa korupsi data (*corruption-free*) menggunakan Flutter dan Dart.

## 🚀 Fitur Utama
* **Background Downloading:** Proses *download* tetap berjalan menggunakan *native service* meskipun aplikasi ditutup oleh pengguna atau dihentikan oleh OS.
* **Resumable Downloads:** Menggunakan mekanisme HTTP Range Requests. Jika koneksi terputus, unduhan akan melanjutkan dari byte terakhir (bukan mengulang dari nol).
* **Cryptographic Integrity Verification:** Validasi file hasil unduhan menggunakan *hash checking* (SHA-256 / MD5) sebelum file dapat diputar oleh pengguna.
* **Low Memory Streaming:** Kalkulasi *hash* menggunakan *stream* data untuk mencegah kendala *Out-of-Memory* (OOM) pada perangkat mobile.

---

## 📦 Dependensi

Tambahkan *library* berikut pada file `pubspec.yaml` Anda:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_downloader: ^1.11.7 # Pastikan gunakan versi stabil terbaru
  path_provider: ^2.1.3
  crypto: ^3.0.3
```

---

## 🔧 Konfigurasi Native Platform

### 1. Android Configuration

1. Buka file `android/app/src/main/AndroidManifest.xml`.
2. Tambahkan izin (*permissions*) berikut di dalam tag `<manifest>`:
   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
   <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
   ```
3. Konfigurasikan `FileProvider` di dalam tag `<application>` untuk mengelola akses penyimpanan internal:
   ```xml
   <provider
       android:name="vn.hunghd.flutterdownloader.DownloadedFileProvider"
       android:authorities="\${applicationId}.flutter_downloader.provider"
       android:exported="false"
       android:grantUriPermissions="true">
       <meta-data
           android:name="android.support.FILE_PROVIDER_PATHS"
           android:resource="@xml/provider_paths"/>
   </provider>
   ```
4. Buat file baru bernama `provider_paths.xml` di direktori `android/app/src/main/res/xml/` dan isi dengan:
   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <paths xmlns:android="http://google.com">
       <external-path name="external" path="." />
       <cache-path name="cache" path="." />
   </paths>
   ```

### 2. iOS Configuration

1. Buka file `ios/Runner/Info.plist`.
2. Aktifkan fitur *Background Modes* dengan menambahkan baris berikut:
   ```xml
   <key>UIBackgroundModes</key>
   <array>
       <string>fetch</string>
       <string>processing</string>
   </array>
   ```
3. Batasi file agar hanya disimpan di dalam *sandbox* aplikasi untuk mencegah auto-clear oleh iOS:
   ```xml
   <key>LSSupportsOpeningDocumentsInPlace</key>
   <false/>
   <key>UISupportsDocumentBrowser</key>
   <false/>
   ```

---

## 🛠️ Alur Implementasi Kode

### 1. Inisialisasi pada `main.dart`
Inisialisasi `flutter_downloader` sebelum aplikasi dijalankan.

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(
    debug: true, // Ubah ke false saat rilis (production)
    ignoreSsl: false
  );
  runApp(const MyApp());
}
```

### 2. Memulai Proses Unduhan (Resumable)
Pastikan server Anda mendukung header `Accept-Ranges: bytes`. Fungsi ini akan menyimpan file di direktori aman yang tidak dapat dihapus otomatis oleh OS.

```dart
import 'dart:io';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';

Future<String?> startMovieDownload(String url, String fileName) async {
  final directory = await getApplicationDocumentsDirectory();
  final savedDir = Directory('\${directory.path}/movies');
  
  if (!await savedDir.exists()) {
    await savedDir.create(recursive: true);
  }

  final taskId = await FlutterDownloader.enqueue(
    url: url,
    savedDir: savedDir.path,
    fileName: fileName,
    showNotification: true, 
    openFileFromNotification: false,
    saveInPublicStorage: false, // Menjaga file tetap aman di dalam sandbox aplikasi
  );

  return taskId;
}
```

### 3. Validasi Anti-Korupsi dengan SHA-256
Setelah unduhan selesai, jalankan fungsi ini untuk mencocokkan *hash* file lokal dengan *hash* asli yang disediakan oleh API backend Anda.

```dart
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

Future<bool> verifyIntegrity(String taskId, String expectedServerHash) async {
  final tasks = await FlutterDownloader.loadTasksWithRawQuery(
    query: "SELECT * FROM task WHERE task_id='\$taskId'"
  );
  
  if (tasks == null || tasks.isEmpty) return false;
  
  final task = tasks.first;
  final localFile = File('task.savedDir/{task.filename}');

  if (!await localFile.exists()) return false;

  // Membaca file menggunakan Stream agar hemat RAM (menghindari crash OOM)
  final stream = localFile.openRead();
  final hash = await sha256.bind(stream).first;
  final localHashString = hash.toString();

  if (localHashString.toLowerCase() == expectedServerHash.toLowerCase()) {
    print("✅ File valid dan tidak korup!");
    return true; 
  } else {
    print("❌ File korup! Menghapus file rusak...");
    await localFile.delete(); 
    return false;
  }
}
```

---

## ⚠️ Aturan Penting (*Best Practices*)
1. **Jangan Gunakan `File.readAsBytes()`:** Perangkat akan langsung kehabisan RAM (*Crash OOM*) saat mencoba membaca video ukuran GB. Gunakan selalu pendekatan `Stream` seperti contoh SHA-256 di atas.
2. **Hindari `getTemporaryDirectory()`:** File yang disimpan di folder *Cache* dapat dihapus sewaktu-waktu oleh sistem operasi saat ruang penyimpanan internal penuh, yang berpotensi merusak file video yang sedang/sudah di-download.
