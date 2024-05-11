import 'package:shelf/shelf.dart';
import 'package:top_shelf/top_shelf.dart';
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  test('provider', () async {
    final handler = const Pipeline()
        .addMiddleware(provide((_) => 'Hello world'))
        .addHandler((request) => Response.ok(request.get<String>()));

    final response = await makeRequest(handler, method: 'GET');
    final body = await response.readAsString();
    expect(body, equals('Hello world'));
  });
}
