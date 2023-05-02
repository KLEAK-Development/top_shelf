import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/shelf_helpers.dart';
import 'package:shelf_helpers_example/src/models/network/put/put_todo.dart';
import 'package:shelf_helpers_example/src/models/network/todo.dart';
import 'package:sqlite3/sqlite3.dart';

Todo handler(Request request, int id, PutTodo updateTodo) {
  if (updateTodo.status != TodoStatus.done) {
    return _updateTodo(request, id, updateTodo);
  }
  return _completeTodo(request, id, updateTodo);
}

Todo _updateTodo(Request request, int id, PutTodo updateTodo) {
  final database = request.get<Database>();
  final results = database.select(
    'UPDATE todos SET title = ?, status = ?, doneDate = ? WHERE id = ? RETURNING id, title, createDate, doneDate, status',
    [updateTodo.title, updateTodo.status.name, null, id],
  );
  return results.map((e) => Todo.fromJson(e)).toList().first;
}

Todo _completeTodo(Request request, int id, PutTodo updateTodo) {
  final database = request.get<Database>();
  var results = database.select(
    'SELECT id, title, createDate, doneDate, status FROM todos WHERE id = ?',
    [id],
  );
  final todo = results.map((e) => Todo.fromJson(e)).toList().first;
  results = database.select(
    'UPDATE todos SET title = ?, status = ?, doneDate = ? WHERE id = ? RETURNING id, title, createDate, doneDate, status',
    [
      updateTodo.title,
      updateTodo.status.name,
      todo.doneDate?.toUtc().toIso8601String() ??
          DateTime.now().toUtc().toIso8601String(),
      id
    ],
  );
  return results.map((e) => Todo.fromJson(e)).toList().first;
}
