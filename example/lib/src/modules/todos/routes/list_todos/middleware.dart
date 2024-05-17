import 'package:shelf/shelf.dart';
import 'package:shelf_helpers_example/src/modules/todos/models/todo.dart';
import 'package:top_shelf/top_shelf.dart';

Middleware middleware() => Pipeline()
    .addMiddleware(queryParameterValidator(
      required: false,
      name: 'status',
      allowedValues: [...TodoStatus.values.map((e) => e.name), 'all'],
    ))
    .middleware;
