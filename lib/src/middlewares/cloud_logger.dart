import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';
import 'package:top_shelf/src/middlewares/request_logger.dart';

// =============================================================================
// EXPERIMENTAL CLOUD PROVIDER MIDDLEWARES
// =============================================================================
//
// ⚠️  EXPERIMENTAL FEATURES WARNING ⚠️
//
// The following cloud provider middlewares are experimental and may change
// in future versions without notice:
//
// • awsCloudWatchLogger()     - AWS CloudWatch Logs integration
// • googleCloudLogger()       - Google Cloud Logging integration  
// • azureMonitorLogger()      - Azure Monitor Logs integration
// • datadogLogger()           - Datadog Logs integration
// • elasticLogger()           - Elasticsearch/Logstash integration
// • webhookLogger()           - Generic webhook integration
//
// These middlewares should be thoroughly tested before use in production.
// For stable logging functionality, use the base requestLogger() with
// ConsoleLogger(), HttpLogger(), or CompositeLogger().
//
// =============================================================================

/// Generic cloud logging middleware for production environments
/// 
/// A production-ready middleware that sends structured logs to any HTTP endpoint
/// with built-in security, performance optimizations, and privacy controls.
/// 
/// ## Features
/// - **Automatic batching**: Efficiently groups log entries for bulk sending
/// - **Privacy protection**: Masks sensitive headers and query parameters
/// - **Performance optimized**: Excludes request/response bodies by default
/// - **Error resilience**: Continues operation even if logging fails
/// - **Custom metadata**: Supports application-specific context
/// 
/// ## Example Usage
/// ```dart
/// final handler = Pipeline()
///     .addMiddleware(cloudLogger(
///       endpoint: 'https://logs.your-service.com/api/ingest',
///       headers: {'Authorization': 'Bearer your-token'},
///       maxBufferSize: 50,
///       flushInterval: Duration(seconds: 30),
///       metadataExtractor: (request) => {
///         'service': 'my-api',
///         'version': '1.0.0',
///       },
///     ))
///     .addHandler(myHandler);
/// ```
/// 
/// ## Configuration
/// - [endpoint]: HTTP URL where logs will be sent via POST requests
/// - [headers]: Authentication and custom headers for the logging service
/// - [minLevel]: Minimum log level to process (filters out lower priority logs)
/// - [excludePaths]: Paths to skip logging (typically health checks, metrics)
/// - [metadataExtractor]: Function to add custom metadata to each log entry
/// - [maxBufferSize]: Maximum number of log entries to buffer before sending
/// - [flushInterval]: How often to send buffered logs to the endpoint
/// 
/// ## Privacy & Security
/// Automatically masks sensitive data including:
/// - Authorization headers, cookies, API keys, session tokens
/// - Password, token, secret query parameters
/// - Request and response bodies (can be enabled if needed)
/// 
/// ## Performance
/// Optimized for production with:
/// - No request/response body logging by default
/// - Automatic exclusion of monitoring endpoints
/// - Efficient batching to reduce network overhead
/// - Non-blocking operation that doesn't affect request processing
Middleware cloudLogger({
  required String endpoint,
  Map<String, String> headers = const {},
  RequestLogLevel minLevel = RequestLogLevel.info,
  List<String> excludePaths = const ['/health', '/ready', '/metrics'],
  Map<String, dynamic> Function(Request)? metadataExtractor,
  int maxBufferSize = 100,
  Duration flushInterval = const Duration(seconds: 30),
}) {
  return requestLogger(
    logger: HttpLogger(
      endpoint: endpoint,
      headers: headers,
      maxBufferSize: maxBufferSize,
      flushInterval: flushInterval,
    ),
    minLevel: minLevel,
    logRequests: true,
    logResponses: true,
    logRequestBody: false,
    logResponseBody: false,
    logHeaders: true,
    logTiming: true,
    excludePaths: excludePaths,
    privacyConfig: const PrivacyConfig(
      sensitiveHeaders: {
        'authorization',
        'cookie',
        'x-api-key',
        'x-auth-token',
        'x-session-token',
      },
      sensitiveQueryParams: {
        'password',
        'token',
        'api_key',
        'secret',
        'session_id',
      },
      maskRequestBody: true,
      maskResponseBody: true,
      maskValue: '[REDACTED]',
    ),
    metadataExtractor: metadataExtractor,
  );
}

