import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:top_shelf/top_shelf.dart';
import 'package:top_shelf_example/src/modules/todos/routes/create_todo/models/post_todo.dart';
import 'package:top_shelf_example/src/modules/todos/routes/create_todo/models/post_todo_body.dart';

Middleware middleware() => Pipeline()
    .addMiddleware(allowedContentType([
      ContentType('application', 'json'),
      ContentType('application', 'xml'),
      ContentType('application', 'x-www-form-urlencoded'),
      ContentType('multipart', 'form-data'),
    ]))
    .addMiddleware(
        getBody((body) => PostTodoBody(body), objectName: 'CreateTodo'))
    .addMiddleware(bodyFieldIsRequired<PostTodoBody>('title'))
    .addMiddleware(bodyFieldIsType<PostTodoBody, String>('title'))
    .addMiddleware(bodyFieldMinLength<PostTodoBody>('title', 5))
    .addMiddleware(parseBody<PostTodo, PostTodoBody>())
    .middleware;
