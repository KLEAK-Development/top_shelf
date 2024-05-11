import 'package:shelf/shelf.dart';
import 'package:top_shelf/top_shelf.dart';
import 'package:shelf_helpers_example/src/models/network/put/put_todo.dart';
import 'package:shelf_helpers_example/src/models/network/todo_id_path_parameters.dart';
import 'package:shelf_helpers_example/src/routes/todos/update_todo/update_todo.dart'
    as update_todo;

Response handler(Request request) {
  final object = update_todo.handler(
    request,
    request.get<TodoIdPathParameter>(),
    request.get<PutTodo>(),
  );
  return generateResponse(request, object);
}
