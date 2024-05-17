import 'package:top_shelf/src/internal/body.dart';
import 'package:top_shelf/src/modules/accounts/models/create_account/create_account.dart';

class CreateAccountBody extends Body<CreateAccount> {
  CreateAccountBody(super.data);

  @override
  CreateAccount parse() => CreateAccount.fromJson(data);
}
