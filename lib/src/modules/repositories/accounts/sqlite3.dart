import 'package:quiver/core.dart';
import 'package:top_shelf/src/modules/models/network/account.dart';
import 'package:top_shelf/src/modules/repositories/accounts/abstract.dart';
import 'package:sqlite3/sqlite3.dart';

class SqliteAccountRepository implements AAccountsRepository {
  final Database database;

  SqliteAccountRepository(this.database);

  @override
  Account create(
      final String email, final String password, final List<String> roles) {
    final results = database.select(
      'INSERT INTO accounts (email, password, creationDate, roles) VALUES (?, ?, ?, ?) RETURNING id, email, password, creationDate, roles',
      [
        email,
        password,
        DateTime.now().toUtc().toIso8601String(),
        roles.join(','),
      ],
    );
    return results.map((e) => Account.fromJson(e)).toList().first;
  }

  @override
  Optional<Account> findAccountByEmail(String email) {
    final results = database.select(
      'SELECT id, email, password, creationDate, roles FROM accounts WHERE email = ?',
      [
        email,
      ],
    );
    return switch (results.isEmpty) {
      true => Optional.absent(),
      false => Optional.of(Account.fromJson(results.first))
    };
  }
}
