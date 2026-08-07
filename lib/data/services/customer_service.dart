import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/customer/customer_page.dart';
import '../models/customer/customer_status.dart';
import 'api_exception.dart';

class CustomerService {
  CustomerService(
    this._baseUrl,
    this._client, {
    this.timeout = const Duration(seconds: 20),
  });

  final Uri _baseUrl;
  final http.Client _client;
  final Duration timeout;

  Future<CustomerPage> getCustomers(
    String accessToken, {
    String? status,
    String? externalUserId,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    final uri = _baseUrl
        .resolve('/api/customers')
        .replace(
          queryParameters: {
            if (status?.trim().isNotEmpty == true) 'Status': status!.trim(),
            if (externalUserId?.trim().isNotEmpty == true)
              'ExternalUserId': externalUserId!.trim(),
            if (search?.trim().isNotEmpty == true) 'Search': search!.trim(),
            'Page': '$page',
            'PageSize': '$pageSize',
          },
        );
    final response = await _get(uri, accessToken);
    return CustomerPage.fromJson(_decodeObject(response.bodyBytes));
  }

  Future<List<CustomerStatus>> getStatuses(String accessToken) async {
    final response = await _get(
      _baseUrl.resolve('/api/customers/statuses'),
      accessToken,
    );
    final decoded = _decode(response.bodyBytes);
    if (decoded is! List) {
      throw const ApiException(
        message: 'El servidor devolvió estados de cliente no válidos.',
      );
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(CustomerStatus.fromJson)
        .where((status) => status.label.isNotEmpty)
        .toList(growable: false);
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

  Object? _decode(List<int> bytes) {
    try {
      return jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw const ApiException(
        message: 'El servidor devolvió una respuesta no válida.',
      );
    }
  }

  Map<String, dynamic> _decodeObject(List<int> bytes) {
    final decoded = _decode(bytes);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const ApiException(
      message: 'El servidor devolvió una respuesta no válida.',
    );
  }

  String _errorMessage(int statusCode, List<int> bytes) {
    if (bytes.isNotEmpty) {
      final decoded = _safeDecode(bytes);
      if (decoded is Map<String, dynamic>) {
        final message =
            decoded['error'] ?? decoded['details'] ?? decoded['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    }
    return switch (statusCode) {
      401 => 'Tu sesión expiró. Inicia sesión nuevamente.',
      >= 500 => 'El servidor no está disponible en este momento.',
      _ => 'No se pudieron consultar los clientes.',
    };
  }

  Object? _safeDecode(List<int> bytes) {
    try {
      return jsonDecode(utf8.decode(bytes));
    } on FormatException {
      return null;
    }
  }
}
