import 'package:shelf/shelf.dart';
import 'package:top_shelf/src/internal/pbkdf2.dart';
import 'package:top_shelf/src/internal/request.dart';
import 'package:top_shelf/src/modules/models/network/account.dart';
import 'package:top_shelf/src/modules/models/network/create_account/create_account.dart';
import 'package:top_shelf/src/modules/repositories/accounts/abstract.dart';

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
