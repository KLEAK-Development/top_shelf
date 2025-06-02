import 'package:shelf/shelf.dart';
import 'package:top_shelf/src/services/accounts/models/account.dart';
import 'package:top_shelf/src/services/accounts/routes/change_password/models/change_password.dart';
import 'package:top_shelf/top_shelf.dart';

Future<Account> handler(Request request, ChangePassword changePassword) async {
  final service = request.get<AccountServiceInterface>();
  final currentAccount = request.get<Account>();

  final updatedAccount = await service.changePassword(
    currentAccount.id,
    changePassword.currentPassword,
    changePassword.newPassword,
  );

  return updatedAccount;
}
