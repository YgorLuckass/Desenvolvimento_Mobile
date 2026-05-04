// lib/viewmodels/auth_viewmodel.dart

import 'package:flutter/material.dart';
import '../models/user_model.dart';

enum AuthMode { login, register }
enum AuthState { idle, loading, success, error }

class AuthViewModel extends ChangeNotifier {
  AuthMode _authMode = AuthMode.login;
  AuthState _state = AuthState.idle;
  String _errorMessage = '';
  UserModel? _currentUser;

  // Simulated user database
  final List<UserModel> _users = [
    UserModel(
      id: '1',
      name: 'Demo User',
      email: 'demo@financeiro.com',
      password: '123456',
    ),
  ];

  // Getters
  AuthMode get authMode => _authMode;
  AuthState get state => _state;
  String get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;
  bool get isLogin => _authMode == AuthMode.login;
  bool get isLoading => _state == AuthState.loading;

  void toggleAuthMode() {
    _authMode = _authMode == AuthMode.login ? AuthMode.register : AuthMode.login;
    _errorMessage = '';
    _state = AuthState.idle;
    notifyListeners();
  }

  Future<bool> authenticate({
    required String email,
    required String password,
    String? name,
  }) async {
    _state = AuthState.loading;
    _errorMessage = '';
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    if (_authMode == AuthMode.login) {
      final user = _users.where(
        (u) => u.email == email && u.password == password,
      ).firstOrNull;

      if (user != null) {
        _currentUser = user;
        _state = AuthState.success;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'E-mail ou senha incorretos.';
        _state = AuthState.error;
        notifyListeners();
        return false;
      }
    } else {
      // Register
      final exists = _users.any((u) => u.email == email);
      if (exists) {
        _errorMessage = 'Este e-mail já está cadastrado.';
        _state = AuthState.error;
        notifyListeners();
        return false;
      }

      final newUser = UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name ?? 'Usuário',
        email: email,
        password: password,
      );
      _users.add(newUser);
      _currentUser = newUser;
      _state = AuthState.success;
      notifyListeners();
      return true;
    }
  }

  void logout() {
    _currentUser = null;
    _state = AuthState.idle;
    _authMode = AuthMode.login;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    _state = AuthState.idle;
    notifyListeners();
  }
}
