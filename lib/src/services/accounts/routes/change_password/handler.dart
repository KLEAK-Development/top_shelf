import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:top_shelf/src/services/accounts/routes/change_password/models/change_password.dart';
import 'package:top_shelf/src/services/accounts/routes/change_password/change_password.dart'
    as change_password;
import 'package:top_shelf/top_shelf.dart';

Future<Response> handler(Request request) async {
  try {
    final object = await change_password.handler(
      request,
      request.get<ChangePassword>(),
    );
    return generateResponse(request, object, status: HttpStatus.ok);
  } on ServiceValidationException catch (_) {
    // TODO: we need better validation error
    return Response.badRequest();
  }
}
