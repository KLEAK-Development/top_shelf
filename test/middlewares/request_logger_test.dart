import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';
import 'package:top_shelf/src/middlewares/request_logger.dart';

import '../utils.dart';

class TestLogger implements RequestLogger {
  final List<LogEntry> entries = [];

  @override
  Future<void> log(LogEntry entry) async {
    entries.add(entry);
  }

  @override
  Future<void> flush() async {
    // Test logger doesn't need flushing
  }

  void clear() {
    entries.clear();
  }
}

class TestHttpServer {
  late HttpServer server;
  final List<Map<String, dynamic>> receivedLogs = [];

  Future<void> start() async {
    server = await HttpServer.bind('localhost', 0);
    server.listen((request) async {
      if (request.method == 'POST') {
        final body = await utf8.decoder.bind(request).join();
        receivedLogs.add(jsonDecode(body));
        request.response.statusCode = 200;
      } else {
        request.response.statusCode = 404;
      }
      await request.response.close();
    });
  }

  void stop() {
    server.close();
  }

  String get endpoint => 'http://localhost:${server.port}/logs';
}

void main() {
  group('LogEntry', () {
    test('converts to JSON correctly', () {
      final entry = LogEntry(
        id: 'test-123',
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
        level: RequestLogLevel.info,
        method: 'GET',
        path: '/test',
        query: 'param=value',
        headers: {'content-type': 'application/json'},
        body: '{"test": true}',
        statusCode: 200,
        duration: Duration(milliseconds: 150),
        error: null,
        stackTrace: null,
        userAgent: 'TestAgent/1.0',
        clientIp: '127.0.0.1',
        metadata: {'custom': 'data'},
      );

      final json = entry.toJson();

      expect(json['id'], 'test-123');
      expect(json['timestamp'], '2024-01-01T12:00:00.000');
      expect(json['level'], 'info');
      expect(json['method'], 'GET');
      expect(json['path'], '/test');
      expect(json['query'], 'param=value');
      expect(json['headers'], {'content-type': 'application/json'});
      expect(json['body'], '{"test": true}');
      expect(json['statusCode'], 200);
      expect(json['duration'], 150);
      expect(json['userAgent'], 'TestAgent/1.0');
      expect(json['clientIp'], '127.0.0.1');
      expect(json['metadata'], {'custom': 'data'});
    });
  });

  group('ConsoleLogger', () {
    test('logs entries without throwing', () async {
      final logger = ConsoleLogger();
      final entry = LogEntry(
        id: 'test',
        timestamp: DateTime.now(),
        level: RequestLogLevel.info,
        method: 'GET',
        path: '/test',
        headers: {},
      );

      expect(() => logger.log(entry), returnsNormally);
      expect(() => logger.flush(), returnsNormally);
    });
  });

  group('HttpLogger', () {
    late TestHttpServer testServer;

    setUp(() async {
      testServer = TestHttpServer();
      await testServer.start();
    });

    tearDown(() {
      testServer.stop();
    });

    test('sends logs to HTTP endpoint', () async {
      final logger = HttpLogger(
        endpoint: testServer.endpoint,
        maxBufferSize: 1, // Force immediate flush
      );

      final entry = LogEntry(
        id: 'test-123',
        timestamp: DateTime.now(),
        level: RequestLogLevel.info,
        method: 'GET',
        path: '/test',
        headers: {},
      );

      await logger.log(entry);
      await Future.delayed(
          Duration(milliseconds: 100)); // Allow HTTP request to complete

      expect(testServer.receivedLogs, hasLength(1));
      expect(testServer.receivedLogs.first['logs'], hasLength(1));
      expect(testServer.receivedLogs.first['logs'].first['id'], 'test-123');
    });

    test('buffers logs and sends in batches', () async {
      final logger = HttpLogger(
        endpoint: testServer.endpoint,
        maxBufferSize: 3,
      );

      // Add 2 entries (should not trigger flush)
      await logger.log(LogEntry(
        id: 'test-1',
        timestamp: DateTime.now(),
        level: RequestLogLevel.info,
        method: 'GET',
        path: '/test1',
        headers: {},
      ));

      await logger.log(LogEntry(
        id: 'test-2',
        timestamp: DateTime.now(),
        level: RequestLogLevel.info,
        method: 'GET',
        path: '/test2',
        headers: {},
      ));

      await Future.delayed(Duration(milliseconds: 50));
      expect(testServer.receivedLogs, isEmpty);

      // Add third entry (should trigger flush)
      await logger.log(LogEntry(
        id: 'test-3',
        timestamp: DateTime.now(),
        level: RequestLogLevel.info,
        method: 'GET',
        path: '/test3',
        headers: {},
      ));

      await Future.delayed(Duration(milliseconds: 100));
      expect(testServer.receivedLogs, hasLength(1));
      expect(testServer.receivedLogs.first['logs'], hasLength(3));
    });
  });

  group('CompositeLogger', () {
    test('logs to multiple loggers', () async {
      final logger1 = TestLogger();
      final logger2 = TestLogger();
      final composite = CompositeLogger([logger1, logger2]);

      final entry = LogEntry(
        id: 'test',
        timestamp: DateTime.now(),
        level: RequestLogLevel.info,
        method: 'GET',
        path: '/test',
        headers: {},
      );

      await composite.log(entry);

      expect(logger1.entries, hasLength(1));
      expect(logger2.entries, hasLength(1));
      expect(logger1.entries.first.id, 'test');
      expect(logger2.entries.first.id, 'test');
    });
  });

  group('requestLogger middleware', () {
    late TestLogger testLogger;

    setUp(() {
      testLogger = TestLogger();
    });

    test('logs basic GET request and response', () async {
      final middleware = requestLogger(logger: testLogger);
      final handler = middleware((request) => Response.ok('Hello, World!'));

      final response = await makeRequest(handler, method: 'GET');
      expect(response.statusCode, 200);

      expect(testLogger.entries, hasLength(2)); // Request + Response

      final requestEntry = testLogger.entries[0];
      expect(requestEntry.method, 'GET');
      expect(requestEntry.level, RequestLogLevel.info);
      expect(requestEntry.metadata['type'], 'request');

      final responseEntry = testLogger.entries[1];
      expect(responseEntry.statusCode, 200);
      expect(responseEntry.level, RequestLogLevel.info);
      expect(responseEntry.metadata['type'], 'response');
    });

    test('logs request and response bodies when enabled', () async {
      final middleware = requestLogger(
        logger: testLogger,
        logRequestBody: true,
        logResponseBody: true,
      );
      final handler = middleware((request) => Response.ok('Response Body'));

      await makeRequest(
        handler,
        method: 'POST',
        body: 'Request Body',
      );

      expect(testLogger.entries, hasLength(2));

      final requestEntry = testLogger.entries[0];
      expect(requestEntry.body, 'Request Body');

      final responseEntry = testLogger.entries[1];
      expect(responseEntry.body, 'Response Body');
    });

    test('masks sensitive headers', () async {
      final middleware = requestLogger(logger: testLogger);
      final handler = middleware((request) => Response.ok('OK'));

      await makeRequest(
        handler,
        method: 'GET',
        headers: {
          'Authorization': 'Bearer secret-token',
          'X-API-Key': 'api-key-123',
          'Content-Type': 'application/json',
        },
      );

      final requestEntry = testLogger.entries[0];
      expect(requestEntry.headers['Authorization'], '***MASKED***');
      expect(requestEntry.headers['X-API-Key'], '***MASKED***');
      expect(requestEntry.headers['Content-Type'], 'application/json');
    });

    test('masks sensitive query parameters', () async {
      final middleware = requestLogger(logger: testLogger);
      final handler = middleware((request) => Response.ok('OK'));

      await makeRequest(
        handler,
        method: 'GET',
        url: 'http://localhost/?password=secret&username=john&token=abc123',
      );

      final requestEntry = testLogger.entries[0];
      expect(requestEntry.query, contains('password=***MASKED***'));
      expect(requestEntry.query, contains('username=john'));
      expect(requestEntry.query, contains('token=***MASKED***'));
    });

    test('respects minimum log level', () async {
      final middleware = requestLogger(
        logger: testLogger,
        minLevel: RequestLogLevel.warning,
      );
      final handler = middleware((request) => Response.ok('OK'));

      await makeRequest(handler, method: 'GET');

      // Info level entries should be filtered out
      expect(testLogger.entries, isEmpty);
    });

    test('logs errors with stack traces', () async {
      final middleware = requestLogger(logger: testLogger);
      final handler = middleware((request) {
        throw Exception('Test error');
      });

      try {
        await makeRequest(handler, method: 'GET');
        fail('Expected exception to be thrown');
      } catch (e) {
        expect(e, isA<Exception>());
      }

      expect(testLogger.entries, hasLength(2)); // Request + Error

      final errorEntry = testLogger.entries[1];
      expect(errorEntry.level, RequestLogLevel.error);
      expect(errorEntry.error, contains('Test error'));
      expect(errorEntry.stackTrace, isNotNull);
      expect(errorEntry.metadata['type'], 'error');
    });

    test('logs warning for error status codes', () async {
      final middleware = requestLogger(logger: testLogger);
      final handler = middleware((request) => Response.notFound('Not found'));

      await makeRequest(handler, method: 'GET');

      expect(testLogger.entries, hasLength(2));

      final responseEntry = testLogger.entries[1];
      expect(responseEntry.level, RequestLogLevel.warning);
      expect(responseEntry.statusCode, 404);
    });

    test('excludes specified paths from logging', () async {
      final middleware = requestLogger(
        logger: testLogger,
        excludePaths: ['/health', '/metrics'],
      );
      final handler = middleware((request) => Response.ok('OK'));

      await makeRequest(handler, method: 'GET', url: 'http://localhost/health');
      expect(testLogger.entries, isEmpty);

      await makeRequest(handler, method: 'GET', url: 'http://localhost/api');
      expect(testLogger.entries, hasLength(2));
    });

    test('extracts custom metadata', () async {
      final middleware = requestLogger(
        logger: testLogger,
        metadataExtractor: (request) => {
          'service': 'test-service',
          'version': '1.0.0',
          'custom_header': request.headers['x-custom'] ?? 'none',
        },
      );
      final handler = middleware((request) => Response.ok('OK'));

      await makeRequest(
        handler,
        method: 'GET',
        headers: {'X-Custom': 'custom-value'},
      );

      final requestEntry = testLogger.entries[0];
      expect(requestEntry.metadata['service'], 'test-service');
      expect(requestEntry.metadata['version'], '1.0.0');
      expect(requestEntry.metadata['custom_header'], 'custom-value');
    });

    test('captures timing information', () async {
      fakeAsync((async) async {
        final middleware = requestLogger(
          logger: testLogger,
          logTiming: true,
        );
        final handler = middleware((request) async {
          // Simulate some processing time
          async.elapse(Duration(milliseconds: 100));
          return Response.ok('OK');
        });

        await makeRequest(handler, method: 'GET');

        final responseEntry = testLogger.entries[1];
        expect(responseEntry.duration, isNotNull);
        expect(responseEntry.duration!.inMilliseconds, 100);
      });
    });

    test('can disable request or response logging', () async {
      final middleware = requestLogger(
        logger: testLogger,
        logRequests: false,
        logResponses: true,
      );
      final handler = middleware((request) => Response.ok('OK'));

      await makeRequest(handler, method: 'GET');

      expect(testLogger.entries, hasLength(1));
      expect(testLogger.entries[0].metadata['type'], 'response');
    });

    test('handles custom privacy configuration', () async {
      final privacyConfig = PrivacyConfig(
        sensitiveHeaders: {'x-secret'},
        sensitiveQueryParams: {'secret_param'},
        maskRequestBody: true,
        maskResponseBody: true,
        maskValue: '[REDACTED]',
      );

      final middleware = requestLogger(
        logger: testLogger,
        logRequestBody: true,
        logResponseBody: true,
        privacyConfig: privacyConfig,
      );
      final handler = middleware((request) => Response.ok('Response Body'));

      await makeRequest(
        handler,
        method: 'POST',
        body: 'Request Body',
        headers: {'X-Secret': 'secret-value'},
        url: 'http://localhost/?secret_param=secret&public=value',
      );

      final requestEntry = testLogger.entries[0];
      expect(requestEntry.headers['X-Secret'], '[REDACTED]');
      expect(requestEntry.query, contains('secret_param=[REDACTED]'));
      expect(requestEntry.query, contains('public=value'));
      expect(requestEntry.body, '[REDACTED]');

      final responseEntry = testLogger.entries[1];
      expect(responseEntry.body, '[REDACTED]');
    });

    test('captures client IP and user agent', () async {
      final middleware = requestLogger(logger: testLogger);
      final handler = middleware((request) => Response.ok('OK'));

      await makeRequest(
        handler,
        method: 'GET',
        headers: {
          'User-Agent': 'TestAgent/1.0',
          'X-Forwarded-For': '192.168.1.100',
        },
      );

      final requestEntry = testLogger.entries[0];
      expect(requestEntry.userAgent, 'TestAgent/1.0');
      expect(requestEntry.clientIp, '192.168.1.100');
    });

    test('generates unique request IDs', () async {
      final middleware = requestLogger(logger: testLogger);
      final handler = middleware((request) => Response.ok('OK'));

      await makeRequest(handler, method: 'GET');
      await makeRequest(handler, method: 'GET');

      expect(testLogger.entries, hasLength(4));

      final firstRequestId = testLogger.entries[0].id;
      final secondRequestId = testLogger.entries[2].id;

      expect(firstRequestId, isNot(equals(secondRequestId)));
      expect(testLogger.entries[0].id,
          equals(testLogger.entries[1].id)); // Request and response share ID
    });
  });
}
