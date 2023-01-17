import 'package:shelf_helpers_example/shelf_helpers_example.dart';
import 'package:shelf_hotreload/shelf_hotreload.dart';

void main(List<String> arguments) {
  withHotreload(() => server);
}
