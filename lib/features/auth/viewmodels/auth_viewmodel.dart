import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';

enum AuthStatus { initial, loading, success, error }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final String? userId;
  final String? userName;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.userId,
    this.userName,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    String? userId,
    String? userName,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
    );
  }
}

class AuthViewModel extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthViewModel(this._authService) : super(const AuthState()) {
    _checkCurrentUser();
  }

  void _checkCurrentUser() {
    final user = _authService.currentUser;
    if (user != null) {
      state = state.copyWith(
        status: AuthStatus.success,
        userId: user.uid,
        userName: user.displayName,
      );
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final credential = await _authService.login(
        email: email,
        password: password,
      );
      state = state.copyWith(
        status: AuthStatus.success,
        userId: credential.user!.uid,
        userName: credential.user!.displayName,
      );
    } catch (e) {
      String msg = 'Erro ao fazer login.';
      if (e.toString().contains('user-not-found')) msg = 'Usuário não encontrado.';
      if (e.toString().contains('wrong-password')) msg = 'Senha incorreta.';
      if (e.toString().contains('invalid-credential')) msg = 'Email ou senha inválidos.';
      state = state.copyWith(status: AuthStatus.error, errorMessage: msg);
    }
  }

  Future<void> register(String name, String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final credential = await _authService.register(
        name: name,
        email: email,
        password: password,
      );
      state = state.copyWith(
        status: AuthStatus.success,
        userId: credential.user!.uid,
        userName: name,
      );
    } catch (e) {
      String msg = 'Erro ao cadastrar.';
      if (e.toString().contains('email-already-in-use')) msg = 'Email já cadastrado.';
      if (e.toString().contains('weak-password')) msg = 'Senha muito fraca.';
      state = state.copyWith(status: AuthStatus.error, errorMessage: msg);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState();
  }
}

// Providers
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  return AuthViewModel(ref.watch(authServiceProvider));
});