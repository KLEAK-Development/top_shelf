import 'dart:async';

import 'package:top_shelf/src/services/accounts/models/account.dart';
import 'package:top_shelf/src/services/common/repositories/account/account_repository_interface.dart';
import 'package:top_shelf/src/services/common/repositories/crud_repository.dart';

/// In-memory implementation of AccountRepositoryInterface
/// Useful for testing and development scenarios where database setup is not needed
class AccountMemoryRepository implements AccountRepositoryInterface {
  final Map<int, Account> _accounts = {};
  int _nextId = 1;

  @override
  FutureOr<Account> create(Account entity) {
    if (entity.id != 0) {
      throw ArgumentError('Entity already has an ID. Use update() instead.');
    }

    // Check for email uniqueness
    if (_accounts.values.any((account) => account.email == entity.email)) {
      throw EntityConstraintException(
        'Email already exists: ${entity.email}',
        'unique_email',
      );
    }

    final newAccount = Account(
      _nextId++,
      entity.email,
      entity.password,
      entity.creationDate,
      List<String>.from(entity.roles),
    );

    _accounts[newAccount.id] = newAccount;
    return newAccount;
  }

  @override
  FutureOr<List<Account>> createAll(List<Account> entities) async {
    final results = <Account>[];
    for (final entity in entities) {
      results.add(await create(entity));
    }
    return results;
  }

  @override
  FutureOr<Account?> findById(int id) {
    return _accounts[id];
  }

  @override
  FutureOr<Account> getById(int id) {
    final account = _accounts[id];
    if (account == null) {
      throw EntityNotFoundException('Account not found', id);
    }
    return account;
  }

  @override
  FutureOr<List<Account>> findAll([QueryParams? params]) {
    var accounts = _accounts.values.toList();

    // Apply filters
    if (params?.filters.isNotEmpty == true) {
      accounts = accounts.where((account) {
        return params!.filters.entries.every((entry) {
          final key = entry.key;
          final value = entry.value;

          switch (key) {
            case 'email':
              if (value is String && value.contains('%')) {
                // Handle LIKE patterns
                final pattern = value.replaceAll('%', '');
                return account.email.contains(pattern);
              }
              return account.email == value;
            case 'roles':
              if (value is String) {
                return account.roles.contains(value);
              }
              return false;
            case 'id':
              return account.id == value;
            default:
              return true;
          }
        });
      }).toList();
    }

    // Apply ordering
    if (params?.orderBy.isNotEmpty == true) {
      final orderBy = params!.orderBy.first;
      accounts.sort((a, b) {
        int comparison;
        switch (orderBy) {
          case 'email':
            comparison = a.email.compareTo(b.email);
            break;
          case 'creationDate':
            comparison = a.creationDate.compareTo(b.creationDate);
            break;
          case 'id':
            comparison = a.id.compareTo(b.id);
            break;
          default:
            comparison = 0;
        }
        return params.ascending ? comparison : -comparison;
      });
    }

    // Apply pagination
    if (params?.offset != null || params?.limit != null) {
      final offset = params?.offset ?? 0;
      final limit = params?.limit;

      if (offset > 0) {
        accounts = accounts.skip(offset).toList();
      }

      if (limit != null) {
        accounts = accounts.take(limit).toList();
      }
    }

    return accounts;
  }

  @override
  FutureOr<PagedResult<Account>> findPage(QueryParams params) async {
    final totalCount = await count(QueryParams(filters: params.filters));
    final items = await findAll(params);

    final offset = params.offset ?? 0;
    final limit = params.limit ?? totalCount;

    return PagedResult<Account>(
      items: items,
      totalCount: totalCount,
      limit: limit,
      offset: offset,
      hasNext: offset + items.length < totalCount,
      hasPrevious: offset > 0,
    );
  }

  @override
  FutureOr<Account?> findFirst(QueryParams params) async {
    final results = await findAll(params.copyWith(limit: 1));
    return results.isEmpty ? null : results.first;
  }

  @override
  FutureOr<Account> findOne(QueryParams params) async {
    final results = await findAll(params.copyWith(limit: 2));

    if (results.isEmpty) {
      throw EntityNotFoundException('No account found matching criteria', null);
    }

    if (results.length > 1) {
      throw EntityConstraintException(
        'Multiple accounts found, expected exactly one',
        'unique_result',
      );
    }

    return results.first;
  }

  @override
  FutureOr<bool> existsById(int id) {
    return _accounts.containsKey(id);
  }

  @override
  FutureOr<int> count([QueryParams? params]) async {
    if (params?.filters.isEmpty ?? true) {
      return _accounts.length;
    }

    final filtered = await findAll(params);
    return filtered.length;
  }

  @override
  FutureOr<Account> update(Account entity) {
    if (!_accounts.containsKey(entity.id)) {
      throw EntityNotFoundException('Account not found', entity.id);
    }

    // Check for email uniqueness (excluding current account)
    final existingWithEmail = _accounts.values
        .where((account) =>
            account.email == entity.email && account.id != entity.id)
        .isNotEmpty;

    if (existingWithEmail) {
      throw EntityConstraintException(
        'Email already exists: ${entity.email}',
        'unique_email',
      );
    }

    final updatedAccount = Account(
      entity.id,
      entity.email,
      entity.password,
      entity.creationDate,
      List<String>.from(entity.roles),
    );

    _accounts[entity.id] = updatedAccount;
    return updatedAccount;
  }

  @override
  FutureOr<List<Account>> updateAll(List<Account> entities) {
    final results = <Account>[];
    for (final entity in entities) {
      results.add(update(entity) as Account);
    }
    return results;
  }

