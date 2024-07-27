import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:top_shelf/src/internal/network_object.dart';

/// Allow you to easily generate response based on accept header
/// [object] is the object that will be serialized
/// you can specify the status code by changing [status]
/// [defaultAcceptHeader] is used only if the request doesn't have accept header
Response generateResponse(
  final Request request,
  final NetworkObject object, {
  final int status = HttpStatus.ok,
  final String defaultAcceptHeader = '*/*',
}) {
  final requestAccept =
      request.headers[HttpHeaders.acceptHeader] ?? defaultAcceptHeader;
  final acceptAll = requestAccept.contains('*/*');

  final statusCode = switch (object) {
    BadRequest _ => HttpStatus.badRequest,
    _ => status,
  };

  if (acceptAll) {
    return switch (object) {
      NetworkObjectToJson _ => _jsonResponse(statusCode, object),
      NetworkObjectToXml _ => _xmlResponse(statusCode, object),
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
      return _jsonResponse(statusCode, object);
    } else if (acceptHeader.primaryType == 'application' &&
        acceptHeader.subType == 'xml' &&
        object is NetworkObjectToXml) {
      return _xmlResponse(statusCode, object);
    }
  }

  return Response.badRequest();
}

/// Allow you to easily generate response based on accept header
/// [object] is a list of object that will be serialized
/// you can specify the status code by changing [status]
/// [defaultAcceptHeader] is used only if the request doesn't have accept header
Response generateJsonReponseList(
  final Request request,
  final List<NetworkObjectToJson> objects, {
  final int status = HttpStatus.ok,
  final String defaultAcceptHeader = '*/*',
}) {
  return generateResponse(request, _NetworkObjectsToJsonWrapper(objects),
      status: status, defaultAcceptHeader: defaultAcceptHeader);
}

class _NetworkObjectsToJsonWrapper implements NetworkObjectToJson {
  final List<NetworkObject> objects;

  _NetworkObjectsToJsonWrapper(this.objects);

  @override
  List<dynamic> toJson() => objects
      .cast<NetworkObjectToJson>()
      .map((element) => element.toJson())
      .toList();
}

Response _jsonResponse(int status, NetworkObjectToJson object) {
  final contentType = switch (object) {
    BadRequest _ => 'application/problem+json',
    NetworkObjectToJson _ => 'application/json',
  };

  return Response(
    status,
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

  return Response(
    status,
    body: object.toXml().toXmlString(),
    headers: {
      HttpHeaders.contentTypeHeader: contentType,
    },
  );
}
