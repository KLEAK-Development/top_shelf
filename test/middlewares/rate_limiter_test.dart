import 'package:clock/clock.dart';
import 'package:shelf/shelf.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';
import 'package:top_shelf/src/middlewares/rate_limiter.dart';

import '../utils.dart';

void main() {
  group('rateLimiter', () {
    test('allows requests below the limit', () async {
      final middleware = rateLimiter(maxRequestsPerDuration: 10);
      final handler = middleware((request) => Response.ok('Hello, world!'));

      final response = await makeRequest(handler, method: 'GET');
      expect(response.statusCode, 200);
    });

    test('rejects requests above the limit', () async {
      fakeAsync((async) async {
        final middleware = rateLimiter(maxRequestsPerDuration: 1);
        final handler = middleware((request) => Response.ok('Hello, world!'));

        // Make 2 requests within 1 second
        final response1 = await makeRequest(handler, method: 'GET');
        expect(response1.statusCode, 200);

        async.elapse(Duration(seconds: 1));

        final response2 = await makeRequest(handler, method: 'GET');
        expect(response2.statusCode, 429);
        expect(response2.headers['retry-after'], ['1']);
      });
    });

    test('resets the limit after the duration', () async {
      fakeAsync((async) async {
        final middleware = rateLimiter(maxRequestsPerDuration: 1);
        final handler = middleware((request) => Response.ok('Hello, world!'));

        // Make 2 requests within 1 second
        final response1 = await makeRequest(handler, method: 'GET');
        expect(response1.statusCode, 200);

        async.elapse(Duration(seconds: 1));

        final response2 = await makeRequest(handler, method: 'GET');
        expect(response2.statusCode, 429);
        expect(response2.headers['retry-after'], ['1']);

        // Wait for the duration to pass
        async.elapse(Duration(minutes: 1));

        final response3 = await makeRequest(handler, method: 'GET');
        expect(response3.statusCode, 200);
      });
    });

    test('tracks requests per client', () async {
      fakeAsync((async) async {
        final middleware = rateLimiter(maxRequestsPerDuration: 1);
        final handler = middleware((request) => Response.ok('Hello, world!'));

        // Make 2 requests from different clients within 1 second
        final response1 = await makeRequest(handler, method: 'GET', headers: {
          'x-forwarded-for': '127.0.0.1',
        });
        expect(response1.statusCode, 200);

        final response2 = await makeRequest(handler, method: 'GET', headers: {
          'x-forwarded-for': '127.0.0.2',
        });
        expect(response2.statusCode, 200);

        async.elapse(Duration(seconds: 1));

        // Make another request from the first client
        final response3 = await makeRequest(handler, method: 'GET', headers: {
          'x-forwarded-for': '127.0.0.1',
        });
        expect(response3.statusCode, 429);
        expect(response3.headers['retry-after'], ['1']);
      });
    });

    test('sets rate limit headers', () async {
      fakeAsync((_) async {
        final middleware = rateLimiter(maxRequestsPerDuration: 1);
        final handler = middleware((request) => Response.ok('Hello, world!'));

        // Make a request
        final response = await makeRequest(handler, method: 'GET');
        expect(response.statusCode, 200);

        expect(response.headers['x-ratelimit-limit'], '1');
        expect(response.headers['x-ratelimit-remaining'], '0');
        final reset = clock
            .now()
            .add(Duration(minutes: 1))
            .millisecondsSinceEpoch
            .toString();
        expect(response.headers['x-ratelimit-reset'], reset);
      });
    });
  });
}
