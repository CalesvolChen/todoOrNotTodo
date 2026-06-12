import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:todo_app/features/auth/presentation/screens/login_screen.dart';
import 'package:todo_app/features/auth/presentation/screens/register_screen.dart';
import 'package:todo_app/features/auth/presentation/view_models/auth_controller.dart';
import 'package:todo_app/features/lists/presentation/screens/members_screen.dart';
import 'package:todo_app/features/invitations/presentation/screens/invitations_screen.dart';
import 'package:todo_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:todo_app/core/router/page_transitions.dart';
import 'package:todo_app/features/tasks/presentation/screens/important_tasks_screen.dart';
import 'package:todo_app/features/tasks/presentation/screens/home_screen.dart';
import 'package:todo_app/features/tasks/presentation/screens/task_detail_screen.dart';

/// 启动鉴权恢复占位页
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('加载中…'),
          ],
        ),
      ),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    refreshListenable: refresh,
    debugLogDiagnostics: kDebugMode,
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '页面无法打开\n${state.error}',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;

      if (auth.initializing) {
        return loc == '/splash' ? null : '/splash';
      }

      if (loc == '/splash') {
        return auth.isAuthenticated ? '/' : '/login';
      }

      final isAuth = auth.isAuthenticated;
      final onAuthPage = loc == '/login' || loc == '/register';

      if (!isAuth) {
        return onAuthPage ? null : '/login';
      }
      if (onAuthPage) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) =>
            appPage(key: state.pageKey, child: const SplashScreen()),
      ),
      GoRoute(
        path: '/',
        pageBuilder: (context, state) =>
            appPage(key: state.pageKey, child: const HomeScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            appPage(key: state.pageKey, child: const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => appPage(
          key: state.pageKey,
          kind: PageTransitionKind.slide,
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => appPage(
          key: state.pageKey,
          kind: PageTransitionKind.slide,
          child: const SettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/important',
        pageBuilder: (context, state) => appPage(
          key: state.pageKey,
          kind: PageTransitionKind.slide,
          child: const ImportantTasksScreen(),
        ),
      ),
      GoRoute(
        path: '/invitations',
        pageBuilder: (context, state) => appPage(
          key: state.pageKey,
          kind: PageTransitionKind.slide,
          child: const InvitationsScreen(),
        ),
      ),
      GoRoute(
        path: '/task/:id',
        pageBuilder: (context, state) => appPage(
          key: state.pageKey,
          kind: PageTransitionKind.slide,
          child: TaskDetailScreen(taskId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/list/:id/members',
        pageBuilder: (context, state) => appPage(
          key: state.pageKey,
          kind: PageTransitionKind.slide,
          child: MembersScreen(listId: state.pathParameters['id']!),
        ),
      ),
    ],
  );
});
