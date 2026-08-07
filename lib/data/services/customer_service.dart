import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/customer/customer_page.dart';
import '../models/customer/customer_detail.dart';
import '../models/customer/customer_input.dart';
import '../models/customer/customer_status.dart';
import '../models/common/resource_creation_result.dart';
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
    final response = await _request('GET', uri, accessToken);
    return CustomerPage.fromJson(_decodeObject(response.bodyBytes));
  }

  Future<List<CustomerStatus>> getStatuses(String accessToken) async {
    final response = await _request(
      'GET',
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

  Future<CustomerDetail> getCustomer(
    String accessToken,
    String externalId,
  ) async {
    final response = await _request(
      'GET',
      _baseUrl.resolve('/api/customers/${Uri.encodeComponent(externalId)}'),
      accessToken,
    );
    return CustomerDetail.fromJson(_decodeObject(response.bodyBytes));
  }

  Future<ResourceCreationResult> createCustomer(
    String accessToken,
    CustomerInput input,
    String clientRequestId,
  ) async {
    final response = await _request(
      'POST',
      _baseUrl.resolve('/api/customers'),
      accessToken,
      payload: input.toCreateJson(clientRequestId),
    );
    return ResourceCreationResult.fromJson(_decodeObject(response.bodyBytes));
  }

  Future<void> updateCustomer(
    String accessToken,
    String externalId,
    CustomerInput input,
  ) async {
    await _request(
      'PUT',
      _baseUrl.resolve('/api/customers/${Uri.encodeComponent(externalId)}'),
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
        '/api/customers/${Uri.encodeComponent(externalId)}/status',
      ),
      accessToken,
      payload: {'statusId': statusId},
    );
  }

  Future<ResourceCreationResult> addNote(
    String accessToken,
    String externalId,
    String text,
    String clientRequestId,
  ) async {
    final response = await _request(
      'POST',
      _baseUrl.resolve(
        '/api/customers/${Uri.encodeComponent(externalId)}/notes',
      ),
      accessToken,
      payload: {'text': text.trim(), 'clientRequestId': clientRequestId},
    );
    return ResourceCreationResult.fromJson(_decodeObject(response.bodyBytes));
  }

  Future<ResourceCreationResult> addReminder(
    String accessToken,
    String externalId, {
    required String text,
    required DateTime reminderAtUtc,
    String? assignedToId,
  }) async {
    final response = await _request(
      'POST',
      _baseUrl.resolve(
        '/api/customers/${Uri.encodeComponent(externalId)}/reminders',
      ),
      accessToken,
      payload: {
        'text': text.trim(),
        'reminderAtUtc': reminderAtUtc.toUtc().toIso8601String(),
        'assignedToId': assignedToId,
      },
    );
    return ResourceCreationResult.fromJson(_decodeObject(response.bodyBytes));
  }

  Future<void> completeReminder(
    String accessToken,
    String customerExternalId,
    String reminderExternalId,
  ) async {
    await _request(
      'PATCH',
      _baseUrl.resolve(
        '/api/customers/${Uri.encodeComponent(customerExternalId)}/reminders/'
        '${Uri.encodeComponent(reminderExternalId)}/complete',
      ),
      accessToken,
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
      404 => 'No se encontró el cliente.',
      400 => 'No se pudo guardar el cliente con estos datos.',
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
