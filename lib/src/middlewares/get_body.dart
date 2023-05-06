import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/src/internal/body.dart';
import 'package:shelf_helpers/src/internal/generate_response.dart';
import 'package:shelf_helpers/src/internal/network_object.dart';
import 'package:shelf_helpers/src/internal/request.dart';
import 'package:shelf_multipart/form_data.dart';
import 'package:xml2json/xml2json.dart';

final _logger = Logger('SHELF_HELPERS');

Middleware getBody<T extends Body>(T Function(dynamic) deserializer,
    {required String objectName}) {
  return (handler) {
    return (request) async {
      try {
        if (!request.headers.containsKey(HttpHeaders.contentTypeHeader)) {
          final body = BadRequest(
            'about:blank',
            'No Content-Type',
            'getBody need a content-type to parse the body accordingly',
            400,
            request.requestedUri.path,
          );
          return generateResponse(request, body);
        }
        final requestContentType =
            ContentType.parse(request.headers[HttpHeaders.contentTypeHeader]!);

        for (final contentType in supportedContentType) {
          if (contentType.primary == requestContentType.primaryType) {
            for (final sub in contentType.subs) {
              if (sub.sub == requestContentType.subType) {
                final content = await sub.getContent(request, objectName);
                final body = deserializer(content);
                return handler(request.set<T>(() => body));
              }
            }
          }
        }

        final body = BadRequest(
          'about:blank',
          'Not allowed Content-Type',
          'getBody middleware does\'t support \'$requestContentType\', allowed content-type are: \'${_allowedContentType.join('\', \'')}\'',
          400,
          request.requestedUri.path,
        );
        return generateResponse(request, body);
      } catch (error, stackTrace) {
        _logger.warning(error);
        _logger.warning(stackTrace);
        return Response.internalServerError();
      }
    };
  };
}

dynamic _getXFormUrlencoded(String content) {
  final entries = content.split('&').map((e) => e.split('=')).map((e) =>
      MapEntry(Uri.decodeComponent(e.first), Uri.decodeComponent(e.last)));
  return Map.fromEntries(entries);
}

dynamic _getJsonContent(String content) => json.decode(content);

dynamic _getXmlContent(String content, String objectName) {
  final transformer = Xml2Json()..parse(content);
  return json.decode(transformer.toParker())[objectName];
}

Future<dynamic> _getMultipartFormData(Request request) async {
  final content = {
    await for (final formData in request.multipartFormData)
      formData.name: await formData.part.readString(),
  };
  return content;
}

class _SubContentType {
  final String sub;
  final Future<dynamic> Function(Request request, String objectName) getContent;

  const _SubContentType(this.sub, this.getContent);
}

class _ContentType {
  final String primary;
  final List<_SubContentType> subs;

  const _ContentType(this.primary, this.subs);
}

final supportedContentType = [
  _ContentType(
    'application',
    [
      _SubContentType(
        'json',
        (request, _) async => _getJsonContent(await request.readAsString()),
      ),
      _SubContentType(
        'xml',
        (request, objectName) async =>
            _getXmlContent(await request.readAsString(), objectName),
      ),
      _SubContentType(
        'x-www-form-urlencoded',
        (request, _) async => _getXFormUrlencoded(await request.readAsString()),
      ),
    ],
  ),
  _ContentType(
    'multipart',
    [
      _SubContentType(
        'form-data',
        (request, _) => _getMultipartFormData(request),
      ),
    ],
  ),
];

final _allowedContentType = [
  for (final contentType in supportedContentType)
    for (final sub in contentType.subs) '${contentType.primary}/${sub.sub}'
];
