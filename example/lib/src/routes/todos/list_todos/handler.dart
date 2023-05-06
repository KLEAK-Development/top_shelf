import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/shelf_helpers.dart';
import 'package:shelf_helpers_example/src/routes/todos/list_todos/list_todos.dart'
    as list_todos;

Response handler(Request request) {
  final object = list_todos.handler(request);
  return generateResponse(request, object);
}
