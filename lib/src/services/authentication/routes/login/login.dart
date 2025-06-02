import 'package:shelf/shelf.dart';
import 'package:top_shelf/src/services/authentication/routes/login/models/login.dart';
import 'package:top_shelf/src/services/authentication/models/tokens.dart';
import 'package:top_shelf/top_shelf.dart';

class AccountNotFound {}

Future<Tokens> handler(Request request, Login login) async {
  final service = request.get<AccountServiceInterface>();
  final account = await service.authenticate(login.email, login.password);

  if (account == null) {
    //  TODO(kevin): should we use a more specific error ?
    throw AccountNotFound();
  }

  return service.login(account);
}
