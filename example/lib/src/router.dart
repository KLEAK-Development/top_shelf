import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:shelf_helpers_example/src/routes/health_check/handler.dart'
    as health_check;

import 'package:shelf_helpers_example/src/routes/list_todos/handler.dart'
    as list_todos;
import 'package:shelf_helpers_example/src/routes/list_todos/middleware.dart'
    as list_todos;

import 'package:shelf_helpers_example/src/routes/create_todo/handler.dart'
    as create_todo;
import 'package:shelf_helpers_example/src/routes/create_todo/middleware.dart'
    as create_todo;

import 'package:shelf_helpers_example/src/routes/update_todo/handler.dart'
    as update_todo;
import 'package:shelf_helpers_example/src/routes/update_todo/middleware.dart'
    as update_todo;

import 'package:shelf_helpers_example/src/routes/delete_todo/handler.dart'
    as delete_todo;
import 'package:shelf_helpers_example/src/routes/delete_todo/middleware.dart'
    as delete_todo;

Router router = _getRouter();

Router _getRouter() {
  final todos = Router()
    ..get(
      '/',
      Pipeline()
          .addMiddleware(list_todos.middleware())
          .addHandler(list_todos.handler),
    )
    ..post(
      '/',
      Pipeline()
          .addMiddleware(create_todo.middleware())
          .addHandler(create_todo.handler),
    )
    ..put(
      '/<id|\\d+>',
      (request, todoId) => Pipeline()
          .addMiddleware(update_todo.middleware(todoId))
          .addHandler(update_todo.handler)(request),
    )
    ..delete(
      '/<id|\\d+>',
      (request, todoId) => Pipeline()
          .addMiddleware(delete_todo.middleware(todoId))
          .addHandler(delete_todo.handler)(request),
    );

  final app = Router()
    ..get('/', (request) => health_check.handler(request))
    ..mount('/todos', todos)
    ..all(
      '/<ignored|.*>',
      (Request request) {
        return Response.notFound('Page not found');
      },
    );

  return app;
}
