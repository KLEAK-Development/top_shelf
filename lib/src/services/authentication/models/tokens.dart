import 'package:top_shelf/src/internal/network_object.dart';

class Tokens implements NetworkObjectToJson {
  final String accessToken;
  final String refreshToken;

  Tokens(this.accessToken, this.refreshToken);

  @override
  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
    };
  }
}
