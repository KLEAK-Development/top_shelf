import 'package:shelf_helpers_example/src/models/network/todo.dart';
import 'package:sqlite3/sqlite3.dart';

class TodosRepository {
  final Database database;

  const TodosRepository(this.database);

  ResultSet getById(int id) => database.select(
        'SELECT id, title, status, createDate, doneDate FROM todos WHERE id = ?',
        [id],
      );

  ResultSet getByStatus(String status) {
    final sb = StringBuffer('SELECT * FROM todos');
    if (status != 'all') {
      sb.write(' WHERE status = ?');
    }

    final results = database.select(
      sb.toString(),
      [
        if (status != 'all')
          TodoStatus.values.firstWhere((element) => element.name == status).name
      ],
    );
    return results;
  }

  ResultSet create(String title) => database.select(
        'INSERT INTO todos (title, createDate, doneDate, status) VALUES (?, ?, ?, ?) RETURNING id, title, createDate, doneDate, status',
        [
          title,
          DateTime.now().toUtc().toIso8601String(),
          null,
          TodoStatus.waiting.name,
        ],
      );

  ResultSet update(int id, String title, String status, {DateTime? doneDate}) {
    final results = database.select(
      'UPDATE todos SET title = ?, status = ?, doneDate = ? WHERE id = ? RETURNING id, title, createDate, doneDate, status',
      [title, status, doneDate?.toUtc().toIso8601String(), id],
    );
    return results;
  }

  ResultSet complete(int id, String title, String status) {
    var results = database.select(
      'SELECT id, title, status, createDate, doneDate FROM todos WHERE id = ?',
      [id],
    );
    final status = results.first['status'] as String?;
    final doneDate = results.first['doneDate'] as String?;
    if (status == 'done') {
      return results;
    }
    results = database.select(
      'UPDATE todos SET title = ?, status = ?, doneDate = ? WHERE id = ? RETURNING id, title, createDate, doneDate, status',
      [title, status, doneDate ?? DateTime.now().toUtc().toIso8601String(), id],
    );
    return results;
  }

  void delete(int id) {
    database.select('DELETE FROM todos WHERE id = ?', [id]);
  }
}
