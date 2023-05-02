import 'package:shelf/shelf.dart';
import 'package:shelf_helpers_example/src/routes/health_check/health_check.dart'
    as health_check;

Response handler(Request request) => Response.ok(health_check.handler());
