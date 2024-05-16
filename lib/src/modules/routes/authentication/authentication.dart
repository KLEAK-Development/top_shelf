import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:top_shelf/src/modules/routes/authentication/login/middleware.dart'
    as authentication;
import 'package:top_shelf/src/modules/routes/authentication/login/handler.dart'
    as authentication;

final authenticationModule = Pipeline().addHandler(
  (Router()
        ..post(
          '/login',
          Pipeline()
              .addMiddleware(authentication.middleware())
              .addHandler(authentication.handler),
        ))
      .call,
);
