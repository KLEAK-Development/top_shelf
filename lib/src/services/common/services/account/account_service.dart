import 'dart:async';
import 'package:logging/logging.dart';
import 'package:pbkdf2/pbkdf2.dart';
import 'package:top_shelf/src/services/accounts/models/account.dart';
import 'package:top_shelf/src/services/authentication/models/tokens.dart';
import 'package:top_shelf/src/services/common/pepper_factory.dart';
import 'package:top_shelf/src/services/common/repositories/account/account_repository_interface.dart';
import 'package:top_shelf/src/services/common/services/account/account_service_interface.dart';
import 'package:top_shelf/src/services/common/services/base_crud_service.dart';
import 'package:top_shelf/src/services/common/repositories/crud_repository.dart';
import 'package:top_shelf/src/internal/jwt.dart';

final _logger = Logger('AccountService');

class AccountService extends AbstractBaseService<Account, int>
    implements AccountServiceInterface {
  final AccountRepositoryInterface _accountRepository;
  final String Function() _pepperFactory;
  final String Function() _jwtSecretFactory;

  AccountService(
    this._accountRepository, {
    String Function()? pepperFactory,
    String Function()? jwtSecretFactory,
    Logger? logger,
  })  : _pepperFactory = pepperFactory ?? defaultPepperFactory,
        _jwtSecretFactory = jwtSecretFactory ?? defaultJwtSecretKeyFactory,
        super(_accountRepository);

  @override
  AccountRepositoryInterface get repository => _accountRepository;

  /// Creates a new account with email and password
  @override
  Future<Account> createAccount({
    required String email,
    required String password,
    List<String> roles = const ['user'],
  }) async {
    _logger.fine('Attempting to create account for email: $email');
    // Validate email format
    final emailValidation = _validateEmail(email);
    if (!emailValidation.isValid) {
      throw ServiceValidationException(emailValidation.errors);
    }

    // Validate password strength
    final passwordValidation = _validatePassword(password);
    if (!passwordValidation.isValid) {
      throw ServiceValidationException(passwordValidation.errors);
    }

    // Check if email is already taken
    if (await _accountRepository.isEmailTaken(email)) {
      throw ServiceValidationException(['Email is already taken']);
    }

    // Hash the password
    final hashedPassword = _hashPassword(password);

    try {
      final account = await _accountRepository.createAccountWithDefaults(
        email,
        hashedPassword,
        roles: roles,
      );
      _logger.fine(
          'Account created successfully: ID ${account.id}, Email: ${account.email}');
      return account;
    } on EntityConstraintException catch (e) {
      _logger.severe(
          'Account creation failed - constraint violation: ${e.message}');
      throw ServiceValidationException([e.message]);
    } on RepositoryException catch (e) {
      _logger
          .severe('Account creation failed - repository error: ${e.message}');
      throw ServiceException('Failed to create account', e);
    }
  }

  /// Authenticates user with email and password
  @override
  Future<Account?> authenticate(String email, String password) async {
    _logger.fine('Authentication attempt for email: $email');
    final account = await _accountRepository.findByEmail(email);
    if (account == null) {
      _logger.warning(
          'Authentication failed - account not found for email: $email');
      return null;
    }

    final pbkdf2 = Pbkdf2(pepperFactory: _pepperFactory);
    final isValidPassword = pbkdf2.verify(password, account.password);
    if (isValidPassword) {
      _logger.info(
          'Authentication successful for email: $email, ID: ${account.id}');
      return account;
    } else {
      _logger.warning(
          'Authentication failed - invalid password for email: $email');
      return null;
    }
  }

  /// Generates JWT tokens for an authenticated account
  @override
  Future<Tokens> login(Account account) async {
    _logger.fine('Generating login tokens for account ID: ${account.id}');

    // Create access token (short-lived)
    var jwt = JsonWebToken(secretKeyFactory: _jwtSecretFactory);
    jwt.createPayload(account.id.toString());
    final accessToken = jwt.sign();

    // Create refresh token (long-lived)
    jwt = JsonWebToken(secretKeyFactory: _jwtSecretFactory);
    jwt.createPayload(account.id.toString(), expireIn: Duration(days: 30));
    final refreshToken = jwt.sign();

    _logger.info(
        'Login tokens generated successfully for account ID: ${account.id}');
    return Tokens(accessToken, refreshToken);
  }

  /// Refreshes JWT tokens using a valid refresh token
  @override
  Future<Tokens> refreshTokens(String refreshToken) async {
    _logger.fine('Attempting to refresh tokens');
    try {
      // Parse and validate the refresh token
      final jwt =
          JsonWebToken.parse(refreshToken, secretKeyFactory: _jwtSecretFactory);
      if (!jwt.verify()) {
        _logger
            .warning('Token refresh failed - invalid or expired refresh token');
        throw ServiceValidationException(['Invalid or expired refresh token']);
      }

      // Extract user ID from the refresh token
      final userId = jwt.sub;
      if (userId == null || userId.isEmpty) {
        _logger
            .severe('Token refresh failed - missing user ID in refresh token');
        throw ServiceValidationException(
            ['Invalid refresh token: missing user ID']);
      }

      // Verify the account still exists
      final accountId = int.tryParse(userId);
      if (accountId == null) {
        _logger
            .severe('Token refresh failed - invalid user ID format: $userId');
        throw ServiceValidationException(
            ['Invalid refresh token: invalid user ID format']);
      }

      final account = await _accountRepository.findById(accountId);
      if (account == null) {
        _logger.warning(
            'Token refresh failed - account not found for ID: $accountId');
        throw ServiceNotFoundException('Account not found', accountId);
      }

      // Generate new tokens
      var newJwt = JsonWebToken(secretKeyFactory: _jwtSecretFactory);
      newJwt.createPayload(userId);
      final accessToken = newJwt.sign();

      newJwt = JsonWebToken(secretKeyFactory: _jwtSecretFactory);
      newJwt.createPayload(userId, expireIn: Duration(days: 30));
      final newRefreshToken = newJwt.sign();

      _logger.info('Token refresh successful for account ID: $accountId');
      return Tokens(accessToken, newRefreshToken);
    } catch (e) {
      if (e is ServiceValidationException || e is ServiceNotFoundException) {
        rethrow;
      }
      // Handle JWT parsing/verification errors
      _logger
          .severe('Token refresh failed - JWT parsing/verification error: $e');
      throw ServiceValidationException(['Invalid or expired refresh token']);
    }
  }

  /// Changes user password
  @override
  Future<Account> changePassword(
      int accountId, String currentPassword, String newPassword) async {
    try {
      final account = await getById(accountId);

      // Verify current password
      final pbkdf2 = Pbkdf2(pepperFactory: _pepperFactory);
      if (!pbkdf2.verify(currentPassword, account.password)) {
        throw ServiceValidationException(['Current password is incorrect']);
      }

      // Validate new password
      final passwordValidation = _validatePassword(newPassword);
      if (!passwordValidation.isValid) {
        throw ServiceValidationException(passwordValidation.errors);
      }

      final hashedNewPassword = _hashPassword(newPassword);
      return await _accountRepository.updatePassword(
          accountId, hashedNewPassword);
    } on EntityNotFoundException catch (_) {
      throw ServiceNotFoundException('Account not found', accountId);
    } on RepositoryException catch (e) {
      throw ServiceException('Failed to change password', e);
    }
  }

  /// Adds a role to an account
  @override
  Future<Account> addRole(int accountId, String role) async {
    _validateRole(role);
    try {
      return await _accountRepository.addRole(accountId, role);
    } on EntityNotFoundException catch (_) {
      throw ServiceNotFoundException('Account not found', accountId);
    } on RepositoryException catch (e) {
      throw ServiceException('Failed to add role', e);
    }
  }

  /// Removes a role from an account
  @override
  Future<Account> removeRole(int accountId, String role) async {
    return await _accountRepository.removeRole(accountId, role);
  }

  /// Searches accounts with pagination
  @override
  Future<PagedResult<Account>> searchAccounts({
    String? emailSearch,
    String? roleFilter,
    int limit = 20,
    int offset = 0,
    bool orderByCreationDate = true,
  }) async {
    return await _accountRepository.searchAccounts(
      emailSearch: emailSearch,
      roleFilter: roleFilter,
      limit: limit,
      offset: offset,
      orderByCreationDate: orderByCreationDate,
    );
  }

  /// Gets account statistics
  @override
  Future<Map<String, dynamic>> getAccountStatistics() async {
    return await _accountRepository.getAccountStats();
  }

  /// Finds accounts by role
  @override
  Future<List<Account>> findAccountsByRole(String role) async {
    return await _accountRepository.findByRole(role);
  }

  /// Finds accounts created within date range
  @override
  Future<List<Account>> findAccountsByDateRange(
      DateTime startDate, DateTime endDate) async {
    return await _accountRepository.findByDateRange(startDate, endDate);
  }

  @override
  Future<ValidationResult> validate(Account entity) async {
    final errors = <String>[];

    // Validate email
    final emailValidation = _validateEmail(entity.email);
    if (!emailValidation.isValid) {
      errors.addAll(emailValidation.errors);
    }

    // Validate roles
    for (final role in entity.roles) {
      try {
        _validateRole(role);
      } catch (e) {
        errors.add('Invalid role: $role');
      }
    }

    // Check if email is unique (for new accounts)
    if (entity.id == 0) {
      if (await _accountRepository.isEmailTaken(entity.email)) {
        errors.add('Email is already taken');
      }
    }

    return errors.isEmpty
        ? ValidationResult.success()
        : ValidationResult.failure(errors);
  }

  @override
  Future<ValidationResult> validatePartialUpdate(
      Map<String, dynamic> fields) async {
    final errors = <String>[];

    if (fields.containsKey('email')) {
      final emailValidation = _validateEmail(fields['email'] as String);
      if (!emailValidation.isValid) {
        errors.addAll(emailValidation.errors);
      }
    }

    if (fields.containsKey('password')) {
      final passwordValidation =
          _validatePassword(fields['password'] as String);
      if (!passwordValidation.isValid) {
        errors.addAll(passwordValidation.errors);
      }
    }

    if (fields.containsKey('roles')) {
      final roles = fields['roles'] as String;
      for (final role in roles.split(',')) {
        try {
          _validateRole(role.trim());
        } catch (e) {
          errors.add('Invalid role: $role');
        }
      }
    }

    return errors.isEmpty
        ? ValidationResult.success()
        : ValidationResult.failure(errors);
  }

  @override
  Future<void> beforeCreate(Account entity) async {
    // Log account creation attempt
    _logger.info('Creating account for email: ${entity.email}');
  }

  @override
  Future<void> afterCreate(Account entity) async {
    // Log successful account creation
    _logger.info(
        'Account created successfully: ID ${entity.id}, Email: ${entity.email}');
  }

  @override
  Future<void> beforeDelete(Account entity) async {
    // Log account deletion
    _logger.info('Deleting account: ID ${entity.id}, Email: ${entity.email}');
  }

  @override
  Future<void> afterDelete(Account entity) async {
    // Log successful account deletion
    _logger.info('Account deleted successfully: ID ${entity.id}');
  }

  // Private helper methods

  String _hashPassword(String password) {
    final pbkdf2 = Pbkdf2(pepperFactory: _pepperFactory);
    final hashedPassword = pbkdf2.hash(password);
    return hashedPassword;
  }

  ValidationResult _validateEmail(String email) {
    final errors = <String>[];

    if (email.isEmpty) {
      errors.add('Email is required');
    } else {
      final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
      if (!emailRegex.hasMatch(email)) {
        errors.add('Invalid email format');
      }
    }

    return errors.isEmpty
        ? ValidationResult.success()
        : ValidationResult.failure(errors);
  }

  ValidationResult _validatePassword(String password) {
    final errors = <String>[];

    if (password.isEmpty) {
      errors.add('Password is required');
    } else {
      if (password.length < 8) {
        errors.add('Password must be at least 8 characters long');
      }
      if (!RegExp(r'[A-Z]').hasMatch(password)) {
        errors.add('Password must contain at least one uppercase letter');
      }
      if (!RegExp(r'[a-z]').hasMatch(password)) {
        errors.add('Password must contain at least one lowercase letter');
      }
      if (!RegExp(r'[0-9]').hasMatch(password)) {
        errors.add('Password must contain at least one number');
      }
    }

    return errors.isEmpty
        ? ValidationResult.success()
        : ValidationResult.failure(errors);
  }

  void _validateRole(String role) {
    const validRoles = ['admin', 'user', 'moderator', 'guest'];
    if (!validRoles.contains(role.toLowerCase())) {
      throw ArgumentError(
          'Invalid role: $role. Valid roles are: ${validRoles.join(', ')}');
    }
  }
}
