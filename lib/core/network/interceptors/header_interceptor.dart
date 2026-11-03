import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Interceptor that attaches standard HTTP headers (Accept, Accept-Encoding, User-Agent)
/// to outgoing network requests when not explicitly overridden.
class HeaderInterceptor extends Interceptor {
  final String? customUserAgent;

  HeaderInterceptor({this.customUserAgent});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    void addIfMissing(String name, String value) {
      if (!options.headers.keys.any((k) => k.toLowerCase() == name.toLowerCase())) {
        options.headers[name] = value;
      }
    }

    addIfMissing('Accept', 'application/json, text/plain, */*');
    addIfMissing('Accept-Encoding', 'gzip, deflate');
    addIfMissing(
      'User-Agent',
      customUserAgent ??
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Cineva/${defaultTargetPlatform.name}',
    );

    handler.next(options);
  }
}

