import 'package:shelf/shelf.dart';
import 'package:top_shelf/src/internal/jwt.dart';
import 'package:top_shelf/src/internal/pbkdf2.dart';
import 'package:top_shelf/src/internal/request.dart';
import 'package:top_shelf/src/modules/middlewares/accounts/get_account_if_exist.dart';
import 'package:top_shelf/src/modules/models/network/account.dart';
import 'package:top_shelf/src/modules/models/network/login/login.dart';
import 'package:top_shelf/src/modules/models/network/token.dart';
import 'package:top_shelf/src/modules/repositories/accounts/abstract.dart';

Future<Token> handler(Request request, Login login) async {
  final accountExist = request.get<AccountExist>();
  if (!accountExist) {
    throw AccountNotFound();
  }

  final account = request.get<Account>();

  final pbkdf2 = Pbkdf2();
  final isValidPassword = pbkdf2.verify(login.password, account.password);

  if (!isValidPassword) {
    //  TODO(kevin): should we use a more specific error ?
    throw AccountNotFound();
  }

  final jwt = JsonWebToken();
  jwt.createPayload(account.id.toString());
  final token = jwt.sign();

  return Token(token);
}
