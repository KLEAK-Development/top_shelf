import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:top_shelf_example/src/modules/todos/models/todo_id_path_parameters.dart';
import 'package:top_shelf/top_shelf.dart';
import 'package:top_shelf_example/src/modules/todos/routes/delete_todo/delete_todo.dart'
    as delete_todo;

Response handler(Request request) {
  delete_todo.handler(request, request.get<TodoIdPathParameter>());
  return Response(HttpStatus.noContent);
}
