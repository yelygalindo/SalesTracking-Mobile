import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/customer/customer_status.dart';
import '../../data/models/customer/customer_summary.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/services/api_exception.dart';

enum CustomerListViewStatus { initial, loading, ready, loadingMore }

class CustomerListViewModel extends ChangeNotifier {
  CustomerListViewModel(
    this._repository, {
    this.pageSize = 20,
    this.searchDebounce = const Duration(milliseconds: 400),
  });

  final CustomerRepository _repository;
  final int pageSize;
  final Duration searchDebounce;

  CustomerListViewStatus _status = CustomerListViewStatus.initial;
  List<CustomerSummary> _customers = const [];
  List<CustomerStatus> _statuses = const [];
  CustomerStatus? _selectedStatus;
  String _search = '';
  String? _errorMessage;
  int _page = 0;
  int _totalPages = 0;
  int _totalItems = 0;
  int _requestVersion = 0;
  bool _initialized = false;
  Timer? _searchTimer;

  CustomerListViewStatus get status => _status;
  List<CustomerSummary> get customers => _customers;
  List<CustomerStatus> get statuses => _statuses;
  CustomerStatus? get selectedStatus => _selectedStatus;
  String get search => _search;
  String? get errorMessage => _errorMessage;
  int get totalItems => _totalItems;
  bool get canLoadMore => _page < _totalPages;
  bool get isLoading => _status == CustomerListViewStatus.loading;
  bool get isLoadingMore => _status == CustomerListViewStatus.loadingMore;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    final statusesFuture = _repository.getStatuses().catchError(
      (_) => <CustomerStatus>[],
    );
    await refresh();
    _statuses = await statusesFuture;
    notifyListeners();
  }

  Future<void> refresh() => _loadPage(1, append: false);

  void updateSearch(String value) {
    _search = value.trim();
    _searchTimer?.cancel();
    _searchTimer = Timer(searchDebounce, () => unawaited(refresh()));
  }

  Future<void> selectStatus(CustomerStatus? status) async {
    if (_selectedStatus?.value == status?.value) return;
    _selectedStatus = status;
    notifyListeners();
    await refresh();
  }

  Future<void> loadMore() async {
    if (!canLoadMore || isLoading || isLoadingMore) return;
    await _loadPage(_page + 1, append: true);
  }

  Future<void> _loadPage(int page, {required bool append}) async {
    final requestVersion = ++_requestVersion;
    _status = append
        ? CustomerListViewStatus.loadingMore
        : CustomerListViewStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getCustomers(
        status: _selectedStatus?.queryValue,
        search: _search,
        page: page,
        pageSize: pageSize,
      );
      if (requestVersion != _requestVersion) return;
      _customers = append
          ? List.unmodifiable([..._customers, ...result.customers])
          : List.unmodifiable(result.customers);
      _page = result.page;
      _totalPages = result.totalPages;
      _totalItems = result.totalItems;
    } on ApiException catch (error) {
      if (requestVersion != _requestVersion) return;
      _errorMessage = error.message;
    } on FormatException {
      if (requestVersion != _requestVersion) return;
      _errorMessage = 'El servidor devolvió clientes no válidos.';
    } catch (_) {
      if (requestVersion != _requestVersion) return;
      _errorMessage = 'No pudimos consultar los clientes.';
    }

    _status = CustomerListViewStatus.ready;
    notifyListeners();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }
}
