/// Custom exceptions thrown by data layer.
class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException([this.message = 'Server error occurred', this.statusCode]);

  @override
  String toString() => 'ServerException($statusCode): $message';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'No internet connection']);

  @override
  String toString() => 'NetworkException: $message';
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Cache error occurred']);

  @override
  String toString() => 'CacheException: $message';
}

class TorrentException implements Exception {
  final String message;
  const TorrentException([this.message = 'Torrent engine error']);

  @override
  String toString() => 'TorrentException: $message';
}
