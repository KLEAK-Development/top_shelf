import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:top_shelf/src/internal/network_object.dart';

/// Allow you to easily generate response based on accept header
/// [object] is the object that will be serialized
/// you can specify the status code by changing [status]
/// [defaultAcceptHeader] is used only if the request doesn't have accept header
Response generateResponse(final Request request, final NetworkObject object,
    {final int status = HttpStatus.ok,
    final String defaultAcceptHeader = '*/*)'}) {
  final requestAccept =
      request.headers[HttpHeaders.acceptHeader] ?? defaultAcceptHeader;
  final acceptAll = requestAccept.contains('*/*');

  if (acceptAll) {
    return switch (object) {
      NetworkObjectToJson _ => _jsonResponse(status, object),
      NetworkObjectToXml _ => _xmlResponse(status, object),
    };
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
  final contentType = switch (object) {
    BadRequest _ => 'application/problem+json',
    NetworkObjectToJson _ => 'application/json',
  };
  final statusCode = switch (object) {
    BadRequest _ => HttpStatus.badRequest,
    _ => status,
  };

  return Response(
    statusCode,
    body: json.encode(object.toJson()),
    headers: {
      HttpHeaders.contentTypeHeader: contentType,
    },
  );
}

Response _xmlResponse(int status, NetworkObjectToXml object) {
  final contentType = switch (object) {
    BadRequest _ => 'application/problem+xml',
    NetworkObjectToXml _ => 'application/xml',
  };
  final statusCode = switch (object) {
    BadRequest _ => HttpStatus.badRequest,
    _ => status,
  };

  return Response(
    statusCode,
    body: object.toXml().toXmlString(),
    headers: {
      HttpHeaders.contentTypeHeader: contentType,
    },
  );
}