  @override
  FutureOr<Account> updatePartial(int id, Map<String, dynamic> fields) {
    final account = _accounts[id];
    if (account == null) {
      throw EntityNotFoundException('Account not found', id);
    }

    // Create updated account with partial fields
    final updatedAccount = Account(
      account.id,
      fields['email'] ?? account.email,
      fields['password'] ?? account.password,
      fields['creationDate'] != null
          ? DateTime.parse(fields['creationDate'])
          : account.creationDate,
      fields['roles'] != null
          ? (fields['roles'] as String).split(',')
          : account.roles,
    );

    return update(updatedAccount) as Account;
  }

  @override
  FutureOr<bool> deleteById(int id) {
    return _accounts.remove(id) != null;
  }

  @override
  FutureOr<bool> delete(Account entity) {
    return deleteById(entity.id) as bool;
  }

  @override
  FutureOr<int> deleteAllById(List<int> ids) {
    int deletedCount = 0;
    for (final id in ids) {
      if (_accounts.remove(id) != null) {
        deletedCount++;
      }
    }
    return deletedCount;
  }

  @override
  FutureOr<int> deleteWhere(QueryParams params) async {
    final toDelete = await findAll(params);
    final ids = toDelete.map((account) => account.id).toList();
    return deleteAllById(ids) as int;
  }

  @override
  FutureOr<int> deleteAll() {
    final count = _accounts.length;
    _accounts.clear();
    _nextId = 1;
    return count;
  }

  @override
  FutureOr<Account> save(Account entity) {
    if (entity.id == 0 || !_accounts.containsKey(entity.id)) {
      return create(entity);
    } else {
      return update(entity);
    }
  }

  @override
  FutureOr<List<Account>> saveAll(List<Account> entities) {
    final results = <Account>[];
    for (final entity in entities) {
      results.add(save(entity) as Account);
    }
    return results;
  }

  // AccountRepositoryInterface specific methods

  @override
  Future<Account> createAccountWithDefaults(
    String email,
    String hashedPassword, {
    List<String> roles = const ['user'],
  }) async {
    final account = Account(
      0, // Will be assigned by create()
      email,
      hashedPassword,
      DateTime.now(),
      roles,
    );

    return await create(account);
  }

  @override
  Future<Account?> findByEmail(String email) async {
    return await findFirst(QueryParams(filters: {'email': email}));
  }

  @override
  Future<List<Account>> findByRole(String role) async {
    return await findAll(QueryParams(filters: {'roles': role}));
  }

  @override
  Future<List<Account>> findByDateRange(
      DateTime startDate, DateTime endDate) async {
    final accounts = _accounts.values.where((account) {
      return account.creationDate.isAfter(startDate) &&
          account.creationDate.isBefore(endDate);
    }).toList();

    return accounts;
  }

  @override
  Future<Account> updatePassword(
      int accountId, String newHashedPassword) async {
    final account = await getById(accountId);

    final updatedAccount = Account(
      account.id,
      account.email,
      newHashedPassword,
      account.creationDate,
      account.roles,
    );

    return await update(updatedAccount);
  }

  @override
  Future<Account> addRole(int accountId, String role) async {
    final account = await getById(accountId);

    if (account.roles.contains(role)) {
      return account; // Role already exists
    }

    final updatedRoles = [...account.roles, role];
    final updatedAccount = Account(
      account.id,
      account.email,
      account.password,
      account.creationDate,
      updatedRoles,
    );

    return await update(updatedAccount);
  }

  @override
  Future<Account> removeRole(int accountId, String role) async {
    final account = await getById(accountId);

    final updatedRoles = account.roles.where((r) => r != role).toList();
    final updatedAccount = Account(
      account.id,
      account.email,
      account.password,
      account.creationDate,
      updatedRoles,
    );

    return await update(updatedAccount);
  }

  @override
  Future<bool> isEmailTaken(String email) async {
    return _accounts.values.any((account) => account.email == email);
  }

  @override
  Future<PagedResult<Account>> searchAccounts({
    String? emailSearch,
    String? roleFilter,
    int limit = 20,
    int offset = 0,
    bool orderByCreationDate = true,
  }) async {
    final filters = <String, dynamic>{};

    if (emailSearch != null && emailSearch.isNotEmpty) {
      filters['email'] = '%$emailSearch%';
    }

    if (roleFilter != null && roleFilter.isNotEmpty) {
      filters['roles'] = roleFilter;
    }

    final params = QueryParams(
      filters: filters,
      orderBy: orderByCreationDate ? ['creationDate'] : ['id'],
      limit: limit,
      offset: offset,
      ascending: !orderByCreationDate, // Most recent first for creation date
    );

    return await findPage(params);
  }

  @override
  Future<Map<String, dynamic>> getAccountStats() async {
    final totalAccounts = _accounts.length;
    final roleStats = <String, int>{};

    for (final account in _accounts.values) {
      for (final role in account.roles) {
        roleStats[role] = (roleStats[role] ?? 0) + 1;
      }
    }

    final now = DateTime.now();
    final last30Days = now.subtract(Duration(days: 30));
    final recentAccounts = _accounts.values
        .where((account) => account.creationDate.isAfter(last30Days))
        .length;

    final totalRoles =
        roleStats.values.fold<int>(0, (sum, count) => sum + count);

    return {
      'total_accounts': totalAccounts,
      'recent_accounts_30_days': recentAccounts,
      'role_distribution': roleStats,
      'average_roles_per_account':
          totalAccounts > 0 ? totalRoles / totalAccounts : 0.0,
    };
  }

  /// Clears all data (useful for testing)
  void clear() {
    _accounts.clear();
    _nextId = 1;
  }

  /// Returns the current number of accounts (useful for testing)
  int get size => _accounts.length;

  /// Returns all account IDs (useful for testing)
  List<int> get accountIds => _accounts.keys.toList();
}
