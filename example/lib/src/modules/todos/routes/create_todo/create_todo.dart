import 'package:shelf/shelf.dart';
import 'package:top_shelf/top_shelf.dart';
import 'package:top_shelf_example/src/modules/todos/routes/create_todo/models/post_todo.dart';
import 'package:top_shelf_example/src/modules/todos/models/todo.dart';
import 'package:top_shelf_example/src/modules/todos/repositories/todos.dart';

Todo handler(Request request, PostTodo createTodo) {
  final todosRepository = request.get<TodosRepository>();
  final results = todosRepository.create(createTodo.title);
  return results.map((e) => Todo.fromJson(e)).toList().first;
}
