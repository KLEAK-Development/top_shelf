import 'package:shelf/shelf.dart';
import 'package:top_shelf/top_shelf.dart';
import 'package:shelf_helpers_example/src/models/network/todo.dart';

Middleware middleware() => Pipeline()
    .addMiddleware(queryParameterValidator(
      required: false,
      name: 'status',
      allowedValues: [...TodoStatus.values.map((e) => e.name), 'all'],
    ))
    .middleware;
