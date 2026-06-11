import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:todo_app/core/network/file_url.dart';
import 'package:todo_app/features/auth/presentation/view_models/auth_controller.dart';
import 'package:todo_app/features/lists/data/models/task_list.dart';
import 'package:todo_app/features/lists/presentation/view_models/lists_controller.dart';
import 'package:todo_app/features/lists/presentation/widgets/list_members_bar.dart';
import 'package:todo_app/features/tasks/presentation/view_models/tasks_controller.dart';
import 'package:todo_app/features/tasks/presentation/widgets/task_tile.dart';
import 'package:todo_app/features/tasks/presentation/widgets/tasks_grouped_list.dart';
import 'package:todo_app/shared/widgets/animated_fab.dart';
import 'package:todo_app/shared/widgets/empty_placeholder.dart';
import 'package:todo_app/shared/widgets/fade_slide_in.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksControllerProvider);
    final selectedId = ref.watch(selectedListIdProvider);
    final listsAsync = ref.watch(listsControllerProvider);

    TaskList? selectedList;
    if (selectedId != null) {
      selectedList = listsAsync.maybeWhen(
        data: (lists) {
          for (final l in lists) {
            if (l.id == selectedId) return l;
          }
          return null;
        },
        orElse: () => null,
      );
    }

    final title = selectedId == null
        ? '全部任务'
        : (selectedList?.name ?? '任务');

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      drawer: const _AppDrawer(),
      floatingActionButton: AnimatedFab(
        onPressed: () => _showAddSheet(context, ref),
        child: const Icon(Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (selectedId != null && (selectedList?.isShared ?? false))
            ListMembersBar(listId: selectedId),
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                if (tasks.isEmpty) {
                  return const EmptyPlaceholder(
                    icon: Icons.checklist_rtl,
                    message: '暂无任务，点击 + 添加',
                  );
                }
                if (selectedId == null) {
                  return listsAsync.when(
                    data: (lists) => TasksGroupedList(
                      tasks: tasks,
                      lists: lists,
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('加载失败：$e')),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return FadeSlideIn(
                      index: index,
                      child: TaskTile(
                        task: task,
                        onTap: () => context.push('/task/${task.id}'),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败：$e')),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => FadeSlideIn(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(hintText: '添加任务'),
                  onSubmitted: (v) {
                    ref.read(tasksControllerProvider.notifier).add(v);
                    Navigator.pop(ctx);
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: const Icon(Icons.send),
                onPressed: () {
                  ref
                      .read(tasksControllerProvider.notifier)
                      .add(controller.text);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppDrawer extends ConsumerWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final listsAsync = ref.watch(listsControllerProvider);
    final selectedId = ref.watch(selectedListIdProvider);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            FadeSlideIn(
              index: 0,
              child: UserAccountsDrawerHeader(
                accountName: Text(user?.displayName ?? '用户'),
                accountEmail: Text(user?.username ?? user?.email ?? ''),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: (user?.avatar != null)
                      ? NetworkImage(fileUrl(user!.avatar))
                      : null,
                  child: user?.avatar == null
                      ? Text(
                          user?.displayName.characters.first.toUpperCase() ??
                              '?',
                        )
                      : null,
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
                selected: selectedId == null,
                onTap: () {
                  ref.read(selectedListIdProvider.notifier).state = null;
                  Navigator.pop(context);
                },
              ),
            ),
            FadeSlideIn(
              index: 2,
              child: ListTile(
                leading: const Icon(Icons.mail_outline),
                title: const Text('协作邀请'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/invitations');
                },
              ),
            ),
            const Divider(height: 1),
            FadeSlideIn(
              index: 3,
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
                        index: 4 + i,
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
                          selected: selectedId == lists[i].id,
                          onTap: () {
                            ref.read(selectedListIdProvider.notifier).state =
                                lists[i].id;
                            Navigator.pop(context);
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
                error: (e, _) => Center(child: Text('加载失败：$e')),
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
              await ref.read(listsControllerProvider.notifier).create(name);
              if (ctx.mounted) Navigator.pop(ctx);
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
              await ref
                  .read(listsControllerProvider.notifier)
                  .rename(list.id, name);
              if (ctx.mounted) Navigator.pop(ctx);
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
              await ref.read(listsControllerProvider.notifier).remove(list.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('解散'),
          ),
        ],
      ),
    );
  }
}
