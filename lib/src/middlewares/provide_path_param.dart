import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/src/internal/request.dart';

Middleware providePathParam<T extends Object>(T value) {
  return (Handler handler) {
    return (Request request) async {
      return handler(request.set<T>(() => value));
    };
  };
}
