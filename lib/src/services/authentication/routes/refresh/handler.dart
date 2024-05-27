import 'package:shelf/shelf.dart';
import 'package:top_shelf/src/internal/generate_response.dart';
import 'package:top_shelf/src/services/authentication/routes/refresh/refresh.dart'
    as refresh;

Future<Response> handler(Request request) async {
  final object = await refresh.handler(request);
  return generateResponse(request, object);
}
