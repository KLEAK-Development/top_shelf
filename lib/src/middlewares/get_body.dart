import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/src/internal/body.dart';
import 'package:shelf_helpers/src/internal/request.dart';
import 'package:xml2json/xml2json.dart';

Middleware getBody<T extends Body>(
    T Function(Map<String, dynamic>) deserializer,
    {required String objectName}) {
  return (Handler handler) {
    return (Request request) async {
      try {
        if (!request.headers.containsKey(HttpHeaders.contentTypeHeader)) {
          return Response.badRequest();
        }
        final requestContentType =
            ContentType.parse(request.headers[HttpHeaders.contentTypeHeader]!);
        dynamic /* List<dynamic> | Map<String, dynamic> */ content;
        if (requestContentType.primaryType == 'application') {
          if (requestContentType.subType == 'json') {
            content = json.decode(getJsonContent(await request.readAsString()));
          } else if (requestContentType.subType == 'xml') {
            content = getXmlContent(await request.readAsString(), objectName);
          } else {
            return Response(HttpStatus.badRequest);
          }
        } else {
          return Response(HttpStatus.badRequest);
        }
        final body = deserializer(content);
        return handler(request.set<T>(() => body));
      } catch (_) {
        return Response.internalServerError();
      }
    };
  };
}

dynamic getJsonContent(String content) => json.decode(content);

dynamic getXmlContent(String content, String objectName) {
  final transformer = Xml2Json()..parse(content);
  return json.decode(transformer.toParker())[objectName];
}
