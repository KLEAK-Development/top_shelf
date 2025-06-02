import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:top_shelf/top_shelf.dart';
import 'package:top_shelf/src/services/accounts/routes/change_password/handler.dart'
    as change_password;
import 'package:top_shelf/src/services/accounts/routes/change_password/middleware.dart'
    as change_password;

import '../../../utils.dart';

String jwtSecretKeyFactory() => 'test-jwt';

void main() {
  group('Change Password Route', () {
    late AccountService accountService;
    late Handler handler;

    setUp(() async {
      // Create in-memory repository and service for testing
      final repository = AccountMemoryRepository();
      accountService = AccountService(
        repository,
        pepperFactory: () => 'test-pepper',
        jwtSecretFactory: jwtSecretKeyFactory,
      );

      // Create handler with middleware
      handler = Pipeline()
          .addMiddleware(
              provide<AccountServiceInterface>((_) => accountService))
          .addMiddleware(
              change_password.middleware(secretKeyFactory: jwtSecretKeyFactory))
          .addHandler(change_password.handler);
    });

    test('should change password with valid JWT and correct current password',
        () async {
      // Arrange
      const email = 'test@example.com';
      const currentPassword = 'CurrentPassword123';
      const newPassword = 'NewPassword456';

      // Create test account
      final account = await accountService.createAccount(
        email: email,
        password: currentPassword,
      );

      final tokens = await accountService.login(account);

      final requestBody = {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      };

      // Act
      final response = await makeRequest(
        handler,
        method: 'PUT',
        body: json.encode(requestBody),
        headers: {
          'content-type': 'application/json',
          'authorization': 'Bearer ${tokens.accessToken}',
        },
      );

      // Assert
      expect(response.statusCode, HttpStatus.ok);

      final responseBody = await response.readAsString();
      final responseJson = json.decode(responseBody);
      expect(responseJson['email'], email);
      expect(responseJson['id'], account.id);

      // Verify password was actually changed by trying to authenticate with new password
      final authenticatedAccount =
          await accountService.authenticate(email, newPassword);
      expect(authenticatedAccount, isNotNull);
      expect(authenticatedAccount!.id, account.id);

      // Verify old password no longer works
      final oldPasswordAuth =
          await accountService.authenticate(email, currentPassword);
      expect(oldPasswordAuth, isNull);
    });

    test('should return 401 when no authorization header provided', () async {
      // Arrange
      final requestBody = {
        'currentPassword': 'current',
        'newPassword': 'new',
      };

      // Act
      final response = await makeRequest(
        handler,
        method: 'PUT',
        body: json.encode(requestBody),
        headers: {'content-type': 'application/json'},
      );

      // Assert
      expect(response.statusCode, HttpStatus.unauthorized);
    });

    test('should return 401 when invalid JWT token provided', () async {
      // Arrange
      final requestBody = {
        'currentPassword': 'current',
        'newPassword': 'new',
      };

      // Act
      final response = await makeRequest(
        handler,
        method: 'PUT',
        body: json.encode(requestBody),
        headers: {
          'content-type': 'application/json',
          'authorization': 'Bearer invalid-token',
        },
      );

      // Assert
      expect(response.statusCode, HttpStatus.unauthorized);
    });

    test('should return 400 when current password is incorrect', () async {
      // Arrange
      const email = 'test@example.com';
      const currentPassword = 'CurrentPassword123';
      const wrongPassword = 'WrongPassword';
      const newPassword = 'NewPassword456';

      // Create test account
      final account = await accountService.createAccount(
        email: email,
        password: currentPassword,
      );

      final tokens = await accountService.login(account);

      final requestBody = {
        'currentPassword': wrongPassword,
        'newPassword': newPassword,
      };

      // Act
      final response = await makeRequest(
        handler,
        method: 'PUT',
        body: json.encode(requestBody),
        headers: {
          'content-type': 'application/json',
          'authorization': 'Bearer ${tokens.accessToken}',
        },
      );

      // Assert
      expect(response.statusCode, HttpStatus.badRequest);
    });

    test('should return 400 when required fields are missing', () async {
      // Arrange
      const email = 'test@example.com';
      const currentPassword = 'CurrentPassword123';

      // Create test account
      final account = await accountService.createAccount(
        email: email,
        password: currentPassword,
      );

      final tokens = await accountService.login(account);

      final requestBody = {
        'currentPassword': currentPassword,
        // Missing newPassword
      };

      // Act
      final response = await makeRequest(
        handler,
        method: 'PUT',
        body: json.encode(requestBody),
        headers: {
          'content-type': 'application/json',
          'authorization': 'Bearer ${tokens.accessToken}',
        },
      );

      // Assert
      expect(response.statusCode, HttpStatus.badRequest);
    });
  });
}
