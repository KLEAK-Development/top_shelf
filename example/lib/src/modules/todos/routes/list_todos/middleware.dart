import 'package:shelf/shelf.dart';
import 'package:top_shelf_example/src/modules/todos/models/todo.dart';
import 'package:top_shelf/top_shelf.dart';

Middleware middleware() => Pipeline()
    .addMiddleware(queryParameterContainsValue(
      required: false,
      name: 'status',
      containsValues: [...TodoStatus.values.map((e) => e.name), 'all'],
    ))
    .middleware;
