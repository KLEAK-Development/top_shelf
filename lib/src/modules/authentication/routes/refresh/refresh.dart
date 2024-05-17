import 'package:shelf/shelf.dart';
import 'package:top_shelf/src/internal/jwt.dart';
import 'package:top_shelf/src/internal/request.dart';
import 'package:top_shelf/src/modules/authentication/models/network/tokens.dart';

Future<Tokens> handler(Request request) async {
  final refreshToken = request.get<JsonWebToken>();
  final userId = refreshToken.sub;

  var jwt = JsonWebToken();
  jwt.createPayload(userId);
  final accessToken = jwt.sign();

  jwt = JsonWebToken();
  jwt.createPayload(userId, expireIn: Duration(days: 30));
  final newRefreshToken = jwt.sign();

  return Tokens(accessToken, newRefreshToken);
}
