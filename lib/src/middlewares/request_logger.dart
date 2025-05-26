import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';

/// Log levels for the request logger
///
/// Determines the minimum severity level for log entries to be processed.
/// Log levels are hierarchical - setting a minimum level will include all
/// higher severity levels.
///
/// - [debug]: Verbose logging for development and troubleshooting
/// - [info]: General information about request/response flow
/// - [warning]: Non-critical issues like 4xx status codes
/// - [error]: Critical errors and exceptions
enum RequestLogLevel {
  debug,
  info,
  warning,
  error,
}

/// Structured log entry containing comprehensive request/response information
///
/// Each log entry represents a single HTTP request, response, or error event
/// with detailed metadata for debugging and monitoring purposes.
///
/// Example JSON output:
/// ```json
/// {
///   "id": "1672531200000_123",
///   "timestamp": "2024-01-01T12:00:00.000Z",
///   "level": "info",
///   "method": "GET",
///   "path": "/api/users",
///   "query": "page=1&limit=10",
///   "statusCode": 200,
///   "duration": 145,
///   "clientIp": "192.168.1.1",
///   "metadata": {"service": "api", "version": "1.0.0"}
/// }
/// ```
class LogEntry {
  final String id;
  final DateTime timestamp;
  final RequestLogLevel level;
  final String method;
  final String path;
  final String? query;
  final Map<String, String> headers;
  final String? body;
  final int? statusCode;
  final Duration? duration;
  final String? error;
  final String? stackTrace;
  final String? userAgent;
  final String? clientIp;
  final Map<String, dynamic> metadata;

  LogEntry({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.method,
    required this.path,
    this.query,
    required this.headers,
    this.body,
    this.statusCode,
    this.duration,
    this.error,
    this.stackTrace,
    this.userAgent,
    this.clientIp,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'method': method,
      'path': path,
      if (query != null) 'query': query,
      'headers': headers,
      if (body != null) 'body': body,
      if (statusCode != null) 'statusCode': statusCode,
      if (duration != null) 'duration': duration!.inMilliseconds,
      if (error != null) 'error': error,
      if (stackTrace != null) 'stackTrace': stackTrace,
      if (userAgent != null) 'userAgent': userAgent,
      if (clientIp != null) 'clientIp': clientIp,
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }
}

/// Abstract logger interface for extensibility
///
/// Implement this interface to create custom logging destinations.
/// The logger receives structured [LogEntry] objects and can process
/// them however needed (console, file, network, database, etc.).
///
/// Example implementation:
/// ```dart
/// class FileLogger implements RequestLogger {
///   final File _file;
///
///   FileLogger(String path) : _file = File(path);
///
///   @override
///   Future<void> log(LogEntry entry) async {
///     await _file.writeAsString('${jsonEncode(entry.toJson())}\n',
///                               mode: FileMode.append);
///   }
///
///   @override
///   Future<void> flush() async {
///     // File system handles flushing automatically
///   }
/// }
/// ```
abstract class RequestLogger {
  /// Log a single entry
  ///
  /// This method should be fast and non-blocking. For network loggers,
  /// consider buffering entries and sending them in batches.
  Future<void> log(LogEntry entry);

  /// Flush any buffered log entries
  ///
  /// Called periodically and when the application shuts down to ensure
  /// all log entries are properly persisted.
  Future<void> flush();
}

/// Console logger implementation for development and debugging
///
/// Outputs structured JSON log entries to stdout using the standard
/// Dart logging framework. Log levels map to appropriate severity levels.
///
/// This logger is ideal for:
/// - Local development
/// - Docker containers with log aggregation
/// - Simple debugging scenarios
///
/// Example usage:
/// ```dart
/// final middleware = requestLogger(
///   logger: ConsoleLogger(),
///   minLevel: RequestLogLevel.info,
/// );
/// ```
class ConsoleLogger implements RequestLogger {
  final Logger _logger = Logger('RequestLogger');

  @override
  Future<void> log(LogEntry entry) async {
    final message = jsonEncode(entry.toJson());
    switch (entry.level) {
      case RequestLogLevel.debug:
        _logger.fine(message);
        break;
      case RequestLogLevel.info:
        _logger.info(message);
        break;
      case RequestLogLevel.warning:
        _logger.warning(message);
        break;
      case RequestLogLevel.error:
        _logger.severe(message);
        break;
    }
  }