/// **EXPERIMENTAL** AWS CloudWatch Logs middleware for Amazon Web Services integration
/// 
/// ⚠️ **EXPERIMENTAL FEATURE**: This middleware is in experimental status.
/// The API may change in future versions without notice. Thoroughly test
/// before using in production environments.
/// 
/// Sends structured logs directly to AWS CloudWatch Logs for monitoring,
/// alerting, and analysis within the AWS ecosystem.
/// 
/// ## Prerequisites
/// - AWS account with CloudWatch Logs access
/// - Log group created in CloudWatch
/// - IAM credentials with `logs:PutLogEvents` permission
/// 
/// ## Example Usage
/// ```dart
/// final handler = Pipeline()
///     .addMiddleware(awsCloudWatchLogger(
///       logGroupName: '/aws/lambda/my-api',
///       region: 'us-east-1',
///       accessKeyId: 'AKIAI...', // Use environment variables in production
///       secretAccessKey: 'wJalr...', // Use environment variables in production
///       metadataExtractor: (request) => {
///         'aws_request_id': request.headers['x-amzn-requestid'],
///         'function_name': 'my-api-function',
///       },
///     ))
///     .addHandler(myHandler);
/// ```
/// 
/// ## Security Note
/// Store AWS credentials securely using:
/// - Environment variables
/// - AWS IAM roles (recommended for EC2/Lambda)
/// - AWS Secrets Manager
/// - Never hardcode credentials in source code
/// 
/// ## Parameters
/// - [logGroupName]: Target CloudWatch log group (must exist)
/// - [region]: AWS region where the log group is located
/// - [accessKeyId]: AWS access key ID for authentication
/// - [secretAccessKey]: AWS secret access key for authentication
/// - [minLevel]: Minimum log level to send to CloudWatch
/// - [excludePaths]: Paths to exclude from logging
/// - [metadataExtractor]: Function to add AWS-specific metadata
@experimental
Middleware awsCloudWatchLogger({
  required String logGroupName,
  required String region,
  required String accessKeyId,
  required String secretAccessKey,
  RequestLogLevel minLevel = RequestLogLevel.info,
  List<String> excludePaths = const ['/health', '/ready', '/metrics'],
  Map<String, dynamic> Function(Request)? metadataExtractor,
}) {
  return cloudLogger(
    endpoint: 'https://logs.$region.amazonaws.com/',
    headers: {
      'X-Amz-Target': 'Logs_20140328.PutLogEvents',
      'Content-Type': 'application/x-amz-json-1.1',
      'Authorization': 'AWS4-HMAC-SHA256 $accessKeyId:$secretAccessKey',
    },
    minLevel: minLevel,
    excludePaths: excludePaths,
    metadataExtractor: (request) => {
      'aws_log_group': logGroupName,
      'aws_region': region,
      ...?metadataExtractor?.call(request),
    },
  );
}

