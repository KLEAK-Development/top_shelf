import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/shelf_helpers.dart';
import 'package:shelf_helpers/src/internal/request.dart';

/// Allow you to provide lazy value down
Middleware provide<T extends Object>(
  T Function(Request request) create,
) {
  return (handler) {
    return (request) => handler(request.set(() => create(request)));
  };
}
