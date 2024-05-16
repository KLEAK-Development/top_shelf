import 'package:sqlite3/sqlite3.dart';

void main(List<String> arguments) {
  final database = sqlite3.open('database.db');
  database.execute(
      'CREATE TABLE IF NOT EXISTS todos (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, createDate TEXT NOT NULL, doneDate TEXT NULLABLE, status TEXT NOT NULL)');
  database.execute(
      'CREATE TABLE IF NOT EXISTS accounts (id INTEGER PRIMARY KEY AUTOINCREMENT, email TEXT NOT NULL, password TEXT NOT NULL, creationDate TEXT NOT NULL, roles TEXT NOT NULL)');
  database.dispose();
}
