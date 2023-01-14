import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/src/internal/body.dart';

Middleware contentTypeValidator<T extends Body>(
    List<ContentType> supportedContentType) {
  return (Handler handler) {
    return (Request request) async {
      if (request.headers.containsKey(HttpHeaders.contentTypeHeader)) {
        final contentType =
            ContentType.parse(request.headers[HttpHeaders.contentTypeHeader]!);
        final isSupported =
            supportedContentType.fold(false, (previousValue, element) {
          if (previousValue) {
            return previousValue;
          }
          return element.primaryType == contentType.primaryType &&
              element.subType == contentType.subType;
        });
        if (!isSupported) {
          return Response(HttpStatus.badRequest);
        }
      }
      return handler(request);
    };
  };
}