/// **EXPERIMENTAL** Google Cloud Logging middleware for Google Cloud Platform integration
/// 
/// ⚠️ **EXPERIMENTAL FEATURE**: This middleware is in experimental status.
/// The API may change in future versions without notice. Thoroughly test
/// before using in production environments.
/// 
/// Integrates with Google Cloud Logging (formerly Stackdriver) for centralized
/// log management, monitoring, and analysis within the Google Cloud ecosystem.
/// 
/// ## Prerequisites
/// - Google Cloud Project with Cloud Logging API enabled
/// - Service account with `logging.logEntries.create` permission
/// - Valid OAuth 2.0 access token or service account key
/// 
/// ## Example Usage
/// ```dart
/// final handler = Pipeline()
///     .addMiddleware(googleCloudLogger(
///       projectId: 'my-gcp-project-123',
///       accessToken: 'ya29.c.El...', // Use service account in production
///       metadataExtractor: (request) => {
///         'gcp_trace_id': request.headers['x-cloud-trace-context'],
///         'instance_id': Platform.environment['GAE_INSTANCE'],
///       },
///     ))
///     .addHandler(myHandler);
/// ```
/// 
/// ## Authentication
/// For production, use service account authentication:
/// ```dart
/// // Use Google Cloud client libraries for proper authentication
/// final credentials = ServiceAccountCredentials.fromJson(serviceAccountJson);
/// final accessToken = await credentials.createScoped(scopes).refreshToken();
/// ```
/// 
/// ## Integration Features
/// - Automatic correlation with Google Cloud Trace
/// - Support for structured logging with labels
/// - Integration with Google Cloud Error Reporting
/// - Automatic resource detection for GCE, GKE, GAE
/// 
/// ## Parameters
/// - [projectId]: Google Cloud Project ID where logs will be stored
/// - [accessToken]: OAuth 2.0 access token for authentication
/// - [minLevel]: Minimum log level to send to Cloud Logging
/// - [excludePaths]: Paths to exclude from logging
/// - [metadataExtractor]: Function to add GCP-specific metadata
@experimental
Middleware googleCloudLogger({
  required String projectId,
  required String accessToken,
  RequestLogLevel minLevel = RequestLogLevel.info,
  List<String> excludePaths = const ['/health', '/ready', '/metrics'],
  Map<String, dynamic> Function(Request)? metadataExtractor,
}) {
  return cloudLogger(
    endpoint: 'https://logging.googleapis.com/v2/entries:write',
    headers: {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    },
    minLevel: minLevel,
    excludePaths: excludePaths,
    metadataExtractor: (request) => {
      'gcp_project_id': projectId,
      'resource': {
        'type': 'gce_instance',
        'labels': {'project_id': projectId},
      },
      ...?metadataExtractor?.call(request),
    },
  );
}

/// **EXPERIMENTAL** Azure Monitor Logs middleware for Microsoft Azure integration
/// 
/// ⚠️ **EXPERIMENTAL FEATURE**: This middleware is in experimental status.
/// The API may change in future versions without notice. Thoroughly test
/// before using in production environments.
/// 
/// Sends logs to Azure Monitor Logs (formerly Log Analytics) for monitoring,
/// alerting, and analysis within the Microsoft Azure ecosystem.
/// 
/// ## Prerequisites
/// - Azure subscription with Log Analytics workspace
/// - Workspace ID and primary/secondary shared key
/// - Custom log type defined (will be created automatically if it doesn't exist)
/// 
/// ## Example Usage
/// ```dart
/// final handler = Pipeline()
///     .addMiddleware(azureMonitorLogger(
///       workspaceId: '12345678-1234-1234-1234-123456789abc',
///       sharedKey: 'aBcDeFg...', // Primary or secondary key from workspace
///       logType: 'MyApiLogs', // Custom log type (will appear as MyApiLogs_CL)
///       metadataExtractor: (request) => {
///         'subscription_id': 'sub-123',
///         'resource_group': 'my-api-rg',
///         'app_service': 'my-api-app',
///       },
///     ))
///     .addHandler(myHandler);
/// ```
/// 
/// ## Security Best Practices
/// - Store workspace credentials in Azure Key Vault
/// - Use managed identity when running on Azure resources
/// - Rotate shared keys regularly
/// - Monitor access to workspace keys
/// 
/// ## Features
/// - Automatic timestamp indexing
/// - Integration with Azure Monitor alerts
/// - KQL (Kusto Query Language) support for log analysis
/// - Custom dashboards and workbooks
/// - Integration with Azure Sentinel for security analysis
/// 
/// ## Parameters
/// - [workspaceId]: Unique identifier for your Log Analytics workspace
/// - [sharedKey]: Primary or secondary shared key for workspace authentication
/// - [logType]: Custom log type name (suffix '_CL' will be added automatically)
/// - [minLevel]: Minimum log level to send to Azure Monitor
/// - [excludePaths]: Paths to exclude from logging
/// - [metadataExtractor]: Function to add Azure-specific metadata
@experimental
Middleware azureMonitorLogger({
  required String workspaceId,
  required String sharedKey,
  required String logType,
  RequestLogLevel minLevel = RequestLogLevel.info,
  List<String> excludePaths = const ['/health', '/ready', '/metrics'],
  Map<String, dynamic> Function(Request)? metadataExtractor,
}) {
  return cloudLogger(
    endpoint: 'https://$workspaceId.ods.opinsights.azure.com/api/logs',
    headers: {
      'Authorization': 'SharedKey $workspaceId:$sharedKey',
      'Content-Type': 'application/json',
      'Log-Type': logType,
    },
    minLevel: minLevel,
    excludePaths: excludePaths,
    metadataExtractor: (request) => {
      'azure_workspace_id': workspaceId,
      'azure_log_type': logType,
      ...?metadataExtractor?.call(request),
    },
  );
}

