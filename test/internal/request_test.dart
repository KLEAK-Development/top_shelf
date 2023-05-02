import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/shelf_helpers.dart';
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
}
