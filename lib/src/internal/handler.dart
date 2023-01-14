import 'package:shelf/shelf.dart';

extension HandlerUse on Handler {
  Handler use(Middleware middleware) =>
      Pipeline().addMiddleware(middleware).addHandler(this);
}
