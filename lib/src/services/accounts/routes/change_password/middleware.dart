import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:top_shelf/src/middlewares/allowed_content_type.dart';
import 'package:top_shelf/src/middlewares/body_validator.dart';
import 'package:top_shelf/src/middlewares/get_body.dart';
import 'package:top_shelf/src/middlewares/parse_body.dart';
import 'package:top_shelf/src/services/accounts/routes/change_password/models/change_password.dart';
import 'package:top_shelf/src/services/accounts/routes/change_password/models/change_password_body.dart';
import 'package:top_shelf/src/services/common/middlewares/auth/jwt_auth.dart';

Middleware middleware({String Function()? secretKeyFactory}) => Pipeline()
    .addMiddleware(
      jwtAuth(secretKeyFactory: secretKeyFactory),
    ) // Authenticate user via JWT
    .addMiddleware(allowedContentType([
      ContentType('application', 'json'),
      ContentType('application', 'xml'),
      ContentType('application', 'x-www-form-urlencoded'),
      ContentType('multipart', 'form-data'),
    ]))
    .addMiddleware(getBody((body) => ChangePasswordBody(body),
        objectName: 'ChangePassword'))
    .addMiddleware(bodyFieldIsRequired<ChangePasswordBody>('currentPassword'))
    .addMiddleware(
        bodyFieldIsType<ChangePasswordBody, String>('currentPassword'))
    .addMiddleware(bodyFieldIsRequired<ChangePasswordBody>('newPassword'))
    .addMiddleware(bodyFieldIsType<ChangePasswordBody, String>('newPassword'))
    .addMiddleware(parseBody<ChangePassword, ChangePasswordBody>())
    .middleware;
