import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/shelf_helpers.dart';
import 'package:shelf_helpers_example/src/models/network/todo.dart';

Middleware middleware() => Pipeline()
    .addMiddleware(queryParameterValidator(
      required: false,
      name: 'status',
      allowedValues: TodoStatus.values.map((e) => e.name).toList(),
    ))
    .middleware;
