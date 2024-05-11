import 'package:shelf/shelf.dart';
import 'package:top_shelf/top_shelf.dart';
import 'package:shelf_helpers_example/src/models/network/post/post_todo.dart';
import 'package:shelf_helpers_example/src/models/network/todo.dart';
import 'package:shelf_helpers_example/src/repositories/todos.dart';

Todo handler(Request request, PostTodo createTodo) {
  final todosRepository = request.get<TodosRepository>();
  final results = todosRepository.create(createTodo.title);
  return results.map((e) => Todo.fromJson(e)).toList().first;
}
