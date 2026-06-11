import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:todo_app/core/network/dio_client.dart';
import 'package:todo_app/core/network/multipart_util.dart';
import 'package:todo_app/features/auth/data/models/auth_user.dart';

typedef AuthResult = ({String token, AuthUser user});

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  Future<AuthResult> login(String username, String password) async {
    final res = await _dio.post(
      '/auth/app/login',
      data: {'username': username, 'password': password},
    );
    return _parse(res.data);
  }

  Future<AuthResult> register(
    String username,
    String password,
    String? name,
  ) async {
    final res = await _dio.post(
      '/auth/app/register',
      data: {
        'username': username,
        'password': password,
        if (name != null && name.isNotEmpty) 'name': name,
      },
    );
    return _parse(res.data);
  }

  Future<AuthUser> fetchMe() async {
    final res = await _dio.get('/users/me');
    return AuthUser.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AuthUser> uploadAvatar(XFile file) async {
    final multipart = await buildMultipartFile(
      xFile: file,
      filename: 'avatar.jpg',
      contentType: guessImageMediaType(file.mimeType, file.name),
    );
    final form = FormData.fromMap({'file': multipart});
    final res = await _dio.post('/users/me/avatar', data: form);
    return AuthUser.fromJson(res.data as Map<String, dynamic>);
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
