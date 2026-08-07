import 'dart:async';

import '../models/common/resource_creation_result.dart';
import '../models/customer/customer_detail.dart';
import '../models/customer/customer_input.dart';
import '../models/customer/customer_page.dart';
import '../models/customer/customer_status.dart';
import '../models/customer/customer_summary.dart';
import '../models/customer/pending_customer_operation.dart';
import '../services/api_exception.dart';
import '../services/network_status_service.dart';
import 'customer_local_store.dart';
import 'customer_repository.dart';
import 'customer_sync_repository.dart';

class OfflineFirstCustomerRepository
    implements CustomerRepository, CustomerSyncController {
  OfflineFirstCustomerRepository(
    this._remote,
    this._local,
    this._network, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final CustomerRepository _remote;
  final CustomerLocalStore _local;
  final NetworkStatusService _network;
  final DateTime Function() _now;

  Future<void>? _activeSync;

  Future<int> pendingCount() => _local.pendingCount();

  @override
  Future<CustomerPage> getCustomers({
    String? status,
    String? externalUserId,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    if (await _network.isConnected) {
      try {
        await syncPending();
        final remotePage = await _remote.getCustomers(
          status: status,
          externalUserId: externalUserId,
          search: search,
          page: page,
          pageSize: pageSize,
        );
        await _local.cacheCustomers(remotePage.customers);
        return _withPending(remotePage, status: status, search: search);
      } on ApiException catch (error) {
        if (!_isTransient(error)) rethrow;
      }
    }
    return _local.readCustomers(
      status: status,
      search: search,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<List<CustomerStatus>> getStatuses() async {
    if (await _network.isConnected) {
      try {
        final statuses = await _remote.getStatuses();
        await _local.cacheStatuses(statuses);
        return statuses;
      } on ApiException catch (error) {
        if (!_isTransient(error)) rethrow;
      }
    }
    return _local.readStatuses();
  }

  @override
  Future<CustomerDetail> getCustomer(String externalId) async {
    if (externalId.startsWith('local:')) {
      final local = await _local.readDetail(externalId);
      if (local != null) return local;
    }

    final resolvedId = await _resolveExternalId(externalId);
    if (await _network.isConnected) {
      try {
        final customer = await _remote.getCustomer(resolvedId);
        await _local.cacheDetail(customer);
        return customer;
      } on ApiException catch (error) {
        if (!_isTransient(error)) rethrow;
      }
    }

    final cached = await _local.readDetail(resolvedId);
    if (cached != null) return cached;
    throw const ApiException(
      message: 'Este cliente todavía no está disponible sin conexión.',
    );
  }

  @override
  Future<ResourceCreationResult> createCustomer(
    CustomerInput input,
    String clientRequestId,
  ) async {
    if (await _network.isConnected) {
      try {
        return await _remote.createCustomer(input, clientRequestId);
      } on ApiException catch (error) {
        if (!_isTransient(error)) rethrow;
      }
    }
    return _enqueueCreate(input, clientRequestId);
  }

  @override
  Future<void> updateCustomer(String externalId, CustomerInput input) async {
    final resolvedId = await _resolveExternalId(externalId);
    if (resolvedId.startsWith('local:')) {
      throw const ApiException(
        message:
            'Sincroniza el cliente antes de editarlo. La creación original permanece segura.',
      );
    }
    if (!await _network.isConnected) {
      throw const ApiException(
        message: 'Necesitas conexión para editar este cliente.',
      );
    }
    await _remote.updateCustomer(resolvedId, input);
    final refreshed = await _remote.getCustomer(resolvedId);
    await _local.cacheDetail(refreshed);
  }

  @override
  Future<void> changeStatus(String externalId, int statusId) async {
    final resolvedId = await _resolveExternalId(externalId);
    if (resolvedId.startsWith('local:')) {
      throw const ApiException(
        message: 'Sincroniza el cliente antes de cambiar su estado.',
      );
    }
    if (!await _network.isConnected) {
      throw const ApiException(
        message: 'Necesitas conexión para cambiar el estado.',
      );
    }
    await _remote.changeStatus(resolvedId, statusId);
    final refreshed = await _remote.getCustomer(resolvedId);
    await _local.cacheDetail(refreshed);
  }

  @override
  Future<ResourceCreationResult> addNote(
    String externalId,
    String text,
    String clientRequestId,
  ) async {
    final resolvedId = await _onlineCustomerId(externalId);
    final result = await _remote.addNote(resolvedId, text, clientRequestId);
    await _refreshDetail(resolvedId);
    return result;
  }

  @override
  Future<ResourceCreationResult> addReminder(
    String externalId, {
    required String text,
    required DateTime reminderAtUtc,
    String? assignedToId,
  }) async {
    final resolvedId = await _onlineCustomerId(externalId);
    final result = await _remote.addReminder(
      resolvedId,
      text: text,
      reminderAtUtc: reminderAtUtc,
      assignedToId: assignedToId,
    );
    await _refreshDetail(resolvedId);
    return result;
  }

  @override
  Future<void> completeReminder(
    String customerExternalId,
    String reminderExternalId,
  ) async {
    final resolvedId = await _onlineCustomerId(customerExternalId);
    await _remote.completeReminder(resolvedId, reminderExternalId);
    await _refreshDetail(resolvedId);
  }

  @override
  Future<void> syncPending() {
    final active = _activeSync;
    if (active != null) return active;

    late final Future<void> current;
    current = _syncPendingInternal().whenComplete(() {
      if (identical(_activeSync, current)) _activeSync = null;
    });
    _activeSync = current;
    return current;
  }

  Future<void> _syncPendingInternal() async {
    if (!await _network.isConnected) return;

    final operations = await _local.readPending();
    for (final operation in operations) {
      try {
        switch (operation.type) {
          case PendingCustomerOperationType.create:
            final result = await _remote.createCustomer(
              operation.input,
              operation.requestId,
            );
            final serverId = result.id;
            if (serverId == null || serverId.isEmpty) {
              throw const ApiException(
                message: 'El servidor no devolvió el ID del cliente.',
              );
            }
            await _local.markCreateSynced(
              operation.requestId,
              localCustomerId: operation.localCustomerId,
              serverCustomerId: serverId,
            );
        }
      } on ApiException catch (error) {
        await _local.recordFailure(operation.requestId, error.message);
        rethrow;
      } catch (error) {
        await _local.recordFailure(operation.requestId, error.toString());
        rethrow;
      }
    }
  }

  Future<ResourceCreationResult> _enqueueCreate(
    CustomerInput input,
    String clientRequestId,
  ) async {
    final createdAtUtc = _now().toUtc();
    final localId = 'local:$clientRequestId';
    final summary = CustomerSummary(
      id: 0,
      externalId: localId,
      name: input.name.trim(),
      companyName: input.companyName.trim(),
      phone: input.phone.trim(),
      email: input.email.trim(),
      status: 'Pendiente de sincronización',
      createdAtUtc: createdAtUtc,
      seller: null,
    );
    final detail = CustomerDetail(
      id: 0,
      externalId: localId,
      name: input.name.trim(),
      companyName: input.companyName.trim(),
      phone: input.phone.trim(),
      email: input.email.trim(),
      statusId: 0,
      status: 'Pendiente de sincronización',
      address: input.address.trim(),
      latitude: input.latitude,
      longitude: input.longitude,
      createdAtUtc: createdAtUtc,
      seller: null,
      notes: const [],
      reminders: const [],
    );
    await _local.enqueueCreate(
      PendingCustomerOperation(
        requestId: clientRequestId,
        localCustomerId: localId,
        type: PendingCustomerOperationType.create,
        input: input,
        createdAtUtc: createdAtUtc,
      ),
      summary: summary,
      detail: detail,
    );
    return ResourceCreationResult(
      id: localId,
      message: 'Cliente guardado. Se sincronizará al recuperar conexión.',
    );
  }

  Future<CustomerPage> _withPending(
    CustomerPage remotePage, {
    String? status,
    String? search,
  }) async {
    if (remotePage.page != 1 || (status?.trim().isNotEmpty ?? false)) {
      return remotePage;
    }
    final normalizedSearch = search?.trim().toLowerCase();
    final pending = (await _local.readPendingCustomers())
        .where((customer) {
          if (normalizedSearch == null || normalizedSearch.isEmpty) return true;
          return customer.name.toLowerCase().contains(normalizedSearch) ||
              customer.companyName.toLowerCase().contains(normalizedSearch) ||
              customer.email.toLowerCase().contains(normalizedSearch) ||
              customer.phone.toLowerCase().contains(normalizedSearch);
        })
        .toList(growable: false);
    if (pending.isEmpty) return remotePage;

    final remoteIds = remotePage.customers
        .map((customer) => customer.externalId)
        .toSet();
    final uniquePending = pending
        .where((customer) => !remoteIds.contains(customer.externalId))
        .toList(growable: false);
    final combined = [...uniquePending, ...remotePage.customers];
    final visible = combined.length > remotePage.pageSize
        ? combined.sublist(0, remotePage.pageSize)
        : combined;
    final totalItems = remotePage.totalItems + uniquePending.length;
    return CustomerPage(
      customers: visible,
      page: remotePage.page,
      pageSize: remotePage.pageSize,
      totalItems: totalItems,
      totalPages: totalItems == 0
          ? 0
          : (totalItems / remotePage.pageSize).ceil(),
    );
  }

  Future<String> _resolveExternalId(String externalId) async {
    if (!externalId.startsWith('local:')) return externalId;
    return await _local.serverIdForLocalId(externalId) ?? externalId;
  }

  Future<String> _onlineCustomerId(String externalId) async {
    final resolvedId = await _resolveExternalId(externalId);
    if (resolvedId.startsWith('local:')) {
      throw const ApiException(
        message:
            'Sincroniza el cliente antes de agregar notas o recordatorios.',
      );
    }
    if (!await _network.isConnected) {
      throw const ApiException(
        message: 'Necesitas conexión para modificar notas o recordatorios.',
      );
    }
    return resolvedId;
  }

  Future<void> _refreshDetail(String externalId) async {
    final refreshed = await _remote.getCustomer(externalId);
    await _local.cacheDetail(refreshed);
  }

  bool _isTransient(ApiException error) {
    final status = error.statusCode;
    return status == null || status == 408 || status == 429 || status >= 500;
  }
}
