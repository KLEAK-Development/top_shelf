import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:top_shelf/top_shelf.dart';

import '../utils.dart';

void main() {
  group('in request', () {
    test('parse cookie and put value inside response', () async {
      final handler = const Pipeline()
          .addMiddleware(cookiesManager())
          .addHandler((request) => Response.ok(
              request.get<CookiesManager>().request.getByName('name')?.value ??
                  'no name'));

      final response = await makeRequest(
        handler,
        method: 'GET',
        body: '',
        headers: {HttpHeaders.cookieHeader: 'name=kleak'},
      );
      expect(response.statusCode, 200);
      final body = await response.readAsString();
      expect(body, 'kleak');
    });

    test('no cookie with this key', () async {
      final handler = const Pipeline()
          .addMiddleware(cookiesManager())
          .addHandler((request) => Response.ok(request
                  .get<CookiesManager>()
                  .request
                  .getByName('username')
                  ?.value ??
              'no name'));

      final response = await makeRequest(
        handler,
        method: 'GET',
        body: '',
        headers: {HttpHeaders.cookieHeader: 'name=kleak'},
      );
      expect(response.statusCode, 200);
      final body = await response.readAsString();
      expect(body, 'no name');
    });

    test('no cookie', () async {
      final handler = const Pipeline()
          .addMiddleware(cookiesManager())
          .addHandler((request) => Response.ok(request
                  .get<CookiesManager>()
                  .request
                  .getByName('username')
                  ?.value ??
              'no name'));

      final response = await makeRequest(
        handler,
        method: 'GET',
        body: '',
      );
      expect(response.statusCode, 200);
      final body = await response.readAsString();
      expect(body, 'no name');
    });
  });

  group('in response', () {
    test('set cookie', () async {
      final cookie = Cookie('name', 'kleak');

      final handler = const Pipeline()
          .addMiddleware(cookiesManager())
          .addHandler((request) {
        final cookieManager = request.get<CookiesManager>();
        cookieManager.add(cookie);
        return Response.ok('');
      });

      final response = await makeRequest(
        handler,
        method: 'GET',
        body: '',
      );
      expect(response.statusCode, 200);
      expect(response.headers[HttpHeaders.setCookieHeader], isNotEmpty);
      expect(response.headers[HttpHeaders.setCookieHeader],
          equals(cookie.toString()));
    });

    test('set cookies', () async {
      final cookies = [
        Cookie('name', 'kleak'),
        Cookie('name', 'kleak'),
        Cookie('name', 'kleak'),
      ];

      final handler = const Pipeline()
          .addMiddleware(cookiesManager())
          .addHandler((request) {
        final cookieManager = request.get<CookiesManager>();
        cookieManager.addAll(cookies);
        return Response.ok('');
      });

      final response = await makeRequest(
        handler,
        method: 'GET',
        body: '',
      );
      expect(response.statusCode, 200);
      expect(response.headers[HttpHeaders.setCookieHeader], isNotEmpty);
      expect(response.headers[HttpHeaders.setCookieHeader],
          equals(cookies.join(',')));
    });
  });
}