/// **EXPERIMENTAL** Datadog Logs middleware for Datadog monitoring platform integration
/// 
/// ⚠️ **EXPERIMENTAL FEATURE**: This middleware is in experimental status.
/// The API may change in future versions without notice. Thoroughly test
/// before using in production environments.
/// 
/// Sends structured logs to Datadog for comprehensive monitoring, alerting,
/// and APM (Application Performance Monitoring) correlation.
/// 
/// ## Prerequisites
/// - Datadog account with Logs feature enabled
/// - API key with logs write permissions
/// - Choose appropriate Datadog site (US1, EU, etc.)
/// 
/// ## Example Usage
/// ```dart
/// final handler = Pipeline()
///     .addMiddleware(datadogLogger(
///       apiKey: 'pub_1234567890abcdef', // Use environment variable in production
///       site: 'datadoghq.com', // or 'datadoghq.eu', 'us3.datadoghq.com', etc.
///       source: 'dart-api',
///       service: 'user-service',
///       metadataExtractor: (request) => {
///         'dd.trace_id': request.headers['x-datadog-trace-id'],
///         'dd.span_id': request.headers['x-datadog-parent-id'],
///         'env': 'production',
///         'version': '1.2.3',
///       },
///     ))
///     .addHandler(myHandler);
/// ```
/// 
/// ## Datadog Integration Features
/// - Automatic correlation with APM traces when trace headers are present
/// - Support for log facets and filtering
/// - Integration with Datadog dashboards and monitors
/// - Log-based metrics and alerts
/// - Automatic parsing of structured JSON logs
/// 
/// ## Tagging Best Practices
/// Use consistent tags for better filtering and correlation:
/// - `env`: Environment (production, staging, development)
/// - `service`: Service name for microservices architecture
/// - `version`: Application version for deployment tracking
/// - `source`: Technology stack identifier
/// 
/// ## Parameters
/// - [apiKey]: Datadog API key for log ingestion (keep secure!)
/// - [site]: Datadog site URL (varies by region)
/// - [source]: Source technology identifier (appears in Datadog UI)
/// - [service]: Service name for grouping and filtering
/// - [minLevel]: Minimum log level to send to Datadog
/// - [excludePaths]: Paths to exclude from logging
/// - [metadataExtractor]: Function to add Datadog-specific tags and metadata
@experimental
Middleware datadogLogger({
  required String apiKey,
  required String site,
  String source = 'dart',
  String service = 'api',
  RequestLogLevel minLevel = RequestLogLevel.info,
  List<String> excludePaths = const ['/health', '/ready', '/metrics'],
  Map<String, dynamic> Function(Request)? metadataExtractor,
}) {
  return cloudLogger(
    endpoint: 'https://http-intake.logs.$site/v1/input/$apiKey',
    headers: {
      'Content-Type': 'application/json',
      'DD-API-KEY': apiKey,
    },
    minLevel: minLevel,
    excludePaths: excludePaths,
    metadataExtractor: (request) => {
      'ddsource': source,
      'service': service,
      'ddtags': 'env:production,source:$source',
      ...?metadataExtractor?.call(request),
    },
  );
}

