import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/src/internal/http_method.dart';

/// A [Middleware] to add CORS to you endpoints
Middleware cors({
  String accessControlAllowOrigin = '*',
  List<String> accessControlAllowMethod = const ['*'],
  List<String> accessControlAllowHeaders = const ['*'],
  int accessControlMaxAge = 86400,
}) {
  return (Handler handler) {
    return (Request request) async {
      final headers = {
        HttpHeaders.accessControlAllowOriginHeader: accessControlAllowOrigin,
        HttpHeaders.accessControlAllowMethodsHeader:
            accessControlAllowMethod.join(','),
        HttpHeaders.accessControlAllowHeadersHeader:
            accessControlAllowHeaders.join(','),
        HttpHeaders.accessControlMaxAgeHeader: accessControlMaxAge,
      };
      if (request.method == HttpMethod.options.name.toUpperCase()) {
        return Response(
          HttpStatus.noContent,
          headers: headers,
        );
      }
      return handler(request);
    };
  };
}
