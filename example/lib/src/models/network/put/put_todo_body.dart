import 'package:shelf_helpers/shelf_helpers.dart';
import 'package:shelf_helpers_example/src/models/network/put/put_todo.dart';
import 'package:shelf_helpers_example/src/models/network/todo.dart';

class PutTodoBody extends Body<PutTodo> {
  PutTodoBody(super.data);

  @override
  PutTodo parse() => PutTodo(
      data['title'],
      TodoStatus.values
          .firstWhere((element) => element.name == data['status']));
}
