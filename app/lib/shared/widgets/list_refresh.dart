import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todo_app/features/invitations/presentation/view_models/invitations_controller.dart';
import 'package:todo_app/features/lists/data/list_repository.dart';
import 'package:todo_app/features/lists/presentation/view_models/lists_controller.dart';
import 'package:todo_app/features/tasks/presentation/view_models/tasks_controller.dart';

/// 首页任务列表刷新
Future<void> refreshHomeTasks(WidgetRef ref, {required bool includeLists}) async {
  ref.invalidate(tasksControllerProvider);
  final futures = <Future<void>>[ref.read(tasksControllerProvider.future)];
  if (includeLists) {
    ref.invalidate(listsControllerProvider);
    futures.add(ref.read(listsControllerProvider.future));
  }
  await Future.wait(futures);
}

/// 协作邀请列表刷新
Future<void> refreshInvitations(WidgetRef ref) async {
  ref.invalidate(invitationsControllerProvider);
  await ref.read(invitationsControllerProvider.future);
}

/// 分组成员列表刷新
Future<void> refreshListMembers(WidgetRef ref, String listId) async {
  ref.invalidate(listMembersProvider(listId));
  await ref.read(listMembersProvider(listId).future);
}
