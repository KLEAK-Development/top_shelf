import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:top_shelf/src/internal/jwt.dart';
import 'package:top_shelf/src/internal/request.dart';
import 'package:top_shelf/src/middlewares/allowed_content_type.dart';
import 'package:top_shelf/src/middlewares/body_validator.dart';
import 'package:top_shelf/src/middlewares/get_body.dart';
import 'package:top_shelf/src/middlewares/parse_body.dart';
import 'package:top_shelf/src/services/authentication/routes/refresh/models/refresh.dart';
import 'package:top_shelf/src/services/authentication/routes/refresh/models/refresh_body.dart';

Middleware middleware() => Pipeline()
    .addMiddleware(allowedContentType([
      ContentType('application', 'json'),
      ContentType('application', 'xml'),
      ContentType('application', 'x-www-form-urlencoded'),
      ContentType('multipart', 'form-data'),
    ]))
    .addMiddleware(getBody((body) => RefreshBody(body), objectName: 'Refresh'))
    .addMiddleware(bodyFieldIsRequired<RefreshBody>('refresh_token'))
    .addMiddleware(bodyFieldIsType<RefreshBody, String>('refresh_token'))
    .addMiddleware(parseBody<Refresh, RefreshBody>())
    .addMiddleware(_isRefreshTokenValid())
    .middleware;

Middleware _isRefreshTokenValid() {
  return (handler) {
    return (request) async {
      final refresh = request.get<Refresh>();

      final jwt = JsonWebToken.parse(refresh.refreshToken);
      if (!jwt.verify()) {
        return Response.unauthorized('');
      }

      return handler(request.set<JsonWebToken>(() => jwt));
    };
  };
}
