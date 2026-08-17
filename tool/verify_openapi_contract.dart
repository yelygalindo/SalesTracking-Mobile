import 'dart:convert';
import 'dart:io';

const _defaultSwaggerUrl =
    'https://salestracking-api.kindriver-61f4971f.brazilsouth.'
    'azurecontainerapps.io/swagger/v1/swagger.json';

Future<void> main(List<String> arguments) async {
  final swaggerUrl = arguments
      .where((argument) => argument.startsWith('--swagger-url='))
      .map((argument) => argument.substring('--swagger-url='.length))
      .firstOrNull;
  final uri = Uri.parse(swaggerUrl ?? _defaultSwaggerUrl);
  final spec = await _download(uri);
  final failures = <String>[];

  final operations = <_OperationExpectation>[
    const _OperationExpectation(
      '/api/auth/login',
      'post',
      body: ['email', 'password', 'deviceType', 'deviceId'],
    ),
    const _OperationExpectation(
      '/api/auth/forgot-password',
      'post',
      body: ['email'],
    ),
    const _OperationExpectation(
      '/api/auth/reset-password',
      'post',
      body: ['token', 'newPassword', 'confirmPassword'],
    ),
    const _OperationExpectation('/api/workdays/current', 'get'),
    const _OperationExpectation(
      '/api/workdays',
      'post',
      body: ['startedAtUtc', 'latitude', 'longitude', 'clientRequestId'],
    ),
    const _OperationExpectation(
      '/api/workdays/{externalId}/close',
      'patch',
      body: ['endedAtUtc', 'latitude', 'longitude', 'clientRequestId'],
    ),
    const _OperationExpectation(
      '/api/customers',
      'get',
      query: ['Status', 'ExternalUserId', 'Search', 'Page', 'PageSize'],
    ),
    const _OperationExpectation('/api/customers', 'post'),
    const _OperationExpectation('/api/customers/statuses', 'get'),
    const _OperationExpectation('/api/customers/{externalId}', 'get'),
    const _OperationExpectation('/api/customers/{externalId}', 'put'),
    const _OperationExpectation(
      '/api/customers/{externalId}/status',
      'patch',
      body: ['statusId'],
    ),
    const _OperationExpectation(
      '/api/customers/{customerExternalId}/notes',
      'post',
      body: ['text', 'clientRequestId'],
    ),
    const _OperationExpectation(
      '/api/customers/{customerExternalId}/reminders',
      'post',
      body: ['text', 'reminderAtUtc'],
    ),
    const _OperationExpectation(
      '/api/customers/{customerExternalId}/reminders/{reminderExternalId}/complete',
      'patch',
    ),
    const _OperationExpectation(
      '/api/projects',
      'get',
      query: ['status', 'customerId', 'sellerId', 'page', 'pageSize'],
    ),
    const _OperationExpectation('/api/projects', 'post'),
    const _OperationExpectation('/api/projects/statuses', 'get'),
    const _OperationExpectation('/api/projects/{externalId}', 'get'),
    const _OperationExpectation('/api/projects/{externalId}', 'put'),
    const _OperationExpectation(
      '/api/projects/{externalId}/status',
      'patch',
      body: ['statusId'],
    ),
    const _OperationExpectation(
      '/api/projects/{projectExternalId}/notes',
      'get',
    ),
    const _OperationExpectation(
      '/api/projects/{projectExternalId}/notes',
      'post',
      body: ['content', 'clientRequestId', 'occurredAtUtc'],
    ),
    const _OperationExpectation(
      '/api/projects/{projectExternalId}/timeline',
      'get',
      query: ['Page', 'PageSize'],
    ),
    const _OperationExpectation(
      '/api/customers/{customerExternalId}/visits',
      'post',
      body: ['checkInAtUtc', 'latitude', 'longitude', 'clientRequestId'],
    ),
    const _OperationExpectation(
      '/api/customers/{customerExternalId}/visits/{visitExternalId}/checkout',
      'patch',
      body: ['checkOutAtUtc', 'latitude', 'longitude', 'clientRequestId'],
    ),
    const _OperationExpectation(
      '/api/projects/{projectExternalId}/visits',
      'post',
      body: ['checkInAtUtc', 'latitude', 'longitude', 'clientRequestId'],
    ),
    const _OperationExpectation(
      '/api/projects/{projectExternalId}/visits',
      'get',
      query: ['SellerExternalId', 'From', 'To'],
    ),
    const _OperationExpectation(
      '/api/projects/{projectExternalId}/visits/{visitExternalId}/checkout',
      'patch',
      body: ['checkOutAtUtc', 'latitude', 'longitude', 'clientRequestId'],
    ),
    const _OperationExpectation('/api/visits/current', 'get'),
    const _OperationExpectation(
      '/api/visits',
      'get',
      query: ['SellerExternalId', 'From', 'To'],
    ),
    const _OperationExpectation(
      '/api/sellers/{sellerExternalId}/timeline',
      'get',
      query: ['From', 'To', 'Page', 'PageSize'],
    ),
    const _OperationExpectation('/api/project-attachments/options', 'get'),
    const _OperationExpectation(
      '/api/projects/{projectExternalId}/attachments',
      'get',
    ),
    const _OperationExpectation(
      '/api/projects/{projectExternalId}/attachments',
      'post',
      body: [
        'File',
        'AttachmentType',
        'Caption',
        'IsCover',
        'VisitExternalId',
        'OccurredAtUtc',
        'ClientRequestId',
      ],
    ),
  ];

  for (final expectation in operations) {
    _verifyOperation(spec, expectation, failures);
  }

  _verifyResponse(spec, '/api/visits/current', 'get', [
    'type',
    'visitExternalId',
    'targetExternalId',
    'targetName',
    'checkInAtUtc',
    'latitude',
    'longitude',
  ], failures);
  _verifyResponse(spec, '/api/visits', 'get', [
    'externalId',
    'projectExternalId',
    'projectName',
    'visitedAtUtc',
    'latitude',
    'longitude',
    'checkOutAtUtc',
    'result',
    'sellerExternalId',
    'sellerName',
  ], failures);
  _verifyResponse(spec, '/api/sellers/{sellerExternalId}/timeline', 'get', [
    'externalId',
    'eventType',
    'resourceType',
    'resourceExternalId',
    'title',
    'description',
    'occurredAtUtc',
  ], failures);
  _verifyResponse(spec, '/api/projects/{projectExternalId}/notes', 'get', [
    'externalId',
    'content',
    'createdBy',
    'createdAtUtc',
    'occurredAtUtc',
    'receivedAtUtc',
  ], failures);
  _verifyResponse(spec, '/api/projects/{projectExternalId}/timeline', 'get', [
    'externalId',
    'eventTypeId',
    'eventTypeName',
    'title',
    'description',
    'occurredAtUtc',
    'createdBy',
    'visitExternalId',
  ], failures);

  if (failures.isNotEmpty) {
    stderr.writeln('OpenAPI contract verification failed:');
    for (final failure in failures) {
      stderr.writeln('- $failure');
    }
    exitCode = 1;
    return;
  }
  stdout.writeln(
    'OpenAPI contract OK: ${operations.length} operations and '
    '5 response schemas verified.',
  );
}

