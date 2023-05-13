import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/shelf_helpers.dart';
import 'package:shelf_helpers_example/src/models/network/post/post_todo.dart';
import 'package:shelf_helpers_example/src/routes/todos/create_todo/create_todo.dart'
    as create_todo;

Response handler(Request request) {
  final object = create_todo.handler(request, request.get<PostTodo>());
  return generateResponse(request, object, status: HttpStatus.created);
}
