import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/shelf_helpers.dart';
import 'package:shelf_helpers_example/src/middlewares/sqlite_database.dart';
import 'package:shelf_helpers_example/src/models/network/post/post_todo_body.dart';

Middleware middleware() => Pipeline()
    .addMiddleware(contentTypeValidator([
      ContentType('application', 'json'),
      ContentType('application', 'xml'),
    ]))
    .addMiddleware(
        getBody((body) => PostTodoBody(body), objectName: 'CreateTodo'))
    .addMiddleware(
        bodyFieldValidator<PostTodoBody>('title', (value) => value is String))
    .addMiddleware(bodyFieldValidator<PostTodoBody>(
        'title', (value) => (value as String).length > 5))
    .addMiddleware(openDatabase(filename: 'database.db'))
    .middleware;