Future<Map<String, dynamic>> _download(Uri uri) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
  try {
    final request = await client.getUrl(uri);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'Swagger responded with HTTP ${response.statusCode}.',
        uri: uri,
      );
    }
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const FormatException('Swagger root is not an object.');
  } finally {
    client.close(force: true);
  }
}

void _verifyOperation(
  Map<String, dynamic> spec,
  _OperationExpectation expectation,
  List<String> failures,
) {
  final operation = _operation(spec, expectation.path, expectation.method);
  if (operation == null) {
    failures.add(
      '${expectation.method.toUpperCase()} ${expectation.path} missing.',
    );
    return;
  }

  final parameters = operation['parameters'];
  final queryNames = parameters is List
      ? parameters
            .whereType<Map<String, dynamic>>()
            .where((parameter) => parameter['in'] == 'query')
            .map((parameter) => parameter['name'])
            .whereType<String>()
            .toSet()
      : const <String>{};
  for (final name in expectation.query) {
    if (!queryNames.contains(name)) {
      failures.add(
        '${expectation.method.toUpperCase()} ${expectation.path} '
        'query parameter "$name" missing.',
      );
    }
  }

  if (expectation.body.isEmpty) return;
  final schema = _requestSchema(spec, operation);
  final properties = _properties(spec, schema);
  for (final name in expectation.body) {
    if (!properties.contains(name)) {
      failures.add(
        '${expectation.method.toUpperCase()} ${expectation.path} '
        'request field "$name" missing.',
      );
    }
  }
}

