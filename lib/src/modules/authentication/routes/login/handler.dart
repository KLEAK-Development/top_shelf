import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:top_shelf/src/internal/generate_response.dart';
import 'package:top_shelf/src/internal/request.dart';
import 'package:top_shelf/src/modules/authentication/routes/login/models/login.dart';
import 'package:top_shelf/src/modules/authentication/routes/login/login.dart'
    as login;
import 'package:top_shelf/src/modules/common/repositories/abstract.dart';

Future<Response> handler(Request request) async {
  try {
    final object = await login.handler(
      request,
      request.get<Login>(),
    );
    return generateResponse(request, object);
  } on AccountNotFound catch (_) {
    return Response(HttpStatus.notFound);
  }
}