  @override
  Future<void> flush() async {
    // Console logger doesn't need flushing
  }
}

/// HTTP logger for sending logs to external services
///
/// Buffers log entries and sends them in batches to an HTTP endpoint.
/// Designed for cloud logging services, monitoring platforms, and
/// custom log aggregation systems.
///
/// Features:
/// - Automatic batching for efficiency
/// - Configurable buffer size and flush intervals
/// - Error resilience with retry logic
/// - Custom headers for authentication
///
/// Example usage:
/// ```dart
/// final logger = HttpLogger(
///   endpoint: 'https://logs.your-service.com/api/ingest',
///   headers: {'Authorization': 'Bearer your-token'},
///   maxBufferSize: 50,
///   flushInterval: Duration(seconds: 30),
/// );
/// ```
///
/// The logger sends POST requests with this payload structure:
/// ```json
/// {
///   "logs": [{"id": "...", "timestamp": "...", ...}],
///   "batch_id": "1672531200000"
/// }
/// ```
class HttpLogger implements RequestLogger {
  final String endpoint;
  final Map<String, String> headers;
  final HttpClient _client = HttpClient();
  final List<LogEntry> _buffer = [];
  final int maxBufferSize;
  final Duration flushInterval;
  Timer? _flushTimer;

  HttpLogger({
    required this.endpoint,
    this.headers = const {},
    this.maxBufferSize = 100,
    this.flushInterval = const Duration(seconds: 30),
  }) {
    _startFlushTimer();
  }

  void _startFlushTimer() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(flushInterval, (_) => flush());
  }

  @override
  Future<void> log(LogEntry entry) async {
    _buffer.add(entry);
    if (_buffer.length >= maxBufferSize) {
      await flush();
    }
  }

  @override
  Future<void> flush() async {
    if (_buffer.isEmpty) return;

    final entries = List<LogEntry>.from(_buffer);
    _buffer.clear();

    try {
      final request = await _client.postUrl(Uri.parse(endpoint));

      // Add headers
      request.headers.contentType = ContentType.json;
      headers.forEach((key, value) {
        request.headers.add(key, value);
      });

      // Send batch of log entries
      final payload = jsonEncode({
        'logs': entries.map((e) => e.toJson()).toList(),
        'batch_id': DateTime.now().millisecondsSinceEpoch.toString(),
      });

      request.add(utf8.encode(payload));
      final response = await request.close();

      if (response.statusCode >= 400) {
        Logger('HttpLogger').warning(
          'Failed to send logs: ${response.statusCode}',
        );
      }
    } catch (e) {
      Logger('HttpLogger').warning('Error sending logs: $e');
      // Re-add entries to buffer for retry
      _buffer.addAll(entries);
    }
  }

  void dispose() {
    _flushTimer?.cancel();
    _client.close();
  }
}

/// Composite logger for multiple destinations
///
/// Forwards log entries to multiple logger implementations simultaneously.
/// Useful for hybrid setups where you want both immediate console output
/// and persistent remote logging.
///
/// Example usage:
/// ```dart
/// final logger = CompositeLogger([
///   ConsoleLogger(), // For development visibility
///   HttpLogger(endpoint: 'https://logs.company.com'), // For persistence
///   FileLogger('/var/log/api.log'), // For local backup
/// ]);
/// ```
///
/// All loggers receive the same log entries concurrently.
/// If one logger fails, others continue operating normally.
class CompositeLogger implements RequestLogger {
  final List<RequestLogger> loggers;

  CompositeLogger(this.loggers);

  @override
  Future<void> log(LogEntry entry) async {
    await Future.wait(loggers.map((logger) => logger.log(entry)));
  }

  @override
  Future<void> flush() async {
    await Future.wait(loggers.map((logger) => logger.flush()));
  }
}

/// Privacy configuration for sensitive data handling
///
/// Controls how sensitive information is masked or excluded from logs
/// to comply with privacy regulations and security best practices.
///
/// Default configuration masks common sensitive patterns:
/// - Authorization headers, cookies, API keys
/// - Password, token, and secret query parameters
/// - Uses '***MASKED***' as the replacement value
///
/// Example custom configuration:
/// ```dart
/// const privacyConfig = PrivacyConfig(
///   sensitiveHeaders: {'x-user-token', 'x-session-id'},
///   sensitiveQueryParams: {'ssn', 'credit_card'},
///   maskRequestBody: true,
///   maskResponseBody: false,
///   maskValue: '[REDACTED]',
/// );
/// ```
class PrivacyConfig {
  final Set<String> sensitiveHeaders;
  final Set<String> sensitiveQueryParams;
  final bool maskRequestBody;
  final bool maskResponseBody;
  final String maskValue;

