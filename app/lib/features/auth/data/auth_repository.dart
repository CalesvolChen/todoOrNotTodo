import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todo_app/core/network/dio_client.dart';
import 'package:todo_app/features/auth/data/models/auth_user.dart';

typedef AuthResult = ({String token, AuthUser user});

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  Future<AuthResult> login(String email, String password) async {
    final res = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return _parse(res.data);
  }

  Future<AuthResult> register(
    String email,
    String password,
    String? name,
  ) async {
    final res = await _dio.post(
      '/auth/register',
      data: {'email': email, 'password': password, 'name': name},
    );
    return _parse(res.data);
  }

  AuthResult _parse(dynamic data) {
    final map = data as Map<String, dynamic>;
    return (
      token: map['accessToken'] as String,
      user: AuthUser.fromJson(map['user'] as Map<String, dynamic>),
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});
