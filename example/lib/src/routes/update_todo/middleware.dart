import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/shelf_helpers.dart';
import 'package:shelf_helpers_example/src/middlewares/sqlite_database.dart';
import 'package:shelf_helpers_example/src/middlewares/todos/check_todo_with_id_exist.dart';
import 'package:shelf_helpers_example/src/models/network/put/put_todo_body.dart';
import 'package:shelf_helpers_example/src/models/network/todo_id_path_parameters.dart';
import 'package:shelf_helpers_example/src/models/network/todo.dart';

Middleware middleware(String todoId) => Pipeline()
    .addMiddleware(contentTypeValidator([
      ContentType('application', 'json'),
      ContentType('application', 'xml')
    ]))
    .addMiddleware(
        getBody((body) => PutTodoBody(body), objectName: 'UpdateTodo'))
    .addMiddleware(
        bodyFieldValidator<PutTodoBody>('title', (value) => value is String))
    .addMiddleware(bodyFieldValidator<PutTodoBody>(
        'title', (value) => (value as String).length > 5))
    .addMiddleware(
        bodyFieldValidator<PutTodoBody>('status', (value) => value is String))
    .addMiddleware(bodyFieldValidator<PutTodoBody>(
        'status',
        (value) =>
            TodoStatus.values.map((e) => e.name).toList().contains(value)))
    .addMiddleware(openDatabase(filename: 'database.db'))
    .addMiddleware(providePathParam<TodoIdPathParameter>(int.parse(todoId)))
    .addMiddleware(checkTodoWithIdExist<TodoIdPathParameter>())
    .middleware;