void _verifyResponse(
  Map<String, dynamic> spec,
  String path,
  String method,
  List<String> expectedProperties,
  List<String> failures,
) {
  final operation = _operation(spec, path, method);
  if (operation == null) return;
  final schema = _successResponseSchema(spec, operation);
  final properties = _properties(spec, schema);
  for (final name in expectedProperties) {
    if (!properties.contains(name)) {
      failures.add(
        '${method.toUpperCase()} $path response field "$name" missing.',
      );
    }
  }
}

Map<String, dynamic>? _operation(
  Map<String, dynamic> spec,
  String path,
  String method,
) {
  final paths = spec['paths'];
  if (paths is! Map<String, dynamic>) return null;
  final pathItem = paths[path];
  if (pathItem is! Map<String, dynamic>) return null;
  final operation = pathItem[method];
  return operation is Map<String, dynamic> ? operation : null;
}

Map<String, dynamic> _requestSchema(
  Map<String, dynamic> spec,
  Map<String, dynamic> operation,
) {
  final requestBody = operation['requestBody'];
  if (requestBody is! Map<String, dynamic>) return const {};
  final content = requestBody['content'];
  if (content is! Map<String, dynamic>) return const {};
  for (final type in const ['application/json', 'multipart/form-data']) {
    final media = content[type];
    if (media is Map<String, dynamic> &&
        media['schema'] is Map<String, dynamic>) {
      return _resolve(spec, media['schema'] as Map<String, dynamic>);
    }
  }
  return const {};
}

Map<String, dynamic> _successResponseSchema(
  Map<String, dynamic> spec,
  Map<String, dynamic> operation,
) {
  final responses = operation['responses'];
  if (responses is! Map<String, dynamic>) return const {};
  for (final entry in responses.entries) {
    if (!entry.key.startsWith('2')) continue;
    final response = entry.value;
    if (response is! Map<String, dynamic>) continue;
    final content = response['content'];
    if (content is! Map<String, dynamic>) continue;
    final media = content['application/json'] ?? content['text/json'];
    if (media is! Map<String, dynamic> ||
        media['schema'] is! Map<String, dynamic>) {
      continue;
    }
    var schema = _resolve(spec, media['schema'] as Map<String, dynamic>);
    if (schema['items'] is Map<String, dynamic>) {
      schema = _resolve(spec, schema['items'] as Map<String, dynamic>);
    } else {
      final properties = schema['properties'];
      if (properties is Map<String, dynamic> &&
          properties['items'] is Map<String, dynamic>) {
        final itemsProperty = _resolve(
          spec,
          properties['items'] as Map<String, dynamic>,
        );
        if (itemsProperty['items'] is Map<String, dynamic>) {
          schema = _resolve(
            spec,
            itemsProperty['items'] as Map<String, dynamic>,
          );
        }
      }
    }
    return schema;
  }
  return const {};
}

Set<String> _properties(
  Map<String, dynamic> spec,
  Map<String, dynamic> schema,
) {
  final resolved = _resolve(spec, schema);
  final properties = resolved['properties'];
  return properties is Map<String, dynamic>
      ? properties.keys.toSet()
      : const <String>{};
}

Map<String, dynamic> _resolve(
  Map<String, dynamic> spec,
  Map<String, dynamic> schema,
) {
  final reference = schema[r'$ref'];
  if (reference is! String || !reference.startsWith('#/')) return schema;
  Object? current = spec;
  for (final segment in reference.substring(2).split('/')) {
    if (current is! Map<String, dynamic>) return const {};
    current = current[segment.replaceAll('~1', '/').replaceAll('~0', '~')];
  }
  return current is Map<String, dynamic> ? current : const {};
}

class _OperationExpectation {
  const _OperationExpectation(
    this.path,
    this.method, {
    this.query = const [],
    this.body = const [],
  });

  final String path;
  final String method;
  final List<String> query;
  final List<String> body;
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
