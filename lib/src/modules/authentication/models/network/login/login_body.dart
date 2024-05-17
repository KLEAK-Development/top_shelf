import 'package:top_shelf/src/internal/body.dart';
import 'package:top_shelf/src/modules/authentication/models/network/login/login.dart';

class LoginBody extends Body<Login> {
  LoginBody(super.data);

  @override
  Login parse() => Login.fromJson(data);
}
