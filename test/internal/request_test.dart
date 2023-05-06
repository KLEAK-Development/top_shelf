import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/shelf_helpers.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:test/test.dart';

import '../utils.dart';

Middleware testSet() {
  return (handler) {
    return (request) async {
      return handler(request.set<String>(() => 'Hello world'));
    };
  };
}

void main() {
  test('set/get', () async {
    final handler = const Pipeline()
        .addMiddleware(testSet())
        .addHandler((request) => Response.ok(request.get<String>()));

    final response = await makeRequest(handler, method: 'GET');
    final body = await response.readAsString();
    expect(body, equals('Hello world'));
  });

  test('no value setted', () async {
    final router = Router()
      ..get(
        '/',
        (Request request) => Response.ok(request.get<String>()),
      );

    try {
      await makeRequest(router, method: 'GET', url: 'http://localhost/');
    } on StateError catch (error) {
      expect(error.message, '''
request.get<String>() called with a request context that does not contain a String.
This can happen if String was not provided to the request context.

Here is an example on how to provide a String
  ```dart
  // _middleware.dart
  Middleware middleware(String value) {
    return (handler) {
      return (request) async {
        return handler(request.set(() => value));
      };
    };
  }
  ```
''');
    }
  });

  test('getPathParameter', () async {
    final router = Router()
      ..get(
        '/<id>',
        (Request request) => Response.ok(request.getPathParameter('id')),
      );

    final response =
        await makeRequest(router, method: 'GET', url: 'http://localhost/12');
    final body = await response.readAsString();
    expect(body, equals('12'));
  });

  test('no path param', () async {
    final router = Router()
      ..get(
        '/',
        (Request request) => Response.ok(request.getPathParameter('id')),
      );

    try {
      await makeRequest(router, method: 'GET', url: 'http://localhost/');
    } on StateError catch (error) {
      expect(error.message, '''
request.getPathParameter(id) called with a request context that does not contain a value in context['shelf_router/params'][id].
This can happen if id was not provided to the shelf_router path params context.

Here is an example on how to provide a path parameter
  ```dart
  // router.dart
  final router = Router()
    ..put(
      '/<todoId|\\d+>',
      Pipeline()
          .addMiddleware(update_todo.middleware())
          .addHandler(update_todo.handler),
    )

  //  middleware.dart
  Middleware middleware() => Pipeline()
    .addMiddleware(provide<TodoIdPathParameter>(
        (request) => int.parse(request.getPathParameter('todoId'))))
    .middleware;
  ```
''');
    }
  });
}
