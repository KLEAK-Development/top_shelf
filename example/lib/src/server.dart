import 'dart:io';

import 'package:logging/logging.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:top_shelf_example/src/router.dart';

Future<HttpServer> server(
    {final InternetAddress? address, final int port = 8080}) {
  final notNullableAddress = address ?? InternetAddress.anyIPv4;
  final readableAddress = switch (notNullableAddress) {
    InternetAddress(address: final address) when address == '0.0.0.0' =>
      'localhost',
    InternetAddress(address: final address) => address,
  };

  final future = shelf_io.serve(router, notNullableAddress, port);

  Logger.root.fine('server listening on http://$readableAddress:$port');
  return future;
}
