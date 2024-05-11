import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:top_shelf/top_shelf.dart';
import 'package:shelf_helpers_example/src/middlewares/todos/check_todo_with_id_exist.dart';
import 'package:shelf_helpers_example/src/models/network/put/put_todo.dart';
import 'package:shelf_helpers_example/src/models/network/put/put_todo_body.dart';
import 'package:shelf_helpers_example/src/models/network/todo.dart';
import 'package:shelf_helpers_example/src/models/network/todo_id_path_parameters.dart';

Middleware middleware() => Pipeline()
    .addMiddleware(allowedContentType([
      ContentType('application', 'json'),
      ContentType('application', 'xml'),
      ContentType('application', 'x-www-form-urlencoded'),
      ContentType('multipart', 'form-data'),
    ]))
    .addMiddleware(
        getBody((body) => PutTodoBody(body), objectName: 'UpdateTodo'))
    .addMiddleware(bodyFieldIsRequired<PutTodoBody>('title'))
    .addMiddleware(bodyFieldIsType<PutTodoBody, String>('title'))
    .addMiddleware(bodyFieldMinLength<PutTodoBody>('title', 5))
    .addMiddleware(bodyFieldIsRequired<PutTodoBody>('status'))
    .addMiddleware(bodyFieldIsType<PutTodoBody, String>('status'))
    .addMiddleware(bodyFieldAllowedValues<PutTodoBody>(
        'status', TodoStatus.values.map((e) => e.name).toList()))
    .addMiddleware(provide<TodoIdPathParameter>((request) =>
        int.parse(request.getPathParameter(todoIdPathParameterKey))))
    .addMiddleware(checkTodoWithIdExist<TodoIdPathParameter>())
    .addMiddleware(parseBody<PutTodo, PutTodoBody>())
    .middleware;
