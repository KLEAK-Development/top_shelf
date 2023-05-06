import 'dart:convert';

abstract class NetworkObject {}

abstract class NetworkObjectToJson extends NetworkObject {
  String toJsonString();
}

abstract class NetworkObjectToXml extends NetworkObject {
  String toXmlString();
}

class BadRequest extends NetworkObjectToJson {
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
}
