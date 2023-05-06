import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/shelf_helpers.dart';
import 'package:shelf_helpers_example/src/models/network/post/post_todo_body.dart';

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
    .middleware;
