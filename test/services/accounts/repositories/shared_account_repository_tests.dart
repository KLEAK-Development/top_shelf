import 'package:test/test.dart';
import 'package:top_shelf/src/services/accounts/models/account.dart';
import 'package:top_shelf/src/services/common/repositories/account/account_repository_interface.dart';
import 'package:top_shelf/src/services/common/repositories/account/account_memory_repository.dart';
import 'package:top_shelf/src/services/common/repositories/crud_repository.dart';

/// Shared unit test suite for repository implementations (pure repository testing)
/// Focuses on data storage, retrieval, and repository-specific operations
void runAccountRepositoryTests(
    Future<AccountRepositoryInterface> Function() repositoryFactory,
    [Future<void> Function()? cleanup]) {
  late AccountRepositoryInterface repository;

  setUp(() async {
    repository = await repositoryFactory();
  });

  tearDown(() async {
    // Clear repository data if it supports it
    if (repository is AccountMemoryRepository) {
      (repository as AccountMemoryRepository).clear();
    }

    // Run custom cleanup if provided
    if (cleanup != null) {
      await cleanup();
    }
  });

  group('Core CRUD Operations', () {
    test('should create account with auto-generated ID', () async {
      // Arrange
      final account = Account(
        0, // Will be auto-generated
        'test@example.com',
        'hashedPassword123',
        DateTime.now(),
        ['user'],
      );

      // Act
      final created = await repository.create(account);

      // Assert
      expect(created.id, isPositive);
      expect(created.email, equals('test@example.com'));
      expect(created.password, equals('hashedPassword123'));
      expect(created.roles, equals(['user']));
    });

    test('should enforce email uniqueness constraint', () async {
      // Arrange
      final account1 =
          Account(0, 'test@example.com', 'pass1', DateTime.now(), ['user']);
      final account2 =
          Account(0, 'test@example.com', 'pass2', DateTime.now(), ['admin']);

      // Act
      await repository.create(account1);

      // Assert - Different implementations may throw different exception types
      expect(
        () => repository.create(account2),
        throwsA(anyOf(
          isA<EntityConstraintException>(),
          isA<RepositoryException>(),
        )),
      );
    });

    test('should retrieve account by ID', () async {
      // Arrange
      final account =
          Account(0, 'retrieve@example.com', 'pass', DateTime.now(), ['user']);
      final created = await repository.create(account);

      // Act
      final found = await repository.findById(created.id);

      // Assert
      expect(found, isNotNull);
      expect(found!.id, equals(created.id));
      expect(found.email, equals('retrieve@example.com'));
    });

    test('should return null for non-existent ID', () async {
      // Act
      final found = await repository.findById(999);

      // Assert
      expect(found, isNull);
    });

    test('should update existing account', () async {
      // Arrange
      final original =
          Account(0, 'original@example.com', 'pass', DateTime.now(), ['user']);
      final created = await repository.create(original);

      final updated = Account(
        created.id,
        'updated@example.com',
        'newPass',
        created.creationDate,
        ['admin'],
      );

      // Act
      final result = await repository.update(updated);

      // Assert
      expect(result.id, equals(created.id));
      expect(result.email, equals('updated@example.com'));
      expect(result.password, equals('newPass'));
      expect(result.roles, equals(['admin']));
    });

    test('should delete account by ID', () async {
      // Arrange
      final account =
          Account(0, 'delete@example.com', 'pass', DateTime.now(), ['user']);
      final created = await repository.create(account);

      // Act
      final deleted = await repository.deleteById(created.id);

      // Assert
      expect(deleted, isTrue);
      expect(await repository.findById(created.id), isNull);
    });
  });

  group('Query Operations', () {
    setUp(() async {
      // Create test data for querying
      await repository.create(Account(
          0, 'alice@example.com', 'pass1', DateTime(2023, 1, 1), ['user']));
      await repository.create(Account(
          0, 'bob@company.com', 'pass2', DateTime(2023, 2, 1), ['admin']));
      await repository.create(Account(0, 'charlie@example.com', 'pass3',
          DateTime(2023, 3, 1), ['user', 'editor']));
    });

    test('should find all accounts', () async {
      // Act
      final accounts = await repository.findAll();

      // Assert
      expect(accounts.length, equals(3));
    });

    test('should filter by email pattern', () async {
      // Act
      final accounts = await repository.findAll(
        QueryParams(filters: {'email': '%example%'}),
      );

      // Assert
      expect(accounts.length, equals(2));
      expect(accounts.every((a) => a.email.contains('example')), isTrue);
    });

    test('should filter by role', () async {
      // Act
      final userAccounts = await repository.findAll(
        QueryParams(filters: {'roles': 'user'}),
      );

      // Assert
      expect(userAccounts.length, equals(2));
      expect(userAccounts.every((a) => a.roles.contains('user')), isTrue);
    });

    test('should support pagination', () async {
      // Act
      final page = await repository.findPage(
        QueryParams(limit: 2, offset: 0),
      );

      // Assert
      expect(page.items.length, equals(2));
      expect(page.totalCount, equals(3));
      expect(page.hasNext, isTrue);
      expect(page.hasPrevious, isFalse);
    });

    test('should sort results', () async {
      // Act
      final accounts = await repository.findAll(
        QueryParams(orderBy: ['email'], ascending: true),
      );

      // Assert
      expect(accounts.length, equals(3));
      expect(accounts[0].email, equals('alice@example.com'));
      expect(accounts[1].email, equals('bob@company.com'));
      expect(accounts[2].email, equals('charlie@example.com'));
    });
  });

  group('Account-Specific Repository Operations', () {
    test('should create account with defaults', () async {
      // Act
      final account = await repository.createAccountWithDefaults(
        'defaults@example.com',
        'hashedPass123',
        roles: ['admin', 'user'],
      );

      // Assert
      expect(account.email, equals('defaults@example.com'));
      expect(account.password, equals('hashedPass123'));
      expect(account.roles, equals(['admin', 'user']));
      expect(account.id, isPositive);
      expect(account.creationDate, isA<DateTime>());
    });

    test('should find account by email', () async {
      // Arrange
      await repository.createAccountWithDefaults('findme@example.com', 'pass');

      // Act
      final account = await repository.findByEmail('findme@example.com');

      // Assert
      expect(account, isNotNull);
      expect(account!.email, equals('findme@example.com'));
    });

    test('should check email availability', () async {
      // Arrange
      await repository.createAccountWithDefaults('taken@example.com', 'pass');

      // Act & Assert
      expect(await repository.isEmailTaken('taken@example.com'), isTrue);
      expect(await repository.isEmailTaken('available@example.com'), isFalse);
    });

    test('should update password directly', () async {
      // Arrange
      final account = await repository.createAccountWithDefaults(
          'password@example.com', 'oldPass');

      // Act
      final updated = await repository.updatePassword(account.id, 'newPass');

      // Assert
      expect(updated.password, equals('newPass'));
      expect(updated.email, equals(account.email)); // Other fields unchanged
      expect(updated.id, equals(account.id));
    });

    test('should manage roles directly', () async {
      // Arrange
      final account = await repository.createAccountWithDefaults(
          'roles@example.com', 'pass',
          roles: ['user']);

      // Act - Add role
      final withAdmin = await repository.addRole(account.id, 'admin');
      expect(withAdmin.roles, containsAll(['user', 'admin']));

      // Act - Remove role
      final withoutUser = await repository.removeRole(account.id, 'user');
      expect(withoutUser.roles, contains('admin'));
      expect(withoutUser.roles, isNot(contains('user')));
    });
  });

  group('Batch Operations', () {
    test('should create multiple accounts', () async {
      // Arrange
      final accounts = [
        Account(0, 'batch1@example.com', 'pass1', DateTime.now(), ['user']),
        Account(0, 'batch2@example.com', 'pass2', DateTime.now(), ['admin']),
      ];

      // Act
      final created = await repository.createAll(accounts);

      // Assert
      expect(created.length, equals(2));
      expect(created.every((a) => a.id > 0), isTrue);
      expect(created[0].email, equals('batch1@example.com'));
      expect(created[1].email, equals('batch2@example.com'));
    });

    test('should delete multiple accounts by ID', () async {
      // Arrange
      final account1 = await repository.createAccountWithDefaults(
          'del1@example.com', 'pass');
      final account2 = await repository.createAccountWithDefaults(
          'del2@example.com', 'pass');
      final account3 = await repository.createAccountWithDefaults(
          'keep@example.com', 'pass');

      // Act
      final deletedCount =
          await repository.deleteAllById([account1.id, account2.id]);

      // Assert
      expect(deletedCount, equals(2));
      expect(await repository.findById(account1.id), isNull);
      expect(await repository.findById(account2.id), isNull);
      expect(await repository.findById(account3.id), isNotNull);
    });
  });

  group('Advanced Query Operations', () {
    test('should search with complex filters', () async {
      // Arrange
      await repository.createAccountWithDefaults('admin@company.com', 'pass',
          roles: ['admin']);
      await repository.createAccountWithDefaults('user@company.com', 'pass',
          roles: ['user']);
      await repository.createAccountWithDefaults('user@personal.com', 'pass',
          roles: ['user']);

      // Act
      final results = await repository.searchAccounts(
        emailSearch: 'company',
        roleFilter: 'user',
        limit: 10,
      );

      // Assert
      expect(results.items.length, equals(1));
      expect(results.items.first.email, equals('user@company.com'));
    });

    test('should find accounts by role', () async {
      // Arrange
      await repository.createAccountWithDefaults('admin1@example.com', 'pass',
          roles: ['admin']);
      await repository.createAccountWithDefaults('admin2@example.com', 'pass',
          roles: ['admin', 'user']);
      await repository.createAccountWithDefaults('user1@example.com', 'pass',
          roles: ['user']);

      // Act
      final adminAccounts = await repository.findByRole('admin');

      // Assert
      expect(adminAccounts.length, equals(2));
      expect(adminAccounts.every((a) => a.roles.contains('admin')), isTrue);
    });

    test('should find accounts by date range', () async {
      // Arrange
      final oldDate = DateTime(2023, 1, 1);
      final recentDate = DateTime(2023, 6, 1);

      await repository
          .create(Account(0, 'old@example.com', 'pass', oldDate, ['user']));
      await repository.create(
          Account(0, 'recent@example.com', 'pass', recentDate, ['user']));

      // Act
      final recentAccounts = await repository.findByDateRange(
        DateTime(2023, 5, 1),
        DateTime(2023, 7, 1),
      );

      // Assert
      expect(recentAccounts.length, equals(1));
      expect(recentAccounts.first.email, equals('recent@example.com'));
    });
  });

  group('Data Consistency', () {
    test('should maintain referential integrity', () async {
      // Arrange
      final account = await repository.createAccountWithDefaults(
          'integrity@example.com', 'originalPass');

      // Act - Multiple operations
      await repository.updatePassword(account.id, 'newPass');
      await repository.addRole(account.id, 'admin');

      // Assert - Verify final state is consistent
      final finalAccount = await repository.findById(account.id);
      expect(finalAccount!.password, equals('newPass'));
      expect(finalAccount.roles, contains('admin'));
      expect(finalAccount.email, equals('integrity@example.com'));
      expect(finalAccount.id, equals(account.id));
    });

    test('should handle edge cases gracefully', () async {
      // Test various edge cases
      expect(await repository.findById(0), isNull);
      expect(await repository.deleteById(999), isFalse);
      expect(await repository.findByEmail('nonexistent@example.com'), isNull);

      final emptyResults = await repository.findByRole('nonexistent');
      expect(emptyResults.length, equals(0));
    });
  });
}
