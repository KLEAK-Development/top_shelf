import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:top_shelf_example/src/modules/todos/models/todo.dart';
import 'package:top_shelf_example/src/modules/todos/models/todo_id_path_parameters.dart';
import 'package:top_shelf/top_shelf.dart';
import 'package:top_shelf_example/src/modules/todos/middlewares/check_todo_with_id_exist.dart';
import 'package:top_shelf_example/src/modules/todos/routes/update_todo/models/put_todo.dart';
import 'package:top_shelf_example/src/modules/todos/routes/update_todo/models/put_todo_body.dart';

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
