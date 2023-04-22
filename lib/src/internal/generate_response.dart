import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/src/internal/network_object.dart';

Response generateResponse(final Request request, final NetworkObject object,
    {final int status = HttpStatus.ok,
    final String defaultContentType = 'application/json'}) {
  var acceptHeader = ContentType.parse(
      request.headers[HttpHeaders.acceptHeader] ?? defaultContentType);
  if (request.headers[HttpHeaders.acceptHeader] == '*/*') {
    acceptHeader = ContentType.parse(defaultContentType);
  }
  if (acceptHeader.primaryType == 'application') {
    if (acceptHeader.subType == 'json' && object is JsonNetworkObject) {
      return Response(
        status,
        body: object.toJsonString(),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
        },
      );
    } else if (acceptHeader.subType == 'xml' && object is XmlNetworkObject) {
      return Response(
        status,
        body: object.toXmlString(),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/xml',
        },
      );
    }
  }
  return Response.badRequest();
}
