import 'package:top_shelf_example/src/modules/todos/models/todo.dart';
import 'package:top_shelf/top_shelf.dart';
import 'package:xml/xml.dart';

class TodoList implements NetworkObjectToJson, NetworkObjectToXml {
  final List<Todo> todos;

  TodoList(this.todos);

  @override
  List<Map<String, dynamic>> toJson() => todos.map((e) => e.toJson()).toList();

  @override
  XmlDocument toXml() {
    final builder = XmlBuilder();
    builder.element('TodoList', nest: () {
      for (final todo in todos) {
        builder.xml(todo.toXml().toXmlString());
      }
    });
    return builder.buildDocument();
  }
}
