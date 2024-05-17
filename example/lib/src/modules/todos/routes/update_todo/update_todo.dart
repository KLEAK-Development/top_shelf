import 'package:shelf/shelf.dart';
import 'package:shelf_helpers_example/src/modules/todos/models/todo.dart';
import 'package:shelf_helpers_example/src/modules/todos/repositories/todos.dart';
import 'package:shelf_helpers_example/src/modules/todos/routes/update_todo/models/put_todo.dart';
import 'package:top_shelf/top_shelf.dart';

Todo handler(Request request, int id, PutTodo updateTodo) {
  final todosRepository = request.get<TodosRepository>();
  if (updateTodo.status != TodoStatus.done) {
    return _updateTodo(todosRepository, id, updateTodo);
  }
  return _completeTodo(todosRepository, id, updateTodo);
}

Todo _updateTodo(TodosRepository todosRepository, int id, PutTodo updateTodo) {
  final results = todosRepository.update(
    id,
    updateTodo.title,
    updateTodo.status.name,
  );
  return results.map((e) => Todo.fromJson(e)).toList().first;
}

Todo _completeTodo(
    TodosRepository todosRepository, int id, PutTodo updateTodo) {
  var results = todosRepository.getById(id);
  final todo = Todo.fromJson(results.first);
  if (todo.status == TodoStatus.done) {
    return todo;
  }
  results = todosRepository.update(
    id,
    updateTodo.title,
    updateTodo.status.name,
    doneDate: todo.doneDate ?? DateTime.now().toUtc(),
  );
  return results.map((e) => Todo.fromJson(e)).toList().first;
}
