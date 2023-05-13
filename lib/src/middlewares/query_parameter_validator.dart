import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/src/internal/generate_response.dart';
import 'package:shelf_helpers/src/internal/network_object.dart';

/// Use [queryParameterValidator] to verify if query parameter [name] is allowed
/// you can provide the list of allowed value in [allowedValues]
/// if the query parameter is mandatory put [required] at true and else at false
Middleware queryParameterValidator(
    {required bool required,
    required String name,
    required List<String> allowedValues}) {
  return (handler) {
    return (request) async {
      if (required) {
        if (!request.url.queryParameters.containsKey(name)) {
          final bodyResponse = BadRequest(
            'about:blank',
            'Required query parameter is missing',
            'The required query parameter \'$name\' is missing',
            400,
            '${request.requestedUri.path}?${request.requestedUri.query}',
            field: name,
          );
          return generateResponse(request, bodyResponse);
        }
      }
      if (request.url.queryParameters.containsKey(name) &&
          !allowedValues.contains(request.url.queryParameters[name])) {
        final bodyResponse = BadRequest(
          'about:blank',
          'Query parameter value not allowed',
          'The value \'${request.url.queryParameters[name]}\' is not allowed, allowed values are: \'${allowedValues.join('\', \'')}\'',
          400,
          '${request.requestedUri.path}?${request.requestedUri.query}',
          field: name,
        );
        return generateResponse(request, bodyResponse);
      }

      return handler(request);
    };
  };
}
