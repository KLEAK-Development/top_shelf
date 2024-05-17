import 'dart:io';

import 'package:shelf/shelf.dart';

import 'package:top_shelf/src/middlewares/allowed_content_type.dart';
import 'package:top_shelf/src/middlewares/body_validator.dart';
import 'package:top_shelf/src/middlewares/get_body.dart';
import 'package:top_shelf/src/middlewares/parse_body.dart';
import 'package:top_shelf/src/modules/common/middlewares/get_account_if_exist.dart';
import 'package:top_shelf/src/modules/authentication/routes/login/models/login.dart';
import 'package:top_shelf/src/modules/authentication/routes/login/models/login_body.dart';

Middleware middleware() => Pipeline()
    .addMiddleware(allowedContentType([
      ContentType('application', 'json'),
      ContentType('application', 'xml'),
      ContentType('application', 'x-www-form-urlencoded'),
      ContentType('multipart', 'form-data'),
    ]))
    .addMiddleware(
        getBody((body) => LoginBody(body), objectName: 'CreateAccount'))
    .addMiddleware(bodyFieldIsRequired<LoginBody>('email'))
    .addMiddleware(bodyFieldIsType<LoginBody, String>('email'))
    .addMiddleware(bodyFieldIsRequired<LoginBody>('password'))
    .addMiddleware(bodyFieldIsType<LoginBody, String>('password'))
    .addMiddleware(parseBody<Login, LoginBody>())
    .addMiddleware(getAccountIfExist<Login>())
    .middleware;
