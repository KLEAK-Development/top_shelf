import 'package:top_shelf/top_shelf.dart';
import 'package:top_shelf_example/src/modules/todos/routes/update_todo/models/put_todo.dart';

class PutTodoBody extends Body<PutTodo> {
  PutTodoBody(super.data);

  @override
  PutTodo parse() => PutTodo.fromJson(data);
}
