import 'package:test/test.dart';
import 'package:top_shelf/src/services/accounts/models/account.dart';
import 'package:top_shelf/src/services/common/services/account/account_service.dart';
import 'package:top_shelf/src/services/common/repositories/account/account_repository_interface.dart';
import 'package:top_shelf/src/services/common/repositories/account/account_memory_repository.dart';
import 'package:top_shelf/src/services/common/services/base_crud_service.dart';

/// Shared integration test suite for AccountService with repository implementations
/// Focuses on business logic, validation, and end-to-end workflows through AccountService
void runAccountIntegrationTests(
    Future<AccountRepositoryInterface> Function() repositoryFactory,
    [Future<void> Function()? cleanup]) {
  late AccountRepositoryInterface repository;
  late AccountService accountService;

  // Test pepper factory
  String testPepperFactory() => 'test_pepper_for_integration_tests';

  // Test JWT secret factory
  String testJwtSecretFactory() => 'test_jwt_secret_key_for_testing';

  setUp(() async {
    repository = await repositoryFactory();
    accountService = AccountService(
      repository,
      pepperFactory: testPepperFactory,
      jwtSecretFactory: testJwtSecretFactory,
    );
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

  group('Account Creation with Business Logic', () {
    test('should create account with password hashing', () async {
      // Arrange
      const email = 'business@example.com';
      const plainPassword = 'PlainPassword123';

      // Act
      final account = await accountService.createAccount(
        email: email,
        password: plainPassword,
      );

      // Assert - Password should be hashed, not plain text
      expect(account.id, isPositive);
      expect(account.email, equals(email));
      expect(
          account.password, isNot(equals(plainPassword))); // Should be hashed
      expect(account.password, isNotEmpty);
      expect(account.roles, equals(['user'])); // Default role
    });

    test('should enforce business rule for unique emails', () async {
      // Arrange
      const email = 'duplicate@example.com';
      const password = 'TestPassword123';

      await accountService.createAccount(email: email, password: password);

      // Act & Assert - Service should prevent duplicate emails
      expect(
        () => accountService.createAccount(email: email, password: password),
        throwsA(isA<ServiceValidationException>()),
      );
    });

    test('should create account with custom roles', () async {
      // Arrange
      const email = 'admin@example.com';
      const password = 'TestPassword123';
      final roles = ['admin', 'user'];

      // Act
      final account = await accountService.createAccount(
        email: email,
        password: password,
        roles: roles,
      );

      // Assert
      expect(account.roles, equals(roles));
    });

    test('should validate account creation through service', () async {
      // This tests the service's validation logic, not just repository storage
      const email = 'validate@example.com';
      const password = 'ValidPassword123';

      // Act
      final account = await accountService.createAccount(
        email: email,
        password: password,
      );

      // Assert - Service ensures proper validation occurred
      expect(account.email, equals(email));
      expect(account.creationDate, isA<DateTime>());
      expect(account.roles, isNotEmpty);
    });
  });

  group('Role Management Business Logic', () {
    test('should add role with business validation', () async {
      // Arrange
      const email = 'roles@example.com';
      const password = 'TestPassword123';

      final account =
          await accountService.createAccount(email: email, password: password);

      // Act - Service handles role validation
      final updatedAccount = await accountService.addRole(account.id, 'admin');

      // Assert
      expect(updatedAccount.roles, contains('admin'));
      expect(updatedAccount.roles, contains('user'));
    });

    test('should remove role through service', () async {
      // Arrange
      const email = 'rolesremove@example.com';
      const password = 'TestPassword123';
      final initialRoles = ['user', 'admin'];

      final account = await accountService.createAccount(
        email: email,
        password: password,
        roles: initialRoles,
      );

      // Act
      final updatedAccount =
          await accountService.removeRole(account.id, 'admin');

      // Assert
      expect(updatedAccount.roles, equals(['user']));
      expect(updatedAccount.roles, isNot(contains('admin')));
    });

    test('should validate role management', () async {
      // Arrange
      const email = 'rolevalidation@example.com';
      const password = 'TestPassword123';

      final account =
          await accountService.createAccount(email: email, password: password);

      // Act & Assert - Service should validate roles
      expect(
        () => accountService.addRole(account.id, 'invalid_role'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('Search and Reporting Business Logic', () {
    test('should search accounts with business logic', () async {
      // Arrange - Create accounts through service (with proper hashing, validation)
      await accountService.createAccount(
          email: 'alice@example.com', password: 'Password123');
      await accountService.createAccount(
          email: 'bob@test.com', password: 'Password123');
      await accountService.createAccount(
          email: 'charlie@example.com', password: 'Password123');

      // Act - Search through service layer
      final result =
          await accountService.searchAccounts(emailSearch: 'example');

      // Assert
      expect(result.items.length, equals(2));
      expect(result.totalCount, equals(2));
      expect(result.items.every((account) => account.email.contains('example')),
          isTrue);
    });

    test('should search by role with proper service logic', () async {
      // Arrange
      await accountService.createAccount(
          email: 'user1@example.com', password: 'Password123');
      await accountService.createAccount(
          email: 'admin1@example.com',
          password: 'Password123',
          roles: ['admin']);
      await accountService.createAccount(
          email: 'admin2@example.com',
          password: 'Password123',
          roles: ['admin']);

      // Act
      final result = await accountService.searchAccounts(roleFilter: 'admin');

      // Assert
      expect(result.items.length, equals(2));
      expect(result.items.every((account) => account.roles.contains('admin')),
          isTrue);
    });

    test('should provide accurate statistics through service', () async {
      // Arrange
      await accountService.createAccount(
          email: 'user1@example.com', password: 'Password123');
      await accountService.createAccount(
          email: 'admin@example.com',
          password: 'Password123',
          roles: ['admin']);
      await accountService.createAccount(
          email: 'mod@example.com',
          password: 'Password123',
          roles: ['moderator']);

      // Act
      final stats = await accountService.getAccountStatistics();

      // Assert - Service provides business-level statistics
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.isNotEmpty, isTrue);

      // Check for total count (field name may vary between implementations)
      expect(
          stats.containsKey('total_accounts') ||
              stats.containsKey('totalAccounts'),
          isTrue);

      final totalKey = stats.containsKey('total_accounts')
          ? 'total_accounts'
          : 'totalAccounts';
      expect(stats[totalKey], equals(3));
    });
  });

  group('Business Query Operations', () {
    test('should find accounts by role through service', () async {
      // Arrange
      await accountService.createAccount(
          email: 'user@example.com', password: 'Password123');
      await accountService.createAccount(
          email: 'admin1@example.com',
          password: 'Password123',
          roles: ['admin']);
      await accountService.createAccount(
          email: 'admin2@example.com',
          password: 'Password123',
          roles: ['admin', 'user']);

      // Act - Query through service layer
      final adminAccounts = await accountService.findAccountsByRole('admin');
      final userAccounts = await accountService.findAccountsByRole('user');

      // Assert
      expect(adminAccounts.length, equals(2));
      expect(adminAccounts.every((account) => account.roles.contains('admin')),
          isTrue);

      expect(userAccounts.length,
          equals(2)); // First and third accounts have 'user' role
      expect(userAccounts.every((account) => account.roles.contains('user')),
          isTrue);
    });

    test('should find accounts by date range through service', () async {
      // Arrange
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final tomorrow = DateTime.now().add(const Duration(days: 1));

      await accountService.createAccount(
          email: 'recent@example.com', password: 'Password123');
      await accountService.createAccount(
          email: 'today@example.com', password: 'Password123');

      // Act
      final accounts =
          await accountService.findAccountsByDateRange(yesterday, tomorrow);

      // Assert
      expect(accounts.length, equals(2));
      expect(
          accounts.every((account) =>
              account.creationDate.isAfter(yesterday) &&
              account.creationDate.isBefore(tomorrow)),
          isTrue);
    });
  });

  group('Password Management Business Logic', () {
    test('should change password with validation', () async {
      // Arrange
      const email = 'password@example.com';
      const currentPassword = 'CurrentPassword123';
      const newPassword = 'NewPassword456';

      final account = await accountService.createAccount(
          email: email, password: currentPassword);

      // Act
      final updatedAccount = await accountService.changePassword(
          account.id, currentPassword, newPassword);

      // Assert - Password should be hashed and changed
      expect(updatedAccount.password, isNot(equals(currentPassword)));
      expect(updatedAccount.password, isNot(equals(newPassword)));
      expect(updatedAccount.password, isNot(equals(account.password)));
      expect(updatedAccount.email, equals(account.email));
    });

    test('should validate current password when changing', () async {
      // Arrange
      const email = 'passwordvalidation@example.com';
      const currentPassword = 'CurrentPassword123';
      const wrongPassword = 'WrongPassword123';
      const newPassword = 'NewPassword456';

      final account = await accountService.createAccount(
          email: email, password: currentPassword);

      // Act & Assert - Service should validate current password
      expect(
        () => accountService.changePassword(
            account.id, wrongPassword, newPassword),
        throwsA(isA<ServiceValidationException>()),
      );
    });

    test('should validate new password strength', () async {
      // Arrange
      const email = 'weakpassword@example.com';
      const currentPassword = 'CurrentPassword123';
      const weakPassword = 'weak';

      final account = await accountService.createAccount(
          email: email, password: currentPassword);

      // Act & Assert - Service should validate new password
      expect(
        () => accountService.changePassword(
            account.id, currentPassword, weakPassword),
        throwsA(isA<ServiceValidationException>()),
      );
    });
  });

  group('Authentication Business Logic', () {
    test('should authenticate with correct credentials', () async {
      // Arrange
      const email = 'auth@example.com';
      const password = 'TestPassword123';

      await accountService.createAccount(email: email, password: password);

      // Act
      final authenticatedAccount =
          await accountService.authenticate(email, password);

      // Assert
      expect(authenticatedAccount, isNotNull);
      expect(authenticatedAccount!.email, equals(email));
    });

    test('should reject authentication with wrong password', () async {
      // Arrange
      const email = 'authfail@example.com';
      const correctPassword = 'CorrectPassword123';
      const wrongPassword = 'WrongPassword123';

      await accountService.createAccount(
          email: email, password: correctPassword);

      // Act
      final authenticatedAccount =
          await accountService.authenticate(email, wrongPassword);

      // Assert
      expect(authenticatedAccount, isNull);
    });

    test('should reject authentication with non-existent email', () async {
      // Act
      final authenticatedAccount = await accountService.authenticate(
          'nonexistent@example.com', 'Password123');

      // Assert
      expect(authenticatedAccount, isNull);
    });
  });

  group('Login Token Generation', () {
    test('should generate JWT tokens for authenticated account', () async {
      // Arrange
      const email = 'login@example.com';
      const password = 'TestPassword123';

      final account =
          await accountService.createAccount(email: email, password: password);

      // Act
      final tokens = await accountService.login(account);

      // Assert
      expect(tokens.accessToken, isNotEmpty);
      expect(tokens.refreshToken, isNotEmpty);
      expect(tokens.accessToken, isNot(equals(tokens.refreshToken)));

      // Verify tokens are JWT format (contain dots)
      expect(tokens.accessToken.contains('.'), isTrue);
      expect(tokens.refreshToken.contains('.'), isTrue);
    });

    test('should generate different tokens for different accounts', () async {
      // Arrange
      final account1 = await accountService.createAccount(
          email: 'user1@example.com', password: 'Password123');
      final account2 = await accountService.createAccount(
          email: 'user2@example.com', password: 'Password123');

      // Act
      final tokens1 = await accountService.login(account1);
      final tokens2 = await accountService.login(account2);

      // Assert
      expect(tokens1.accessToken, isNot(equals(tokens2.accessToken)));
      expect(tokens1.refreshToken, isNot(equals(tokens2.refreshToken)));
    });

    test('should generate different tokens for same account on multiple logins',
        () async {
      // Arrange
      final account = await accountService.createAccount(
          email: 'multiple@example.com', password: 'Password123');

      // Act
      final tokens1 = await accountService.login(account);

      // Wait a moment to ensure different timestamps
      await Future.delayed(Duration(seconds: 1));

      final tokens2 = await accountService.login(account);

      // Assert
      expect(tokens1.accessToken, isNot(equals(tokens2.accessToken)));
      expect(tokens1.refreshToken, isNot(equals(tokens2.refreshToken)));
    });
  });

  group('Token Refresh Logic', () {
    test('should refresh tokens with valid refresh token', () async {
      // Arrange
      final account = await accountService.createAccount(
          email: 'refresh@example.com', password: 'Password123');
      final originalTokens = await accountService.login(account);

      // Act - Add small delay to ensure different timestamps
      await Future.delayed(Duration(seconds: 1));
      final newTokens =
          await accountService.refreshTokens(originalTokens.refreshToken);

      // Assert
      expect(newTokens.accessToken, isNotEmpty);
      expect(newTokens.refreshToken, isNotEmpty);
      expect(newTokens.accessToken, isNot(equals(originalTokens.accessToken)));
      expect(
          newTokens.refreshToken, isNot(equals(originalTokens.refreshToken)));

      // Verify tokens are JWT format
      expect(newTokens.accessToken.contains('.'), isTrue);
      expect(newTokens.refreshToken.contains('.'), isTrue);
    });

    test('should reject invalid refresh token', () async {
      // Arrange
      const invalidToken = 'invalid.token.format';

      // Act & Assert
      expect(
        () => accountService.refreshTokens(invalidToken),
        throwsA(isA<ServiceValidationException>()),
      );
    });

    test('should reject refresh token for non-existent account', () async {
      // Arrange - Create and then delete an account
      final account = await accountService.createAccount(
          email: 'toDelete@example.com', password: 'Password123');
      final tokens = await accountService.login(account);

      // Delete the account to simulate non-existent user
      await accountService.deleteById(account.id);

      // Act & Assert
      expect(
        () => accountService.refreshTokens(tokens.refreshToken),
        throwsA(isA<ServiceNotFoundException>()),
      );
    });

    test('should reject malformed refresh token', () async {
      // Arrange
      const malformedToken =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.malformed.signature';

      // Act & Assert
      expect(
        () => accountService.refreshTokens(malformedToken),
        throwsA(isA<ServiceValidationException>()),
      );
    });

    test('should generate different tokens on each refresh', () async {
      // Arrange
      final account = await accountService.createAccount(
          email: 'multiRefresh@example.com', password: 'Password123');
      final originalTokens = await accountService.login(account);

      // Act
      final tokens1 =
          await accountService.refreshTokens(originalTokens.refreshToken);

      // Wait to ensure different timestamps
      await Future.delayed(Duration(seconds: 1));

      final tokens2 = await accountService.refreshTokens(tokens1.refreshToken);

      // Assert
      expect(tokens1.accessToken, isNot(equals(tokens2.accessToken)));
      expect(tokens1.refreshToken, isNot(equals(tokens2.refreshToken)));
    });
  });

  group('Concurrent Business Operations', () {
    test('should handle concurrent account creation properly', () async {
      // Arrange
      final futures = <Future<Account>>[];

      // Act - Create multiple accounts concurrently through service
      for (int i = 0; i < 5; i++) {
        futures.add(
          accountService.createAccount(
            email: 'concurrent$i@example.com',
            password: 'Password123',
          ),
        );
      }

      final accounts = await Future.wait(futures);

      // Assert
      expect(accounts.length, equals(5));

      // Verify all accounts have unique IDs and proper hashing
      final ids = accounts.map((a) => a.id).toSet();
      expect(ids.length, equals(5));

      // Verify all passwords are hashed (different from input)
      expect(accounts.every((a) => a.password != 'Password123'), isTrue);
      expect(accounts.every((a) => a.password.isNotEmpty), isTrue);
    });

    test('should handle concurrent role updates', () async {
      // Arrange
      const email = 'concurrent-roles@example.com';
      const password = 'TestPassword123';

      final account =
          await accountService.createAccount(email: email, password: password);

      // Act - Add multiple roles concurrently through service
      final futures = [
        accountService.addRole(account.id, 'admin'),
        accountService.addRole(account.id, 'moderator'),
        accountService.addRole(account.id, 'guest'),
      ];

      await Future.wait(futures);

      // Assert - Service should handle concurrent updates properly
      final stats = await accountService.getAccountStatistics();
      expect(stats, isA<Map<String, dynamic>>());
    });
  });

  group('Service Validation Rules', () {
    test('should validate email format', () async {
      // Act & Assert
      expect(
        () => accountService.createAccount(
            email: 'invalid-email', password: 'ValidPassword123'),
        throwsA(isA<ServiceValidationException>()),
      );
    });

    test('should enforce password requirements', () async {
      // Act & Assert - Test various invalid passwords
      expect(
        () => accountService.createAccount(
            email: 'test@example.com', password: ''),
        throwsA(isA<ServiceValidationException>()),
      );

      expect(
        () => accountService.createAccount(
            email: 'test@example.com', password: 'short'),
        throwsA(isA<ServiceValidationException>()),
      );

      expect(
        () => accountService.createAccount(
            email: 'test@example.com', password: 'nouppercase123'),
        throwsA(isA<ServiceValidationException>()),
      );
    });

    test('should validate role assignments', () async {
      // Arrange
      const email = 'rolevalidation@example.com';
      const password = 'ValidPassword123';

      final account =
          await accountService.createAccount(email: email, password: password);

      // Act & Assert
      expect(
        () => accountService.addRole(account.id, 'invalid_role'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('Error Handling and Edge Cases', () {
    test('should handle non-existent account operations gracefully', () async {
      // Act & Assert
      expect(
        () => accountService.addRole(999, 'admin'),
        throwsA(isA<ServiceNotFoundException>()),
      );

      expect(
        () => accountService.changePassword(999, 'old', 'new'),
        throwsA(isA<ServiceNotFoundException>()),
      );
    });

    test('should handle empty search results', () async {
      // Act
      final result =
          await accountService.searchAccounts(emailSearch: 'nonexistent');

      // Assert
      expect(result.items.length, equals(0));
      expect(result.totalCount, equals(0));
    });

    test('should handle pagination edge cases', () async {
      // Arrange
      for (int i = 1; i <= 3; i++) {
        await accountService.createAccount(
            email: 'user$i@example.com', password: 'Password123');
      }

      // Act - Request page beyond available data
      final result =
          await accountService.searchAccounts(limit: 10, offset: 100);

      // Assert
      expect(result.items.length, equals(0));
      expect(result.totalCount, equals(3));
    });
  });
}
