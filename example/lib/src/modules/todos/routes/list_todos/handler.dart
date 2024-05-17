import 'package:shelf/shelf.dart';
import 'package:top_shelf/top_shelf.dart';
import 'package:top_shelf_example/src/modules/todos/routes/list_todos/list_todos.dart'
    as list_todos;

Response handler(Request request) {
  final object = list_todos.handler(request);
  return generateResponse(request, object);
}
