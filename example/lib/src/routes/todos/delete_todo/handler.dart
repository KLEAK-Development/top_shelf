import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:top_shelf/top_shelf.dart';
import 'package:shelf_helpers_example/src/models/network/todo_id_path_parameters.dart';
import 'package:shelf_helpers_example/src/routes/todos/delete_todo/delete_todo.dart'
    as delete_todo;

Response handler(Request request) {
  delete_todo.handler(request, request.get<TodoIdPathParameter>());
  return Response(HttpStatus.noContent);
}
