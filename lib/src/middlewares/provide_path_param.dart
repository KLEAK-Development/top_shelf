import 'package:shelf/shelf.dart';
import 'package:top_shelf/src/internal/request.dart';

@Deprecated('use provider middleware instead')
Middleware providePathParam<T extends Object>(T value) {
  return (handler) {
    return (request) async {
      return handler(request.set<T>(() => value));
    };
  };
}
