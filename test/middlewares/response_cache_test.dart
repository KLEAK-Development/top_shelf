import 'package:shelf/shelf.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';
import 'package:top_shelf/src/middlewares/response_cache.dart';

import '../utils.dart';

void main() {
  group('responseCache', () {
    test('caches GET requests by default', () async {
      final middleware = responseCache(cacheDuration: Duration(minutes: 5));
      var callCount = 0;
      final handler = middleware((request) {
        callCount++;
        return Response.ok('Response $callCount');
      });

      final response1 = await makeRequest(handler, method: 'GET');
      expect(response1.statusCode, 200);
      expect(await response1.readAsString(), 'Response 1');
      expect(response1.headers['x-cache'], 'MISS');

      final response2 = await makeRequest(handler, method: 'GET');
      expect(response2.statusCode, 200);
      expect(await response2.readAsString(), 'Response 1');
      expect(response2.headers['x-cache'], 'HIT');
      expect(callCount, 1); // Handler should only be called once
    });

    test('does not cache POST requests by default', () async {
      final middleware = responseCache();
      var callCount = 0;
      final handler = middleware((request) {
        callCount++;
        return Response.ok('Response $callCount');
      });

      final response1 = await makeRequest(handler, method: 'POST');
      expect(response1.statusCode, 200);
      expect(await response1.readAsString(), 'Response 1');
      expect(response1.headers.containsKey('x-cache'), false);

      final response2 = await makeRequest(handler, method: 'POST');
      expect(response2.statusCode, 200);
      expect(await response2.readAsString(), 'Response 2');
      expect(callCount, 2); // Handler should be called twice
    });

    test('respects cacheable methods configuration', () async {
      final middleware = responseCache(
        cacheableMethods: ['POST', 'PUT'],
      );
      var callCount = 0;
      final handler = middleware((request) {
        callCount++;
        return Response.ok('Response $callCount');
      });

      final response1 = await makeRequest(handler, method: 'POST');
      expect(response1.statusCode, 200);
      expect(response1.headers['x-cache'], 'MISS');

      final response2 = await makeRequest(handler, method: 'POST');
      expect(response2.statusCode, 200);
      expect(response2.headers['x-cache'], 'HIT');
      expect(callCount, 1);
    });

    test('only caches specified status codes', () async {
      final middleware = responseCache(
        cacheableStatusCodes: [200],
      );
      var callCount = 0;
      final handler = middleware((request) {
        callCount++;
        if (request.url.path.contains('error')) {
          return Response.internalServerError(body: 'Error $callCount');
        }
        return Response.ok('Success $callCount');
      });

      // Test 500 response - should not be cached
      final response1 = await makeRequest(handler,
          method: 'GET', url: 'http://localhost/error');
      expect(response1.statusCode, 500);
      expect(response1.headers['x-cache'], 'BYPASS');

      final response2 = await makeRequest(handler,
          method: 'GET', url: 'http://localhost/error');
      expect(response2.statusCode, 500);
      expect(await response2.readAsString(), 'Error 2');
      expect(callCount, 2);

      // Test 200 response - should be cached
      final response3 = await makeRequest(handler,
          method: 'GET', url: 'http://localhost/success');
      expect(response3.statusCode, 200);
      expect(response3.headers['x-cache'], 'MISS');

      final response4 = await makeRequest(handler,
          method: 'GET', url: 'http://localhost/success');
      expect(response4.statusCode, 200);
      expect(response4.headers['x-cache'], 'HIT');
      expect(callCount, 3);
    });

    test('expires cache after specified duration', () async {
      fakeAsync((async) async {
        final middleware = responseCache(cacheDuration: Duration(minutes: 1));
        var callCount = 0;
        final handler = middleware((request) {
          callCount++;
          return Response.ok('Response $callCount');
        });

        final response1 = await makeRequest(handler, method: 'GET');
        expect(response1.headers['x-cache'], 'MISS');
        expect(callCount, 1);

        final response2 = await makeRequest(handler, method: 'GET');
        expect(response2.headers['x-cache'], 'HIT');
        expect(callCount, 1);

        // Advance time past cache expiration
        async.elapse(Duration(minutes: 2));

        final response3 = await makeRequest(handler, method: 'GET');
        expect(response3.headers['x-cache'], 'MISS');
        expect(callCount, 2);
      });
    });

    test('includes query parameters in cache key by default', () async {
      final middleware = responseCache();
      var callCount = 0;
      final handler = middleware((request) {
        callCount++;
        return Response.ok('Response for ${request.url.query}');
      });

      final response1 = await makeRequest(handler,
          method: 'GET', url: 'http://localhost/?param=1');
      expect(response1.headers['x-cache'], 'MISS');

      final response2 = await makeRequest(handler,
          method: 'GET', url: 'http://localhost/?param=2');
      expect(response2.headers['x-cache'], 'MISS');
      expect(callCount, 2); // Different cache entries

      final response3 = await makeRequest(handler,
          method: 'GET', url: 'http://localhost/?param=1');
      expect(response3.headers['x-cache'], 'HIT');
      expect(callCount, 2); // Same cache entry as first request
    });

    test('can exclude query parameters from cache key', () async {
      final middleware = responseCache(includeQueryParams: false);
      var callCount = 0;
      final handler = middleware((request) {
        callCount++;
        return Response.ok('Response $callCount');
      });

      final response1 = await makeRequest(handler,
          method: 'GET', url: 'http://localhost/?param=1');
      expect(response1.headers['x-cache'], 'MISS');

      final response2 = await makeRequest(handler,
          method: 'GET', url: 'http://localhost/?param=2');
      expect(response2.headers['x-cache'], 'HIT');
      expect(callCount, 1); // Same cache entry despite different query params
    });

    test('includes vary headers in cache key', () async {
      final middleware = responseCache(varyHeaders: ['Accept-Language']);
      var callCount = 0;
      final handler = middleware((request) {
        callCount++;
        return Response.ok('Response $callCount');
      });

      final response1 = await makeRequest(
        handler,
        method: 'GET',
        headers: {'Accept-Language': 'en-US'},
      );
      expect(response1.headers['x-cache'], 'MISS');

      final response2 = await makeRequest(
        handler,
        method: 'GET',
        headers: {'Accept-Language': 'es-ES'},
      );
      expect(response2.headers['x-cache'], 'MISS');
      expect(callCount, 2); // Different cache entries

      final response3 = await makeRequest(
        handler,
        method: 'GET',
        headers: {'Accept-Language': 'en-US'},
      );
      expect(response3.headers['x-cache'], 'HIT');
      expect(callCount, 2); // Same cache entry as first request
    });

    test('enforces max cache size', () async {
      final middleware = responseCache(maxCacheSize: 2);
      var callCount = 0;
      final handler = middleware((request) {
        callCount++;
        return Response.ok('Response for ${request.url.path}');
      });

      // Fill cache to capacity
      await makeRequest(handler, method: 'GET', url: 'http://localhost/path1');
      await makeRequest(handler, method: 'GET', url: 'http://localhost/path2');
      expect(callCount, 2);

      // Verify cache hits
      final response1 = await makeRequest(handler,
          method: 'GET', url: 'http://localhost/path1');
      expect(response1.headers['x-cache'], 'HIT');
      expect(callCount, 2);

      // Add third entry, should evict first entry
      await makeRequest(handler, method: 'GET', url: 'http://localhost/path3');
      expect(callCount, 3);

      // First entry should be evicted, causing cache miss
      final response2 = await makeRequest(handler,
          method: 'GET', url: 'http://localhost/path1');
      expect(response2.headers['x-cache'], 'MISS');
      expect(callCount, 4);
    });

    test('adds cache control headers', () async {
      final middleware = responseCache(cacheDuration: Duration(seconds: 300));
      final handler = middleware((request) => Response.ok('Hello'));

      final response = await makeRequest(handler, method: 'GET');
      expect(response.headers['cache-control'], 'public, max-age=300');
    });

    test('adds vary header when vary headers are specified', () async {
      final middleware = responseCache(
        varyHeaders: ['Accept-Language', 'User-Agent'],
      );
      final handler = middleware((request) => Response.ok('Hello'));

      final response = await makeRequest(handler, method: 'GET');
      expect(response.headers['vary'], 'Accept-Language, User-Agent');
    });

    test('includes cache key prefix in cache key', () async {
      final middleware1 = responseCache(cacheKeyPrefix: 'v1');
      final middleware2 = responseCache(cacheKeyPrefix: 'v2');

      var callCount1 = 0;
      var callCount2 = 0;

      final handler1 = middleware1((request) {
        callCount1++;
        return Response.ok('V1 Response');
      });

      final handler2 = middleware2((request) {
        callCount2++;
        return Response.ok('V2 Response');
      });

      // Same path but different prefixes should create separate cache entries
      await makeRequest(handler1, method: 'GET');
      await makeRequest(handler2, method: 'GET');

      expect(callCount1, 1);
      expect(callCount2, 1);

      // Second requests should hit cache
      final response1 = await makeRequest(handler1, method: 'GET');
      final response2 = await makeRequest(handler2, method: 'GET');

      expect(response1.headers['x-cache'], 'HIT');
      expect(response2.headers['x-cache'], 'HIT');
      expect(callCount1, 1);
      expect(callCount2, 1);
    });

    test('provides cache key in response headers', () async {
      final middleware = responseCache();
      final handler = middleware((request) => Response.ok('Hello'));

      final response = await makeRequest(handler, method: 'GET');
      expect(response.headers['x-cache-key'], isNotNull);
      expect(response.headers['x-cache-key'], isNotEmpty);
    });
  });
}
