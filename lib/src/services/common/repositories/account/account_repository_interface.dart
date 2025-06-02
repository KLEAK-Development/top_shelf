import 'dart:async';
import 'package:top_shelf/src/services/accounts/models/account.dart';
import 'package:top_shelf/src/services/common/repositories/crud_repository.dart';

/// Abstract interface for account repository operations
/// This allows the AccountService to work with different database implementations
abstract class AccountRepositoryInterface
    implements CrudRepository<Account, int> {
  /// Creates a new account with hashed password and default roles
  Future<Account> createAccountWithDefaults(
    String email,
    String hashedPassword, {
    List<String> roles = const ['user'],
  });

  /// Finds an account by email address
  Future<Account?> findByEmail(String email);

  /// Finds accounts by role using LIKE pattern
  Future<List<Account>> findByRole(String role);

  /// Finds accounts created within a date range
  Future<List<Account>> findByDateRange(DateTime startDate, DateTime endDate);

  /// Updates account password
  Future<Account> updatePassword(int accountId, String newHashedPassword);

  /// Adds a role to an account
  Future<Account> addRole(int accountId, String role);

  /// Removes a role from an account
  Future<Account> removeRole(int accountId, String role);

  /// Checks if email is already taken
  Future<bool> isEmailTaken(String email);

  /// Searches accounts with pagination and filtering
  Future<PagedResult<Account>> searchAccounts({
    String? emailSearch,
    String? roleFilter,
    int limit = 20,
    int offset = 0,
    bool orderByCreationDate = true,
  });

  /// Gets account statistics
  Future<Map<String, dynamic>> getAccountStats();
}
