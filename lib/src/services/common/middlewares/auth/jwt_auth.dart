import 'package:shelf/shelf.dart';
import 'package:top_shelf/src/internal/jwt.dart';
import 'package:top_shelf/src/internal/request.dart';
import 'package:top_shelf/src/services/accounts/models/account.dart';
import 'package:top_shelf/src/services/common/services/account/account_service_interface.dart';

/// Middleware that validates JWT Bearer token and extracts the associated account
Middleware jwtAuth({String Function()? secretKeyFactory}) {
  return (handler) {
    return (request) async {
      final authHeader = request.headers['authorization'];

      // Check if Authorization header is present and starts with 'Bearer '
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response.unauthorized('Missing or invalid authorization header');
      }

      // Extract token from header
      final token = authHeader.substring('Bearer '.length);

      try {
        // Parse and verify JWT
        final jwt = JsonWebToken.parse(
          token,
          secretKeyFactory: secretKeyFactory,
        );
        if (!jwt.verify()) {
          return Response.unauthorized('Invalid or expired token');
        }

        // Extract user ID from token payload
        final userId = jwt.sub;
        if (userId == null || userId.isEmpty) {
          return Response.unauthorized('Invalid token payload');
        }

        // Get account service and fetch the account
        final accountService = request.get<AccountServiceInterface>();
        final accountId = int.tryParse(userId);
        if (accountId == null) {
          return Response.unauthorized('Invalid user ID in token');
        }

        try {
          final account = await accountService.getById(accountId);
          // Add account to request context
          return handler(request.set<Account>(() => account));
        } catch (e) {
          return Response.unauthorized('Account not found');
        }
      } catch (e) {
        return Response.unauthorized('Invalid token format');
      }
    };
  };
}
