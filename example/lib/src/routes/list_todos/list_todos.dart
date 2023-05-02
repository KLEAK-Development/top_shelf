import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/shelf_helpers.dart';
import 'package:shelf_helpers_example/src/models/network/todo.dart';
import 'package:shelf_helpers_example/src/models/network/todo_list.dart';
import 'package:sqlite3/sqlite3.dart';

TodoList handler(Request request) {
  final status = request.url.queryParameters['status'] ?? 'all';
  final sb = StringBuffer('SELECT * FROM todos');
  if (status != 'all') {
    sb.write(' WHERE status = ?');
  }

  final database = request.get<Database>();
  final results = database.select(
    sb.toString(),
    [
      if (status != 'all')
        TodoStatus.values.firstWhere((element) => element.name == status).name
    ],
  );
  return TodoList(results.map((e) => Todo.fromJson(e)).toList());
}
