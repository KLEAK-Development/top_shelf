import 'package:shelf/shelf.dart';
import 'package:top_shelf/top_shelf.dart';
import 'package:sqlite3/sqlite3.dart';

Middleware checkTodoWithIdExist<T extends Object>() {
  return (handler) {
    return (request) {
      final todoId = request.get<T>();
      final database = request.get<Database>();
      var results =
          database.select('SELECT id FROM todos WHERE id = ?', [todoId]);
      if (results.isEmpty) {
        return Response.notFound('');
      }
      return handler(request);
    };
  };
}
