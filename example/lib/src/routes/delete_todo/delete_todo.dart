import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/shelf_helpers.dart';
import 'package:sqlite3/sqlite3.dart';

void handler(Request request, int id) {
  final database = request.get<Database>();
  database.select(
    'DELETE FROM todos WHERE id = ?',
    [id],
  );
}
