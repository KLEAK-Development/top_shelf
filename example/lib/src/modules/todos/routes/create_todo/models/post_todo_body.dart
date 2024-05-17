import 'package:top_shelf/top_shelf.dart';
import 'package:shelf_helpers_example/src/modules/todos/routes/create_todo/models/post_todo.dart';

class PostTodoBody extends Body<PostTodo> {
  PostTodoBody(super.data);

  @override
  PostTodo parse() => PostTodo.fromJson(data);
}
