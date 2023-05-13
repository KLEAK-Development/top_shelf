import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/shelf_helpers.dart';
import 'package:shelf_helpers_example/src/models/network/identifiable.dart';
import 'package:shelf_helpers_example/src/repositories/todos.dart';

void handler(Request request) {
  final todosRepository = request.get<TodosRepository>();
  todosRepository.deleteAll();
  Logger.root.fine('${request.get<Identifiable>().id} deleted all todos');
}
