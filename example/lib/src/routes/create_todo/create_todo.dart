import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/shelf_helpers.dart';
import 'package:shelf_helpers_example/src/models/network/post/post_todo.dart';
import 'package:shelf_helpers_example/src/models/network/todo.dart';
import 'package:sqlite3/sqlite3.dart';

Todo handler(Request request, PostTodo createTodo) {
  final database = request.get<Database>();
  final results = database.select(
    'INSERT INTO todos (title, createDate, doneDate, status) VALUES (?, ?, ?, ?) RETURNING (id, title, createDate, doneDate, status)',
    [
      createTodo.title,
      DateTime.now().toUtc().toIso8601String(),
      null,
      TodoStatus.waiting.name
    ],
  );
  return results.map((e) => Todo.fromJson(e)).toList().first;
}
