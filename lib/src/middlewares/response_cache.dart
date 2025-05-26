import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:shelf/shelf.dart';

class _CacheEntry {
  final Response response;
  final DateTime expiresAt;

  _CacheEntry(this.response, this.expiresAt);

  bool get isExpired => clock.now().isAfter(expiresAt);
}

/// A [Middleware] to cache responses
Middleware responseCache({
  Duration cacheDuration = const Duration(minutes: 5),
  int maxCacheSize = 100,
  List<String> cacheableMethods = const ['GET', 'HEAD'],
  List<int> cacheableStatusCodes = const [200, 301, 302, 304, 404, 410],
  bool includeQueryParams = true,
  String? cacheKeyPrefix,
  List<String> varyHeaders = const [],
}) {
  final cache = <String, _CacheEntry>{};

  String generateCacheKey(Request request) {
    final buffer = StringBuffer();

    if (cacheKeyPrefix != null) {
      buffer.write('$cacheKeyPrefix:');
    }

    buffer.write('${request.method}:${request.url.path}');

    if (includeQueryParams && request.url.query.isNotEmpty) {
      buffer.write('?${request.url.query}');
    }

    // Include vary headers in cache key for more granular caching
    for (final header in varyHeaders) {
      final value = request.headers[header.toLowerCase()];
      if (value != null) {
        buffer.write(':$header=$value');
      }
    }

    return base64Encode(utf8.encode(buffer.toString()));
  }

  void cleanupExpiredEntries() {
    cache.removeWhere((key, entry) => entry.isExpired);
  }

  void enforceMaxCacheSize() {
    if (cache.length > maxCacheSize) {
      // Remove oldest entries (simple FIFO eviction)
      final keysToRemove =
          cache.keys.take(cache.length - maxCacheSize).toList();
      for (final key in keysToRemove) {
        cache.remove(key);
      }
    }
  }

  return (Handler handler) {
    return (Request request) async {
      // Only cache specified HTTP methods
      if (!cacheableMethods.contains(request.method.toUpperCase())) {
        return handler(request);
      }

      final cacheKey = generateCacheKey(request);

      // Clean up expired entries periodically
      cleanupExpiredEntries();

      // Check if we have a cached response
      final cachedEntry = cache[cacheKey];
      if (cachedEntry != null && !cachedEntry.isExpired) {
        // Return cached response with cache headers
        return cachedEntry.response.change(headers: {
          ...cachedEntry.response.headers,
          HttpHeaders.cacheControlHeader:
              'public, max-age=${cacheDuration.inSeconds}',
          'X-Cache': 'HIT',
          'X-Cache-Key': cacheKey,
        });
      }

      // No valid cache entry, process request
      final response = await handler(request);

      // Only cache responses with cacheable status codes
      if (cacheableStatusCodes.contains(response.statusCode)) {
        // Create cache entry
        final expiresAt = clock.now().add(cacheDuration);

        // Read response body for caching
        final body = await response.readAsString();
        final cachedResponse = Response(
          response.statusCode,
          body: body,
          headers: response.headers,
        );

        cache[cacheKey] = _CacheEntry(cachedResponse, expiresAt);

        // Enforce cache size limit
        enforceMaxCacheSize();

        // Return response with cache headers
        return Response(
          response.statusCode,
          body: body,
          headers: {
            ...response.headers,
            HttpHeaders.cacheControlHeader:
                'public, max-age=${cacheDuration.inSeconds}',
            'X-Cache': 'MISS',
            'X-Cache-Key': cacheKey,
            if (varyHeaders.isNotEmpty)
              HttpHeaders.varyHeader: varyHeaders.join(', '),
          },
        );
      }

      // Return response without caching
      return response.change(headers: {
        ...response.headers,
        'X-Cache': 'BYPASS',
      });
    };
  };
}
