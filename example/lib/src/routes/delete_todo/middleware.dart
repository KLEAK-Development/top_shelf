import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/shelf_helpers.dart';
import 'package:shelf_helpers_example/src/middlewares/sqlite_database.dart';
import 'package:shelf_helpers_example/src/middlewares/todos/check_todo_with_id_exist.dart';
import 'package:shelf_helpers_example/src/models/network/todo_id_path_parameters.dart';

Middleware middleware(String todoId) => Pipeline()
    .addMiddleware(openDatabase(filename: 'database.db'))
    .addMiddleware(providePathParam<TodoIdPathParameter>(int.parse(todoId)))
    .addMiddleware(checkTodoWithIdExist<TodoIdPathParameter>())
    .middleware;
