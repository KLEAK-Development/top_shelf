import 'package:shelf/shelf.dart';
import 'package:top_shelf/src/internal/request.dart';
import 'package:top_shelf/src/services/accounts/models/account.dart';
import 'package:top_shelf/src/services/common/models/has_email.dart';
import 'package:top_shelf/src/services/common/services/account/account_service_interface.dart';

typedef AccountExist = bool;

Middleware getAccountIfExist<T extends HasEmail>() {
  return (handler) {
    return (request) async {
      final objectWithEmail = request.get<T>();
      final service = request.get<AccountServiceInterface>();

      final account =
          await service.repository.findByEmail(objectWithEmail.email);

      var modifiedRequest = request.set<AccountExist>(() => account != null);
      if (account != null) {
        modifiedRequest = modifiedRequest.set<Account>(() => account);
      }

      return handler(modifiedRequest);
    };
  };
}
