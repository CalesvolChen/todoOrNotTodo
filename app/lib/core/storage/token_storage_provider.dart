import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:todo_app/core/storage/token_storage.dart';

/// Web 不实例化 FlutterSecureStorage，避免部分环境下插件初始化干扰启动
final secureStorageProvider = Provider<FlutterSecureStorage?>((ref) {
  if (kIsWeb) return null;
  return const FlutterSecureStorage(
    webOptions: WebOptions(
      dbName: 'TodoAppSecureStorage',
      publicKey: 'TodoAppSecureStorage',
    ),
  );
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(ref.watch(secureStorageProvider));
});

/// Dio 401 时递增，由 App 层监听并触发登出
final sessionExpiredProvider = StateProvider<int>((ref) => 0);

/// 启动鉴权恢复中；此期间 Dio 401 不触发 sessionExpired
final authBootstrappingProvider = StateProvider<bool>((ref) => true);
