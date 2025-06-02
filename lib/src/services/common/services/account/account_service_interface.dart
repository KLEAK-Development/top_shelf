import 'dart:async';
import 'package:top_shelf/src/services/accounts/models/account.dart';
import 'package:top_shelf/src/services/authentication/models/tokens.dart';
import 'package:top_shelf/src/services/common/repositories/account/account_repository_interface.dart';
import 'package:top_shelf/src/services/common/repositories/crud_repository.dart';
import 'package:top_shelf/src/services/common/services/base_crud_service.dart';

/// Abstract interface for account service operations
/// This allows different implementations of account services for various databases
abstract class AccountServiceInterface implements BaseService<Account, int> {
  /// Gets the underlying repository
  @override
  AccountRepositoryInterface get repository;

  /// Creates a new account with email and password
  Future<Account> createAccount({
    required String email,
    required String password,
    List<String> roles = const ['user'],
  });

  /// Authenticates user with email and password
  /// Returns the account if authentication is successful, null otherwise
  Future<Account?> authenticate(String email, String password);

  /// Generates JWT tokens for an authenticated account
  Future<Tokens> login(Account account);

  /// Refreshes JWT tokens using a valid refresh token
  Future<Tokens> refreshTokens(String refreshToken);

  /// Changes user password after verifying current password
  Future<Account> changePassword(
    int accountId,
    String currentPassword,
    String newPassword,
  );

  /// Adds a role to an account
  Future<Account> addRole(int accountId, String role);

  /// Removes a role from an account
  Future<Account> removeRole(int accountId, String role);

  /// Searches accounts with pagination and filtering
  Future<PagedResult<Account>> searchAccounts({
    String? emailSearch,
    String? roleFilter,
    int limit = 20,
    int offset = 0,
    bool orderByCreationDate = true,
  });

  /// Gets account statistics
  Future<Map<String, dynamic>> getAccountStatistics();

  /// Finds accounts by role
  Future<List<Account>> findAccountsByRole(String role);

  /// Finds accounts created within date range
  Future<List<Account>> findAccountsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
}
