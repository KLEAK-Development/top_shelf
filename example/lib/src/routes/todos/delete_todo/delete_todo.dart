import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/shelf_helpers.dart';
import 'package:shelf_helpers_example/src/repositories/todos.dart';

void handler(Request request, int id) {
  final todosRepository = request.get<TodosRepository>();
  todosRepository.delete(id);
}
