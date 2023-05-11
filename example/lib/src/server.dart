import 'dart:io';

import 'package:logging/logging.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_helpers_example/src/router.dart';

Future<HttpServer> server(
    {final InternetAddress? address, final int port = 8080}) {
  final notNullableAddress = address ?? InternetAddress.anyIPv4;
  final future = shelf_io.serve(router, notNullableAddress, port);

  var readableAddress = switch (notNullableAddress) {
    InternetAddress(address: var address) when address == '0.0.0.0' =>
      'localhost',
    InternetAddress(address: var address) => address,
  };

  Logger.root.fine('server listening on http://$readableAddress:$port');
  return future;
}
