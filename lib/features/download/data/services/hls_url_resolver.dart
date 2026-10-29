/// High-reliability URL resolver for HLS playlists, encryption keys, and media segments.
/// Ensures security tokens, expiration timestamps, and CDN query parameters are always
/// preserved across relative and absolute playlist child references (RFC 8216 compliance).
class HlsUrlResolver {
  /// Resolves [relativeOrAbsolute] against [parentUrl].
  /// Preserves query parameters (such as token, expires, h, lang) from [parentUrl]
  /// if [relativeOrAbsolute] does not specify its own query parameters.
  static String resolve(String relativeOrAbsolute, String parentUrl) {
    final cleanChild = relativeOrAbsolute.trim();
    if (cleanChild.isEmpty) return parentUrl;

    final parentUri = Uri.parse(parentUrl);
    Uri resolvedUri;

    if (cleanChild.startsWith('http://') || cleanChild.startsWith('https://')) {
      resolvedUri = Uri.parse(cleanChild);
    } else if (cleanChild.startsWith('/')) {
      if (parentUri.hasScheme && parentUri.hasAuthority) {
        resolvedUri = Uri(
          scheme: parentUri.scheme,
          userInfo: parentUri.userInfo.isNotEmpty ? parentUri.userInfo : null,
          host: parentUri.host,
          port: parentUri.hasPort ? parentUri.port : null,
          path: cleanChild,
        );
      } else {
        resolvedUri = Uri.parse('https://vixsrc.to$cleanChild');
      }
    } else {
      resolvedUri = parentUri.resolve(cleanChild);
    }

    // If resolved URI doesn't have query parameters, but parent had query parameters,
    // inherit them!
    if (resolvedUri.queryParameters.isEmpty && parentUri.queryParameters.isNotEmpty) {
      resolvedUri = resolvedUri.replace(queryParameters: parentUri.queryParameters);
    }

    return resolvedUri.toString();
  }
}

