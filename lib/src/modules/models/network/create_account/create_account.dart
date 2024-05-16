import 'package:top_shelf/src/modules/models/network/has_email.dart';

class CreateAccount extends HasEmail {
  @override
  final String email;
  final String password;

  const CreateAccount(this.email, this.password);

  factory CreateAccount.fromJson(Map<String, dynamic> json) {
    if (json
        case {'email': final String email, 'password': final String password}) {
      return CreateAccount(email, password);
    } else {
      throw FormatException('Unexpected JSON');
    }
  }
}
