import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/common/location_sample.dart';
import '../../data/models/customer/customer_detail.dart';
import '../../data/models/customer/customer_input.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/services/api_exception.dart';
import '../../data/services/location_service.dart';

enum CustomerFormViewStatus { initial, loading, ready, locating, saving }

class CustomerFormViewModel extends ChangeNotifier {
  CustomerFormViewModel(
    this._repository,
    this._locationService, {
    this.externalId,
    String Function()? requestId,
  }) : _requestId = requestId ?? const Uuid().v4;

  final CustomerRepository _repository;
  final LocationService _locationService;
  final String? externalId;
  final String Function() _requestId;

  CustomerFormViewStatus _status = CustomerFormViewStatus.initial;
  CustomerDetail? _customer;
  LocationSample? _location;
  String? _errorMessage;
  String? _savedExternalId;

  CustomerFormViewStatus get status => _status;
  CustomerDetail? get customer => _customer;
  LocationSample? get location => _location;
  String? get errorMessage => _errorMessage;
  String? get savedExternalId => _savedExternalId;
  bool get editing => externalId != null;
  bool get isBusy =>
      _status == CustomerFormViewStatus.loading ||
      _status == CustomerFormViewStatus.locating ||
      _status == CustomerFormViewStatus.saving;

  Future<void> initialize() async {
    if (!editing) {
      _status = CustomerFormViewStatus.ready;
      notifyListeners();
      return;
    }
    _status = CustomerFormViewStatus.loading;
    notifyListeners();
    try {
      _customer = await _repository.getCustomer(externalId!);
      final customer = _customer!;
      if (customer.latitude != null && customer.longitude != null) {
        _location = LocationSample(
          latitude: customer.latitude!,
          longitude: customer.longitude!,
          accuracyMeters: 0,
        );
      }
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No pudimos cargar el cliente.';
    }
    _status = CustomerFormViewStatus.ready;
    notifyListeners();
  }

  Future<bool> captureLocation() async {
    _status = CustomerFormViewStatus.locating;
    _errorMessage = null;
    notifyListeners();
    try {
      _location = await _locationService.captureCurrent();
      _status = CustomerFormViewStatus.ready;
      notifyListeners();
      return true;
    } on LocationFailure catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No pudimos obtener la ubicación.';
    }
    _status = CustomerFormViewStatus.ready;
    notifyListeners();
    return false;
  }

  Future<bool> save({
    required String name,
    required String companyName,
    required String phone,
    required String email,
    required String address,
  }) async {
    if (name.trim().isEmpty ||
        companyName.trim().isEmpty ||
        phone.trim().isEmpty) {
      _errorMessage = 'Completa los campos obligatorios.';
      notifyListeners();
      return false;
    }

    final input = CustomerInput(
      name: name,
      companyName: companyName,
      phone: phone,
      email: email,
      sellerExternalId: _customer?.seller?.externalId,
      address: address,
      latitude: _location?.latitude,
      longitude: _location?.longitude,
      expectedUpdatedAtUtc: _customer?.updatedAtUtc,
      expectedUpdatedAtUtcToken: _customer?.updatedAtUtcToken,
    );
    _status = CustomerFormViewStatus.saving;
    _errorMessage = null;
    notifyListeners();

    try {
      if (editing) {
        await _repository.updateCustomer(externalId!, input);
        _savedExternalId = externalId;
      } else {
        final result = await _repository.createCustomer(input, _requestId());
        _savedExternalId = result.id;
      }
      _status = CustomerFormViewStatus.ready;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No pudimos guardar el cliente.';
    }

    _status = CustomerFormViewStatus.ready;
    notifyListeners();
    return false;
  }
}
