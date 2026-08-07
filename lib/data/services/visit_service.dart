import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/common/location_sample.dart';
import '../models/common/resource_creation_result.dart';
import '../models/visit/current_visit.dart';
import '../models/visit/visit_target_type.dart';
import 'api_exception.dart';

class VisitService {
  VisitService(
    this._baseUrl,
    this._client, {
    this.timeout = const Duration(seconds: 20),
  });

  final Uri _baseUrl;
  final http.Client _client;
  final Duration timeout;

  Future<CurrentVisit?> getCurrent(String accessToken) async {
    final response = await _request(
      'GET',
      _baseUrl.resolve('/api/visits/current'),
      accessToken,
    );
    if (response.statusCode == 204 || response.bodyBytes.isEmpty) return null;
    return CurrentVisit.fromJson(_decodeObject(response.bodyBytes));
  }

  Future<ResourceCreationResult> checkIn(
    String accessToken, {
    required VisitTargetType targetType,
    required String targetExternalId,
    required DateTime checkInAtUtc,
    required LocationSample location,
    required String clientRequestId,
    String? note,
  }) async {
    final response = await _request(
      'POST',
      _targetUri(targetType, targetExternalId),
      accessToken,
      payload: {
        'checkInAtUtc': checkInAtUtc.toUtc().toIso8601String(),
        'latitude': location.latitude,
        'longitude': location.longitude,
        'note': note?.trim(),
        'clientRequestId': clientRequestId,
      },
    );
    return ResourceCreationResult.fromJson(_decodeObject(response.bodyBytes));
  }

  Future<ResourceCreationResult> checkOut(
    String accessToken, {
    required VisitTargetType targetType,
    required String targetExternalId,
    required String visitExternalId,
    required DateTime checkOutAtUtc,
    required LocationSample location,
    required String clientRequestId,
    String? note,
    String? result,
  }) async {
    final base = _targetUri(targetType, targetExternalId).toString();
    final response = await _request(
      'PATCH',
      Uri.parse('$base/${Uri.encodeComponent(visitExternalId)}/checkout'),
      accessToken,
      payload: {
        'checkOutAtUtc': checkOutAtUtc.toUtc().toIso8601String(),
        'latitude': location.latitude,
        'longitude': location.longitude,
        'note': note?.trim(),
        'result': result?.trim(),
        'clientRequestId': clientRequestId,
      },
    );
    return ResourceCreationResult.fromJson(_decodeObject(response.bodyBytes));
  }

  Uri _targetUri(VisitTargetType type, String externalId) {
    final segment = type == VisitTargetType.customer ? 'customers' : 'projects';
    return _baseUrl.resolve(
      '/api/$segment/${Uri.encodeComponent(externalId)}/visits',
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
      // Mapped below.
    }
    throw const ApiException(
      message: 'El servidor devolvió una visita no válida.',
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
        // Fall through.
      }
    }
    return switch (statusCode) {
      401 => 'Tu sesión expiró. Inicia sesión nuevamente.',
      404 => 'No se encontró la visita.',
      409 => 'Ya existe una visita en curso.',
      400 => 'No se pudo registrar la visita con estos datos.',
      >= 500 => 'El servidor no está disponible en este momento.',
      _ => 'No se pudo completar la operación de visita.',
    };
  }
}
