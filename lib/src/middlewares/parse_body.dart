import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/shelf_helpers.dart';

Middleware parseBody<R extends Object, B extends Body>() {
  return (handler) {
    return (request) async {
      final body = request.get<B>();
      return handler(request.set<R>(() => body.parse()));
    };
  };
}
