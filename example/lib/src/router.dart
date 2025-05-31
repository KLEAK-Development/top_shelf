import 'package:shelf/shelf.dart';
import 'package:top_shelf_example/src/middlewares/sqlite_database.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:top_shelf/top_shelf.dart';
import 'package:top_shelf_example/src/modules/health_check/routes/handler.dart'
    as health_check;
import 'package:top_shelf_example/src/modules/todos/router/todos.dart';
import 'package:shelf_router/shelf_router.dart';

Handler router = _getRouter();

Handler _getRouter() {
  final app = Router()
    ..get('/', health_check.handler)
    ..mount(
      '/authentication',
      Pipeline()
          .addMiddleware(provide<AAccountsRepository>(
              (request) => SqliteAccountRepository(request.get<Database>())))
          .addHandler(authenticationModule),
    )
    ..mount(
      '/accounts',
      Pipeline()
          .addMiddleware(provide<AAccountsRepository>(
              (request) => SqliteAccountRepository(request.get<Database>())))
          .addHandler(accountsModule()),
    )
    ..mount('/todos', todos)
    ..all(
      '/<ignored|.*>',
      (Request request) {
        return Response.notFound('Page not found');
      },
    );

  return Pipeline()
      .addMiddleware(cors())
      .addMiddleware(requestLogger(
        logger: ConsoleLogger(),
        logRequests: true,
        logResponses: true,
        logTiming: true,
        // excludePaths: ['/'], // Exclude health check endpoint from logging
        metadataExtractor: (request) => {
          'service': 'top_shelf_example',
          'version': '1.0.0',
        },
      ))
      .addMiddleware(openSqlite3Database(filename: 'database.db'))
      .addHandler(app.call);
}
