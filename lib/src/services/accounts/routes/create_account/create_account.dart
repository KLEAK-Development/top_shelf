import 'package:shelf/shelf.dart';
import 'package:top_shelf/src/services/accounts/models/account.dart';
import 'package:top_shelf/src/services/accounts/models/default_roles.dart';
import 'package:top_shelf/src/services/accounts/routes/create_account/models/create_account.dart';
import 'package:top_shelf/top_shelf.dart';

Future<Account> handler(Request request, CreateAccount createAccount) async {
  final service = request.get<AccountServiceInterface>();

  final account = await service.createAccount(
    email: createAccount.email,
    password: createAccount.password,
    roles: request.get<RolesType>(),
  );

  return account;
}
