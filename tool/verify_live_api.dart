import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:urbantrack/data/models/auth/login_request.dart';
import 'package:urbantrack/data/models/history/project_visit.dart';
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
          deviceType: 'android',
          deviceId: 'urbantrack-readonly-smoke',
        ),
      );
    });

    final refreshedTokens = await _verify(
      'Token refresh',
      () => auth.refresh(session.refreshToken),
    );
    final token = refreshedTokens.accessToken;
    final customers = CustomerService(baseUrl, client);
    final projects = ProjectService(baseUrl, client);
    final workdays = WorkdayService(baseUrl, client);
    final visits = VisitService(baseUrl, client);
    final history = HistoryService(baseUrl, client);
    final attachments = ProjectAttachmentService(baseUrl, client);
    final failures = <String>[];

    await _check('Current workday', () => workdays.getCurrent(token), failures);
    await _check('Current visit', () => visits.getCurrent(token), failures);
    await _check(
      'Customer statuses',
      () => customers.getStatuses(token),
      failures,
    );
    final customerPage = await _check(
      'Customer list',
      () => customers.getCustomers(token, pageSize: 5),
      failures,
    );
    if (customerPage?.customers.firstOrNull case final customer?) {
      await _check(
        'Customer detail',
        () => customers.getCustomer(token, customer.externalId),
        failures,
      );
    } else {
      _skip(
        'Customer detail',
        customerPage == null
            ? 'the customer list check failed'
            : 'the seller has no visible customers',
      );
    }

    await _check(
      'Project statuses',
      () => projects.getStatuses(token),
      failures,
    );
    final projectPage = await _check(
      'Project list',
      () => projects.getProjects(token, pageSize: 5),
      failures,
    );
    await _check(
      'Attachment options',
      () => attachments.getOptions(token),
      failures,
    );

    if (projectPage?.projects.firstOrNull case final project?) {
      await _check(
        'Project detail',
        () => projects.getProject(token, project.externalId),
        failures,
      );
      await _check(
        'Project notes',
        () => projects.getNotes(token, project.externalId),
        failures,
      );
      await _check(
        'Project reminders',
        () =>
            projects.getReminders(token, project.externalId, completed: false),
        failures,
      );
      await _check(
        'Project timeline',
        () => projects.getTimeline(token, project.externalId, pageSize: 5),
        failures,
      );
      final projectVisits = await _check(
        'Project visits',
        () => history.getProjectVisits(token, project.externalId),
        failures,
      );
      await _verifyVisitAttachments(
        history,
        accessToken: token,
        visits: projectVisits,
        failures: failures,
      );
      await _check(
        'Project attachments',
        () => attachments.getAttachments(token, project.externalId),
        failures,
      );
    } else {
      for (final check in const [
        'Project detail',
        'Project notes',
        'Project reminders',
        'Project timeline',
        'Project visits',
        'Visit attachments',
        'Project attachments',
      ]) {
        _skip(
          check,
          projectPage == null
              ? 'the project list check failed'
              : 'the seller has no visible projects',
        );
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
      failures: failures,
    );

    if (failures.isNotEmpty) {
      stderr.writeln(
        'Live API read-only smoke verification completed with '
        '${failures.length} failed check(s): ${failures.join(', ')}.',
      );
      exitCode = 1;
      return;
    }
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

Future<void> _verifyVisitAttachments(
  HistoryService history, {
  required String accessToken,
  required List<ProjectVisit>? visits,
  required List<String> failures,
}) async {
  if (visits == null) {
    _skip('Visit attachments', 'the project visits check failed');
    return;
  }
  if (visits.isEmpty) {
    _skip('Visit attachments', 'the project has no visits');
    return;
  }
  for (final visit in visits) {
    final stopwatch = Stopwatch()..start();
    try {
      await history.getVisitAttachments(accessToken, visit.externalId);
      stopwatch.stop();
      stdout.writeln(
        '[OK] Visit attachments (${stopwatch.elapsedMilliseconds} ms)',
      );
      return;
    } on ApiException catch (error) {
      stopwatch.stop();
      if (error.statusCode == 404) continue;
      stderr.writeln(
        '[FAIL] Visit attachments${_status(error.statusCode)} '
        '(${stopwatch.elapsedMilliseconds} ms)',
      );
      failures.add('Visit attachments${_status(error.statusCode)}');
      return;
    }
  }
  _skip('Visit attachments', 'none of the project visits has attachments');
}

Future<void> _verifySellerHistory(
  HistoryService history, {
  required String accessToken,
  required String sellerExternalId,
  required List<String> failures,
}) async {
  try {
    await _verify(
      'Seller timeline',
      () =>
          history.getSellerTimeline(accessToken, sellerExternalId, pageSize: 5),
    );
  } on ApiException catch (error) {
    if (error.statusCode == 403) {
      await _check(
        'Seller visit history fallback',
        () =>
            history.getVisits(accessToken, sellerExternalId: sellerExternalId),
        failures,
      );
      return;
    }
    failures.add('Seller timeline${_status(error.statusCode)}');
  }
}

Future<T?> _check<T>(
  String label,
  Future<T> Function() request,
  List<String> failures,
) async {
  try {
    return await _verify(label, request);
  } on ApiException catch (error) {
    failures.add('$label${_status(error.statusCode)}');
    return null;
  }
}

Future<T> _verify<T>(String label, Future<T> Function() request) async {
  final stopwatch = Stopwatch()..start();
  try {
    final value = await request();
    stopwatch.stop();
    stdout.writeln('[OK] $label (${stopwatch.elapsedMilliseconds} ms)');
    return value;
  } on ApiException catch (error) {
    stopwatch.stop();
    stderr.writeln(
      '[FAIL] $label${_status(error.statusCode)} '
      '(${stopwatch.elapsedMilliseconds} ms)',
    );
    rethrow;
  }
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
