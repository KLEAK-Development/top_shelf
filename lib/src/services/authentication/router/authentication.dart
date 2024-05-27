import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:top_shelf/src/services/authentication/routes/login/middleware.dart'
    as authentication;
import 'package:top_shelf/src/services/authentication/routes/login/handler.dart'
    as authentication;

import 'package:top_shelf/src/services/authentication/routes/refresh/middleware.dart'
    as refresh;
import 'package:top_shelf/src/services/authentication/routes/refresh/handler.dart'
    as refresh;

final authenticationModule = Pipeline().addHandler(
  (Router()
        ..post(
          '/login',
          Pipeline()
              .addMiddleware(authentication.middleware())
              .addHandler(authentication.handler),
        )
        ..post(
          '/refresh',
          Pipeline()
              .addMiddleware(refresh.middleware())
              .addHandler(refresh.handler),
        ))
      .call,
);
