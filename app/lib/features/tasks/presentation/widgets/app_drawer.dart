import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:todo_app/core/errors/app_error_message.dart';
import 'package:todo_app/features/auth/presentation/view_models/auth_controller.dart';
import 'package:todo_app/features/invitations/presentation/view_models/invitations_badge_provider.dart';
import 'package:todo_app/features/lists/data/models/task_list.dart';
import 'package:todo_app/features/lists/presentation/view_models/lists_controller.dart';
import 'package:todo_app/shared/widgets/app_error_dialog.dart';
import 'package:todo_app/shared/widgets/fade_slide_in.dart';
import 'package:todo_app/shared/widgets/user_avatar.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final listsAsync = ref.watch(listsControllerProvider);
    final selectedId = ref.watch(selectedListIdProvider);
    final location = GoRouterState.of(context).matchedLocation;
    final pendingCount = ref.watch(pendingInvitationsCountProvider).valueOrNull ?? 0;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            FadeSlideIn(
              index: 0,
              child: UserAccountsDrawerHeader(
                accountName: Text(user?.displayName ?? '用户'),
                accountEmail: Text(user?.username ?? user?.email ?? ''),
                currentAccountPicture: UserAvatar(
                  key: ValueKey(user?.avatar),
                  avatar: user?.avatar,
                  name: user?.displayName ?? '用户',
                  radius: 20,
                ),
                onDetailsPressed: () {
                  Navigator.pop(context);
                  context.go('/settings');
                },
              ),
            ),
            FadeSlideIn(
              index: 1,
              child: ListTile(
                leading: const Icon(Icons.all_inbox_outlined),
                title: const Text('全部任务'),
                selected: location == '/' && selectedId == null,
                onTap: () {
                  ref.read(selectedListIdProvider.notifier).state = null;
                  Navigator.pop(context);
                  if (location != '/') context.go('/');
                },
              ),
            ),
            FadeSlideIn(
              index: 2,
              child: ListTile(
                leading: const Icon(Icons.star_outline),
                title: const Text('重要任务'),
                selected: location == '/important',
                onTap: () {
                  Navigator.pop(context);
                  context.go('/important');
                },
              ),
            ),
            FadeSlideIn(
              index: 3,
              child: ListTile(
                leading: Badge(
                  isLabelVisible: pendingCount > 0,
                  label: Text('$pendingCount'),
                  child: const Icon(Icons.mail_outline),
                ),
                title: const Text('协作邀请'),
                selected: location == '/invitations',
                onTap: () {
                  Navigator.pop(context);
                  context.go('/invitations');
                },
              ),
            ),
            const Divider(height: 1),
            FadeSlideIn(
              index: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '我的分组',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      tooltip: '新建分组',
                      onPressed: () => _showCreateDialog(context, ref),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: listsAsync.when(
                data: (lists) => ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    for (var i = 0; i < lists.length; i++)
                      FadeSlideIn(
                        index: 5 + i,
                        child: ListTile(
                          leading: Icon(
                            lists[i].isShared
                                ? Icons.group_outlined
                                : Icons.list_alt_outlined,
                          ),
                          title: Text(lists[i].name),
                          subtitle: lists[i].isShared
                              ? Text('${lists[i].memberCount + 1} 人协作')
                              : null,
                          selected: location == '/' && selectedId == lists[i].id,
                          onTap: () {
                            ref.read(selectedListIdProvider.notifier).state =
                                lists[i].id;
                            Navigator.pop(context);
                            if (location != '/') context.go('/');
                          },
                          trailing: PopupMenuButton<String>(
                            onSelected: (action) =>
                                _onListAction(context, ref, lists[i], action),
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'rename',
                                child: Text('重命名'),
                              ),
                              const PopupMenuItem(
                                value: 'invite',
                                child: Text('邀请协作'),
                              ),
                              if (user?.id == lists[i].ownerId)
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('解散分组'),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('加载失败：${messageFromError(e)}'),
                ),
              ),
            ),
            const Divider(height: 1),
            FadeSlideIn(
              index: 20,
              child: ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('设置'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/settings');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _onListAction(
  BuildContext context,
  WidgetRef ref,
  TaskList list,
  String action,
) {
  switch (action) {
    case 'rename':
      _showRenameDialog(context, ref, list);
    case 'invite':
      Navigator.pop(context);
      context.go('/list/${list.id}/members');
    case 'delete':
      _confirmDelete(context, ref, list);
  }
}

void _showCreateDialog(BuildContext context, WidgetRef ref) {
  final controller = TextEditingController();
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('新建分组'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: '分组名称'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () async {
            final name = controller.text.trim();
            if (name.isEmpty) return;
            final ok = await runWithAppErrorDialog(
              ctx,
              () => ref.read(listsControllerProvider.notifier).create(name),
            );
            if (ok && ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('创建'),
        ),
      ],
    ),
  );
}

void _showRenameDialog(BuildContext context, WidgetRef ref, TaskList list) {
  final controller = TextEditingController(text: list.name);
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('重命名分组'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: '分组名称'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () async {
            final name = controller.text.trim();
            if (name.isEmpty) return;
            final ok = await runWithAppErrorDialog(
              ctx,
              () => ref.read(listsControllerProvider.notifier).rename(list.id, name),
            );
            if (ok && ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('保存'),
        ),
      ],
    ),
  );
}

void _confirmDelete(BuildContext context, WidgetRef ref, TaskList list) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('解散分组'),
      content: Text('确定解散「${list.name}」？组内任务将一并删除。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () async {
            final ok = await runWithAppErrorDialog(
              ctx,
              () => ref.read(listsControllerProvider.notifier).remove(list.id),
            );
            if (ok && ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('解散'),
        ),
      ],
    ),
  );
}
