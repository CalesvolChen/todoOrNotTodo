import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:todo_app/core/errors/app_error_message.dart';
import 'package:todo_app/features/lists/data/models/task_list.dart';
import 'package:todo_app/features/lists/presentation/view_models/lists_controller.dart';
import 'package:todo_app/features/lists/presentation/widgets/list_members_bar.dart';
import 'package:todo_app/features/tasks/presentation/view_models/tasks_controller.dart';
import 'package:todo_app/features/invitations/presentation/view_models/invitations_badge_provider.dart';
import 'package:todo_app/features/tasks/presentation/widgets/app_drawer.dart';
import 'package:todo_app/features/tasks/presentation/widgets/home_menu_button.dart';
import 'package:todo_app/features/tasks/presentation/widgets/tasks_grouped_list.dart';
import 'package:todo_app/features/tasks/presentation/widgets/tasks_list_body.dart';
import 'package:todo_app/shared/widgets/animated_fab.dart';
import 'package:todo_app/shared/widgets/app_error_dialog.dart';
import 'package:todo_app/shared/widgets/app_pull_to_refresh.dart';
import 'package:todo_app/shared/widgets/empty_placeholder.dart';
import 'package:todo_app/shared/widgets/fade_slide_in.dart';
import 'package:todo_app/shared/widgets/list_refresh.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    syncListPageOnEnter(ref, syncHomeTasksOnEnter);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshPendingInvitationsBadge(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(selectedListIdProvider, (previous, next) {
      if (previous != next) {
        syncListPageOnEnter(ref, syncHomeTasksOnEnter);
      }
    });

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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const HomeMenuButton(),
        title: Text(title),
      ),
      drawer: const AppDrawer(),
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
            child: AppPullToRefresh(
              onRefresh: () => runWithAppErrorDialog(
                context,
                () => refreshHomeTasks(
                  ref,
                  includeLists: selectedId == null,
                  includeInvitationBadge: true,
                ),
              ),
              child: tasksAsync.when(
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return AppPullToRefresh.scrollableEmpty(
                      child: const EmptyPlaceholder(
                        icon: Icons.checklist_rtl,
                        message: '暂无任务，点击 + 添加',
                      ),
                    );
                  }
                  if (selectedId == null) {
                    return listsAsync.when(
                      data: (lists) => TasksGroupedList(
                        tasks: tasks,
                        lists: lists,
                      ),
                      loading: () => AppPullToRefresh.scrollableEmpty(
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (e, _) => AppPullToRefresh.scrollableEmpty(
                        child: Center(
                          child: Text('加载失败：${messageFromError(e)}'),
                        ),
                      ),
                    );
                  }
                  return TasksListBody(
                    tasks: tasks,
                    onTaskTap: (task) => context.push('/task/${task.id}'),
                  );
                },
                loading: () => AppPullToRefresh.scrollableEmpty(
                  child: const Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => AppPullToRefresh.scrollableEmpty(
                  child: Center(
                    child: Text('加载失败：${messageFromError(e)}'),
                  ),
                ),
              ),
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
                  onSubmitted: (v) async {
                    final ok = await runWithAppErrorDialog(
                      ctx,
                      () => ref.read(tasksControllerProvider.notifier).add(v),
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
                        .read(tasksControllerProvider.notifier)
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
}
