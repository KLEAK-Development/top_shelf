import 'package:pbkdf2/pbkdf2.dart';
import 'package:shelf/shelf.dart';
import 'package:top_shelf/src/internal/jwt.dart';
import 'package:top_shelf/src/internal/request.dart';
import 'package:top_shelf/src/services/common/middlewares/get_account_if_exist.dart';
import 'package:top_shelf/src/services/accounts/models/account.dart';
import 'package:top_shelf/src/services/authentication/routes/login/models/login.dart';
import 'package:top_shelf/src/services/authentication/models/tokens.dart';
import 'package:top_shelf/src/services/common/pepper_factory.dart';
import 'package:top_shelf/src/services/common/repositories/abstract.dart';

Future<Tokens> handler(Request request, Login login) async {
  final accountExist = request.get<AccountExist>();
  if (!accountExist) {
    throw AccountNotFound();
  }

  final account = request.get<Account>();

  final pbkdf2 = Pbkdf2(pepperFactory: defaultPepperFactory);
  final isValidPassword = pbkdf2.verify(login.password, account.password);

  if (!isValidPassword) {
    //  TODO(kevin): should we use a more specific error ?
    throw AccountNotFound();
  }

  var jwt = JsonWebToken();
  jwt.createPayload(account.id.toString());
  final accessToken = jwt.sign();

  jwt = JsonWebToken();
  jwt.createPayload(account.id.toString(), expireIn: Duration(days: 30));
  final resfreshToken = jwt.sign();

  return Tokens(accessToken, resfreshToken);
}
