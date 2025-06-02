import 'package:test/test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:top_shelf/src/services/common/repositories/account/account_repository_factory.dart';

import 'shared_account_service_tests.dart';

void main() {
  group('SQLite Account Repository Integration Tests', () {
    late Database database;

    // Run all shared integration tests
    runAccountIntegrationTests(
      () async {
        database = sqlite3.openInMemory();
        database.execute('''
          CREATE TABLE accounts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL,
            creationDate TEXT NOT NULL,
            roles TEXT NOT NULL DEFAULT 'user'
          )
        ''');
        return AccountRepositoryFactory.createSqliteRepository(database);
      },
      () async {
        database.dispose();
      },
    );
  });
}
