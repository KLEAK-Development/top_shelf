import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/shelf_helpers.dart';
import 'package:shelf_helpers_example/src/middlewares/todos/check_todo_with_id_exist.dart';
import 'package:shelf_helpers_example/src/models/network/todo_id_path_parameters.dart';

Middleware middleware() => Pipeline()
    .addMiddleware(provide<TodoIdPathParameter>((request) =>
        int.parse(request.getPathParameter(todoIdPathParameterKey))))
    .addMiddleware(checkTodoWithIdExist<TodoIdPathParameter>())
    .middleware;
