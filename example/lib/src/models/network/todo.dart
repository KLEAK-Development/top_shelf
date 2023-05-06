import 'dart:convert';

import 'package:shelf_helpers/shelf_helpers.dart';
import 'package:xml/xml.dart';

enum TodoStatus {
  waiting,
  working,
  done,
}

class Todo implements NetworkObjectToJson, NetworkObjectToXml {
  final int id;
  final String title;
  final DateTime createDate;
  final DateTime? doneDate;
  final TodoStatus status;

  Todo(this.id, this.title, this.createDate, this.doneDate, this.status);

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      json['id'],
      json['title'],
      DateTime.parse(json['createDate']),
      json['doneDate'] != null ? DateTime.parse(json['doneDate']) : null,
      TodoStatus.values.firstWhere((element) => element.name == json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createDate': createDate.toIso8601String(),
      if (doneDate != null) 'doneDate': doneDate!.toIso8601String(),
      'status': status.name,
    };
  }

  @override
  String toJsonString() => json.encode(toJson());

  @override
  String toXmlString() {
    final builder = XmlBuilder();
    builder.element('Todo', nest: () {
      builder.element('id', nest: () {
        builder.text(id);
      });
      builder.element('title', nest: () {
        builder.text(title);
      });
      builder.element('createDate', nest: () {
        builder.text(createDate.toUtc().toIso8601String());
      });
      if (doneDate != null) {
        builder.element('doneDate', nest: () {
          builder.text(doneDate!.toUtc().toIso8601String());
        });
      }
      builder.element('status', nest: () {
        builder.text(status.name);
      });
    });
    return builder.buildDocument().toXmlString();
  }
}
