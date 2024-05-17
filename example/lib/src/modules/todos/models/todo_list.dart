import 'dart:convert';

import 'package:top_shelf_example/src/modules/todos/models/todo.dart';
import 'package:top_shelf/top_shelf.dart';
import 'package:xml/xml.dart';

class TodoList implements NetworkObjectToJson, NetworkObjectToXml {
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
