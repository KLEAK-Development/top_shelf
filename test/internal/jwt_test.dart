import 'package:test/test.dart';
import 'dart:convert';
import 'package:top_shelf/src/internal/jwt.dart';

void main() {
  // Use a constant secret key for testing
  String getTestJwtSecretKey() => 'your_test_secret_key';

  test('JWT generation and verification', () {
    final userId = 'user123';
    final additionalPayload = {'name': 'Alice', 'role': 'admin'};

    final jwt = JsonWebToken(secretKeyFactory: getTestJwtSecretKey);
    jwt.createPayload(userId, payload: additionalPayload);
    // Sign and Generate the JWT
    jwt.sign();

    // Verify the token
    expect(jwt.verify(), isTrue);
  });

  test('JWT with invalid signature', () {
    final userId = 'user123';

    var jwt = JsonWebToken(secretKeyFactory: getTestJwtSecretKey);
    jwt.createPayload(userId);
    final token = jwt.sign();

    // Tamper with the token (change the payload)
    final parts = token.split('.');
    final tamperedPayload =
        base64Url.encode(utf8.encode(json.encode({'sub': 'invalid'})));
    final tamperedToken = '${parts[0]}.$tamperedPayload.${parts[2]}';

    jwt = JsonWebToken.parse(tamperedToken);

    // Verify the tampered token (should fail)
    expect(jwt.verify(), isFalse);
  });

  test('Expired JWT', () {
    final userId = 'user123';

    // Generate a token that expires in the past
    var jwt = JsonWebToken(secretKeyFactory: getTestJwtSecretKey);
    jwt.createPayload(userId, payload: {
      'exp': DateTime.now()
              .subtract(const Duration(hours: 1))
              .millisecondsSinceEpoch ~/
          1000
    });
    jwt.sign();

    // Verify the expired token (should fail)
    expect(jwt.verify(), isFalse);
  });
}
