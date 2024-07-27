import 'package:logging/logging.dart';
import 'package:shelf_hotreload/shelf_hotreload.dart';
import 'package:top_shelf_example/shelf_helpers_example.dart';

void main(List<String> arguments) {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print(record);
  });

  const port = 8080;
  withHotreload(
    () => server(port: port),
    logLevel: Logger.root.level,
  );
}
