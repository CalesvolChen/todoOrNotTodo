import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/storage/token_storage_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/view_models/auth_controller.dart';

class TodoApp extends ConsumerWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(sessionExpiredProvider, (prev, next) {
      if (next > (prev ?? 0)) {
        ref.read(authControllerProvider.notifier).logout();
      }
    });

    final auth = ref.watch(authControllerProvider);

    // 启动阶段：不创建 GoRouter，用普通 MaterialApp 保证一定有 UI（Web 刷新白屏的根因之一）
    if (auth.initializing) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const SplashScreen(),
      );
    }

    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Todo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}
