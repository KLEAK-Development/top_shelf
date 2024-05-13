import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:top_shelf/src/internal/request.dart';

Middleware cookiesManager() {
  return (handler) {
    return (request) async {
      final cookiesManager = CookiesManager.init(request);

      final response =
          await handler(request.set<CookiesManager>(() => cookiesManager));

      return response.change(headers: {
        ...response.headers,
        HttpHeaders.setCookieHeader:
            cookiesManager._response.it.map((e) => '$e').toList(),
      });
    };
  };
}

class CookiesManager {
  final RequestCookies _request;
  final ResponseCookies _response;

  CookiesManager.init(Request request)
      : _request = RequestCookies.parse(request),
        _response = ResponseCookies([]);

  RequestCookies get request => _request;

  void add(Cookie cookie) => _response.add(cookie);

  void addAll(List<Cookie> cookies) => _response.addAll(cookies);
}

class RequestCookies {
  late final List<Cookie> _cookies;

  RequestCookies.parse(Request request) {
    final cookieHeader = request.headers[HttpHeaders.cookieHeader];
    _cookies = _parseCookies(cookieHeader);
  }

  Cookie? getByName(String name) {
    try {
      return _cookies.firstWhere((element) => element.name == name);
    } on StateError catch (_) {
      return null;
    }
  }

  List<Cookie> _parseCookies(String? header) {
    if (header == null || header.isEmpty) {
      return [];
    }

    const cookieAttributes = [
      'Domain',
      'Expires',
      'HttpOnly',
      'Max-Age',
      'Path',
      'Secure',
    ];

    return header
        .split('; ')
        .map((e) {
          final data = e.split('=');
          return (data.first, data.last);
        })
        .where((element) => !cookieAttributes.contains(element.$1))
        .map((e) {
          return Cookie(e.$1, e.$2);
        })
        .whereType<Cookie>()
        .toList();
  }
}

extension type ResponseCookies(List<Cookie> it) {
  void add(Cookie cookie) => it.add(cookie);

  void addAll(List<Cookie> cookies) => it.addAll(cookies);
}
