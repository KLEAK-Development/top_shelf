import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:top_shelf/src/internal/request.dart';
import 'package:top_shelf/src/middlewares/allowed_content_type.dart';
import 'package:top_shelf/src/middlewares/body_validator.dart';
import 'package:top_shelf/src/middlewares/get_body.dart';
import 'package:top_shelf/src/middlewares/parse_body.dart';
import 'package:top_shelf/src/modules/common/middlewares/get_account_if_exist.dart';
import 'package:top_shelf/src/modules/accounts/models/create_account/create_account.dart';
import 'package:top_shelf/src/modules/accounts/models/create_account/create_account_body.dart';

Middleware middleware() => Pipeline()
    .addMiddleware(allowedContentType([
      ContentType('application', 'json'),
      ContentType('application', 'xml'),
      ContentType('application', 'x-www-form-urlencoded'),
      ContentType('multipart', 'form-data'),
    ]))
    .addMiddleware(
        getBody((body) => CreateAccountBody(body), objectName: 'CreateAccount'))
    .addMiddleware(bodyFieldIsRequired<CreateAccountBody>('email'))
    .addMiddleware(bodyFieldIsType<CreateAccountBody, String>('email'))
    .addMiddleware(bodyFieldIsRequired<CreateAccountBody>('password'))
    .addMiddleware(bodyFieldIsType<CreateAccountBody, String>('password'))
    .addMiddleware(parseBody<CreateAccount, CreateAccountBody>())
    .addMiddleware(getAccountIfExist<CreateAccount>())
    .addMiddleware(_cannotCreateAccountThatAlreadyExist())
    .middleware;

Middleware _cannotCreateAccountThatAlreadyExist() {
  return (handler) {
    return (request) async {
      final accountExist = request.get<AccountExist>();

      if (accountExist) {
        return Response(HttpStatus.conflict);
      }

      return handler(request);
    };
  };
}
