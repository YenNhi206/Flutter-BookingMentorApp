import 'package:flutter/foundation.dart';

import '../data/repositories/auth_repository.dart';
import '../models/user_profile.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  AuthProvider({AuthRepository? repository}) : _repository = repository ?? AuthRepository();

  UserProfile? _currentUser;
  AuthStatus _status = AuthStatus.unauthenticated;
  bool _isLoading = false;
  String? _errorMessage;

  UserProfile? get currentUser => _currentUser;
  AuthStatus get status => _status;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    try {
      _currentUser = await _repository.login(email: email, password: password);
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('AuthException: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      _currentUser = await _repository.register(name: name, email: email, password: password);
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('AuthException: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProfile({String? name, String? phone}) async {
    if (_currentUser == null) return;
    final updated = _currentUser!.copyWith(name: name, phone: phone);
    _currentUser = await _repository.updateProfile(updated);
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
