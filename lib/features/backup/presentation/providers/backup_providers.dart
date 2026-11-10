import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/google_sync_service.dart';

/// Riverpod provider for Google Cloud Sync state and operations.
final googleSyncProvider =
    StateNotifierProvider<GoogleSyncService, GoogleSyncState>((ref) {
  return GoogleSyncService();
});
