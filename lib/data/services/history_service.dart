import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/history/project_visit.dart';
import '../models/history/seller_timeline_page.dart';
import 'api_exception.dart';

class HistoryService {
  const HistoryService(
    this._baseUrl,
    this._client, {
    this.timeout = const Duration(seconds: 20),
  });

  final Uri _baseUrl;
  final http.Client _client;
  final Duration timeout;

  Future<SellerTimelinePage> getSellerTimeline(
    String accessToken,
    String sellerExternalId, {
    DateTime? from,
    DateTime? to,
    int page = 1,
    int pageSize = 30,
  }) async {
    final uri = _baseUrl
        .resolve(
          '/api/sellers/${Uri.encodeComponent(sellerExternalId)}/timeline',
        )
        .replace(
          queryParameters: {
            if (from != null) 'From': from.toUtc().toIso8601String(),
            if (to != null) 'To': to.toUtc().toIso8601String(),
            'Page': '$page',
            'PageSize': '$pageSize',
          },
        );
    final response = await _get(uri, accessToken);
    return SellerTimelinePage.fromJson(_decodeObject(response.bodyBytes));
  }

  Future<List<ProjectVisit>> getProjectVisits(
    String accessToken,
    String projectExternalId, {
    String? sellerExternalId,
    DateTime? from,
    DateTime? to,
  }) async {
    final uri = _baseUrl
        .resolve(
          '/api/projects/${Uri.encodeComponent(projectExternalId)}/visits',
        )
        .replace(
          queryParameters: {
            if (sellerExternalId?.trim().isNotEmpty == true)
              'SellerExternalId': sellerExternalId!.trim(),
            if (from != null) 'From': from.toUtc().toIso8601String(),
            if (to != null) 'To': to.toUtc().toIso8601String(),
          },
        );
    final response = await _get(uri, accessToken);
    final decoded = _decode(response.bodyBytes);
    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ProjectVisit.fromJson)
          .toList(growable: false);
    }
    throw const ApiException(
      message: 'El servidor devolvió un historial de visitas no válido.',
    );
  }

  Future<http.Response> _get(Uri uri, String accessToken) async {
    try {
      final response = await _client
          .get(
            uri,
            headers: {
              HttpHeaders.acceptHeader: 'application/json',
              HttpHeaders.authorizationHeader: 'Bearer $accessToken',
            },
          )
          .timeout(timeout);
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
      message: 'El servidor devolvió un historial no válido.',
    );
  }

  Object? _decode(List<int> bytes) {
    try {
      return jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw const ApiException(
        message: 'El servidor devolvió un historial no válido.',
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
        // Fall through to the stable status message.
      }
    }
    return switch (statusCode) {
      401 => 'Tu sesión expiró. Inicia sesión nuevamente.',
      404 => 'No se encontró el historial solicitado.',
      >= 500 => 'El servidor no está disponible en este momento.',
      _ => 'No se pudo consultar el historial.',
    };
  }
}
