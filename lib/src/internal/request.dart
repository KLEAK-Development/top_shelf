import 'package:shelf/shelf.dart';

const _providersKey = 'providers';

extension RequestSet on Request {
  Request set<T extends Object>(T Function() create) {
    final providers = context[_providersKey] as Map<String, dynamic>? ?? {};
    return change(
      context: {
        ...context,
        _providersKey: {
          ...providers,
          '$T': create,
        },
      },
    );
  }
}

extension RequestGet on Request {
  T get<T>() {
    final providers = (context[_providersKey] as Map<String, dynamic>?) ?? {};
    final value = providers['$T'];
    if (value == null) {
      throw StateError(
        '''
request.get<$T>() called with a request context that does not contain a $T.
This can happen if $T was not provided to the request context.

Here is an example on how to provide a String
  ```dart
  // _middleware.dart
  Middleware middleware(String value) {
    return (handler) {
      return (request) async {
        return handler(request.set(() => value));
      };
    };
  }
  ```
''',
      );
    }
    return (value as T Function())();
  }
}

extension RequestGetPathParameter on Request {
  String getPathParameter(String key) {
    final params = (context['shelf_router/params'] as Map<String, String>?) ??
        <String, String>{};
    if (!params.containsKey(key)) {
      throw 'oops';
    }
    return params[key]!;
  }
}
