import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_helpers_example/src/modules/todos/models/identifiable.dart';
import 'package:top_shelf/top_shelf.dart';
import 'package:shelf_helpers_example/src/modules/todos/repositories/todos.dart';

void handler(Request request) {
  final todosRepository = request.get<TodosRepository>();
  todosRepository.deleteAll();
  Logger.root.fine('${request.get<Identifiable>().id} deleted all todos');
}
