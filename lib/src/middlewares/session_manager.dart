import 'dart:io';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:shelf/shelf.dart';
import 'package:top_shelf/top_shelf.dart';

final _sessions = <String, Session>{};

Middleware sessionManager() {
  return (handler) {
    return (request) async {
      try {
        final cookieManager = request.get<CookiesManager>();
        final sessionId = cookieManager.request.getByName('sessionId')?.value ??
            _generateSessionId();

        _sessions[sessionId] ??= Session({});

        final session = _sessions[sessionId]!;
        final response = await handler(request.set<Session>(() => session));

        final now = clock.now();
        //  (kevin): Maybe we should let user set this ?
        const sessionDuration = Duration(hours: 1);
        final expiresAt = now.add(sessionDuration);

        final cookie = Cookie('sessionId', sessionId)
          ..expires = expiresAt
          ..httpOnly = true
          ..maxAge = expiresAt.difference(now).inSeconds
          ..path = '/'
          ..secure = request.requestedUri.scheme == 'https';

        cookieManager.add(cookie);

        return response;
      } on StateError catch (e) {
        if (e.message.startsWith('request.get<CookiesManager>()')) {
          throw StateError(
              'cookieManger middleware should be present to use sessionManager');
        }

        rethrow;
      }
    };
  };
}

String _generateSessionId() {
  while (true) {
    final alphabets =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
            .split('');
    final random = Random.secure();
    final sessionId = [
      for (int index = 0; index < 32; index++)
        alphabets.elementAt(random.nextInt(alphabets.length))
    ].join('');
    if (!_sessions.containsKey(sessionId)) {
      return sessionId;
    }
  }
}

extension type Session(Map<String, Object?> data) {}
