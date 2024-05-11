import 'package:shelf/shelf.dart';
import 'package:top_shelf/top_shelf.dart';
import 'package:shelf_helpers_example/src/models/network/todo.dart';
import 'package:shelf_helpers_example/src/models/network/todo_list.dart';
import 'package:shelf_helpers_example/src/repositories/todos.dart';

TodoList handler(Request request) {
  final todosRepository = request.get<TodosRepository>();
  final status = request.url.queryParameters['status'] ?? 'all';
  final results = todosRepository.getByStatus(status);
  return TodoList(results.map((e) => Todo.fromJson(e)).toList());
}
