import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/src/internal/body.dart';
import 'package:shelf_helpers/src/internal/request.dart';
import 'package:xml2json/xml2json.dart';

Middleware getBody<T extends Body>(T Function(dynamic) deserializer,
    {required String objectName}) {
  return (handler) {
    return (request) async {
      try {
        if (!request.headers.containsKey(HttpHeaders.contentTypeHeader)) {
          return Response.badRequest();
        }
        final requestContentType =
            ContentType.parse(request.headers[HttpHeaders.contentTypeHeader]!);
        dynamic /* List<dynamic> | Map<String, dynamic> */ content;
        if (requestContentType.primaryType == 'application') {
          if (requestContentType.subType == 'json') {
            content = getJsonContent(await request.readAsString());
          } else if (requestContentType.subType == 'xml') {
            content = getXmlContent(await request.readAsString(), objectName);
          } else if (requestContentType.subType == 'x-www-form-urlencoded') {
            content = getFormUrlencoded(await request.readAsString());
          } else {
            return Response.badRequest();
          }
        } else {
          return Response.badRequest();
        }
        final body = deserializer(content);
        return handler(request.set<T>(() => body));
      } catch (_) {
        return Response.internalServerError();
      }
    };
  };
}

dynamic getFormUrlencoded(String content) => Map.fromEntries(content
    .split('&')
    .map((e) => e.split('='))
    .map((e) => MapEntry(e.first, num.tryParse(e.last) ?? e.last)));

dynamic getJsonContent(String content) => json.decode(content);

dynamic getXmlContent(String content, String objectName) {
  final transformer = Xml2Json()..parse(content);
  return json.decode(transformer.toParker())[objectName];
}
