import 'package:top_shelf/src/modules/common/models/has_email.dart';

class Login implements HasEmail {
  @override
  final String email;
  final String password;

  const Login(this.email, this.password);

  factory Login.fromJson(Map<String, dynamic> json) {
    if (json
        case {'email': final String email, 'password': final String password}) {
      return Login(email, password);
    } else {
      throw FormatException('Unexpected JSON');
    }
  }
}
