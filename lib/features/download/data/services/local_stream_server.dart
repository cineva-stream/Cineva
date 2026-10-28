import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Lightweight embedded HTTP server running on 127.0.0.1 (loopback).
/// Solves local HLS playback in libmpv/media_kit by providing an HTTP socket
/// stream with network jitter buffering, packet queues, and seamless A/V sync
/// without requiring any internet connection (100% offline).
class LocalStreamServer {
  static LocalStreamServer? _instance;
  static LocalStreamServer get instance => _instance ??= LocalStreamServer._();

  LocalStreamServer._();

  HttpServer? _server;
  int get port => _server?.port ?? 0;
  bool get isRunning => _server != null;

  final Map<String, String> _idToDirMap = {};

  /// Starts the embedded loopback HTTP server on a random free port.
  Future<int> start() async {
    if (_server != null) return _server!.port;

    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      debugPrint('[LocalStreamServer] Started offline stream server on port: ${_server!.port}');

      _server!.listen(
        _handleRequest,
        onError: (e) {
          debugPrint('[LocalStreamServer] Server error: $e');
        },
      );
      return _server!.port;
    } catch (e) {
      debugPrint('[LocalStreamServer] Failed to bind local server: $e');
      return 0;
    }
  }

  /// Registers an offline item's storage directory with a unique ID.
  void registerDirectory(String id, String dirPath) {
    _idToDirMap[id] = dirPath;
  }

  /// Returns the loopback HTTP URL for an offline HLS playlist or media file.
  String getStreamUrl({
    required String dirPath,
    required String fileName,
    String? id,
  }) {
    // Generate clean alphanumeric ID ensuring no empty segments or invalid URI characters
    final cleanId = (id != null && id.trim().isNotEmpty)
        ? id.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
        : 'stream_${dirPath.hashCode.abs()}';

    registerDirectory(cleanId, dirPath);
    final p = port;
    return 'http://127.0.0.1:$p/stream/$cleanId/$fileName';
  }

  /// Request handler serving HLS playlists and media segments from disk.
  Future<void> _handleRequest(HttpRequest request) async {
    final response = request.response;
    response.headers.set('access-control-allow-origin', '*');
    response.headers.set('access-control-allow-methods', 'GET, HEAD, OPTIONS');
    response.headers.set('access-control-allow-headers', '*');
    response.headers.set('connection', 'keep-alive');
    response.headers.set('cache-control', 'no-cache');

    if (request.method == 'OPTIONS') {
      response.statusCode = HttpStatus.ok;
      await response.close();
      return;
    }

    final cleanSegments = request.uri.pathSegments.where((s) => s.isNotEmpty).toList();

    // Route: /stream/{id}/{fileName...}
    if (cleanSegments.length >= 3 && cleanSegments[0] == 'stream') {
      final id = cleanSegments[1];
      final relativeFileName = cleanSegments.sublist(2).join('/');
      final dirPath = _idToDirMap[id];

      if (dirPath != null) {
        final file = File('$dirPath/$relativeFileName');
        if (await file.exists()) {
          await _serveFile(request, response, file, relativeFileName);
          return;
        } else {
          debugPrint('[LocalStreamServer] File not found: ${file.path}');
        }
      } else {
        debugPrint('[LocalStreamServer] ID not mapped: $id');
      }
    }

    // Defensive fallback 1: Search registered directories for the requested file
    if (cleanSegments.isNotEmpty) {
      final targetName = cleanSegments.last;
      for (final dirPath in _idToDirMap.values) {
        final candidate = File('$dirPath/$targetName');
        if (await candidate.exists()) {
          await _serveFile(request, response, candidate, targetName);
          return;
        }
      }
    }

    // Defensive fallback 2: Direct path query /file?path=...
    final rawPath = request.uri.queryParameters['path'];
    if (rawPath != null) {
      final file = File(rawPath);
      if (await file.exists()) {
        await _serveFile(request, response, file, file.path);
        return;
      }
    }

    debugPrint('[LocalStreamServer] 404 Not Found: ${request.uri}');
    response.statusCode = HttpStatus.notFound;
    response.write('Not Found');
    await response.close();
  }

  Future<void> _serveFile(
    HttpRequest request,
    HttpResponse response,
    File file,
    String fileName,
  ) async {
    try {
      final ext = fileName.split('.').last.toLowerCase();
      switch (ext) {
        case 'cineva':
        case 'm3u8':
          response.headers.contentType = ContentType('application', 'vnd.apple.mpegurl', charset: 'utf-8');
          break;
        case 'cdat':
        case 'ts':
          response.headers.contentType = ContentType('video', 'mp2t');
          break;
        case 'mp4':
          response.headers.contentType = ContentType('video', 'mp4');
          break;
        case 'mkv':
          response.headers.contentType = ContentType('video', 'x-matroska');
          break;
        case 'srt':
          response.headers.contentType = ContentType('text', 'plain', charset: 'utf-8');
          break;
        case 'vtt':
          response.headers.contentType = ContentType('text', 'vtt', charset: 'utf-8');
          break;
        default:
          response.headers.contentType = ContentType('application', 'octet-stream');
      }

      final fileSize = await file.length();
      response.headers.set('accept-ranges', 'bytes');

      // Range request support for seeking
      final rangeHeader = request.headers.value('range');
      if (rangeHeader != null && rangeHeader.startsWith('bytes=')) {
        final parts = rangeHeader.substring(6).split('-');
        final start = int.tryParse(parts[0]) ?? 0;
        final end = parts.length > 1 && parts[1].isNotEmpty
            ? int.tryParse(parts[1]) ?? (fileSize - 1)
            : fileSize - 1;

        if (start < fileSize && end < fileSize && start <= end) {
          final length = end - start + 1;
          response.statusCode = HttpStatus.partialContent;
          response.headers.set('content-range', 'bytes $start-$end/$fileSize');
          response.contentLength = length;
          if (request.method != 'HEAD') {
            await response.addStream(file.openRead(start, end + 1));
          }
          await response.close();
          return;
        }
      }

      response.statusCode = HttpStatus.ok;
      response.contentLength = fileSize;
      if (request.method != 'HEAD') {
        await response.addStream(file.openRead());
      }
      await response.close();
    } catch (e) {
      try {
        response.statusCode = HttpStatus.internalServerError;
        await response.close();
      } catch (_) {}
    }
  }

  /// Stops the loopback server.
  Future<void> stop() async {
    try {
      await _server?.close(force: true);
    } catch (_) {}
    _server = null;
    _idToDirMap.clear();
  }
}
