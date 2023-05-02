import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/shelf_helpers.dart';
import 'package:test/test.dart';

import '../utils.dart';

class User implements NetworkObjectToJson {
  final String name;
  final int age;

  const User(this.name, this.age);

  Map<String, dynamic> toJson() => {'name': name, 'age': age};

  @override
  String toJsonString() => json.encode(toJson());
}

class UserBody extends Body<User> {
  const UserBody(super.data);

  @override
  User parse() {
    return User(data['name'], data['age']);
  }
}

void main() {
  test('form urlencoded', () async {
    final handler = const Pipeline()
        .addMiddleware(
            getBody<UserBody>((body) => UserBody(body), objectName: ''))
        .addMiddleware(parseBody<User, UserBody>())
        .addHandler(
            (request) => Response.ok(request.get<User>().toJsonString()));

    final response = await makeRequest(
      handler,
      method: 'POST',
      body: 'name=kleak&age=25',
      headers: {
        HttpHeaders.contentTypeHeader: 'application/x-www-form-urlencoded'
      },
    );
    expect(response.statusCode, 200);
    final body = json.decode(await response.readAsString());
    expect(body['name'], equals('kleak'));
    expect(body['age'], equals(25));
  });

  test('json', () async {
    final handler = const Pipeline()
        .addMiddleware(getBody((body) => UserBody(body), objectName: ''))
        .addMiddleware(parseBody<User, UserBody>())
        .addHandler(
            (request) => Response.ok(request.get<User>().toJsonString()));

    final response = await makeRequest(
      handler,
      method: 'POST',
      body: json.encode({'name': 'kleak', 'age': 25}),
      headers: {HttpHeaders.contentTypeHeader: 'application/json'},
    );
    expect(response.statusCode, 200);
    final body = json.decode(await response.readAsString());
    expect(body['name'], equals('kleak'));
    expect(body['age'], equals(25));
  });
}
