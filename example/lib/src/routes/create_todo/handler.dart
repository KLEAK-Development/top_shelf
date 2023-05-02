import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/shelf_helpers.dart';
import 'package:shelf_helpers_example/src/models/network/post/post_todo_body.dart';
import 'package:shelf_helpers_example/src/routes/create_todo/create_todo.dart'
    as create_todo;

Response handler(Request request) {
  final body = request.get<PostTodoBody>();
  final object = create_todo.handler(request, body.parse());
  return generateResponse(request, object);
}
