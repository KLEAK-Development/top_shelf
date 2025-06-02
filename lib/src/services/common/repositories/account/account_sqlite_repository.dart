import 'dart:async';

import 'package:top_shelf/src/services/accounts/models/account.dart';
import 'package:top_shelf/src/services/common/repositories/account/account_repository_interface.dart';
import 'package:top_shelf/src/services/common/repositories/crud_repository.dart';
import 'package:top_shelf/src/services/common/repositories/sqlite_crud_repository.dart';

class AccountSqliteRepository extends SqliteCrudRepository<Account, int>
    implements AccountRepositoryInterface {
  AccountSqliteRepository(super.database);

  @override
  Account fromMap(Map<String, dynamic> map) {
    return Account.fromJson(map);
  }

  @override
  Map<String, dynamic> toMap(Account entity) {
    return {
      'id': entity.id,
      'email': entity.email,
      'password': entity.password,
      'creationDate': entity.creationDate.toUtc().toIso8601String(),
      'roles': entity.roles.join(','),
    };
  }

  @override
  String get createSql =>
      'INSERT INTO accounts (email, password, creationDate, roles) VALUES (?, ?, ?, ?) RETURNING id, email, password, creationDate, roles';

  @override
  String get findByIdSql =>
      'SELECT id, email, password, creationDate, roles FROM accounts WHERE id = ?';

  @override
  String get findAllSql =>
      'SELECT id, email, password, creationDate, roles FROM accounts';

  @override
  String get countSql => 'SELECT COUNT(*) as count FROM accounts';

  @override
  String get updateByIdSql =>
      'UPDATE accounts SET email = ?, password = ?, creationDate = ?, roles = ? WHERE id = ? RETURNING id, email, password, creationDate, roles';

  @override
  String get deleteByIdSql => 'DELETE FROM accounts WHERE id = ?';

  @override
  List<dynamic> getInsertValues(Account entity) {
    return [
      entity.email,
      entity.password,
      entity.creationDate.toUtc().toIso8601String(),
      entity.roles.join(','),
    ];
  }

  @override
  List<dynamic> getUpdateValues(Account entity) {
    return [
      entity.email,
      entity.password,
      entity.creationDate.toUtc().toIso8601String(),
      entity.roles.join(','),
      entity.id,
    ];
  }

  @override
  Future<List<Account>> findWithParams(QueryParams params) async {
    // Handle specific query patterns with hardcoded SQL
    if (params.filters.length == 1) {
      final key = params.filters.keys.first;
      final value = params.filters.values.first;

      if (key == 'email') {
        if (value is String && value.contains('%')) {
          return await _findByEmailLike(value, params);
        } else {
          return await _findByEmailExact(value, params);
        }
      } else if (key == 'roles') {
        return await _findByRoles(value, params);
      }
    }

    // For complex filters, fall back to multiple simple queries
    return await _findWithComplexFilters(params);
  }

  @override
  Future<int> countWithParams(QueryParams params) async {
    if (params.filters.length == 1) {
      final key = params.filters.keys.first;
      final value = params.filters.values.first;

      if (key == 'email') {
        final results = database.select(
            'SELECT COUNT(*) as count FROM accounts WHERE email = ?', [value]);
        return results.first['count'] as int;
      } else if (key == 'roles') {
        // Wrap the role value with % for LIKE pattern matching
        final rolePattern = value.toString().contains('%')
            ? value.toString()
            : '%${value.toString()}%';
        final results = database.select(
          'SELECT COUNT(*) as count FROM accounts WHERE roles LIKE ?',
          [rolePattern],
        );
        return results.first['count'] as int;
      }
    }

    // For complex counting, count all matching results
    final items = await findWithParams(params);
    return items.length;
  }

  /// Find account by exact email match
  Future<List<Account>> _findByEmailExact(
      String email, QueryParams params) async {
    String sql;
    final sqlParams = [email];

    // Use specific hardcoded SQL based on ordering and limits
    if (params.orderBy.isNotEmpty && params.orderBy.first == 'creationDate') {
      if (params.ascending) {
        sql =
            'SELECT id, email, password, creationDate, roles FROM accounts WHERE email = ? ORDER BY creationDate ASC';
      } else {
        sql =
            'SELECT id, email, password, creationDate, roles FROM accounts WHERE email = ? ORDER BY creationDate DESC';
      }
    } else if (params.orderBy.isNotEmpty && params.orderBy.first == 'email') {
      if (params.ascending) {
        sql =
            'SELECT id, email, password, creationDate, roles FROM accounts WHERE email = ? ORDER BY email ASC';
      } else {
        sql =
            'SELECT id, email, password, creationDate, roles FROM accounts WHERE email = ? ORDER BY email DESC';
      }
    } else {
      sql =
          'SELECT id, email, password, creationDate, roles FROM accounts WHERE email = ?';
    }

    final results = database.select(sql, sqlParams);
    var items = results.map((row) => fromMap(row)).toList();

    // Apply pagination in memory for simplicity
    if (params.offset != null && params.offset! > 0) {
      items = items.skip(params.offset!).toList();
    }
    if (params.limit != null) {
      items = items.take(params.limit!).toList();
    }

    return items;
  }

  /// Find accounts by email LIKE pattern
  Future<List<Account>> _findByEmailLike(
      String emailPattern, QueryParams params) async {
    String sql;
    final sqlParams = [emailPattern];

    // Use specific hardcoded SQL based on ordering
    if (params.orderBy.isNotEmpty && params.orderBy.first == 'creationDate') {
      if (params.ascending) {
        sql =
            'SELECT id, email, password, creationDate, roles FROM accounts WHERE email LIKE ? ORDER BY creationDate ASC';
      } else {
        sql =
            'SELECT id, email, password, creationDate, roles FROM accounts WHERE email LIKE ? ORDER BY creationDate DESC';
      }
    } else if (params.orderBy.isNotEmpty && params.orderBy.first == 'email') {
      if (params.ascending) {
        sql =
            'SELECT id, email, password, creationDate, roles FROM accounts WHERE email LIKE ? ORDER BY email ASC';
      } else {
        sql =
            'SELECT id, email, password, creationDate, roles FROM accounts WHERE email LIKE ? ORDER BY email DESC';
      }
    } else {
      sql =
          'SELECT id, email, password, creationDate, roles FROM accounts WHERE email LIKE ?';
    }

    final results = database.select(sql, sqlParams);
    var items = results.map((row) => fromMap(row)).toList();

    // Apply pagination in memory for simplicity
    if (params.offset != null && params.offset! > 0) {
      items = items.skip(params.offset!).toList();
    }
    if (params.limit != null) {
      items = items.take(params.limit!).toList();
    }

    return items;
  }

  /// Find accounts by roles (supports LIKE pattern)
  Future<List<Account>> _findByRoles(
      dynamic rolesValue, QueryParams params) async {
    String sql;
    // Wrap the role value with % for LIKE pattern matching
    final rolePattern = rolesValue.toString().contains('%')
        ? rolesValue.toString()
        : '%${rolesValue.toString()}%';
    final sqlParams = [rolePattern];

    // Use specific hardcoded SQL based on ordering
    if (params.orderBy.isNotEmpty && params.orderBy.first == 'creationDate') {
      if (params.ascending) {
        sql =
            'SELECT id, email, password, creationDate, roles FROM accounts WHERE roles LIKE ? ORDER BY creationDate ASC';
      } else {
        sql =
            'SELECT id, email, password, creationDate, roles FROM accounts WHERE roles LIKE ? ORDER BY creationDate DESC';
      }
    } else if (params.orderBy.isNotEmpty && params.orderBy.first == 'email') {
      if (params.ascending) {
        sql =
            'SELECT id, email, password, creationDate, roles FROM accounts WHERE roles LIKE ? ORDER BY email ASC';
      } else {
        sql =
            'SELECT id, email, password, creationDate, roles FROM accounts WHERE roles LIKE ? ORDER BY email DESC';
      }
    } else {
      sql =
          'SELECT id, email, password, creationDate, roles FROM accounts WHERE roles LIKE ?';
    }

    final results = database.select(sql, sqlParams);
    var items = results.map((row) => fromMap(row)).toList();

    // Apply pagination in memory for simplicity
    if (params.offset != null && params.offset! > 0) {
      items = items.skip(params.offset!).toList();
    }
    if (params.limit != null) {
      items = items.take(params.limit!).toList();
    }

    return items;
  }

  /// Handle complex filters by combining simple queries
  Future<List<Account>> _findWithComplexFilters(QueryParams params) async {
    if (params.filters.isEmpty) {
      String sql;

      // Use specific hardcoded SQL based on ordering
      if (params.orderBy.isNotEmpty && params.orderBy.first == 'creationDate') {
        if (params.ascending) {
          sql =
              'SELECT id, email, password, creationDate, roles FROM accounts ORDER BY creationDate ASC';
        } else {
          sql =
              'SELECT id, email, password, creationDate, roles FROM accounts ORDER BY creationDate DESC';
        }
      } else if (params.orderBy.isNotEmpty && params.orderBy.first == 'email') {
        if (params.ascending) {
          sql =
              'SELECT id, email, password, creationDate, roles FROM accounts ORDER BY email ASC';
        } else {
          sql =
              'SELECT id, email, password, creationDate, roles FROM accounts ORDER BY email DESC';
        }
      } else {
        sql = 'SELECT id, email, password, creationDate, roles FROM accounts';
      }

      final dbResults = database.select(sql);
      var results = dbResults.map((row) => fromMap(row)).toList();

      // Apply pagination in memory for simplicity
      if (params.offset != null && params.offset! > 0) {
        results = results.skip(params.offset!).toList();
      }
      if (params.limit != null) {
        results = results.take(params.limit!).toList();
      }

      return results;
    } else {
      // For complex filter combinations, use specific repository methods instead
      throw RepositoryException(
          'Complex filter combinations not yet implemented. Use specific repository methods instead.');
    }
  }

  /// Find account by email address (convenience method)
  @override
  Future<Account?> findByEmail(String email) async {
    final results = database.select(
        'SELECT id, email, password, creationDate, roles FROM accounts WHERE email = ?',
        [email]);
    return results.isEmpty ? null : fromMap(results.first);
  }

  /// Find accounts by role using LIKE
  @override
  Future<List<Account>> findByRole(String role) async {
    final results = database.select(
        'SELECT id, email, password, creationDate, roles FROM accounts WHERE roles LIKE ?',
        ['%$role%']);
    return results.map((row) => fromMap(row)).toList();
  }

  /// Find accounts created within a date range
  @override
  Future<List<Account>> findByDateRange(
      DateTime startDate, DateTime endDate) async {
    final results = database.select(
        'SELECT id, email, password, creationDate, roles FROM accounts WHERE creationDate >= ? AND creationDate <= ? ORDER BY creationDate DESC',
        [
          startDate.toUtc().toIso8601String(),
          endDate.toUtc().toIso8601String()
        ]);
    return results.map((row) => fromMap(row)).toList();
  }

  /// Create account with hashed password and default roles
  @override
  Future<Account> createAccountWithDefaults(
    String email,
    String hashedPassword, {
    List<String> roles = const ['user'],
  }) async {
    final results = database.select(
        'INSERT INTO accounts (email, password, creationDate, roles) VALUES (?, ?, ?, ?) RETURNING id, email, password, creationDate, roles',
        [
          email,
          hashedPassword,
          DateTime.now().toUtc().toIso8601String(),
          roles.join(','),
        ]);
    return fromMap(results.first);
  }

  /// Update account password
  @override
  Future<Account> updatePassword(
      int accountId, String newHashedPassword) async {
    final results = database.select(
        'UPDATE accounts SET password = ? WHERE id = ? RETURNING id, email, password, creationDate, roles',
        [newHashedPassword, accountId]);
    if (results.isEmpty) {
      throw EntityNotFoundException(
          'Account not found for password update', accountId);
    }
    return fromMap(results.first);
  }

  /// Add role to account
  @override
  Future<Account> addRole(int accountId, String role) async {
    final account = await getById(accountId);
    if (!account.roles.contains(role)) {
      final updatedRoles = [...account.roles, role];
      final results = database.select(
          'UPDATE accounts SET roles = ? WHERE id = ? RETURNING id, email, password, creationDate, roles',
          [updatedRoles.join(','), accountId]);
      return fromMap(results.first);
    }
    return account;
  }

  /// Remove role from account
  @override
  Future<Account> removeRole(int accountId, String role) async {
    final account = await getById(accountId);
    final updatedRoles = account.roles.where((r) => r != role).toList();
    final results = database.select(
        'UPDATE accounts SET roles = ? WHERE id = ? RETURNING id, email, password, creationDate, roles',
        [updatedRoles.join(','), accountId]);
    return fromMap(results.first);
  }

  /// Check if email is already taken
  @override
  Future<bool> isEmailTaken(String email) async {
    final results = database.select(
        'SELECT COUNT(*) as count FROM accounts WHERE email = ?', [email]);
    return results.first['count'] as int > 0;
  }

  /// Get accounts with pagination and search
  @override
  Future<PagedResult<Account>> searchAccounts({
    String? emailSearch,
    String? roleFilter,
    int limit = 20,
    int offset = 0,
    bool orderByCreationDate = true,
  }) async {
    String countSql;
    String dataSql;
    List<dynamic> params = [];

    // Build hardcoded SQL based on filter combinations
    if (emailSearch != null &&
        emailSearch.isNotEmpty &&
        roleFilter != null &&
        roleFilter.isNotEmpty) {
      // Both email and role filters
      countSql =
          'SELECT COUNT(*) as count FROM accounts WHERE email LIKE ? AND roles LIKE ?';
      if (orderByCreationDate) {
        dataSql =
            'SELECT id, email, password, creationDate, roles FROM accounts WHERE email LIKE ? AND roles LIKE ? ORDER BY creationDate DESC LIMIT ? OFFSET ?';
      } else {
        dataSql =
            'SELECT id, email, password, creationDate, roles FROM accounts WHERE email LIKE ? AND roles LIKE ? ORDER BY email ASC LIMIT ? OFFSET ?';
      }
      params = ['%$emailSearch%', '%$roleFilter%', limit, offset];
    } else if (emailSearch != null && emailSearch.isNotEmpty) {
      // Only email filter
      countSql = 'SELECT COUNT(*) as count FROM accounts WHERE email LIKE ?';
      if (orderByCreationDate) {
        dataSql =
            'SELECT id, email, password, creationDate, roles FROM accounts WHERE email LIKE ? ORDER BY creationDate DESC LIMIT ? OFFSET ?';
      } else {
        dataSql =
            'SELECT id, email, password, creationDate, roles FROM accounts WHERE email LIKE ? ORDER BY email ASC LIMIT ? OFFSET ?';
      }
      params = ['%$emailSearch%', limit, offset];
    } else if (roleFilter != null && roleFilter.isNotEmpty) {
      // Only role filter
      countSql = 'SELECT COUNT(*) as count FROM accounts WHERE roles LIKE ?';
      if (orderByCreationDate) {
        dataSql =
            'SELECT id, email, password, creationDate, roles FROM accounts WHERE roles LIKE ? ORDER BY creationDate DESC LIMIT ? OFFSET ?';
      } else {
        dataSql =
            'SELECT id, email, password, creationDate, roles FROM accounts WHERE roles LIKE ? ORDER BY email ASC LIMIT ? OFFSET ?';
      }
      params = ['%$roleFilter%', limit, offset];
    } else {
      // No filters
      countSql = 'SELECT COUNT(*) as count FROM accounts';
      if (orderByCreationDate) {
        dataSql =
            'SELECT id, email, password, creationDate, roles FROM accounts ORDER BY creationDate DESC LIMIT ? OFFSET ?';
      } else {
        dataSql =
            'SELECT id, email, password, creationDate, roles FROM accounts ORDER BY email ASC LIMIT ? OFFSET ?';
      }
      params = [limit, offset];
    }

    // Get total count (use appropriate parameters for count query)
    final countParams = params
        .take(params.length - 2)
        .toList(); // Remove limit and offset for count
    final countResults = database.select(countSql, countParams);
    final totalCount = countResults.first['count'] as int;

    // Get data
    final dataResults = database.select(dataSql, params);
    final items = dataResults.map((row) => fromMap(row)).toList();

    return PagedResult(
      items: items,
      totalCount: totalCount,
      limit: limit,
      offset: offset,
      hasNext: (offset + limit) < totalCount,
      hasPrevious: offset > 0,
    );
  }

  /// Get account statistics
  @override
  Future<Map<String, dynamic>> getAccountStats() async {
    // Total count
    final totalResults =
        database.select('SELECT COUNT(*) as count FROM accounts');
    final totalCount = totalResults.first['count'] as int;

    // Recent count (last 30 days)
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final recentResults = database.select(
        'SELECT COUNT(*) as count FROM accounts WHERE creationDate >= ?',
        [thirtyDaysAgo.toUtc().toIso8601String()]);
    final recentCount = recentResults.first['count'] as int;

    // Role distribution
    final allAccounts = await findAll();
    final roleDistribution = <String, int>{};
    for (final account in allAccounts) {
      for (final role in account.roles) {
        roleDistribution[role] = (roleDistribution[role] ?? 0) + 1;
      }
    }

    return {
      'totalAccounts': totalCount,
      'recentAccounts': recentCount,
      'roleDistribution': roleDistribution,
    };
  }

  @override
  Future<int> deleteAllById(List<int> ids) async {
    if (ids.isEmpty) return 0;

    // Create placeholders for the IN clause
    final placeholders = List.filled(ids.length, '?').join(',');
    final sql = 'DELETE FROM accounts WHERE id IN ($placeholders)';

    // Count existing records first
    final countSql =
        'SELECT COUNT(*) as count FROM accounts WHERE id IN ($placeholders)';
    final countResult = database.select(countSql, ids);
    final existingCount = countResult.first['count'] as int;

    // Execute the delete query
    database.execute(sql, ids);
    return existingCount;
  }
}
