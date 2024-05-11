import 'package:shelf/shelf.dart';
import 'package:top_shelf/top_shelf.dart';
import 'package:sqlite3/sqlite3.dart';

Middleware openDatabase({required final String filename}) {
  return (handler) {
    return (request) async {
      final database = sqlite3.open(filename);
      request = request.set<Database>(() => database);
      final response = await handler(request);
      database.dispose();
      return response;
    };
  };
}
