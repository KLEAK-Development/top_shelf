import 'package:top_shelf/src/internal/body.dart';
import 'package:top_shelf/src/services/authentication/routes/login/models/login.dart';

class RefreshBody extends Body<Login> {
  RefreshBody(super.data);

  @override
  Login parse() => Login.fromJson(data);
}
