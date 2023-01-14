import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/src/internal/request.dart';

Middleware provider<T extends Object>(
  T Function(Request request) create,
) {
  return (handler) {
    return (request) => handler(request.set(() => create(request)));
  };
}
