import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_helpers_example/src/routes/healthcheck_handler.dart'
    as healthcheck_handler;

Router router = _getRouter();

Router _getRouter() {
  final app = Router();

  app.get('/', (request) => healthcheck_handler.handler(request));

  return app;
}
