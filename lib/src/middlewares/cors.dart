import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:top_shelf/src/internal/http_method.dart';

/// A [Middleware] to add CORS
Middleware cors({
  String accessControlAllowOrigin = '*',
  List<String> accessControlAllowMethod = const ['*'],
  List<String> accessControlAllowHeaders = const ['*'],
  int accessControlMaxAge = 86400,
}) {
  return (handler) {
    return (request) async {
      final headers = {
        HttpHeaders.accessControlAllowOriginHeader: accessControlAllowOrigin,
        HttpHeaders.accessControlAllowMethodsHeader:
            accessControlAllowMethod.join(','),
        HttpHeaders.accessControlAllowHeadersHeader:
            accessControlAllowHeaders.join(','),
        HttpHeaders.accessControlMaxAgeHeader: '$accessControlMaxAge',
      };
      if (request.method == HttpMethod.options.name.toUpperCase()) {
        return Response(
          HttpStatus.noContent,
          headers: headers,
        );
      }
      final response = await handler(request);
      return response.change(headers: {...response.headers, ...headers});
    };
  };
}
