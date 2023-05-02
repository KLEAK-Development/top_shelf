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
  return Response(
    status,
    body: object.toJsonString(),
    headers: {
      HttpHeaders.contentTypeHeader: 'application/json',
    },
  );
}

Response _xmlResponse(int status, NetworkObjectToXml object) {
  return Response(
    status,
    body: object.toXmlString(),
    headers: {
      HttpHeaders.contentTypeHeader: 'application/xml',
    },
  );
}
