import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'torrent_source_service.dart';

/// Service to detect network connectivity and automatically select the optimal
/// torrent streaming source based on bandwidth and seeder health.
class NetworkQualityService {
  final Connectivity _connectivity = Connectivity();

  /// Checks if current device connection is high-speed (WiFi or Ethernet).
  Future<bool> isHighSpeedConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet)) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[NetworkQualityService] Connectivity check error: $e');
      return true; // Default optimistic
    }
  }

  /// Returns network label for UI (e.g. 'WiFi (Koneksi Cepat)' or 'Data Seluler (Hemat Kuota)').
  Future<String> getNetworkTypeLabel() async {
    final isWifi = await isHighSpeedConnection();
    return isWifi ? 'WiFi (Kecepatan Tinggi)' : 'Data Seluler (Mode Hemat Kuota)';
  }

  /// Automatically selects the best torrent source.
  ///
  /// - WiFi: Prefers 1080p (or 2160p 4K if very high seeds), sorted by seeds.
  /// - Cellular/Other: Prefers 720p or 480p to prevent buffering and conserve mobile data.
  Future<TorrentSource> selectOptimalSource(List<TorrentSource> sources) async {
    if (sources.isEmpty) {
      throw StateError('Daftar sumber kosong');
    }

    final isWifi = await isHighSpeedConnection();

    if (isWifi) {
      // 1. Prefer 1080p with good seeds (>20)
      final p1080 = sources.where((s) => s.quality == '1080p').toList();
      if (p1080.isNotEmpty) {
        p1080.sort((a, b) => b.seeds.compareTo(a.seeds));
        return p1080.first;
      }

      // 2. Or 2160p (4K) if healthy seeds (>50)
      final p4k = sources.where((s) => s.quality == '2160p').toList();
      if (p4k.isNotEmpty && p4k.first.seeds >= 50) {
        p4k.sort((a, b) => b.seeds.compareTo(a.seeds));
        return p4k.first;
      }

      // 3. Fallback to 720p
      final p720 = sources.where((s) => s.quality == '720p').toList();
      if (p720.isNotEmpty) {
        p720.sort((a, b) => b.seeds.compareTo(a.seeds));
        return p720.first;
      }
    } else {
      // Mobile data: prefer 720p or 480p to avoid buffering and high data usage
      final p720 = sources.where((s) => s.quality == '720p').toList();
      if (p720.isNotEmpty) {
        p720.sort((a, b) => b.seeds.compareTo(a.seeds));
        return p720.first;
      }

      final p480 = sources.where((s) => s.quality == '480p').toList();
      if (p480.isNotEmpty) {
        p480.sort((a, b) => b.seeds.compareTo(a.seeds));
        return p480.first;
      }

      final p1080 = sources.where((s) => s.quality == '1080p').toList();
      if (p1080.isNotEmpty) {
        p1080.sort((a, b) => b.seeds.compareTo(a.seeds));
        return p1080.first;
      }
    }

    // Default fallback: source with the highest seeds
    final sorted = List<TorrentSource>.from(sources)
      ..sort((a, b) => b.seeds.compareTo(a.seeds));
    return sorted.first;
  }
}
