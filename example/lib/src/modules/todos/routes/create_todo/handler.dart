import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:top_shelf/top_shelf.dart';
import 'package:shelf_helpers_example/src/modules/todos/routes/create_todo/models/post_todo.dart';
import 'package:shelf_helpers_example/src/modules/todos/routes/create_todo/create_todo.dart'
    as create_todo;

Response handler(Request request) {
  final object = create_todo.handler(request, request.get<PostTodo>());
  return generateResponse(request, object, status: HttpStatus.created);
}
