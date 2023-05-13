import 'package:shelf/shelf.dart';
import 'package:shelf_helpers/src/internal/body.dart';
import 'package:shelf_helpers/src/internal/generate_response.dart';
import 'package:shelf_helpers/src/internal/network_object.dart';
import 'package:shelf_helpers/src/internal/request.dart';

/// [bodyValidator] is a flexible validator that allow you to check whatever
/// you need on the body
/// if validator failed return [BadRequest] response
Middleware bodyValidator<T extends Body>(
    bool Function(Object? value) validator) {
  return (handler) {
    return (request) {
      final body = request.get<T>();
      if (!validator(body.data)) {
        final bodyResponse = BadRequest(
          'about:blank',
          'Validator doesn\'t accept this body',
          'Body with value \'${body.data}\' is not authorized by this validator',
          400,
          request.requestedUri.path,
        );
        return generateResponse(request, bodyResponse);
      }
      return handler(request);
    };
  };
}

/// [bodyFieldIsRequired] check if the [fieldName] is present in the body
/// if check failed return [BadRequest] response
Middleware bodyFieldIsRequired<B extends Body>(String fieldName) {
  return (handler) {
    return (request) {
      Response? checkItem(Map<String, dynamic> item) {
        if (item[fieldName] == null) {
          final bodyResponse = BadRequest(
            'about:blank',
            'Required field is missing',
            'The required field \'$fieldName\' is missing',
            400,
            request.requestedUri.path,
            field: fieldName,
          );
          return generateResponse(request, bodyResponse);
        }
        return null;
      }

      final body = request.get<B>();
      final response = _checkData(body.data, checkItem);
      if (response != null) {
        return response;
      }
      return handler(request);
    };
  };
}

/// [bodyFieldIsType] check if the [fieldName] is type T
/// if check failed return [BadRequest] response
Middleware bodyFieldIsType<B extends Body, T>(String fieldName) {
  return (handler) {
    return (request) {
      Response? checkItem(Map<String, dynamic> item) {
        if (item[fieldName] is! T) {
          final bodyResponse = BadRequest(
            'about:blank',
            'Type of value not authorized',
            'The field \'$fieldName\' is type \'${item[fieldName].runtimeType}\' but must be \'$T\'',
            400,
            request.requestedUri.path,
            field: fieldName,
          );
          return generateResponse(request, bodyResponse);
        }
        return null;
      }

      final body = request.get<B>();
      final response = _checkData(body.data, checkItem);
      if (response != null) {
        return response;
      }
      return handler(request);
    };
  };
}

/// [bodyFieldMinLength] check if the [fieldName] length is at least [minLength]
/// if check failed return [BadRequest] response
Middleware bodyFieldMinLength<B extends Body>(String fieldName, int minLength) {
  return (handler) {
    return (request) {
      Response? checkItem(Map<String, dynamic> item) {
        final value = item[fieldName] as String;
        if (value.length < minLength) {
          final bodyResponse = BadRequest(
            'about:blank',
            'Value is too short',
            'The field \'$fieldName\' is too short, length is \'${value.length}\' but min length must be \'$minLength\'',
            400,
            request.requestedUri.path,
            field: fieldName,
          );
          return generateResponse(request, bodyResponse);
        }
        return null;
      }

      final body = request.get<B>();
      final response = _checkData(body.data, checkItem);
      if (response != null) {
        return response;
      }
      return handler(request);
    };
  };
}

/// [bodyFieldMinLength] check if the [fieldName] length is under [maxLength]
/// if check failed return [BadRequest] response
Middleware bodyFieldMaxLength<B extends Body>(String fieldName, int maxLength) {
  return (handler) {
    return (request) {
      Response? checkItem(Map<String, dynamic> item) {
        final value = item[fieldName] as String;
        if (value.length > maxLength) {
          final bodyResponse = BadRequest(
            'about:blank',
            'Value is too long',
            'The field \'$fieldName\' is too long, length is \'${value.length}\' but max length must be \'$maxLength\'',
            400,
            request.requestedUri.path,
            field: fieldName,
          );
          return generateResponse(request, bodyResponse);
        }
        return null;
      }

      final body = request.get<B>();
      final response = _checkData(body.data, checkItem);
      if (response != null) {
        return response;
      }
      return handler(request);
    };
  };
}

/// [bodyFieldAllowedValues] check if the [fieldName] value is allowed base on [allowedValues]
/// if check failed return [BadRequest] response
Middleware bodyFieldAllowedValues<B extends Body>(
    String fieldName, List<String> allowedValues) {
  return (handler) {
    return (request) {
      Response? checkItem(Map<String, dynamic> item) {
        final value = item[fieldName] as String;
        if (!allowedValues.contains(value)) {
          final bodyResponse = BadRequest(
            'about:blank',
            'Not allowed value',
            'The value \'$value\' is not allowed, allowed values are: \'${allowedValues.join('\', \'')}\'',
            400,
            request.requestedUri.path,
            field: fieldName,
          );
          return generateResponse(request, bodyResponse);
        }
        return null;
      }

      final body = request.get<B>();
      final response = _checkData(body.data, checkItem);
      if (response != null) {
        return response;
      }
      return handler(request);
    };
  };
}

/// [bodyFieldValidator] run [validator] on the field [fieldName]
/// if validator failed return [BadRequest] response
Middleware bodyFieldValidator<T extends Body>(
    String fieldName, bool Function(Object? value) validator) {
  return (handler) {
    return (request) {
      Response? checkItem(Map<String, dynamic> item) {
        final value = item[fieldName] as String;
        if (!validator(value)) {
          final bodyResponse = BadRequest(
            'about:blank',
            'Validator doesn\'t accept this value',
            'Field \'$fieldName\' with value \'$value\' is not authorized by this validator',
            400,
            request.requestedUri.path,
            field: fieldName,
          );
          return generateResponse(request, bodyResponse);
        }
        return null;
      }

      final body = request.get<T>();
      final response = _checkData(body.data, checkItem);
      if (response != null) {
        return response;
      }
      return handler(request);
    };
  };
}

Response? _checkData(dynamic /*List || Map<String, dynamic>*/ data,
    Response? Function(Map<String, dynamic> item) checkItem) {
  if (data is List) {
    for (var index = 0; index < data.length; index++) {
      final item = data.elementAt(index);
      final response = checkItem(item);
      if (response != null) {
        return response;
      }
    }
  } else if (data is Map<String, dynamic>) {
    return checkItem(data);
  }
  return null;
}
