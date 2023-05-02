import 'dart:convert';

import 'package:shelf_helpers/shelf_helpers.dart';
import 'package:shelf_helpers_example/src/models/network/todo.dart';
import 'package:xml/xml.dart';

class TodoList implements JsonNetworkObject, XmlNetworkObject {
  final List<Todo> todos;

  TodoList(this.todos);

  @override
  String toJsonString() => json.encode(todos.map((e) => e.toJson()).toList());

  @override
  String toXmlString() {
    final builder = XmlBuilder();
    builder.element('TodoList', nest: () {
      for (final todo in todos) {
        builder.xml(todo.toXmlString());
      }
    });
    return builder.buildDocument().toXmlString();
  }
}
