import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../models/customer/customer_detail.dart';
import '../models/customer/customer_page.dart';
import '../models/customer/customer_status.dart';
import '../models/customer/customer_summary.dart';
import '../models/customer/pending_customer_operation.dart';
import '../storage/app_database.dart';
import 'customer_local_store.dart';

class SqfliteCustomerLocalStore implements CustomerLocalStore {
  SqfliteCustomerLocalStore(AppDatabase appDatabase)
    : _database = appDatabase.database;

  final Future<Database> _database;

  @override
  Future<void> cacheCustomers(List<CustomerSummary> customers) async {
    if (customers.isEmpty) return;
    final database = await _database;
    await database.transaction((transaction) async {
      for (final customer in customers) {
        await transaction.insert('customer_summary_cache', {
          'external_id': customer.externalId,
          'payload': jsonEncode(customer.toJson()),
          'is_pending': 0,
          'updated_at_utc': DateTime.now().toUtc().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  @override
  Future<CustomerPage> readCustomers({
    String? status,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    final database = await _database;
    final rows = await database.query(
      'customer_summary_cache',
      columns: ['payload'],
      orderBy: 'is_pending DESC, updated_at_utc DESC',
    );
    final normalizedStatus = status?.trim().toLowerCase();
    final normalizedSearch = search?.trim().toLowerCase();
    final filtered = rows
        .map((row) => _summary(row['payload'] as String))
        .where((customer) {
          final matchesStatus =
              normalizedStatus == null ||
              normalizedStatus.isEmpty ||
              customer.status.toLowerCase() == normalizedStatus;
          final matchesSearch =
              normalizedSearch == null ||
              normalizedSearch.isEmpty ||
              customer.name.toLowerCase().contains(normalizedSearch) ||
              customer.companyName.toLowerCase().contains(normalizedSearch) ||
              customer.email.toLowerCase().contains(normalizedSearch) ||
              customer.phone.toLowerCase().contains(normalizedSearch);
          return matchesStatus && matchesSearch;
        })
        .toList(growable: false);
    final safePage = page < 1 ? 1 : page;
    final safePageSize = pageSize < 1 ? 20 : pageSize;
    final start = (safePage - 1) * safePageSize;
    final customers = start >= filtered.length
        ? const <CustomerSummary>[]
        : filtered.sublist(
            start,
            (start + safePageSize).clamp(0, filtered.length),
          );
    final totalPages = filtered.isEmpty
        ? 0
        : (filtered.length / safePageSize).ceil();
    return CustomerPage(
      customers: customers,
      page: safePage,
      pageSize: safePageSize,
      totalItems: filtered.length,
      totalPages: totalPages,
    );
  }

  @override
  Future<List<CustomerSummary>> readPendingCustomers() async {
    final database = await _database;
    final rows = await database.query(
      'customer_summary_cache',
      columns: ['payload'],
      where: 'is_pending = 1',
      orderBy: 'updated_at_utc DESC',
    );
    return rows
        .map((row) => _summary(row['payload'] as String))
        .toList(growable: false);
  }

  @override
  Future<void> cacheDetail(CustomerDetail customer) async {
    final database = await _database;
    await database.insert('customer_detail_cache', {
      'external_id': customer.externalId,
      'payload': jsonEncode(customer.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<CustomerDetail?> readDetail(String externalId) async {
    final database = await _database;
    final rows = await database.query(
      'customer_detail_cache',
      columns: ['payload'],
      where: 'external_id = ?',
      whereArgs: [externalId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final payload = jsonDecode(rows.first['payload'] as String);
    return payload is Map<String, dynamic>
        ? CustomerDetail.fromJson(payload)
        : null;
  }

  @override
  Future<void> cacheStatuses(List<CustomerStatus> statuses) async {
    final database = await _database;
    await database.transaction((transaction) async {
      await transaction.delete('customer_status_cache');
      for (final status in statuses) {
        await transaction.insert('customer_status_cache', {
          'value': status.value,
          'payload': jsonEncode(status.toJson()),
        });
      }
    });
  }

  @override
  Future<List<CustomerStatus>> readStatuses() async {
    final database = await _database;
    final rows = await database.query(
      'customer_status_cache',
      columns: ['payload'],
      orderBy: 'value ASC',
    );
    return rows
        .map((row) {
          final payload = jsonDecode(row['payload'] as String);
          return CustomerStatus.fromJson(payload as Map<String, dynamic>);
        })
        .toList(growable: false);
  }

  @override
  Future<void> enqueueCreate(
    PendingCustomerOperation operation, {
    required CustomerSummary summary,
    required CustomerDetail detail,
  }) async {
    final database = await _database;
    await database.transaction((transaction) async {
      await transaction.insert(
        'customer_sync_operations',
        operation.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      await transaction.insert('customer_summary_cache', {
        'external_id': summary.externalId,
        'payload': jsonEncode(summary.toJson()),
        'is_pending': 1,
        'updated_at_utc': operation.createdAtUtc.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await transaction.insert('customer_detail_cache', {
        'external_id': detail.externalId,
        'payload': jsonEncode(detail.toJson()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  @override
  Future<List<PendingCustomerOperation>> readPending() async {
    final database = await _database;
    final rows = await database.query(
      'customer_sync_operations',
      orderBy: 'sequence ASC',
    );
    return rows.map(PendingCustomerOperation.fromMap).toList(growable: false);
  }

  @override
  Future<int> pendingCount() async {
    final database = await _database;
    final rows = await database.rawQuery(
      'SELECT COUNT(*) AS total FROM customer_sync_operations',
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  @override
  Future<String?> serverIdForLocalId(String localCustomerId) async {
    final database = await _database;
    final rows = await database.query(
      'customer_id_map',
      columns: ['server_customer_id'],
      where: 'local_customer_id = ?',
      whereArgs: [localCustomerId],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['server_customer_id'] as String?;
  }

  @override
  Future<void> markCreateSynced(
    String requestId, {
    required String localCustomerId,
    required String serverCustomerId,
  }) async {
    final database = await _database;
    await database.transaction((transaction) async {
      await transaction.insert('customer_id_map', {
        'local_customer_id': localCustomerId,
        'server_customer_id': serverCustomerId,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await transaction.delete(
        'customer_sync_operations',
        where: 'request_id = ?',
        whereArgs: [requestId],
      );
      await transaction.delete(
        'customer_summary_cache',
        where: 'external_id = ?',
        whereArgs: [localCustomerId],
      );
      await transaction.delete(
        'customer_detail_cache',
        where: 'external_id = ?',
        whereArgs: [localCustomerId],
      );
    });
  }

  @override
  Future<void> recordFailure(String requestId, String message) async {
    final database = await _database;
    await database.rawUpdate(
      '''
        UPDATE customer_sync_operations
        SET attempt_count = attempt_count + 1, last_error = ?
        WHERE request_id = ?
      ''',
      [message, requestId],
    );
  }

  CustomerSummary _summary(String encoded) {
    final payload = jsonDecode(encoded);
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Invalid customer cache payload.');
    }
    return CustomerSummary.fromJson(payload);
  }
}
