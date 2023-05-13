import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_helpers_example/src/routes/todos/delete_all_todo/delete_all_todo.dart'
    as delete_all_todo;

Response handler(Request request) {
  delete_all_todo.handler(request);
  return Response(HttpStatus.ok);
}
