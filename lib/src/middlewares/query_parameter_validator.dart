import 'dart:io';

import 'package:shelf/shelf.dart';

Middleware queryParameterValidator(
    {required bool required,
    required String name,
    required List<String> possibleValues}) {
  return (handler) {
    return (request) async {
      if (required) {
        if (!request.url.queryParameters.containsKey(name) ||
            !possibleValues.contains(request.url.queryParameters[name])) {
          return Response(HttpStatus.badRequest);
        }
      } else {
        if (request.url.queryParameters.containsKey(name) &&
            !possibleValues.contains(request.url.queryParameters[name])) {
          return Response(HttpStatus.badRequest);
        }
      }
      return handler(request);
    };
  };
}