/// **EXPERIMENTAL** Elasticsearch/Logstash middleware for Elastic Stack integration
/// 
/// ⚠️ **EXPERIMENTAL FEATURE**: This middleware is in experimental status.
/// The API may change in future versions without notice. Thoroughly test
/// before using in production environments.
/// 
/// Sends logs directly to Elasticsearch or through Logstash for the ELK
/// (Elasticsearch, Logstash, Kibana) stack integration, enabling powerful
/// search, analysis, and visualization capabilities.
/// 
/// ## Prerequisites
/// - Elasticsearch cluster (self-hosted or Elastic Cloud)
/// - Index template configured for log structure
/// - Authentication credentials (if security is enabled)
/// - Network connectivity to Elasticsearch/Logstash endpoint
/// 
/// ## Example Usage
/// ```dart
/// // Direct to Elasticsearch
/// final handler = Pipeline()
///     .addMiddleware(elasticLogger(
///       endpoint: 'https://my-cluster.es.io:9200',
///       username: 'elastic',
///       password: 'your-password', // Use environment variable in production
///       index: 'api-logs-2024',
///       metadataExtractor: (request) => {
///         '@timestamp': DateTime.now().toIso8601String(),
///         'environment': 'production',
///         'application': 'user-api',
///         'log_level': 'info',
///       },
///     ))
///     .addHandler(myHandler);
/// 
/// // Through Logstash
/// final handler = Pipeline()
///     .addMiddleware(elasticLogger(
///       endpoint: 'https://logstash.company.com:5044',
///       index: 'api-logs', // Logstash will handle index routing
///     ))
///     .addHandler(myHandler);
/// ```
/// 
/// ## Index Management
/// - Use time-based indices for better performance: `api-logs-2024-01`
/// - Configure index templates for consistent field mapping
/// - Set up index lifecycle policies for automatic rollover
/// - Consider shard allocation based on data volume
/// 
/// ## Security
/// - Enable TLS for production deployments
/// - Use Elasticsearch security features (X-Pack)
/// - Store credentials securely (environment variables, vault)
/// - Configure proper user roles and permissions
/// 
/// ## Integration with Kibana
/// - Create index patterns in Kibana for log visualization
/// - Build dashboards for monitoring API performance
/// - Set up alerts for error rates and response times
/// - Use Kibana Lens for advanced analytics
/// 
/// ## Parameters
/// - [endpoint]: Elasticsearch or Logstash endpoint URL
/// - [username]: Username for basic authentication (optional)
/// - [password]: Password for basic authentication (optional)
/// - [index]: Target index name (supports time-based patterns)
/// - [minLevel]: Minimum log level to send to Elasticsearch
/// - [excludePaths]: Paths to exclude from logging
/// - [metadataExtractor]: Function to add Elastic-specific metadata
@experimental
Middleware elasticLogger({
  required String endpoint,
  String? username,
  String? password,
  String index = 'api-logs',
  RequestLogLevel minLevel = RequestLogLevel.info,
  List<String> excludePaths = const ['/health', '/ready', '/metrics'],
  Map<String, dynamic> Function(Request)? metadataExtractor,
}) {
  final headers = <String, String>{
    'Content-Type': 'application/json',
  };

  if (username != null && password != null) {
    headers['Authorization'] = 'Basic $username:$password';
  }

  return cloudLogger(
    endpoint: '$endpoint/$index/_doc',
    headers: headers,
    minLevel: minLevel,
    excludePaths: excludePaths,
    metadataExtractor: (request) => {
      'elastic_index': index,
      '@timestamp': DateTime.now().toIso8601String(),
      ...?metadataExtractor?.call(request),
    },
  );
}

