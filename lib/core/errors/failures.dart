/// Error handling: Failure classes for domain layer.
///
/// Each failure type carries a human-readable [message] so the
/// presentation layer can display meaningful error information.
abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

/// Network-related failures (no internet, timeout, etc.)
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Koneksi jaringan bermasalah. Periksa koneksi internet Anda.']);
}

/// Server returned an error status code.
class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure([super.message = 'Server sedang bermasalah. Coba lagi nanti.', this.statusCode]);
}

/// Error parsing or decoding response data.
class ParsingFailure extends Failure {
  const ParsingFailure([super.message = 'Gagal memproses data dari server.']);
}

/// Local storage (Hive/Isar) failures.
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Gagal mengakses data lokal.']);
}

/// Torrent engine or P2P related failures.
class TorrentFailure extends Failure {
  const TorrentFailure([super.message = 'Gagal memulai streaming P2P.']);
}

/// No torrent sources found for the selected content.
class NoSourcesFailure extends Failure {
  const NoSourcesFailure([super.message = 'Tidak ada sumber streaming yang tersedia untuk konten ini.']);
}

/// Subtitle-related failures.
class SubtitleFailure extends Failure {
  const SubtitleFailure([super.message = 'Gagal memuat subtitle.']);
}
