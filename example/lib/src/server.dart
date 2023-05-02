import 'dart:io';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_helpers_example/src/router.dart';

Future<HttpServer> server() {
  return shelf_io.serve(router, InternetAddress.anyIPv4, 8080);
}
