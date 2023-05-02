import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/shelf_helpers.dart';
import 'package:shelf_helpers_example/src/models/network/todo_id_path_parameters.dart';

import 'package:shelf_helpers_example/src/routes/delete_todo/delete_todo.dart'
    as delete_todo;

Response handler(Request request) {
  delete_todo.handler(request, request.get<TodoIdPathParameter>());
  return Response(HttpStatus.noContent);
}
