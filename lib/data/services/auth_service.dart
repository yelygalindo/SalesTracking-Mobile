import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/auth/auth_session.dart';
import '../models/auth/auth_message_response.dart';
import '../models/auth/forgot_password_request.dart';
import '../models/auth/login_request.dart';
import '../models/auth/refresh_tokens.dart';
import '../models/auth/reset_password_request.dart';
import 'api_exception.dart';

class AuthService {
  AuthService(
    this._baseUrl,
    this._client, {
    this.timeout = const Duration(seconds: 45),
  });

  final Uri _baseUrl;
  final http.Client _client;
  final Duration timeout;

  Future<AuthSession> login(LoginRequest request) async {
    final response = await _post('/api/auth/login', request.toJson());
    return AuthSession.fromJson(_decodeObject(response.bodyBytes));
  }

  Future<RefreshTokens> refresh(String refreshToken) async {
    final response = await _post('/api/auth/refresh-token', {
      'refreshToken': refreshToken,
    });
    return RefreshTokens.fromJson(_decodeObject(response.bodyBytes));
  }

  Future<String> forgotPassword(ForgotPasswordRequest request) async {
    await _post('/api/auth/forgot-password', request.toJson());
    return 'Si el correo está registrado, recibirás instrucciones para restablecer tu contraseña.';
  }

  Future<String> resetPassword(ResetPasswordRequest request) async {
    final response = await _post('/api/auth/reset-password', request.toJson());
    final result = AuthMessageResponse.fromJson(
      _decodeObject(response.bodyBytes),
    );
    return result.message?.trim().isNotEmpty == true
        ? result.message!.trim()
        : 'Tu contraseña fue actualizada correctamente.';
  }

  Future<void> logout({
    required AuthSession session,
    required String deviceId,
  }) async {
    await _post('/api/auth/logout', {
      'refreshToken': session.refreshToken,
      'deviceId': deviceId,
    }, accessToken: session.accessToken);
  }

  Future<http.Response> _post(
    String path,
    Map<String, dynamic> payload, {
    String? accessToken,
  }) async {
    try {
      final response = await _client
          .post(
            _baseUrl.resolve(path),
            headers: {
              HttpHeaders.acceptHeader: 'application/json',
              HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
              if (accessToken != null)
                HttpHeaders.authorizationHeader: 'Bearer $accessToken',
            },
            body: jsonEncode(payload),
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
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded case final Map<String, dynamic> object) {
        return object;
      }
      throw const FormatException('Expected a JSON object.');
    } on FormatException {
      throw const ApiException(
        message: 'El servidor devolvió una respuesta no válida.',
      );
    }
  }

  String _errorMessage(int statusCode, List<int> bytes) {
    final serverMessage = _tryReadServerMessage(bytes);
    if (serverMessage != null) return serverMessage;

    return switch (statusCode) {
      400 => 'Revisa los datos ingresados.',
      401 => 'Correo o contraseña incorrectos.',
      403 => 'No tienes permiso para realizar esta acción.',
      >= 500 => 'El servidor no está disponible en este momento.',
      _ => 'No se pudo completar la solicitud.',
    };
  }

  String? _tryReadServerMessage(List<int> bytes) {
    if (bytes.isEmpty) return null;
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) return null;
      final message = decoded['message'] ?? decoded['title'];
      return message is String && message.trim().isNotEmpty
          ? message.trim()
          : null;
    } on FormatException {
      return null;
    }
  }
}
