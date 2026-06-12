import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:todo_app/core/errors/app_error_message.dart';
import 'package:todo_app/core/storage/token_storage_provider.dart';
import 'package:todo_app/features/auth/data/auth_repository.dart';
import 'package:todo_app/features/auth/data/models/auth_user.dart';
import 'package:todo_app/features/lists/presentation/view_models/lists_controller.dart';

class AuthState {
  const AuthState({
    this.initializing = true,
    this.loading = false,
    this.token,
    this.user,
    this.error,
  });

  final bool initializing;
  final bool loading;
  final String? token;
  final AuthUser? user;
  final String? error;

  bool get isAuthenticated => token != null;

  AuthState copyWith({
    bool? initializing,
    bool? loading,
    String? token,
    AuthUser? user,
    String? error,
    bool clearToken = false,
    bool clearUser = false,
  }) {
    return AuthState(
      initializing: initializing ?? this.initializing,
      loading: loading ?? this.loading,
      token: clearToken ? null : (token ?? this.token),
      user: clearUser ? null : (user ?? this.user),
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
    _ref.read(authBootstrappingProvider.notifier).state = true;
    try {
      final token = await _ref
          .read(tokenStorageProvider)
          .read()
          .timeout(const Duration(seconds: 5));
      if (token == null || token.isEmpty) {
        state = const AuthState(initializing: false);
        return;
      }
      try {
        final me = await _ref
            .read(authRepositoryProvider)
            .fetchMe()
            .timeout(const Duration(seconds: 8));
        state = AuthState(token: token, user: me, initializing: false);
      } on DioException catch (e) {
        if (e.response?.statusCode == 401) {
          await _ref.read(tokenStorageProvider).clear();
          state = const AuthState(initializing: false);
        } else {
          state = AuthState(token: token, initializing: false);
        }
      } on TimeoutException {
        state = AuthState(token: token, initializing: false);
      } catch (_) {
        state = AuthState(token: token, initializing: false);
      }
    } on TimeoutException {
      state = const AuthState(initializing: false);
    } catch (_) {
      state = const AuthState(initializing: false);
    } finally {
      _ref.read(authBootstrappingProvider.notifier).state = false;
      if (state.initializing) {
        state = state.copyWith(initializing: false);
      }
    }
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final result =
          await _ref.read(authRepositoryProvider).login(username, password);
      await _ref.read(tokenStorageProvider).write(result.token);
      state = AuthState(
        token: result.token,
        user: result.user,
        initializing: false,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        initializing: false,
        error: messageFromError(e),
      );
    }
  }

  Future<void> register(String username, String password, String? name) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final result = await _ref
          .read(authRepositoryProvider)
          .register(username, password, name);
      await _ref.read(tokenStorageProvider).write(result.token);
      state = AuthState(
        token: result.token,
        user: result.user,
        initializing: false,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        initializing: false,
        error: messageFromError(e),
      );
    }
  }

  void setUser(AuthUser user) {
    state = state.copyWith(user: user);
    _invalidateMemberCaches();
  }

  Future<void> updateAvatar(XFile file) async {
    final user = await _ref.read(authRepositoryProvider).uploadAvatar(file);
    state = state.copyWith(user: user);
    _invalidateMemberCaches();
  }

  Future<void> updateDisplayName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final user = await _ref.read(authRepositoryProvider).updateProfile(name: trimmed);
    state = state.copyWith(user: user);
    _invalidateMemberCaches();
  }

  void _invalidateMemberCaches() {
    _ref.invalidate(listMembersProvider);
  }

  Future<void> logout() async {
    await _ref.read(tokenStorageProvider).clear();
    state = const AuthState(initializing: false);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});
