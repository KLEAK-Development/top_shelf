import 'dart:convert';

import 'package:xml/xml.dart';

sealed class NetworkObject {}

abstract interface class NetworkObjectToJson extends NetworkObject {
  String toJsonString();
}

abstract interface class NetworkObjectToXml extends NetworkObject {
  String toXmlString();
}

final class BadRequest implements NetworkObjectToJson, NetworkObjectToXml {
  final String type;
  final String title;
  final String details;
  final int status;
  final String instance;
  final String? field;

  BadRequest(this.type, this.title, this.details, this.status, this.instance,
      {this.field});

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'details': details,
      'status': status,
      'instance': instance,
      if (field != null) 'field': field,
    };
  }

  @override
  String toJsonString() => json.encode(toJson());

  @override
  String toXmlString() {
    final builder = XmlBuilder();
    builder.element('BadRequest', nest: () {
      builder.element('type', nest: () {
        builder.text(type);
      });
      builder.element('title', nest: () {
        builder.text(title);
      });
      builder.element('details', nest: () {
        builder.text(details);
      });
      builder.element('status', nest: () {
        builder.text(status);
      });
      builder.element('instance', nest: () {
        builder.text(instance);
      });
      if (field != null) {
        builder.element('field', nest: () {
          builder.text(field!);
        });
      }
    });
    return builder.buildDocument().toXmlString();
  }
}
