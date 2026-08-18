import 'package:flutter/foundation.dart';

import '../../data/models/auth/auth_session.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/api_exception.dart';

enum AuthStatus { restoring, unauthenticated, authenticating, authenticated }

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._repository);

  final AuthRepository _repository;

  AuthStatus _status = AuthStatus.restoring;
  AuthSession? _session;
  String? _errorMessage;

  AuthStatus get status => _status;
  AuthSession? get session => _session;
  String? get errorMessage => _errorMessage;

  Future<void> restoreSession() async {
    _status = AuthStatus.restoring;
    notifyListeners();

    try {
      _session = await _repository.restoreSession();
      _status = _session == null
          ? AuthStatus.unauthenticated
          : AuthStatus.authenticated;
    } catch (_) {
      _session = null;
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    if (_status == AuthStatus.authenticating) return false;

    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      _session = await _repository.login(email: email, password: password);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } on FormatException {
      _errorMessage = 'El servidor devolvió datos de sesión no válidos.';
    } catch (_) {
      _errorMessage = 'Ocurrió un error inesperado. Inténtalo nuevamente.';
    }

    _status = AuthStatus.unauthenticated;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    final currentSession = _session;
    _session = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();

    if (currentSession != null) {
      try {
        await _repository.logout(currentSession);
      } catch (_) {
        // Local session deletion has priority when the device is offline.
      }
    }
  }
}
