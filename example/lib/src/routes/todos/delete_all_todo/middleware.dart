import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/shelf_helpers.dart';
import 'package:shelf_helpers_example/src/models/network/identifiable.dart';

final _credential = 'your:credential';

Future<(bool, Identifiable)> basicAuth(
    Request request, String authorization) async {
  final credential =
      await Future.delayed(Duration(seconds: 1), () => _credential);
  final authorized = authorization == base64.encode(utf8.encode(credential));
  return (authorized, Identifiable(_credential));
}

(bool, Identifiable) bearerAuth(Request request, String token) {
  return (token == '123', Identifiable('123'));
}

(bool, Identifiable) apiKeyAuth(Request request, String value) {
  return (value == 'GOOGLE', Identifiable('GOOGLE'));
}

(bool, Identifiable?) customAuth(Request request) {
  return (false, null);
}

Middleware middleware() => Pipeline()
    .addMiddleware(
      auth(
        BasicAuth(basicAuth) | BearerAuth(bearerAuth) | ApiKeyAuth(apiKeyAuth),
      ),
    )
    .middleware;
