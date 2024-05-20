import 'package:shelf/shelf.dart';
import 'package:top_shelf/src/internal/pbkdf2.dart';
import 'package:top_shelf/src/internal/request.dart';
import 'package:top_shelf/src/modules/accounts/models/account.dart';
import 'package:top_shelf/src/modules/accounts/routes/create_account/models/create_account.dart';
import 'package:top_shelf/src/modules/common/repositories/abstract.dart';

Future<Account> handler(Request request, CreateAccount createAccount) async {
  final accountRepository = request.get<AAccountsRepository>();
  final pbkdf2 = Pbkdf2();
  final hashedPassword = pbkdf2.hash(createAccount.password);

  final account = await accountRepository.create(
    createAccount.email,
    hashedPassword,
    ['user'],
  );

  return account;
}
