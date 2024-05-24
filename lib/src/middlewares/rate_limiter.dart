import 'dart:io';

import 'package:clock/clock.dart';
import 'package:shelf/shelf.dart';

Middleware rateLimiter({
  int maxRequestsPerMinute = 10,
  Duration duration = const Duration(minutes: 1),
}) {
  final clientRequests = <String, List<DateTime>>{};

  return (Handler handler) {
    return (Request request) async {
      final clientId = request.headers['x-forwarded-for'] ??
          (request.context['shelf.io.connection_info'] as HttpConnectionInfo)
              .remoteAddress
              .address;

      // Check if client exists in tracking data
      if (clientRequests.containsKey(clientId)) {
        final timestamps = clientRequests[clientId]!;

        // Check if client has exceeded request limit
        if (timestamps.length >= maxRequestsPerMinute) {
          final lastRequestTime = timestamps.last;
          final timeRemaining =
              duration - (clock.now().difference(lastRequestTime));

          // Return 429 Too Many Requests with Retry-After header
          return Response.forbidden(
            'Too Many Requests',
            headers: {
              'Retry-After': timeRemaining.inSeconds.toString(),
            },
          );
        }

        // Add current timestamp to list and proceed with request
        timestamps.add(clock.now());
      } else {
        // Add new client to tracking data
        clientRequests[clientId] = [clock.now()];
      }

      // Clean up expired requests
      clientRequests.removeWhere(
          (key, value) => value.last.isBefore(clock.now().subtract(duration)));

      // Set rate limit headers
      final remainingRequests =
          maxRequestsPerMinute - clientRequests[clientId]!.length;
      final resetTime = clock.now().add(duration);

      final response = await handler(request);
      return response.change(
        headers: {
          'X-RateLimit-Limit': [maxRequestsPerMinute.toString()],
          'X-RateLimit-Remaining': [remainingRequests.toString()],
          'X-RateLimit-Reset': [resetTime.millisecondsSinceEpoch.toString()],
        },
      );
    };
  };
}
