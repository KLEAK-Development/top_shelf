import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:top_shelf/top_shelf.dart';
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
    final age =
        data['age'] is! num ? (int.tryParse(data['age']) ?? -1) : data['age'];
    return User(data['name'], age);
  }
}

void main() {
  test('x www form urlencoded', () async {
    final handler = const Pipeline()
        .addMiddleware(
            getBody<UserBody>((body) => UserBody(body), objectName: ''))
        .addMiddleware(parseBody<User, UserBody>())
        .addHandler(
            (request) => Response.ok(request.get<User>().toJsonString()));

    final response = await makeRequest(
      handler,
      method: 'POST',
      body: 'name=kleak%2084&age=25',
      headers: {
        HttpHeaders.contentTypeHeader: 'application/x-www-form-urlencoded'
      },
    );
    expect(response.statusCode, 200);
    final body = json.decode(await response.readAsString());
    expect(body['name'], equals('kleak 84'));
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

  test('xml', () async {
    final objectName = 'User';

    final handler = const Pipeline()
        .addMiddleware(
            getBody((body) => UserBody(body), objectName: objectName))
        .addMiddleware(parseBody<User, UserBody>())
        .addHandler(
            (request) => Response.ok(request.get<User>().toJsonString()));

    final response = await makeRequest(
      handler,
      method: 'POST',
      body: '''<?xml version="1.0" encoding="UTF-8"?>
<$objectName>
    <name>kleak</name>
    <age>25</age>
</$objectName>''',
      headers: {HttpHeaders.contentTypeHeader: 'application/xml'},
    );
    expect(response.statusCode, 200);
    final body = json.decode(await response.readAsString());
    expect(body['name'], equals('kleak'));
    expect(body['age'], equals(25));
  });

  test('form-data', () async {
    final handler = const Pipeline()
        .addMiddleware(getBody((body) => UserBody(body), objectName: ''))
        .addMiddleware(parseBody<User, UserBody>())
        .addHandler(
            (request) => Response.ok(request.get<User>().toJsonString()));

    final bodyFromFile = File('test/body.txt').readAsStringSync();

    final response = await makeRequest(
      handler,
      method: 'POST',
      body: bodyFromFile,
      headers: {
        HttpHeaders.contentTypeHeader:
            'multipart/form-data; boundary=--------------------------844627790734331649273621'
      },
    );
    expect(response.statusCode, 200);
    final body = json.decode(await response.readAsString());
    expect(body['name'], equals('kleak'));
    expect(body['age'], equals(25));
  });
}
