import 'dart:async';

import 'package:quiver/core.dart';
import 'package:top_shelf/src/modules/accounts/models/account.dart';

abstract class AAccountsRepository {
  FutureOr<Optional<Account>> findAccountByEmail(final String email);
  FutureOr<Account> create(
      final String email, final String password, final List<String> roles);
}

class AccountNotFound implements Exception {}
