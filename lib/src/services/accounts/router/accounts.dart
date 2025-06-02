import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:top_shelf/src/internal/provider.dart';
import 'package:top_shelf/src/services/accounts/models/default_roles.dart';

import 'package:top_shelf/src/services/accounts/routes/create_account/middleware.dart'
    as create_account;
import 'package:top_shelf/src/services/accounts/routes/create_account/handler.dart'
    as create_account;
import 'package:top_shelf/src/services/accounts/routes/change_password/middleware.dart'
    as change_password;
import 'package:top_shelf/src/services/accounts/routes/change_password/handler.dart'
    as change_password;

Handler accountsModule({List<String> roles = defaultRoles}) {
  return Pipeline()
      .addMiddleware(provide<RolesType>((_) => defaultRoles))
      .addHandler(
        ((Router()
              ..post(
                '/',
                Pipeline()
                    .addMiddleware(create_account.middleware())
                    .addHandler(create_account.handler),
              )
              ..put(
                '/change-password',
                Pipeline()
                    .addMiddleware(change_password.middleware())
                    .addHandler(change_password.handler),
              ))
            .call),
      );
}
