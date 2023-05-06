import 'package:logging/logging.dart';
import 'package:shelf_helpers_example/shelf_helpers_example.dart';

void main(List<String> arguments) {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print(record);
  });

  server();
}
