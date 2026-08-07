import 'package:flutter/foundation.dart';

import '../../data/models/customer/customer_summary.dart';
import '../../data/models/project/project_summary.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/services/api_exception.dart';

enum ProjectListViewStatus { initial, loading, ready, loadingMore }

class ProjectListViewModel extends ChangeNotifier {
  ProjectListViewModel(this._projects, this._customers, {this.pageSize = 20});

  final ProjectRepository _projects;
  final CustomerRepository _customers;
  final int pageSize;

  ProjectListViewStatus _status = ProjectListViewStatus.initial;
  List<ProjectSummary> _items = const [];
  List<CustomerSummary> _customerOptions = const [];
  String? _selectedStatus;
  String? _selectedCustomerId;
  String? _errorMessage;
  int _page = 0;
  int _totalPages = 0;
  bool _initialized = false;

  ProjectListViewStatus get status => _status;
  List<ProjectSummary> get items => _items;
  List<CustomerSummary> get customerOptions => _customerOptions;
  String? get selectedStatus => _selectedStatus;
  String? get selectedCustomerId => _selectedCustomerId;
  String? get errorMessage => _errorMessage;
  bool get canLoadMore => _page < _totalPages;
  bool get isLoading => _status == ProjectListViewStatus.loading;
  bool get isLoadingMore => _status == ProjectListViewStatus.loadingMore;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    final customersFuture = _customers
        .getCustomers(pageSize: 100)
        .then((page) => page.customers)
        .catchError((_) => <CustomerSummary>[]);
    await refresh();
    _customerOptions = await customersFuture;
    notifyListeners();
  }

  Future<void> selectStatus(String? status) async {
    if (_selectedStatus == status) return;
    _selectedStatus = status;
    notifyListeners();
    await refresh();
  }

  Future<void> selectCustomer(String? externalId) async {
    if (_selectedCustomerId == externalId) return;
    _selectedCustomerId = externalId;
    notifyListeners();
    await refresh();
  }

  Future<void> refresh() => _loadPage(1, append: false);

  Future<void> loadMore() async {
    if (!canLoadMore || isLoading || isLoadingMore) return;
    await _loadPage(_page + 1, append: true);
  }

  Future<void> _loadPage(int page, {required bool append}) async {
    _status = append
        ? ProjectListViewStatus.loadingMore
        : ProjectListViewStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _projects.getProjects(
        status: _selectedStatus,
        customerId: _selectedCustomerId,
        page: page,
        pageSize: pageSize,
      );
      _items = append
          ? List.unmodifiable([..._items, ...result.projects])
          : List.unmodifiable(result.projects);
      _page = result.page;
      _totalPages = result.totalPages;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No pudimos consultar las obras.';
    }
    _status = ProjectListViewStatus.ready;
    notifyListeners();
  }
}
