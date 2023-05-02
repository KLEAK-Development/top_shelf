import 'package:shelf/shelf.dart';

Future<Response> makeRequest(
  Handler handler, {
  required String method,
  String url = 'http://localhost/',
  String? body,
  Map<String, String>? headers,
}) =>
    Future.sync(
      () => handler(
        Request(
          method,
          Uri.parse(url),
          body: body,
          headers: headers,
        ),
      ),
    );
