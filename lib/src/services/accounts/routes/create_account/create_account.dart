import 'package:pbkdf2/pbkdf2.dart';
import 'package:shelf/shelf.dart';
import 'package:top_shelf/src/internal/request.dart';
import 'package:top_shelf/src/services/accounts/models/account.dart';
import 'package:top_shelf/src/services/accounts/models/default_roles.dart';
import 'package:top_shelf/src/services/accounts/routes/create_account/models/create_account.dart';
import 'package:top_shelf/src/services/common/pepper_factory.dart';
import 'package:top_shelf/src/services/common/repositories/abstract.dart';

Future<Account> handler(Request request, CreateAccount createAccount) async {
  final accountRepository = request.get<AAccountsRepository>();
  final pbkdf2 = Pbkdf2(pepperFactory: defaultPepperFactory);
  final hashedPassword = pbkdf2.hash(createAccount.password);

  final account = await accountRepository.create(
    createAccount.email,
    hashedPassword,
    request.get<RolesType>(),
  );

  return account;
}
