import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/shelf_helpers.dart';
import 'package:shelf_helpers_example/src/middlewares/sqlite_database.dart';
import 'package:shelf_helpers_example/src/models/network/todo_id_path_parameters.dart';
import 'package:shelf_helpers_example/src/repositories/todos.dart';
import 'package:shelf_helpers_example/src/routes/todos/create_todo/handler.dart'
    as create_todo;
import 'package:shelf_helpers_example/src/routes/todos/create_todo/middleware.dart'
    as create_todo;
import 'package:shelf_helpers_example/src/routes/todos/delete_todo/handler.dart'
    as delete_todo;
import 'package:shelf_helpers_example/src/routes/todos/delete_todo/middleware.dart'
    as delete_todo;
import 'package:shelf_helpers_example/src/routes/todos/list_todos/handler.dart'
    as list_todos;
import 'package:shelf_helpers_example/src/routes/todos/list_todos/middleware.dart'
    as list_todos;
import 'package:shelf_helpers_example/src/routes/todos/update_todo/handler.dart'
    as update_todo;
import 'package:shelf_helpers_example/src/routes/todos/update_todo/middleware.dart'
    as update_todo;
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';

final todos = Pipeline()
    .addMiddleware(
      openDatabase(filename: 'database.db'),
    )
    .addMiddleware(
      provide((request) => TodosRepository(request.get<Database>())),
    )
    .addHandler(
      Router()
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
          '/<$todoIdPathParameterKey|\\d+>',
          Pipeline()
              .addMiddleware(update_todo.middleware())
              .addHandler(update_todo.handler),
        )
        ..delete(
          '/<$todoIdPathParameterKey|\\d+>',
          Pipeline()
              .addMiddleware(delete_todo.middleware())
              .addHandler(delete_todo.handler),
        ),
    );
