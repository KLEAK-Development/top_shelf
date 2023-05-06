import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/shelf_helpers.dart';
import 'package:shelf_helpers_example/src/routes/health_check/handler.dart'
    as health_check;
import 'package:shelf_helpers_example/src/routes/todos/todos.dart';
import 'package:shelf_router/shelf_router.dart';

Handler router = _getRouter();

Handler _getRouter() {
  final app = Router()
    ..get('/', (request) => health_check.handler(request))
    ..mount('/todos', todos)
    ..all(
      '/<ignored|.*>',
      (Request request) {
        return Response.notFound('Page not found');
      },
    );

  return Pipeline().addMiddleware(cors()).addHandler(app);
}
