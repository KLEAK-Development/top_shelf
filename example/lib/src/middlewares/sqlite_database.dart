import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/shelf_helpers.dart';
import 'package:sqlite3/sqlite3.dart';

Middleware openDatabase({required final String filename}) {
  return (Handler handler) {
    return (Request request) async {
      final database = sqlite3.open(filename);
      request = request.set<Database>(() => database);
      final response = await handler(request);
      database.dispose();
      return response;
    };
  };
}
