import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/project/project_detail.dart';
import '../models/project/project_input.dart';
import '../models/project/project_page.dart';
import 'api_exception.dart';

class ProjectService {
  ProjectService(
    this._baseUrl,
    this._client, {
    this.timeout = const Duration(seconds: 20),
  });

  final Uri _baseUrl;
  final http.Client _client;
  final Duration timeout;

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
    await _request(
      'PUT',
      _baseUrl.resolve('/api/projects/${Uri.encodeComponent(externalId)}'),
      accessToken,
      payload: input.toJson(),
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
      payload: {'statusId': statusId},
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
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      // Mapped below to a stable domain error.
    }
    throw const ApiException(
      message: 'El servidor devolvió una respuesta de obras no válida.',
    );
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
