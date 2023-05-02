import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/shelf_helpers.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';
import 'package:xml2json/xml2json.dart';

class User implements NetworkObjectToJson, NetworkObjectToXml {
  Map<String, dynamic> toJson() {
    return {
      'name': 'kleak',
      'age': 25,
    };
  }

  @override
  String toJsonString() => json.encode(toJson());

  @override
  String toXmlString() {
    final builder = XmlBuilder();
    builder.element('User', nest: () {
      builder.element('name', nest: () {
        builder.text('kleak');
      });
      builder.element('age', nest: () {
        builder.text(25);
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
