import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:urbantrack/data/models/auth/login_request.dart';
import 'package:urbantrack/data/services/api_exception.dart';
import 'package:urbantrack/data/services/auth_service.dart';
import 'package:urbantrack/data/services/customer_service.dart';
import 'package:urbantrack/data/services/history_service.dart';
import 'package:urbantrack/data/services/project_attachment_service.dart';
import 'package:urbantrack/data/services/project_service.dart';
import 'package:urbantrack/data/services/visit_service.dart';
import 'package:urbantrack/data/services/workday_service.dart';

const _defaultApiBaseUrl =
    'https://salestracking-api.kindriver-61f4971f.brazilsouth.'
    'azurecontainerapps.io';

Future<void> main() async {
  final email = _requiredEnvironment('URBANTRACK_SMOKE_EMAIL');
  final password = _requiredEnvironment('URBANTRACK_SMOKE_PASSWORD');
  final baseUrl = Uri.parse(
    Platform.environment['API_BASE_URL']?.trim().isNotEmpty == true
        ? Platform.environment['API_BASE_URL']!.trim()
        : _defaultApiBaseUrl,
  );
  final client = http.Client();

  try {
    final auth = AuthService(baseUrl, client);
    final session = await _verify('Authentication', () {
      return auth.login(
        LoginRequest(
          email: email,
          password: password,
          deviceType: 'qa-readonly',
          deviceId: 'urbantrack-readonly-smoke',
        ),
      );
    });

    final token = session.accessToken;
    final customers = CustomerService(baseUrl, client);
    final projects = ProjectService(baseUrl, client);
    final workdays = WorkdayService(baseUrl, client);
    final visits = VisitService(baseUrl, client);
    final history = HistoryService(baseUrl, client);
    final attachments = ProjectAttachmentService(baseUrl, client);

    await _verify('Current workday', () => workdays.getCurrent(token));
    await _verify('Current visit', () => visits.getCurrent(token));
    await _verify('Customer statuses', () => customers.getStatuses(token));
    final customerPage = await _verify(
      'Customer list',
      () => customers.getCustomers(token, pageSize: 5),
    );
    if (customerPage.customers.firstOrNull case final customer?) {
      await _verify(
        'Customer detail',
        () => customers.getCustomer(token, customer.externalId),
      );
    } else {
      _skip('Customer detail', 'the seller has no visible customers');
    }

    await _verify('Project statuses', () => projects.getStatuses(token));
    final projectPage = await _verify(
      'Project list',
      () => projects.getProjects(token, pageSize: 5),
    );
    await _verify('Attachment options', () => attachments.getOptions(token));

    if (projectPage.projects.firstOrNull case final project?) {
      await _verify(
        'Project detail',
        () => projects.getProject(token, project.externalId),
      );
      await _verify(
        'Project notes',
        () => projects.getNotes(token, project.externalId),
      );
      await _verify(
        'Project timeline',
        () => projects.getTimeline(token, project.externalId, pageSize: 5),
      );
      await _verify(
        'Project visits',
        () => history.getProjectVisits(token, project.externalId),
      );
      await _verify(
        'Project attachments',
        () => attachments.getAttachments(token, project.externalId),
      );
    } else {
      for (final check in const [
        'Project detail',
        'Project notes',
        'Project timeline',
        'Project visits',
        'Project attachments',
      ]) {
        _skip(check, 'the seller has no visible projects');
      }
    }

    final sellerExternalId = session.user.externalId?.trim();
    if (sellerExternalId == null || sellerExternalId.isEmpty) {
      throw const FormatException(
        'The authenticated user has no seller external identifier.',
      );
    }
    await _verifySellerHistory(
      history,
      accessToken: token,
      sellerExternalId: sellerExternalId,
    );

    stdout.writeln('Live API read-only smoke verification passed.');
  } on ApiException catch (error) {
    stderr.writeln(
      'Live API verification failed${_status(error.statusCode)}: '
      '${error.message}',
    );
    exitCode = 1;
  } on FormatException catch (error) {
    stderr.writeln('Live API verification failed: ${error.message}');
    exitCode = 1;
  } finally {
    client.close();
  }
}

Future<void> _verifySellerHistory(
  HistoryService history, {
  required String accessToken,
  required String sellerExternalId,
}) async {
  try {
    await _verify(
      'Seller timeline',
      () =>
          history.getSellerTimeline(accessToken, sellerExternalId, pageSize: 5),
    );
  } on ApiException catch (error) {
    if (error.statusCode != 403) rethrow;
    await _verify(
      'Seller visit history fallback',
      () => history.getVisits(accessToken, sellerExternalId: sellerExternalId),
    );
  }
}

Future<T> _verify<T>(String label, Future<T> Function() request) async {
  final stopwatch = Stopwatch()..start();
  final value = await request();
  stopwatch.stop();
  stdout.writeln('[OK] $label (${stopwatch.elapsedMilliseconds} ms)');
  return value;
}

void _skip(String label, String reason) {
  stdout.writeln('[SKIP] $label: $reason.');
}

String _requiredEnvironment(String name) {
  final value = Platform.environment[name]?.trim();
  if (value == null || value.isEmpty) {
    stderr.writeln(
      'Missing $name. Provide smoke-test credentials through environment '
      'variables; never commit them to the repository.',
    );
    exit(64);
  }
  return value;
}

String _status(int? statusCode) =>
    statusCode == null ? '' : ' (HTTP $statusCode)';

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
