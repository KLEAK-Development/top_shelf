import 'dart:io';

import 'package:shelf/shelf.dart';

class _HttpConnectionInfo implements HttpConnectionInfo {
  @override
  final int localPort = 0;
  @override
  final int remotePort = 0;
  @override
  final InternetAddress remoteAddress;

  _HttpConnectionInfo(this.remoteAddress);
}

Future<Response> makeRequest(
  Handler handler, {
  required String method,
  String url = 'http://localhost/',
  String? body,
  Map<String, String>? headers,
}) =>
    Future(
      () => handler(
        Request(
          method,
          Uri.parse(url),
          body: body,
          headers: headers,
        ).change(
          context: {
            'shelf.io.connection_info':
                _HttpConnectionInfo(InternetAddress('123.123.123.123')),
          },
        ),
      ),
    );
