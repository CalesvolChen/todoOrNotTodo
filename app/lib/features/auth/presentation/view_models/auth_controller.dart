import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todo_app/core/network/dio_client.dart';
import 'package:todo_app/features/auth/data/auth_repository.dart';
import 'package:todo_app/features/auth/data/models/auth_user.dart';

class AuthState {
  const AuthState({
    this.loading = false,
    this.token,
    this.user,
    this.error,
  });

  final bool loading;
  final String? token;
  final AuthUser? user;
  final String? error;

  bool get isAuthenticated => token != null;

  AuthState copyWith({
    bool? loading,
    String? token,
    AuthUser? user,
    String? error,
  }) {
    return AuthState(
      loading: loading ?? this.loading,
      token: token ?? this.token,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(const AuthState()) {
    _restore();
  }

  final Ref _ref;

  Future<void> _restore() async {
    final token = await _ref.read(tokenStorageProvider).read();
    if (token != null) {
      state = state.copyWith(token: token);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final result =
          await _ref.read(authRepositoryProvider).login(email, password);
      await _ref.read(tokenStorageProvider).write(result.token);
      state = AuthState(token: result.token, user: result.user);
    } catch (_) {
      state = state.copyWith(loading: false, error: '登录失败，请检查邮箱或密码');
    }
  }

  Future<void> logout() async {
    await _ref.read(tokenStorageProvider).clear();
    state = const AuthState();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});
