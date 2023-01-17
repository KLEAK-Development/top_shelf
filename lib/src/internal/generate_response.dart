import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/src/internal/network_object.dart';

Response generateResponse(Request request, NetworkObject object,
    {int status = HttpStatus.ok,
    String defaultContentType = 'application/json'}) {
  var acceptHeader = ContentType.parse(
      request.headers[HttpHeaders.acceptHeader] ?? defaultContentType);
  if (request.headers[HttpHeaders.acceptHeader] == '*/*') {
    acceptHeader = ContentType.parse(defaultContentType);
  }
  if (acceptHeader.primaryType == 'application') {
    if (acceptHeader.subType == 'json') {
      return Response(
        status,
        body: object.toJsonString(),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
        },
      );
    } else if (acceptHeader.subType == 'xml') {
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
