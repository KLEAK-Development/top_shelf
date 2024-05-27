import 'package:shelf/shelf.dart';
import 'package:top_shelf/src/internal/request.dart';
import 'package:top_shelf/src/services/accounts/models/account.dart';
import 'package:top_shelf/src/services/common/models/has_email.dart';
import 'package:top_shelf/src/services/common/repositories/abstract.dart';

typedef AccountExist = bool;

Middleware getAccountIfExist<T extends HasEmail>() {
  return (handler) {
    return (request) async {
      final objectWithEmail = request.get<T>();
      final repository = request.get<AAccountsRepository>();

      final optionalAccount =
          await repository.findAccountByEmail(objectWithEmail.email);

      var modifiedRequest =
          request.set<AccountExist>(() => optionalAccount.isPresent);
      if (optionalAccount.isPresent) {
        modifiedRequest =
            modifiedRequest.set<Account>(() => optionalAccount.value);
      }

      return handler(modifiedRequest);
    };
  };
}
