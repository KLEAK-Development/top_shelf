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

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
    };
  }

  @override
  String toJsonString() => json.encode(toJson());

  @override
  String toXmlString() {
    final builder = XmlBuilder();
    builder.element('User', nest: () {
      builder.element('name', nest: () {
        builder.text(name);
      });
      builder.element('age', nest: () {
        builder.text(age.toString());
      });
    });
    return builder.buildDocument().toXmlString();
  }
}

void main() {
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
}
