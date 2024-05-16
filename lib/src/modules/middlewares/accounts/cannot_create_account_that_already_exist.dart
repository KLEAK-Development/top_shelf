import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:top_shelf/src/modules/middlewares/accounts/get_account_if_exist.dart';
import 'package:top_shelf/top_shelf.dart';

Middleware cannotCreateAccountThatAlreadyExist() {
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
