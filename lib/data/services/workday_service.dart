import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/workday/close_workday_request.dart';
import '../models/workday/current_workday_response.dart';
import '../models/workday/start_workday_request.dart';
import '../models/workday/workday.dart';
import '../models/workday/workday_operation_response.dart';
import 'api_exception.dart';

class WorkdayService {
  WorkdayService(
    this._baseUrl,
    this._client, {
    this.timeout = const Duration(seconds: 20),
  });

  final Uri _baseUrl;
  final http.Client _client;
  final Duration timeout;

  Future<CurrentWorkdayResponse> getCurrent(String accessToken) async {
    final response = await _request(
      method: 'GET',
      path: '/api/workdays/current',
      accessToken: accessToken,
    );
    return CurrentWorkdayResponse.fromJson(_decodeObject(response.bodyBytes));
  }

  Future<Workday> start(String accessToken, StartWorkdayRequest request) async {
    final response = await _request(
      method: 'POST',
      path: '/api/workdays',
      accessToken: accessToken,
      payload: request.toJson(),
    );
    return WorkdayOperationResponse.fromJson(
      _decodeObject(response.bodyBytes),
    ).workday;
  }

  Future<Workday> close(
    String accessToken,
    String externalId,
    CloseWorkdayRequest request,
  ) async {
    final response = await _request(
      method: 'PATCH',
      path: '/api/workdays/${Uri.encodeComponent(externalId)}/close',
      accessToken: accessToken,
      payload: request.toJson(),
    );
    return WorkdayOperationResponse.fromJson(
      _decodeObject(response.bodyBytes),
    ).workday;
  }

  Future<http.Response> _request({
    required String method,
    required String path,
    required String accessToken,
    Map<String, dynamic>? payload,
  }) async {
    final headers = {
      HttpHeaders.acceptHeader: 'application/json',
      HttpHeaders.authorizationHeader: 'Bearer $accessToken',
      if (payload != null)
        HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
    };

    try {
      final future = switch (method) {
        'GET' => _client.get(_baseUrl.resolve(path), headers: headers),
        'POST' => _client.post(
          _baseUrl.resolve(path),
          headers: headers,
          body: jsonEncode(payload),
        ),
        'PATCH' => _client.patch(
          _baseUrl.resolve(path),
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
      if (decoded case final Map<String, dynamic> object) return object;
      throw const FormatException('Expected a JSON object.');
    } on FormatException {
      throw const ApiException(
        message: 'El servidor devolvió una respuesta no válida.',
      );
    }
  }

  String _errorMessage(int statusCode, List<int> bytes) {
    if (bytes.isNotEmpty) {
      try {
        final decoded = jsonDecode(utf8.decode(bytes));
        if (decoded is Map<String, dynamic>) {
          final message =
              decoded['error'] ??
              decoded['details'] ??
              decoded['message'] ??
              decoded['title'];
          if (message is String && message.trim().isNotEmpty) {
            return message.trim();
          }
        }
      } on FormatException {
        // Fall back to a safe status-based message.
      }
    }

    return switch (statusCode) {
      400 => 'No se pudo registrar la jornada con estos datos.',
      401 => 'Tu sesión expiró. Inicia sesión nuevamente.',
      404 => 'No se encontró la jornada.',
      409 =>
        'La jornada cambió en el servidor. Actualiza e inténtalo nuevamente.',
      >= 500 => 'El servidor no está disponible en este momento.',
      _ => 'No se pudo completar la solicitud.',
    };
  }
}
