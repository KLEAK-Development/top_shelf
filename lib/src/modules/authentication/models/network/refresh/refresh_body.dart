import 'package:top_shelf/src/internal/body.dart';
import 'package:top_shelf/src/modules/authentication/models/network/login/login.dart';

class RefreshBody extends Body<Login> {
  RefreshBody(super.data);

  @override
  Login parse() => Login.fromJson(data);
}
