import 'package:shelf/shelf.dart';
import 'package:top_shelf_example/src/modules/todos/models/todo_id_path_parameters.dart';
import 'package:top_shelf/top_shelf.dart';
import 'package:top_shelf_example/src/modules/todos/repositories/todos.dart';
import 'package:top_shelf_example/src/modules/todos/routes/create_todo/handler.dart'
    as create_todo;
import 'package:top_shelf_example/src/modules/todos/routes/create_todo/middleware.dart'
    as create_todo;
import 'package:top_shelf_example/src/modules/todos/routes/delete_todo/handler.dart'
    as delete_todo;
import 'package:top_shelf_example/src/modules/todos/routes/delete_todo/middleware.dart'
    as delete_todo;
import 'package:top_shelf_example/src/modules/todos/routes/list_todos/handler.dart'
    as list_todos;
import 'package:top_shelf_example/src/modules/todos/routes/list_todos/middleware.dart'
    as list_todos;
import 'package:top_shelf_example/src/modules/todos/routes/update_todo/handler.dart'
    as update_todo;
import 'package:top_shelf_example/src/modules/todos/routes/update_todo/middleware.dart'
    as update_todo;
import 'package:top_shelf_example/src/modules/todos/routes/delete_all_todo/handler.dart'
    as delete_all_todo;
import 'package:top_shelf_example/src/modules/todos/routes/delete_all_todo/middleware.dart'
    as delete_all_todo;
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';

final todos = Pipeline()
    .addMiddleware(
      provide((request) => TodosRepository(request.get<Database>())),
    )
    .addHandler(
      (Router()
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
            ..delete(
              '/',
              Pipeline()
                  .addMiddleware(delete_all_todo.middleware())
                  .addHandler(delete_all_todo.handler),
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
            ))
          .call,
    );
