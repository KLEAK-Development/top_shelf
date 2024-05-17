import 'package:shelf/shelf.dart';
import 'package:top_shelf_example/src/modules/health_check/routes/health_check.dart'
    as health_check;

Response handler(Request request) => Response.ok(health_check.handler());
