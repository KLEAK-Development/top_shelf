import 'package:top_shelf/src/internal/body.dart';
import 'package:top_shelf/src/services/accounts/routes/change_password/models/change_password.dart';

class ChangePasswordBody extends Body<ChangePassword> {
  ChangePasswordBody(super.data);

  @override
  ChangePassword parse() => ChangePassword.fromJson(data);
}
