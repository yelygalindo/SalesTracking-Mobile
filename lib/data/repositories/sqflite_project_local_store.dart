import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../models/project/project_detail.dart';
import '../models/project/project_page.dart';
import '../models/project/project_summary.dart';
import '../models/project/project_status.dart';
import '../storage/app_database.dart';
import 'project_local_store.dart';

class SqfliteProjectLocalStore implements ProjectLocalStore {
  SqfliteProjectLocalStore(AppDatabase appDatabase)
    : _database = appDatabase.database;

  final Future<Database> _database;

  @override
  Future<void> cacheProjects(List<ProjectSummary> projects) async {
    if (projects.isEmpty) return;
    final database = await _database;
    await database.transaction((transaction) async {
      for (final project in projects) {
        final payload = jsonEncode(project.toJson());
        final updatedAt = DateTime.now().toUtc().toIso8601String();
        await transaction.insert('project_summary_cache', {
          'external_id': project.externalId,
          'payload': payload,
          'updated_at_utc': updatedAt,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        await transaction.insert('project_detail_cache', {
          'external_id': project.externalId,
          'payload': payload,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  @override
  Future<ProjectPage> readProjects({
    String? status,
    String? customerId,
    String? sellerId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final database = await _database;
    final rows = await database.query(
      'project_summary_cache',
      columns: ['payload'],
      orderBy: 'updated_at_utc DESC',
    );
    final normalizedStatus = status?.trim().toLowerCase();
    final normalizedCustomerId = customerId?.trim().toLowerCase();
    final normalizedSellerId = sellerId?.trim().toLowerCase();
    final filtered = rows
        .map((row) => _summary(row['payload'] as String))
        .where((project) {
          final matchesStatus =
              normalizedStatus == null ||
              normalizedStatus.isEmpty ||
              _matchesStatus(project.status, normalizedStatus);
          final matchesCustomer =
              normalizedCustomerId == null ||
              normalizedCustomerId.isEmpty ||
              project.customerExternalId?.toLowerCase() == normalizedCustomerId;
          final matchesSeller =
              normalizedSellerId == null ||
              normalizedSellerId.isEmpty ||
              project.sellerExternalId?.toLowerCase() == normalizedSellerId;
          return matchesStatus && matchesCustomer && matchesSeller;
        })
        .toList(growable: false);
    final safePage = page < 1 ? 1 : page;
    final safePageSize = pageSize < 1 ? 20 : pageSize;
    final start = (safePage - 1) * safePageSize;
    final projects = start >= filtered.length
        ? const <ProjectSummary>[]
        : filtered.sublist(
            start,
            (start + safePageSize).clamp(0, filtered.length),
          );
    return ProjectPage(
      projects: projects,
      page: safePage,
      pageSize: safePageSize,
      totalItems: filtered.length,
      totalPages: filtered.isEmpty
          ? 0
          : (filtered.length / safePageSize).ceil(),
    );
  }

  @override
  Future<void> cacheDetail(ProjectDetail project) async {
    final database = await _database;
    await database.insert('project_detail_cache', {
      'external_id': project.externalId,
      'payload': jsonEncode(project.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await database.insert('project_summary_cache', {
      'external_id': project.externalId,
      'payload': jsonEncode(project.toJson()),
      'updated_at_utc': DateTime.now().toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<ProjectDetail?> readDetail(String externalId) async {
    final database = await _database;
    final rows = await database.query(
      'project_detail_cache',
      columns: ['payload'],
      where: 'external_id = ?',
      whereArgs: [externalId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final decoded = jsonDecode(rows.first['payload'] as String);
    return decoded is Map<String, dynamic>
        ? ProjectDetail.fromJson(decoded)
        : null;
  }

  @override
  Future<void> cacheStatuses(List<ProjectStatus> statuses) async {
    final database = await _database;
    await database.transaction((transaction) async {
      await transaction.delete('project_status_cache');
      for (final status in statuses) {
        await transaction.insert('project_status_cache', {
          'value': status.value,
          'payload': jsonEncode(status.toJson()),
        });
      }
    });
  }

  @override
  Future<List<ProjectStatus>> readStatuses() async {
    final database = await _database;
    final rows = await database.query(
      'project_status_cache',
      columns: ['payload'],
      orderBy: 'value ASC',
    );
    return rows
        .map((row) {
          final decoded = jsonDecode(row['payload'] as String);
          if (decoded is! Map<String, dynamic>) {
            throw const FormatException('Invalid project status payload.');
          }
          return ProjectStatus.fromJson(decoded);
        })
        .toList(growable: false);
  }

  ProjectSummary _summary(String encoded) {
    final decoded = jsonDecode(encoded);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid project cache payload.');
    }
    return ProjectSummary.fromJson(decoded);
  }

  bool _matchesStatus(String projectStatus, String? selectedStatus) {
    if (selectedStatus == null || selectedStatus.isEmpty) return true;
    final normalized = projectStatus.trim().toLowerCase();
    final expected = switch (selectedStatus) {
      '1' => {'draft', 'borrador'},
      '2' => {'active', 'activo'},
      '3' => {'paused', 'on hold', 'en pausa'},
      '4' => {'completed', 'completado'},
      '5' => {'lost', 'cancelled', 'canceled', 'perdido', 'cancelado'},
      _ => {selectedStatus},
    };
    return expected.contains(normalized);
  }
}
