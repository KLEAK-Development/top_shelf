import 'dart:convert';

import 'package:top_shelf/src/internal/network_object.dart';

class Token implements NetworkObjectToJson {
  final String token;

  Token(this.token);

  Map<String, dynamic> toJson() {
    return {
      'token': token,
    };
  }

  @override
  String toJsonString() => json.encode(toJson());
}
