import 'package:shelf/shelf.dart';
import 'package:shelf_helpers_example/src/modules/health_check/routes/handler.dart'
    as health_check;

final healthCheck = Pipeline().addHandler(health_check.handler);
