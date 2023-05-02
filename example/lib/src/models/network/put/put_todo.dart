import 'package:shelf_helpers_example/src/models/network/todo.dart';

class PutTodo {
  final String title;
  final TodoStatus status;

  const PutTodo(this.title, this.status);
}
