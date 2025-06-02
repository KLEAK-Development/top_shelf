import 'package:sqlite3/sqlite3.dart';
import 'package:top_shelf/src/services/common/repositories/account/account_repository_interface.dart';
import 'package:top_shelf/src/services/common/repositories/account/account_sqlite_repository.dart';
import 'package:top_shelf/src/services/common/repositories/account/account_memory_repository.dart';

/// Factory for creating account repository instances
class AccountRepositoryFactory {
  /// Creates an account repository for SQLite database
  static AccountRepositoryInterface createSqliteRepository(Database database) {
    return AccountSqliteRepository(database);
  }

  /// Creates an in-memory account repository
  /// Useful for testing and development scenarios
  static AccountRepositoryInterface createMemoryRepository() {
    return AccountMemoryRepository();
  }
}
