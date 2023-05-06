import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/src/internal/network_object.dart';

Response generateResponse(final Request request, final NetworkObject object,
    {final int status = HttpStatus.ok,
    final String defaultAcceptHeader = '*/*)'}) {
  final requestAccept =
      request.headers[HttpHeaders.acceptHeader] ?? defaultAcceptHeader;
  final acceptAll = requestAccept.contains('*/*');

  if (acceptAll) {
    if (object is NetworkObjectToJson) {
      return _jsonResponse(status, object);
    } else if (object is NetworkObjectToXml) {
      return _xmlResponse(status, object);
    }
  }

  final splitRequestAccept = requestAccept.split(';');
  final filteredAccept =
      splitRequestAccept.where((element) => !element.contains('=')).toList();
  final acceptableHeader =
      filteredAccept.map((e) => ContentType.parse(e)).toList();

  for (final acceptHeader in acceptableHeader) {
    if (acceptHeader.primaryType == 'application' &&
        acceptHeader.subType == 'json' &&
        object is NetworkObjectToJson) {
      return _jsonResponse(status, object);
    } else if (acceptHeader.primaryType == 'application' &&
        acceptHeader.subType == 'xml' &&
        object is NetworkObjectToXml) {
      return _xmlResponse(status, object);
    }
  }

  return Response.badRequest();
}

Response _jsonResponse(int status, NetworkObjectToJson object) {
  final contentType =
      object is BadRequest ? 'application/problem+json' : 'application/json';

  return Response(
    object is BadRequest ? HttpStatus.badRequest : status,
    body: object.toJsonString(),
    headers: {
      HttpHeaders.contentTypeHeader: contentType,
    },
  );
}

Response _xmlResponse(int status, NetworkObjectToXml object) {
  final contentType =
      object is BadRequest ? 'application/problem+xml' : 'application/xml';

  return Response(
    object is BadRequest ? HttpStatus.badRequest : status,
    body: object.toXmlString(),
    headers: {
      HttpHeaders.contentTypeHeader: contentType,
    },
  );
}
