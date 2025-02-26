import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:top_shelf/top_shelf.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';
import 'package:xml2json/xml2json.dart';

class User implements NetworkObjectToJson, NetworkObjectToXml {
  final String name = 'kleak';
  final int age = 25;

  @override
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
    };
  }

  @override
  XmlDocument toXml() {
    final builder = XmlBuilder();
    builder.element('User', nest: () {
      builder.element('name', nest: () {
        builder.text(name);
      });
      builder.element('age', nest: () {
        builder.text(age.toString());
      });
    });
    return builder.buildDocument();
  }
}

void main() {
  group('generateResponse', () {
    test('default', () async {
      final response = generateResponse(
          Request('GET', Uri.parse('http://localhost/')), User());
      final body = await response.readAsString();
      final data = json.decode(body);
      expect(data['name'], equals('kleak'));
      expect(data['age'], equals(25));
    });

    test('json', () async {
      final response = generateResponse(
          Request(
            'GET',
            Uri.parse('http://localhost/'),
            headers: {
              HttpHeaders.acceptHeader: 'application/json',
            },
          ),
          User());
      final body = await response.readAsString();
      final data = json.decode(body);
      expect(data['name'], equals('kleak'));
      expect(data['age'], equals(25));
    });

    test('xml', () async {
      final response = generateResponse(
        Request(
          'GET',
          Uri.parse('http://localhost/'),
          headers: {
            HttpHeaders.acceptHeader: 'application/xml',
          },
        ),
        User(),
      );
      final body = await response.readAsString();
      final transformer = Xml2Json()..parse(body);
      final data = json.decode(transformer.toParker())['User'];
      expect(data['name'], equals('kleak'));
      expect(data['age'], equals('25'));
    });

    test('unsupported accept', () async {
      final response = generateResponse(
        Request(
          'GET',
          Uri.parse('http://localhost/'),
          headers: {
            HttpHeaders.acceptHeader: 'text/plain',
          },
        ),
        User(),
      );

      expect(response.statusCode, HttpStatus.badRequest);
    });
  });

  group('generateJsonReponseList', () {
    test('json list', () async {
      final response = generateJsonReponseList(
        Request(
          'GET',
          Uri.parse('http://localhost/'),
          headers: {
            HttpHeaders.acceptHeader: 'application/json',
          },
        ),
        [User()],
      );

      final body = await response.readAsString();
      final data = json.decode(body);

      expect(response.statusCode, HttpStatus.ok);
      expect(data, isA<List>());
    });
  });

  group('BadRequest', () {
    test('should use status code from BadRequest object', () async {
      final badRequest = BadRequest(
        'about:blank',
        'Invalid input',
        'The provided data is invalid',
        HttpStatus.unprocessableEntity,
        'http://localhost:8080/bad-request',
      );

      final response = generateResponse(
        Request(
          'GET',
          Uri.parse('http://localhost:8080/bad-request'),
          headers: {
            HttpHeaders.acceptHeader: 'application/json',
          },
        ),
        badRequest,
      );

      expect(response.statusCode, HttpStatus.unprocessableEntity);

      final body = await response.readAsString();
      final data = json.decode(body);

      expect(data['type'], equals('about:blank'));
      expect(data['title'], equals('Invalid input'));
      expect(data['details'], equals('The provided data is invalid'));
      expect(data['status'], equals(HttpStatus.unprocessableEntity));
      expect(
        response.headers[HttpHeaders.contentTypeHeader],
        equals('application/problem+json'),
      );
      expect(data['instance'], equals('http://localhost:8080/bad-request'));
    });

    test('should handle BadRequest with XML format', () async {
      final badRequest = BadRequest(
        'about:blank',
        'Invalid input',
        'The provided data is invalid',
        HttpStatus.unprocessableEntity,
        'http://localhost:8080/bad-request',
      );

      final response = generateResponse(
        Request(
          'GET',
          Uri.parse('http://localhost:8080/bad-request'),
          headers: {
            HttpHeaders.acceptHeader: 'application/xml',
          },
        ),
        badRequest,
      );

      expect(response.statusCode, HttpStatus.unprocessableEntity);

      final body = await response.readAsString();
      final transformer = Xml2Json()..parse(body);
      final data = json.decode(transformer.toParker())['BadRequest'];

      expect(data['type'], equals('about:blank'));
      expect(data['title'], equals('Invalid input'));
      expect(data['details'], equals('The provided data is invalid'));
      expect(data['status'], equals('422'));
      expect(
        response.headers[HttpHeaders.contentTypeHeader],
        equals('application/problem+xml'),
      );
      expect(data['instance'], equals('http://localhost:8080/bad-request'));
    });
  });
}