/// **EXPERIMENTAL** Generic webhook logger for custom logging services and integrations
/// 
/// ⚠️ **EXPERIMENTAL FEATURE**: This middleware is in experimental status.
/// The API may change in future versions without notice. Thoroughly test
/// before using in production environments.
/// 
/// Sends structured logs to any HTTP endpoint via POST requests, making it
/// ideal for custom logging services, third-party integrations, and
/// webhook-based monitoring systems.
/// 
/// ## Use Cases
/// - Custom logging services and internal tools
/// - Slack/Discord notifications for critical errors
/// - Third-party monitoring and alerting services
/// - Legacy systems integration
/// - Custom analytics and business intelligence
/// 
/// ## Example Usage
/// ```dart
/// // Custom logging service
/// final handler = Pipeline()
///     .addMiddleware(webhookLogger(
///       webhookUrl: 'https://logs.your-company.com/api/ingest',
///       headers: {
///         'Authorization': 'Bearer your-api-token',
///         'X-Service-Name': 'user-api',
///         'X-Environment': 'production',
///       },
///       metadataExtractor: (request) => {
///         'application': 'user-service',
///         'team': 'backend',
///         'alert_channel': '#api-alerts',
///       },
///     ))
///     .addHandler(myHandler);
/// 
/// // Slack webhook for errors only
/// final handler = Pipeline()
///     .addMiddleware(webhookLogger(
///       webhookUrl: 'https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX',
///       minLevel: RequestLogLevel.error, // Only send errors
///       headers: {'Content-Type': 'application/json'},
///       metadataExtractor: (request) => {
///         'channel': '#critical-alerts',
///         'username': 'API Monitor',
///         'icon_emoji': ':warning:',
///       },
///     ))
///     .addHandler(myHandler);
/// ```
/// 
/// ## Webhook Payload
/// The middleware sends POST requests with this structure:
/// ```json
/// {
///   "logs": [
///     {
///       "id": "1672531200000_123",
///       "timestamp": "2024-01-01T12:00:00.000Z",
///       "level": "error",
///       "method": "POST",
///       "path": "/api/users",
///       "statusCode": 500,
///       "error": "Database connection failed",
///       "metadata": {
///         "application": "user-service",
///         "team": "backend"
///       }
///     }
///   ],
///   "batch_id": "1672531200000"
/// }
/// ```
/// 
/// ## Integration Tips
/// - Use appropriate `Content-Type` headers for your webhook service
/// - Include authentication tokens in headers for security
/// - Set `minLevel` to `error` or `warning` for alert-only webhooks
/// - Use `metadataExtractor` to format data for specific services
/// - Test webhook endpoints with sample payloads before deployment
/// 
/// ## Parameters
/// - [webhookUrl]: Target webhook URL that accepts POST requests
/// - [headers]: Custom headers for authentication and content type
/// - [minLevel]: Minimum log level to send to the webhook
/// - [excludePaths]: Paths to exclude from logging
/// - [metadataExtractor]: Function to add service-specific metadata
@experimental
Middleware webhookLogger({
  required String webhookUrl,
  Map<String, String> headers = const {},
  RequestLogLevel minLevel = RequestLogLevel.info,
  List<String> excludePaths = const ['/health', '/ready', '/metrics'],
  Map<String, dynamic> Function(Request)? metadataExtractor,
}) {
  return cloudLogger(
    endpoint: webhookUrl,
    headers: {
      'Content-Type': 'application/json',
      ...headers,
    },
    minLevel: minLevel,
    excludePaths: excludePaths,
    metadataExtractor: metadataExtractor,
  );
}