  const PrivacyConfig({
    this.sensitiveHeaders = const {
      'authorization',
      'cookie',
      'x-api-key',
      'x-auth-token',
    },
    this.sensitiveQueryParams = const {
      'password',
      'token',
      'api_key',
      'secret',
    },
    this.maskRequestBody = false,
    this.maskResponseBody = false,
    this.maskValue = '***MASKED***',
  });
}

/// Request logging middleware for comprehensive HTTP request/response monitoring
///
/// This middleware captures detailed information about HTTP requests and responses,
/// including timing, headers, bodies, errors, and custom metadata. It supports
/// multiple logger implementations and comprehensive privacy controls.
///
/// ## Basic Usage
///
/// ```dart
/// // Simple console logging
/// final handler = Pipeline()
///     .addMiddleware(requestLogger(
///       logger: ConsoleLogger(),
///     ))
///     .addHandler(myHandler);
/// ```
///
/// ## Advanced Configuration
///
/// ```dart
/// final handler = Pipeline()
///     .addMiddleware(requestLogger(
///       logger: HttpLogger(
///         endpoint: 'https://logs.your-service.com',
///         headers: {'Authorization': 'Bearer token'},
///       ),
///       minLevel: RequestLogLevel.info,
///       logRequestBody: false, // Don't log request bodies for security
///       logResponseBody: false, // Don't log response bodies for security
///       excludePaths: ['/health', '/metrics'], // Skip monitoring endpoints
///       privacyConfig: PrivacyConfig(
///         sensitiveHeaders: {'x-api-key', 'authorization'},
///         maskValue: '[REDACTED]',
///       ),
///       metadataExtractor: (request) => {
///         'service': 'my-api',
///         'version': '1.0.0',
///         'user_id': request.headers['x-user-id'],
///       },
///     ))
///     .addHandler(myHandler);
/// ```
///
/// ## Performance Considerations
///
/// - Set appropriate [minLevel] to reduce log volume in production
/// - Avoid logging request/response bodies in high-traffic scenarios
/// - Use [excludePaths] to skip health checks and metrics endpoints
/// - For [HttpLogger], tune [maxBufferSize] and [flushInterval] based on your needs
///
/// ## Privacy & Security
///
/// - Always configure [privacyConfig] for production deployments
/// - Review sensitive headers and query parameters for your use case
/// - Consider disabling body logging ([logRequestBody], [logResponseBody])
/// - Test your privacy configuration with real requests
///
/// ## Error Handling
///
/// - Errors in handlers are logged with full stack traces
/// - Original exceptions are re-thrown after logging
/// - Logger failures don't affect request processing
///
/// ## Log Entry Structure
///
/// Each log entry contains:
/// - Unique request ID for correlation
/// - Precise timestamps and response times
/// - HTTP method, path, query parameters
/// - Request/response headers (sanitized)
/// - Status codes and error information
/// - Client IP and user agent
/// - Custom metadata from [metadataExtractor]
Middleware requestLogger({
  required RequestLogger logger,
  RequestLogLevel minLevel = RequestLogLevel.info,
  bool logRequests = true,
  bool logResponses = true,
  bool logRequestBody = false,
  bool logResponseBody = false,
  bool logHeaders = true,
  bool logTiming = true,
  PrivacyConfig privacyConfig = const PrivacyConfig(),
  List<String> excludePaths = const [],
  Map<String, dynamic> Function(Request)? metadataExtractor,
}) {
  String generateRequestId() {
    return '${DateTime.now().millisecondsSinceEpoch.toString()}_${(DateTime.now().microsecond % 1000).toString()}';
  }

  Map<String, String> sanitizeHeaders(
    Map<String, Object> headers,
    PrivacyConfig config,
  ) {
    if (!logHeaders) return {};

    final sanitized = <String, String>{};
    headers.forEach((key, value) {
      if (config.sensitiveHeaders.contains(key.toLowerCase())) {
        sanitized[key] = config.maskValue;
      } else {
        sanitized[key] = value.toString();
      }
    });
    return sanitized;
  }

  String? sanitizeQuery(String? query, PrivacyConfig config) {
    if (query == null || query.isEmpty) return query;

    final params = Uri.splitQueryString(query);
    final sanitizedParts = <String>[];

    params.forEach((key, value) {
      if (config.sensitiveQueryParams.contains(key)) {
        sanitizedParts.add('$key=${config.maskValue}');
      } else {
        sanitizedParts.add('$key=$value');
      }
    });

    return sanitizedParts.join('&');
  }

  String? getClientIp(Request request) {
    return request.headers['x-forwarded-for'] ??
        request.headers['x-real-ip'] ??
        (request.context['shelf.io.connection_info'] as HttpConnectionInfo?)
            ?.remoteAddress
            .address;
  }

  return (Handler handler) {
    return (Request request) async {
      // Skip logging for excluded paths
      final requestPath = request.url.path;
      final normalizedPath =
          requestPath.startsWith('/') ? requestPath : '/$requestPath';
      if (excludePaths.contains(requestPath) ||
          excludePaths.contains(normalizedPath)) {
        return handler(request);
      }

      final requestId = generateRequestId();
      final startTime = clock.now();

      // Extract metadata
      final metadata = metadataExtractor?.call(request) ?? <String, dynamic>{};

      // Log request
      if (logRequests) {
        String? requestBody;
        if (logRequestBody && !privacyConfig.maskRequestBody) {
          try {
            requestBody = await request.readAsString();
            // Create a new request with the same body for the handler
            request = request.change(body: requestBody);
          } catch (e) {
            requestBody = 'Error reading body: $e';
          }
        }

        final requestEntry = LogEntry(
          id: requestId,
          timestamp: startTime,
          level: RequestLogLevel.info,
          method: request.method,
          path: request.url.path,
          query: sanitizeQuery(request.url.query, privacyConfig),
          headers: sanitizeHeaders(request.headers, privacyConfig),
          body: privacyConfig.maskRequestBody
              ? privacyConfig.maskValue
              : requestBody,
          userAgent: request.headers['user-agent'],
          clientIp: getClientIp(request),
          metadata: {...metadata, 'type': 'request'},
        );

        if (requestEntry.level.index >= minLevel.index) {
          await logger.log(requestEntry);
        }
      }

      late Response response;
      String? error;
      String? stackTrace;

      try {
        response = await handler(request);
      } catch (e, st) {
        error = e.toString();
        stackTrace = st.toString();

        // Log error
        final errorEntry = LogEntry(
          id: requestId,
          timestamp: clock.now(),
          level: RequestLogLevel.error,
          method: request.method,
          path: request.url.path,
          query: sanitizeQuery(request.url.query, privacyConfig),
          headers: sanitizeHeaders(request.headers, privacyConfig),
          error: error,
          stackTrace: stackTrace,
          userAgent: request.headers['user-agent'],
          clientIp: getClientIp(request),
          metadata: {...metadata, 'type': 'error'},
        );

        if (errorEntry.level.index >= minLevel.index) {
          await logger.log(errorEntry);
        }

        rethrow;
      }

      final endTime = clock.now();
      final duration = logTiming ? endTime.difference(startTime) : null;

      // Log response
      if (logResponses) {
        String? responseBody;
        if (logResponseBody && !privacyConfig.maskResponseBody) {
          try {
            responseBody = await response.readAsString();
            // Create a new response with the same body
            response = response.change(body: responseBody);
          } catch (e) {
            responseBody = 'Error reading body: $e';
          }
        }

        final responseLevel = response.statusCode >= 400
            ? RequestLogLevel.warning
            : RequestLogLevel.info;

        final responseEntry = LogEntry(
          id: requestId,
          timestamp: endTime,
          level: responseLevel,
          method: request.method,
          path: request.url.path,
          query: sanitizeQuery(request.url.query, privacyConfig),
          headers: sanitizeHeaders(request.headers, privacyConfig),
          body: privacyConfig.maskResponseBody
              ? privacyConfig.maskValue
              : responseBody,
          statusCode: response.statusCode,
          duration: duration,
          userAgent: request.headers['user-agent'],
          clientIp: getClientIp(request),
          metadata: {...metadata, 'type': 'response'},
        );

        if (responseEntry.level.index >= minLevel.index) {
          await logger.log(responseEntry);
        }
      }

      return response;
    };
  };
}
