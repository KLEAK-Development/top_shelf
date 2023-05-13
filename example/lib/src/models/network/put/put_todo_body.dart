import 'package:shelf_helpers/shelf_helpers.dart';
import 'package:shelf_helpers_example/src/models/network/put/put_todo.dart';

class PutTodoBody extends Body<PutTodo> {
  PutTodoBody(super.data);

  @override
  PutTodo parse() => PutTodo.fromJson(data);
}
