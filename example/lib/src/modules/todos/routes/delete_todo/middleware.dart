import 'package:shelf/shelf.dart';
import 'package:shelf_helpers_example/src/modules/todos/models/todo_id_path_parameters.dart';
import 'package:top_shelf/top_shelf.dart';
import 'package:shelf_helpers_example/src/modules/todos/middlewares/check_todo_with_id_exist.dart';

Middleware middleware() => Pipeline()
    .addMiddleware(provide<TodoIdPathParameter>((request) =>
        int.parse(request.getPathParameter(todoIdPathParameterKey))))
    .addMiddleware(checkTodoWithIdExist<TodoIdPathParameter>())
    .middleware;
