import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../models/project/project_detail.dart';
import '../models/project/project_input.dart';
import '../models/project/project_note.dart';
import '../models/project/project_page.dart';
import '../models/project/project_reminder.dart';
import '../models/project/project_status.dart';
import '../models/project/project_timeline_page.dart';
import '../models/common/resource_creation_result.dart';
import 'api_exception.dart';

class ProjectService {
  ProjectService(
    this._baseUrl,
    this._client, {
    this.timeout = const Duration(seconds: 20),
    String Function()? requestId,
  }) : _requestId = requestId ?? const Uuid().v4;

  final Uri _baseUrl;
  final http.Client _client;
  final Duration timeout;
  final String Function() _requestId;

  Future<ProjectPage> getProjects(
    String accessToken, {
    String? status,
    String? customerId,
    String? sellerId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final uri = _baseUrl
        .resolve('/api/projects')
        .replace(
          queryParameters: {
            if (status?.trim().isNotEmpty == true) 'status': status!.trim(),
            if (customerId?.trim().isNotEmpty == true)
              'customerId': customerId!.trim(),
            if (sellerId?.trim().isNotEmpty == true)
              'sellerId': sellerId!.trim(),
            'page': '$page',
            'pageSize': '$pageSize',
          },
        );
    final response = await _request('GET', uri, accessToken);
    return ProjectPage.fromJson(_decodeObject(response.bodyBytes));
  }

  Future<ProjectDetail> getProject(
    String accessToken,
    String externalId,
  ) async {
    final response = await _request(
      'GET',
      _baseUrl.resolve('/api/projects/${Uri.encodeComponent(externalId)}'),
      accessToken,
    );
    return ProjectDetail.fromJson(_decodeObject(response.bodyBytes));
  }

  Future<List<ProjectStatus>> getStatuses(String accessToken) async {
    final response = await _request(
      'GET',
      _baseUrl.resolve('/api/projects/statuses'),
      accessToken,
    );
    final decoded = _decode(response.bodyBytes);
    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ProjectStatus.fromJson)
          .where((status) => status.value > 0 && status.label.isNotEmpty)
          .toList(growable: false);
    }
    throw const ApiException(
      message: 'El servidor devolvió estados de obra no válidos.',
    );
  }

  Future<List<ProjectNote>> getNotes(
    String accessToken,
    String projectExternalId,
  ) async {
    final response = await _request(
      'GET',
      _baseUrl.resolve(
        '/api/projects/${Uri.encodeComponent(projectExternalId)}/notes',
      ),
      accessToken,
    );
    final decoded = _decode(response.bodyBytes);
    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ProjectNote.fromJson)
          .toList(growable: false);
    }
    throw const ApiException(
      message: 'El servidor devolvió notas de obra no válidas.',
    );
  }

  Future<ResourceCreationResult> addNote(
    String accessToken,
    String projectExternalId, {
    required String content,
    required String clientRequestId,
    required DateTime occurredAtUtc,
  }) async {
    final response = await _request(
      'POST',
      _baseUrl.resolve(
        '/api/projects/${Uri.encodeComponent(projectExternalId)}/notes',
      ),
      accessToken,
      payload: {
        'content': content.trim(),
        'clientRequestId': clientRequestId,
        'occurredAtUtc': occurredAtUtc.toUtc().toIso8601String(),
      },
    );
    return ResourceCreationResult.fromJson(_decodeObject(response.bodyBytes));
  }

  Future<List<ProjectReminder>> getReminders(
    String accessToken,
    String projectExternalId, {
    bool? completed,
  }) async {
    final uri = _baseUrl
        .resolve(
          '/api/projects/${Uri.encodeComponent(projectExternalId)}/reminders',
        )
        .replace(
          queryParameters: {if (completed != null) 'completed': '$completed'},
        );
    final response = await _request('GET', uri, accessToken);
    final decoded = _decode(response.bodyBytes);
    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ProjectReminder.fromJson)
          .toList(growable: false);
    }
    throw const ApiException(
      message: 'El servidor devolvió recordatorios de obra no válidos.',
    );
  }

  Future<ResourceCreationResult> addReminder(
    String accessToken,
    String projectExternalId, {
    required String text,
    required DateTime reminderAtUtc,
    required String clientRequestId,
    String? assignedToId,
  }) async {
    final response = await _request(
      'POST',
      _baseUrl.resolve(
        '/api/projects/${Uri.encodeComponent(projectExternalId)}/reminders',
      ),
      accessToken,
      payload: {
        'text': text.trim(),
        'reminderAtUtc': reminderAtUtc.toUtc().toIso8601String(),
        'assignedToId': assignedToId,
        'clientRequestId': clientRequestId,
      },
    );
    return ResourceCreationResult.fromJson(_decodeObject(response.bodyBytes));
  }

  Future<void> completeReminder(
    String accessToken,
    String projectExternalId,
    String reminderExternalId,
    String clientRequestId,
  ) async {
    await _request(
      'PATCH',
      _baseUrl.resolve(
        '/api/projects/${Uri.encodeComponent(projectExternalId)}/reminders/'
        '${Uri.encodeComponent(reminderExternalId)}/complete',
      ),
      accessToken,
      payload: {'clientRequestId': clientRequestId},
    );
  }

  Future<ProjectTimelinePage> getTimeline(
    String accessToken,
    String projectExternalId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    final uri = _baseUrl
        .resolve(
          '/api/projects/${Uri.encodeComponent(projectExternalId)}/timeline',
        )
        .replace(queryParameters: {'Page': '$page', 'PageSize': '$pageSize'});
    final response = await _request('GET', uri, accessToken);
    return ProjectTimelinePage.fromJson(_decodeObject(response.bodyBytes));
  }

  Future<ProjectDetail> createProject(
    String accessToken,
    ProjectInput input,
    String clientRequestId,
  ) async {
    final response = await _request(
      'POST',
      _baseUrl.resolve('/api/projects'),
      accessToken,
      payload: input.toCreateJson(clientRequestId),
    );
    return ProjectDetail.fromJson(_decodeObject(response.bodyBytes));
  }

  Future<void> updateProject(
    String accessToken,
    String externalId,
    ProjectInput input,
  ) async {
    final payload = input.toJson();
    final expectedUpdatedAtUtc = payload['expectedUpdatedAtUtc'];
    if (expectedUpdatedAtUtc is! String ||
        expectedUpdatedAtUtc.trim().isEmpty) {
      throw const ApiException(
        message:
            'No pudimos obtener la versión actual de la obra. Recarga los datos antes de guardar.',
      );
    }
    await _request(
      'PUT',
      _baseUrl.resolve('/api/projects/${Uri.encodeComponent(externalId)}'),
      accessToken,
      payload: payload,
    );
  }

  Future<void> changeStatus(
    String accessToken,
    String externalId,
    int statusId,
  ) async {
    await _request(
      'PATCH',
      _baseUrl.resolve(
        '/api/projects/${Uri.encodeComponent(externalId)}/status',
      ),
      accessToken,
      payload: {'statusId': statusId, 'clientRequestId': _requestId()},
    );
  }

  Future<http.Response> _request(
    String method,
    Uri uri,
    String accessToken, {
    Map<String, dynamic>? payload,
  }) async {
    try {
      final headers = {
        HttpHeaders.acceptHeader: 'application/json',
        HttpHeaders.authorizationHeader: 'Bearer $accessToken',
        if (payload != null)
          HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
      };
      final future = switch (method) {
        'GET' => _client.get(uri, headers: headers),
        'POST' => _client.post(
          uri,
          headers: headers,
          body: jsonEncode(payload),
        ),
        'PUT' => _client.put(uri, headers: headers, body: jsonEncode(payload)),
        'PATCH' => _client.patch(
          uri,
          headers: headers,
          body: jsonEncode(payload),
        ),
        _ => throw ArgumentError.value(method, 'method'),
      };
      final response = await future.timeout(timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }
      throw ApiException(
        statusCode: response.statusCode,
        message: _errorMessage(response.statusCode, response.bodyBytes),
      );
    } on TimeoutException {
      throw const ApiException(
        message: 'La conexión tardó demasiado. Inténtalo nuevamente.',
      );
    } on http.ClientException {
      throw const ApiException(message: 'No se pudo conectar con el servidor.');
    } on SocketException {
      throw const ApiException(message: 'No hay conexión a Internet.');
    }
  }

  Map<String, dynamic> _decodeObject(List<int> bytes) {
    final decoded = _decode(bytes);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const ApiException(
      message: 'El servidor devolvió una respuesta de obras no válida.',
    );
  }

  Object? _decode(List<int> bytes) {
    try {
      return jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw const ApiException(
        message: 'El servidor devolvió una respuesta de obras no válida.',
      );
    }
  }

  String _errorMessage(int statusCode, List<int> bytes) {
    if (bytes.isNotEmpty) {
      try {
        final decoded = jsonDecode(utf8.decode(bytes));
        if (decoded is Map<String, dynamic>) {
          final value =
              decoded['error'] ?? decoded['details'] ?? decoded['message'];
          if (value is String && value.trim().isNotEmpty) return value.trim();
        }
      } on FormatException {
        // Fall through to the status-based message.
      }
    }
    return switch (statusCode) {
      401 => 'Tu sesión expiró. Inicia sesión nuevamente.',
      404 => 'No se encontró la obra.',
      400 => 'No se pudo guardar la obra con estos datos.',
      >= 500 => 'El servidor no está disponible en este momento.',
      _ => 'No se pudieron consultar las obras.',
    };
  }
}
