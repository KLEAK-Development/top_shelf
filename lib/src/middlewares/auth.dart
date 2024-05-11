import 'dart:async';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';
import 'package:top_shelf/src/internal/request.dart';

const _basic = 'Basic';
const _bearer = 'Bearer';
const _headerApiKey = 'X-API-KEY';

/// [auth ] middleware allow you to hook to get token, apiKey or something else
/// in order to check if credential are correct.
/// The function that check if credential are correct return
/// a record that look like this (bool, T) where T is defined by you.
///
/// example on how to use it:
/// (bool, Identifiable) apiKeyAuth(Request request, String value) {
///   return (value == 'GOOGLE', Identifiable('GOOGLE'));
/// }
///
/// addMiddleware(
///   auth(ApiKeyAuth(apiKeyAuth)),
/// )
Middleware auth<T>(Auth<T> auth) {
  return (handler) {
    return (request) async {
      final (authorized, data) = await auth.authenticate(request);
      if (authorized) {
        if (data == null) {
          return handler(request);
        }
        return handler(request.set<T>(() => data));
      }
      return Response.unauthorized('');
    };
  };
}

/// The [BasicAuth] helpers check if
/// - authorization header is present
/// - authorization header start with 'Basic '
/// - give you what is after 'Basic ' in order to you to verify it's correct
///
/// [basicAuth] parameter return a record type (bool, T) where T is defined by
/// you and represent the User
/// or something else that identify this authentication
class BasicAuth<T> extends _Auth<T> {
  BasicAuth(
      FutureOr<(bool, T)> Function(Request request, String authorization)
          basicAuth)
      : super((request) => _bearerAuth<T>(request, basicAuth, '$_basic '));
}

/// The [BearerAuth] helpers check if
/// - authorization header is present
/// - authorization header start with 'Bearer '
/// - give you what is after 'Bearer ' in order to you to verify it's correct
///
/// [bearerAuth] parameter return a record type (bool, T) where T is defined by
/// you and represent the User
/// or something else that identify this authentication
class BearerAuth<T> extends _Auth<T> {
  BearerAuth(
      FutureOr<(bool, T)> Function(Request request, String authorization)
          bearerAuth,
      {String prefix = _bearer})
      : super((request) => _bearerAuth<T>(request, bearerAuth, '$prefix '));
}

/// The [ApiKeyAuth] helpers check if
/// - [apiKey] header is present
/// - give you what is in the [apiKey] header in order to you to verify it's correct
///
/// [apiKeyAuth] parameter return a record type (bool, T) where T is defined by
/// you and represent the User
/// or something else that identify this authentication
class ApiKeyAuth<T> extends _Auth<T> {
  ApiKeyAuth(
      FutureOr<(bool, T)> Function(Request request, String value) apiKeyAuth,
      {String apiKey = _headerApiKey})
      : super((request) => _apiKeyAuth<T>(request, apiKeyAuth, apiKey));
}

Future<(bool, T?)> _bearerAuth<T>(
    Request request,
    FutureOr<(bool, T)> Function(Request request, String authorization)
        bearerAuth,
    String prefix) async {
  final authorizationHeader =
      request.headers[HttpHeaders.authorizationHeader] ?? '';

  if (authorizationHeader.startsWith(prefix)) {
    return bearerAuth(request, authorizationHeader.substring(prefix.length));
  }
  return (false, null);
}

Future<(bool, T?)> _apiKeyAuth<T>(
    Request request,
    FutureOr<(bool, T)> Function(Request request, String value) apiKeyAuth,
    String apiKey) async {
  final value = request.headers[apiKey] ?? '';
  return apiKeyAuth(request, value);
}

abstract class Auth<T> {
  final Future<(bool, T?)> Function(Request request) isAuthorizedWithData;

  const Auth(this.isAuthorizedWithData);

  Future<(bool, T?)> authenticate(Request request);

  Auth<T> operator |(Auth<T> other);
}

class _Auth<T> extends Auth<T> {
  final Auth<T>? _parent;

  const _Auth(super.isAuthorizedWithData) : _parent = null;

  const _Auth._withParent(this._parent, super.isAuthorizedWithData);

  @override
  Future<(bool, T?)> authenticate(Request request) async {
    if (_parent != null) {
      final (authorized, identifiable) = await _parent!.authenticate(request);
      if (authorized) {
        return (authorized, identifiable);
      }
    }
    return isAuthorizedWithData(request);
  }

  @override
  Auth<T> operator |(Auth<T> other) {
    return _Auth._withParent(this, other.isAuthorizedWithData);
  }
}

@experimental
Middleware authentication<T>({
  FutureOr<(bool, T?)> Function(Request request, String authorization)?
      basicAuth,
  FutureOr<(bool, T?)> Function(Request request, String token)? bearerAuth,
  FutureOr<(bool, T?)> Function(Request request, String value)? apiKeyAuth,
  FutureOr<(bool, T?)> Function(Request request)? customAuth,
  String headerKey = _headerApiKey,
  String bearerPrefix = _bearer,
}) {
  return (handler) {
    return (request) async {
      final (authorized, data) = await _isAuthorizedWithData<T?>(
        request,
        basicAuth,
        bearerAuth,
        apiKeyAuth,
        customAuth,
        headerKey,
        bearerPrefix,
      );
      if (authorized) {
        if (data == null) {
          return handler(request);
        }
        return handler(request.set<T>(() => data));
      }
      return Response.unauthorized('');
    };
  };
}

FutureOr<(bool, T?)> _isAuthorizedWithData<T>(
  Request request,
  FutureOr<(bool, T?)> Function(Request request, String authorization)?
      basicAuth,
  FutureOr<(bool, T?)> Function(Request request, String token)? bearerAuth,
  FutureOr<(bool, T?)> Function(Request request, String value)? apiKeyAuth,
  FutureOr<(bool, T?)> Function(Request request)? customAuth,
  String headerKey,
  String bearerPrefix,
) async {
  final authorizationHeader =
      request.headers[HttpHeaders.authorizationHeader] ?? '';

  if (basicAuth != null && authorizationHeader.startsWith('$_basic ')) {
    return await basicAuth(
        request, authorizationHeader.substring('$_basic '.length));
  } else if (bearerAuth != null &&
      authorizationHeader.startsWith('$bearerPrefix ')) {
    return await bearerAuth(
        request, authorizationHeader.substring('$bearerPrefix '.length));
  } else if (apiKeyAuth != null) {
    return await apiKeyAuth(request, request.headers[headerKey] ?? '');
  } else if (customAuth != null) {
    return await customAuth(request);
  }
  return (false, null);
}
