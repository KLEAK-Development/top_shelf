import 'package:shelf/shelf.dart';
import 'package:top_shelf/top_shelf.dart';
import 'package:top_shelf_example/src/modules/todos/repositories/todos.dart';

void handler(Request request, int id) {
  final todosRepository = request.get<TodosRepository>();
  todosRepository.delete(id);
}
