import 'package:top_shelf_example/src/modules/todos/models/todo.dart';

class PutTodo {
  final String title;
  final TodoStatus status;

  const PutTodo(this.title, this.status);

  factory PutTodo.fromJson(Map<String, dynamic> json) {
    if (json
        case {'title': final String title, 'status': final String status}) {
      return PutTodo(title,
          TodoStatus.values.firstWhere((element) => element.name == status));
    } else {
      throw FormatException('Unexpected JSON');
    }
  }
}
