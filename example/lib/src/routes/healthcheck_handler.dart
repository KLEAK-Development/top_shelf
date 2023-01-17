import 'package:shelf/shelf.dart';
import 'package:shelf_helpers_example/src/routes/healthcheck.dart'
    as healthcheck;

Response handler(Request request) => Response.ok(healthcheck.handler());
