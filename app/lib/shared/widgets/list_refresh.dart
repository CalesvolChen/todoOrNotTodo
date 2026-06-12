import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todo_app/features/invitations/presentation/view_models/invitations_badge_provider.dart';
import 'package:todo_app/features/invitations/presentation/view_models/invitations_controller.dart';
import 'package:todo_app/features/tasks/presentation/view_models/important_tasks_controller.dart';
import 'package:todo_app/features/lists/presentation/view_models/lists_controller.dart';
import 'package:todo_app/features/tasks/presentation/view_models/tasks_controller.dart';

/// 进入列表页后于首帧静默同步（错误由列表 UI 展示，不弹窗）
void syncListPageOnEnter(WidgetRef ref, Future<void> Function(WidgetRef) refresh) {
  SchedulerBinding.instance.addPostFrameCallback((_) {
    refresh(ref);
  });
}

/// 首页任务列表刷新
Future<void> refreshHomeTasks(
  WidgetRef ref, {
  required bool includeLists,
  bool includeInvitationBadge = false,
}) async {
  ref.invalidate(tasksControllerProvider);
  final futures = <Future<void>>[ref.read(tasksControllerProvider.future)];
  if (includeLists) {
    ref.invalidate(listsControllerProvider);
    futures.add(ref.read(listsControllerProvider.future));
  }
  if (includeInvitationBadge) {
    refreshPendingInvitationsBadge(ref);
    futures.add(ref.read(pendingInvitationsCountProvider.future));
  }
  await Future.wait(futures);
}

/// 进入首页时同步当前选中列表
Future<void> syncHomeTasksOnEnter(WidgetRef ref) {
  final selectedId = ref.read(selectedListIdProvider);
  return refreshHomeTasks(
    ref,
    includeLists: selectedId == null,
    includeInvitationBadge: true,
  );
}

/// 重要任务列表刷新
Future<void> refreshImportantTasks(WidgetRef ref) async {
  ref.invalidate(importantTasksControllerProvider);
  ref.invalidate(listsControllerProvider);
  refreshPendingInvitationsBadge(ref);
  await Future.wait([
    ref.read(importantTasksControllerProvider.future),
    ref.read(listsControllerProvider.future),
    ref.read(pendingInvitationsCountProvider.future),
  ]);
}

/// 协作邀请列表刷新
Future<void> refreshInvitations(WidgetRef ref) async {
  ref.invalidate(invitationsControllerProvider);
  refreshPendingInvitationsBadge(ref);
  await Future.wait([
    ref.read(invitationsControllerProvider.future),
    ref.read(pendingInvitationsCountProvider.future),
  ]);
}

/// 分组成员列表刷新
Future<void> refreshListMembers(WidgetRef ref, String listId) async {
  ref.invalidate(listMembersProvider(listId));
  await ref.read(listMembersProvider(listId).future);
}
