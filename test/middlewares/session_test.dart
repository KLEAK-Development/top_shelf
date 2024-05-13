import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:top_shelf/top_shelf.dart';

import '../utils.dart';

void main() {
  test('init empty session', () async {
    final handler = const Pipeline()
        .addMiddleware(cookiesManager())
        .addMiddleware(sessionManager())
        .addHandler((request) => Response.ok(''));

    final response = await makeRequest(
      handler,
      method: 'GET',
    );

    expect(response.statusCode, equals(200));
    expect(response.headers[HttpHeaders.setCookieHeader], isNotEmpty);
  });

  test('session set value', () async {
    final handler = const Pipeline()
        .addMiddleware(cookiesManager())
        .addMiddleware(sessionManager())
        .addHandler((request) {
      final session = request.get<Session>();
      final value = (session.data['value'] ?? 0) as int;
      session.data['value'] = value + 1;
      return Response.ok(session.data['value'].toString());
    });

    var response = await makeRequest(
      handler,
      method: 'GET',
    );

    expect(response.statusCode, equals(200));
    expect(response.headers[HttpHeaders.setCookieHeader], isNotEmpty);
    var body = await response.readAsString();
    expect(body, equals('1'));

    response = await makeRequest(
      handler,
      method: 'GET',
      headers: {
        HttpHeaders.cookieHeader: Cookie.fromSetCookieValue(
                response.headers[HttpHeaders.setCookieHeader]!)
            .toString()
      },
    );
    body = await response.readAsString();
    expect(body, equals('2'));
  });

  test('no cookie manager', () async {
    final handler = const Pipeline()
        .addMiddleware(sessionManager())
        .addHandler((request) => Response.ok(''));
    try {
      await makeRequest(
        handler,
        method: 'GET',
      );
    } on StateError catch (e) {
      expect(
          e.message,
          equals(
              'cookieManger middleware should be present to use sessionManager'));
    }
  });
}
