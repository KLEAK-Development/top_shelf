import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:top_shelf/src/modules/accounts/routes/create_account/middleware.dart'
    as create_account;
import 'package:top_shelf/src/modules/accounts/routes/create_account/handler.dart'
    as create_account;

final accountsModule = Pipeline().addHandler(
  (Router()
        ..post(
          '/',
          Pipeline()
              .addMiddleware(create_account.middleware())
              .addHandler(create_account.handler),
        ))
      .call,
);
