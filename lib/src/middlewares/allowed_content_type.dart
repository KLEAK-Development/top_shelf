import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/src/internal/body.dart';
import 'package:shelf_helpers/src/internal/generate_response.dart';
import 'package:shelf_helpers/src/internal/network_object.dart';

/// [allowedContentType] check if the content-type in the request is part of
/// the [supportedContentType] that your endpoint support
/// else return [BadRequest]
Middleware allowedContentType<T extends Body>(
    List<ContentType> supportedContentType) {
  return (handler) {
    return (request) async {
      if (request.headers.containsKey(HttpHeaders.contentTypeHeader)) {
        final contentType =
            ContentType.parse(request.headers[HttpHeaders.contentTypeHeader]!);
        final isSupported =
            supportedContentType.fold(false, (previousValue, element) {
          return previousValue ||
              element.primaryType == contentType.primaryType &&
                  element.subType == contentType.subType;
        });
        if (!isSupported) {
          final body = BadRequest(
            'about:blank',
            'Not supported content-type',
            '${request.method} ${request.requestedUri.path} doesn\'t support content-type ${contentType.toString()}, supported content-type are: ${supportedContentType.join(', ')}',
            400,
            request.requestedUri.path,
          );
          return generateResponse(request, body);
        }
      }
      return handler(request);
    };
  };
}
