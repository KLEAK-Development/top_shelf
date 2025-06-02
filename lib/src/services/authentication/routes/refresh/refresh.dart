import 'package:shelf/shelf.dart';
import 'package:top_shelf/src/internal/jwt.dart';
import 'package:top_shelf/src/internal/request.dart';
import 'package:top_shelf/src/services/authentication/models/tokens.dart';
import 'package:top_shelf/src/services/common/services/account/account_service_interface.dart';

Future<Tokens> handler(Request request) async {
  final refreshToken = request.get<JsonWebToken>();
  final service = request.get<AccountServiceInterface>();
  
  // Use the AccountService to handle token refresh logic
  return await service.refreshTokens(refreshToken.jwt);
}
