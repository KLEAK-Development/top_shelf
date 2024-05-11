import 'package:shelf/shelf.dart';
import 'package:top_shelf/top_shelf.dart';
import 'package:test/test.dart';

import '../utils.dart';

Response _handler(Request request) {
  return Response.ok(request.get<String>());
}

void main() {
  test('handler', () async {
    final handler = _handler.use(provide((request) => 'Hello world'));

    final response = await makeRequest(
      handler,
      method: 'GET',
    );
    final body = await response.readAsString();
    expect(body, equals('Hello world'));
  });
}
