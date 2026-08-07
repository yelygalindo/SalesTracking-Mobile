import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/attachment/attachment_source_file.dart';
import '../models/attachment/attachment_upload_options.dart';
import '../models/attachment/project_attachment.dart';
import 'api_exception.dart';

class ProjectAttachmentService {
  ProjectAttachmentService(
    this._baseUrl,
    this._client, {
    this.timeout = const Duration(seconds: 45),
  });

  final Uri _baseUrl;
  final http.Client _client;
  final Duration timeout;

  Future<AttachmentUploadOptions> getOptions(String accessToken) async {
    final response = await _get(
      _baseUrl.resolve('/api/project-attachments/options'),
      accessToken,
    );
    return AttachmentUploadOptions.fromJson(_decodeObject(response.bodyBytes));
  }

  Future<List<ProjectAttachment>> getAttachments(
    String accessToken,
    String projectExternalId,
  ) async {
    final response = await _get(
      _baseUrl.resolve(
        '/api/projects/${Uri.encodeComponent(projectExternalId)}/attachments',
      ),
      accessToken,
    );
    final decoded = _decode(response.bodyBytes);
    if (decoded is! List) {
      throw const ApiException(
        message: 'El servidor devolvió evidencias no válidas.',
      );
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ProjectAttachment.fromJson)
        .toList(growable: false);
  }

  Future<void> upload(
    String accessToken, {
    required String projectExternalId,
    required AttachmentSourceFile source,
    required String attachmentType,
    String? visitExternalId,
    String? caption,
    bool isCover = false,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      _baseUrl.resolve(
        '/api/projects/${Uri.encodeComponent(projectExternalId)}/attachments',
      ),
    );
    request.headers[HttpHeaders.acceptHeader] = 'application/json';
    request.headers[HttpHeaders.authorizationHeader] = 'Bearer $accessToken';
    request.fields['AttachmentType'] = attachmentType;
    request.fields['Caption'] = caption?.trim() ?? '';
    request.fields['IsCover'] = '$isCover';
    if (visitExternalId?.isNotEmpty == true) {
      request.fields['VisitExternalId'] = visitExternalId!;
    }
    request.files.add(
      await http.MultipartFile.fromPath(
        'File',
        source.path,
        filename: source.fileName,
        contentType: MediaType.parse(source.contentType),
      ),
    );

    try {
      final streamed = await _client.send(request).timeout(timeout);
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode >= 200 && response.statusCode < 300) return;
      throw ApiException(
        statusCode: response.statusCode,
        message: _errorMessage(response.statusCode, response.bodyBytes),
      );
    } on TimeoutException {
      throw const ApiException(
        message: 'La carga tardó demasiado. La fotografía sigue guardada.',
      );
    } on http.ClientException {
      throw const ApiException(
        message: 'No se pudo conectar para cargar la fotografía.',
      );
    } on SocketException {
      throw const ApiException(
        message: 'No hay conexión. La fotografía sigue guardada.',
      );
    }
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
      throw const ApiException(message: 'La conexión tardó demasiado.');
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
      message: 'El servidor devolvió opciones de evidencia no válidas.',
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
      400 => 'El archivo no cumple los requisitos permitidos.',
      404 => 'No se encontró la obra o la visita.',
      413 => 'La fotografía supera el tamaño permitido.',
      >= 500 => 'El servidor no está disponible en este momento.',
      _ => 'No se pudo cargar la evidencia.',
    };
  }
}
