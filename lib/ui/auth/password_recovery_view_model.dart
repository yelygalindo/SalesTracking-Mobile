import 'package:flutter/foundation.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/services/api_exception.dart';

enum PasswordRecoveryStatus { idle, submitting, success, failure }

class PasswordRecoveryViewModel extends ChangeNotifier {
  PasswordRecoveryViewModel(this._repository);

  final AuthRepository _repository;

  PasswordRecoveryStatus _status = PasswordRecoveryStatus.idle;
  String? _message;

  PasswordRecoveryStatus get status => _status;
  String? get message => _message;
  bool get isSubmitting => _status == PasswordRecoveryStatus.submitting;

  Future<bool> requestReset(String email) async {
    return _run(() => _repository.forgotPassword(email));
  }

  Future<bool> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return _run(
      () => _repository.resetPassword(
        token: token,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      ),
    );
  }

  Future<bool> _run(Future<String> Function() action) async {
    _status = PasswordRecoveryStatus.submitting;
    _message = null;
    notifyListeners();

    try {
      _message = await action();
      _status = PasswordRecoveryStatus.success;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _message = error.message;
    } catch (_) {
      _message = 'Ocurrió un error inesperado. Inténtalo nuevamente.';
    }

    _status = PasswordRecoveryStatus.failure;
    notifyListeners();
    return false;
  }
}
