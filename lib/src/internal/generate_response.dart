import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/src/internal/response_object.dart';

Response generateResponse(Request request, ResponseObject object,
    {int status = HttpStatus.ok}) {
  if (!request.headers.containsKey(HttpHeaders.acceptHeader) ||
      request.headers[HttpHeaders.acceptHeader] == '*/*') {
    return Response(
      status,
      body: object.toJsonString(),
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
      },
    );
  }
  final acceptResponse =
      ContentType.parse(request.headers[HttpHeaders.acceptHeader]!);
  if (acceptResponse.primaryType == 'application') {
    if (acceptResponse.subType == 'json') {
      return Response(
        status,
        body: object.toJsonString(),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
        },
      );
    } else if (acceptResponse.subType == 'xml') {
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
