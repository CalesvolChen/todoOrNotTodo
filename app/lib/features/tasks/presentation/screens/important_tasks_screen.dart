import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todo_app/core/errors/app_error_message.dart';
import 'package:todo_app/features/lists/presentation/view_models/lists_controller.dart';
import 'package:todo_app/features/tasks/presentation/view_models/important_tasks_controller.dart';
import 'package:todo_app/features/tasks/presentation/widgets/app_drawer.dart';
import 'package:todo_app/features/tasks/presentation/widgets/home_menu_button.dart';
import 'package:todo_app/features/tasks/presentation/widgets/task_tile.dart';
import 'package:todo_app/features/tasks/presentation/widgets/tasks_grouped_list.dart';
import 'package:todo_app/shared/widgets/animated_fab.dart';
import 'package:todo_app/shared/widgets/app_error_dialog.dart';
import 'package:todo_app/shared/widgets/app_pull_to_refresh.dart';
import 'package:todo_app/shared/widgets/empty_placeholder.dart';
import 'package:todo_app/shared/widgets/fade_slide_in.dart';
import 'package:todo_app/shared/widgets/list_refresh.dart';

class ImportantTasksScreen extends ConsumerStatefulWidget {
  const ImportantTasksScreen({super.key});

  @override
  ConsumerState<ImportantTasksScreen> createState() =>
      _ImportantTasksScreenState();
}

class _ImportantTasksScreenState extends ConsumerState<ImportantTasksScreen> {
  @override
  void initState() {
    super.initState();
    syncListPageOnEnter(ref, refreshImportantTasks);
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(importantTasksControllerProvider);
    final listsAsync = ref.watch(listsControllerProvider);
    final notifier = ref.read(importantTasksControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const HomeMenuButton(),
        title: const Text('重要任务'),
      ),
      drawer: const AppDrawer(),
      floatingActionButton: AnimatedFab(
        onPressed: () => _showAddSheet(context, ref),
        child: const Icon(Icons.add),
      ),
      body: AppPullToRefresh(
        onRefresh: () => runWithAppErrorDialog(
          context,
          () => refreshImportantTasks(ref),
        ),
        child: tasksAsync.when(
          data: (tasks) {
            final importantTasks =
                tasks.where((t) => t.important && !t.completed).toList();
            if (importantTasks.isEmpty) {
              return AppPullToRefresh.scrollableEmpty(
                child: const EmptyPlaceholder(
                  icon: Icons.star_outline,
                  message: '暂无重要任务，点击 + 添加',
                ),
              );
            }
            return listsAsync.when(
              data: (lists) => TasksGroupedList(
                tasks: importantTasks,
                lists: lists,
                showCompletedSection: false,
                enableDrag: false,
                taskTileBuilder: (task, onTap) => TaskTile(
                  task: task,
                  onTap: onTap,
                  enableDismiss: false,
                  onToggle: notifier.toggle,
                  onToggleImportant: notifier.toggleImportant,
                ),
              ),
              loading: () => AppPullToRefresh.scrollableEmpty(
                child: const Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => AppPullToRefresh.scrollableEmpty(
                child: Center(
                  child: Text('加载失败：${messageFromError(e)}'),
                ),
              ),
            );
          },
          loading: () => AppPullToRefresh.scrollableEmpty(
            child: const Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => AppPullToRefresh.scrollableEmpty(
            child: Center(child: Text('加载失败：${messageFromError(e)}')),
          ),
        ),
      ),
    );
  }
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
                decoration: const InputDecoration(
                  hintText: '添加重要任务',
                ),
                onSubmitted: (v) async {
                  final ok = await runWithAppErrorDialog(
                    ctx,
                    () => ref
                        .read(importantTasksControllerProvider.notifier)
                        .add(v),
                  );
                  if (ok && ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              icon: const Icon(Icons.send),
              onPressed: () async {
                final ok = await runWithAppErrorDialog(
                  ctx,
                  () => ref
                      .read(importantTasksControllerProvider.notifier)
                      .add(controller.text),
                );
                if (ok && ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    ),
  );
}
