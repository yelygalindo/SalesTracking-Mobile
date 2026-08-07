import 'package:flutter/foundation.dart';

import '../../data/models/customer/customer_detail.dart';
import '../../data/models/customer/customer_status.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/services/api_exception.dart';

enum CustomerDetailViewStatus { initial, loading, ready, changingStatus }

class CustomerDetailViewModel extends ChangeNotifier {
  CustomerDetailViewModel(this._repository, this.externalId);

  final CustomerRepository _repository;
  final String externalId;

  CustomerDetailViewStatus _status = CustomerDetailViewStatus.initial;
  CustomerDetail? _customer;
  List<CustomerStatus> _statuses = const [];
  String? _errorMessage;

  CustomerDetailViewStatus get status => _status;
  CustomerDetail? get customer => _customer;
  List<CustomerStatus> get statuses => _statuses;
  String? get errorMessage => _errorMessage;
  bool get isBusy =>
      _status == CustomerDetailViewStatus.loading ||
      _status == CustomerDetailViewStatus.changingStatus;

  Future<void> load() async {
    _status = CustomerDetailViewStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait<Object>([
        _repository.getCustomer(externalId),
        _repository.getStatuses(),
      ]);
      _customer = results[0] as CustomerDetail;
      _statuses = results[1] as List<CustomerStatus>;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No pudimos consultar el cliente.';
    }

    _status = CustomerDetailViewStatus.ready;
    notifyListeners();
  }

  Future<bool> changeStatus(CustomerStatus status) async {
    final customer = _customer;
    if (customer == null || customer.statusId == status.value) return true;
    _status = CustomerDetailViewStatus.changingStatus;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.changeStatus(externalId, status.value);
      _customer = await _repository.getCustomer(externalId);
      _status = CustomerDetailViewStatus.ready;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No pudimos cambiar el estado del cliente.';
    }

    _status = CustomerDetailViewStatus.ready;
    notifyListeners();
    return false;
  }
}
