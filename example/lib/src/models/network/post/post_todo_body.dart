import 'package:shelf_helpers/shelf_helpers.dart';
import 'package:shelf_helpers_example/src/models/network/post/post_todo.dart';

class PostTodoBody extends Body<PostTodo> {
  PostTodoBody(super.data);

  @override
  PostTodo parse() => PostTodo(data['title']);
}
