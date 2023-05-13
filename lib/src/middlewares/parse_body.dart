import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/shelf_helpers.dart';

/// take a [Body] and parse it to put it in the context
/// you can then get it by using `request.get<R>()`
Middleware parseBody<R extends Object, B extends Body>() {
  return (handler) {
    return (request) async {
      final body = request.get<B>();
      return handler(request.set<R>(() => body.parse()));
    };
  };
}
