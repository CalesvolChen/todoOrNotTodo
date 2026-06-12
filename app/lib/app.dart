import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/storage/token_storage_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/view_models/auth_controller.dart';
import 'features/invitations/presentation/view_models/invitations_badge_provider.dart';
import 'features/tasks/presentation/view_models/important_tasks_controller.dart';
import 'features/tasks/presentation/view_models/tasks_controller.dart';

class TodoApp extends ConsumerWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(sessionExpiredProvider, (prev, next) {
      if (next > (prev ?? 0)) {
        ref.read(authControllerProvider.notifier).logout();
      }
    });

    ref.listen(authControllerProvider, (prev, next) {
      if (prev?.token != next.token) {
        ref.invalidate(tasksControllerProvider);
        ref.invalidate(importantTasksControllerProvider);
        ref.invalidate(taskDetailProvider);
        ref.invalidate(pendingInvitationsCountProvider);
      }
    });

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Todo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
      builder: (context, child) => child ?? const SplashScreen(),
    );
  }
}
