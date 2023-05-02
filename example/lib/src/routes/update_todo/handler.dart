import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/shelf_helpers.dart';
import 'package:shelf_helpers_example/src/models/network/put/put_todo_body.dart';
import 'package:shelf_helpers_example/src/models/network/todo_id_path_parameters.dart';
import 'package:shelf_helpers_example/src/routes/update_todo/update_todo.dart'
    as update_todo;

Response handler(Request request) {
  final body = request.get<PutTodoBody>();
  final object = update_todo.handler(
    request,
    request.get<TodoIdPathParameter>(),
    body.parse(),
  );
  return generateResponse(request, object);
}
