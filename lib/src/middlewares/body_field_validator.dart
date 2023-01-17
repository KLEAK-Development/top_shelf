import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/src/internal/body.dart';
import 'package:shelf_helpers/src/internal/request.dart';

Middleware bodyFieldValidator<T extends Body>(
    String fieldName, bool Function(Object? value) validator) {
  return (handler) {
    return (request) async {
      final body = request.get<T>();
      if (!validator(body.data[fieldName])) {
        return Response(HttpStatus.badRequest);
      }
      return handler(request);
    };
  };
}
