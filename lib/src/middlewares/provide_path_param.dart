import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/shelf_helpers.dart';
import 'package:shelf_helpers/src/internal/request.dart';

@Deprecated('use provider middleware instead')
Middleware providePathParam<T extends Object>(T value) {
  return (handler) {
    return (request) async {
      return handler(request.set<T>(() => value));
    };
  };
}
