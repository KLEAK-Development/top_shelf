import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

String _defaultJwtSecretKeyFactory() {
  final secretKey = Platform.environment['JWT_SECRET_KEY'];
  if (secretKey == null) {
    throw Exception("JWT_SECRET_KEY environment variable is not set");
  }
  return secretKey;
}

class JsonWebToken {
  final String Function() secretKeyFactory;

  String _jwt = '';
  Map<String, dynamic> _header = {"alg": "HS256", "typ": "JWT"};
  Map<String, dynamic> _payload = {};

  JsonWebToken({this.secretKeyFactory = _defaultJwtSecretKeyFactory});

  JsonWebToken.parse(String jwt)
      : secretKeyFactory = _defaultJwtSecretKeyFactory {
    _jwt = jwt;
    final parts = jwt.split('.');

    final encodedHeader = parts[0];
    _header = json.decode(utf8.decode(base64Url.decode(encodedHeader)));

    final encodedPayload = parts[1];
    _payload = json.decode(utf8.decode(base64Url.decode(encodedPayload)));
  }

  String get sub => _payload['sub'];
  String get iat => _payload['iat'];
  String get exp => _payload['exp'];

  Map<String, dynamic> get payload => _payload;

  void createPayload(
    String userId, {
    Map<String, dynamic>? payload,
    Duration expireIn = const Duration(hours: 1),
  }) {
    _payload = {
      'sub': userId,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp': DateTime.now().add(expireIn).millisecondsSinceEpoch ~/ 1000,
      ...?payload,
    };
  }

  String sign() {
    final secretKey = secretKeyFactory();
    final encodedHeader = base64Url.encode(utf8.encode(json.encode(_header)));
    final encodedPayload = base64Url.encode(utf8.encode(json.encode(_payload)));

    final signature = Hmac(sha256, utf8.encode(secretKey))
        .convert(utf8.encode('$encodedHeader.$encodedPayload'))
        .bytes;

    final encodedSignature = base64Url.encode(signature);

    _jwt = '$encodedHeader.$encodedPayload.$encodedSignature';
    return _jwt;
  }

  bool verify() {
    try {
      final parts = _jwt.split('.');
      if (parts.length != 3) {
        return false; // Invalid token format
      }

      final encodedHeader = parts[0];
      final encodedPayload = parts[1];
      final encodedSignature = parts[2];

      // 1. Verify Signature:
      final secretKey = secretKeyFactory();
      final expectedSignature = base64Url.encode(
          Hmac(sha256, utf8.encode(secretKey))
              .convert(utf8.encode('$encodedHeader.$encodedPayload'))
              .bytes);

      if (expectedSignature != encodedSignature) {
        return false; // Invalid signature
      }

      // 2. Check Expiration:
      final payload =
          json.decode(utf8.decode(base64Url.decode(encodedPayload)));
      final expirationTimestamp =
          payload['exp'] as int?; // Get expiration timestamp

      if (expirationTimestamp == null) {
        return false; // Missing expiration claim
      }

      final expirationDate =
          DateTime.fromMillisecondsSinceEpoch(expirationTimestamp * 1000);
      return expirationDate.isAfter(DateTime.now()); // True if still valid
    } catch (e) {
      // Handle exceptions (e.g., invalid token format)
      return false;
    }
  }
}

// String generateJwtToken(String userId,
//     {Map<String, dynamic>? additionalPayload,
//     String Function() getJwtSecretKey = _defaultJwtSecretKeyFactory}) {
//   final secretKey = getJwtSecretKey();

//   // Create the payload (claims)
//   final claims = {
//     'sub': userId,
//     'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
//     'exp':
//         DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch ~/
//             1000,
//     ...?additionalPayload,
//   };

//   final encodedHeader = base64Url
//       .encode(utf8.encode(json.encode({'alg': 'HS256', 'typ': 'JWT'})));
//   final encodedPayload = base64Url.encode(utf8.encode(json.encode(claims)));

//   final signature = Hmac(sha256, utf8.encode(secretKey))
//       .convert(utf8.encode('$encodedHeader.$encodedPayload'))
//       .bytes;

//   final encodedSignature = base64Url.encode(signature);

//   return '$encodedHeader.$encodedPayload.$encodedSignature';
// }

// bool verifyJwtToken(String token, String secretKey) {
//   try {
//     final parts = token.split('.');
//     if (parts.length != 3) {
//       return false; // Invalid token format
//     }

//     final encodedHeader = parts[0];
//     final encodedPayload = parts[1];
//     final encodedSignature = parts[2];

//     // 1. Verify Signature:
//     final expectedSignature = base64Url.encode(
//         Hmac(sha256, utf8.encode(secretKey))
//             .convert(utf8.encode('$encodedHeader.$encodedPayload'))
//             .bytes);

//     if (expectedSignature != encodedSignature) {
//       return false; // Invalid signature
//     }

//     // 2. Check Expiration:
//     final payload = json.decode(utf8.decode(base64Url.decode(encodedPayload)));
//     final expirationTimestamp =
//         payload['exp'] as int?; // Get expiration timestamp

//     if (expirationTimestamp == null) {
//       return false; // Missing expiration claim
//     }

//     final expirationDate =
//         DateTime.fromMillisecondsSinceEpoch(expirationTimestamp * 1000);
//     return expirationDate.isAfter(DateTime.now()); // True if still valid
//   } catch (e) {
//     // Handle exceptions (e.g., invalid token format)
//     return false;
//   }
// }
