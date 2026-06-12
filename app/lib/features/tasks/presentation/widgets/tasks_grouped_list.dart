import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:todo_app/features/lists/data/models/task_list.dart';
import 'package:todo_app/features/tasks/data/models/task.dart';
import 'package:todo_app/features/tasks/presentation/view_models/tasks_controller.dart';
import 'package:todo_app/features/tasks/presentation/widgets/completed_tasks_section.dart';
import 'package:todo_app/features/tasks/presentation/widgets/task_tile.dart';
import 'package:todo_app/shared/widgets/app_error_dialog.dart';
import 'package:todo_app/shared/widgets/app_pull_to_refresh.dart';

/// 按分组折叠展示任务（用于「全部任务」视图），支持长按拖拽跨分组移动
class TasksGroupedList extends ConsumerStatefulWidget {
  const TasksGroupedList({
    super.key,
    required this.tasks,
    required this.lists,
    this.showCompletedSection = true,
    this.enableDrag = true,
    this.taskTileBuilder,
  });

  final List<Task> tasks;
  final List<TaskList> lists;
  final bool showCompletedSection;
  final bool enableDrag;
  final Widget Function(Task task, VoidCallback onTap)? taskTileBuilder;

  @override
  ConsumerState<TasksGroupedList> createState() => _TasksGroupedListState();
}

class _TasksGroupedListState extends ConsumerState<TasksGroupedList> {
  final Map<String, bool> _expanded = {};

  bool _isExpanded(String key) => _expanded[key] ?? true;

  void _toggle(String key) {
    setState(() => _expanded[key] = !_isExpanded(key));
  }

  String? _listIdForKey(String key) => key == '_ungrouped' ? null : key;

  void _onDrop(String targetKey, Task task) {
    final listId = _listIdForKey(targetKey);
    if (task.listId == listId) return;
    runWithAppErrorDialog(
      context,
      () => ref.read(tasksControllerProvider.notifier).moveToList(task, listId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final split = splitTasksByCompletion(widget.tasks);
    final listById = {for (final l in widget.lists) l.id: l};
    final grouped = <String, List<Task>>{};

    for (final task in split.active) {
      final key = task.listId ?? '_ungrouped';
      grouped.putIfAbsent(key, () => []).add(task);
    }

    final orderedKeys = <String>[
      ...widget.lists
          .where((l) => grouped.containsKey(l.id))
          .map((l) => l.id),
      if (grouped.containsKey('_ungrouped')) '_ungrouped',
    ];

    return ListView(
      physics: kAppListScrollPhysics,
      padding: const EdgeInsets.all(16),
      children: [
        for (var index = 0; index < orderedKeys.length; index++)
          Padding(
            padding:
                EdgeInsets.only(bottom: index < orderedKeys.length - 1 ? 12 : 0),
            child: _GroupSection(
              title: orderedKeys[index] == '_ungrouped'
                  ? '未分组'
                  : (listById[orderedKeys[index]]?.name ?? '分组'),
              sectionKey: orderedKeys[index],
              tasks: grouped[orderedKeys[index]]!,
              expanded: _isExpanded(orderedKeys[index]),
              onToggle: () => _toggle(orderedKeys[index]),
              onDrop: widget.enableDrag
                  ? (task) => _onDrop(orderedKeys[index], task)
                  : null,
              onTaskTap: (task) => context.push('/task/${task.id}'),
              enableDrag: widget.enableDrag,
              taskTileBuilder: widget.taskTileBuilder,
            ),
          ),
        if (widget.showCompletedSection)
          CompletedTasksSection(
            tasks: split.completed,
            onTaskTap: (task) => context.push('/task/${task.id}'),
          ),
      ],
    );
  }
}

class _GroupSection extends StatelessWidget {
  const _GroupSection({
    required this.title,
    required this.sectionKey,
    required this.tasks,
    required this.expanded,
    required this.onToggle,
    required this.onTaskTap,
    this.onDrop,
    this.enableDrag = true,
    this.taskTileBuilder,
  });

  final String title;
  final String sectionKey;
  final List<Task> tasks;
  final bool expanded;
  final VoidCallback onToggle;
  final void Function(Task task)? onDrop;
  final void Function(Task task) onTaskTap;
  final bool enableDrag;
  final Widget Function(Task task, VoidCallback onTap)? taskTileBuilder;

  @override
  Widget build(BuildContext context) {
    if (!enableDrag || onDrop == null) {
      return _buildSectionContent(context, highlight: false);
    }

    return DragTarget<Task>(
      onWillAcceptWithDetails: (d) =>
          !d.data.completed && d.data.listId != _listIdForKey(sectionKey),
      onAcceptWithDetails: (d) => onDrop!(d.data),
      builder: (context, candidate, rejected) {
        return _buildSectionContent(context, highlight: candidate.isNotEmpty);
      },
    );
  }

  Widget _buildSectionContent(BuildContext context, {required bool highlight}) {
    final theme = Theme.of(context);
    return Material(
      color: highlight
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: expanded ? 0 : -0.25,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    child: const Icon(Icons.expand_more),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  if (highlight)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.move_to_inbox_outlined,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  Text(
                    '${tasks.length}',
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: expanded
                ? Column(
                    children: tasks
                        .map(
                          (task) => Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                            child: _buildTaskTile(task),
                          ),
                        )
                        .toList(),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTile(Task task) {
    final onTap = () => onTaskTap(task);
    if (taskTileBuilder != null) {
      return taskTileBuilder!(task, onTap);
    }
    if (!enableDrag) {
      return TaskTile(task: task, onTap: onTap, enableDismiss: false);
    }
    return _DraggableTaskTile(task: task, onTap: onTap);
  }

  String? _listIdForKey(String key) => key == '_ungrouped' ? null : key;
}

class _DraggableTaskTile extends StatelessWidget {
  const _DraggableTaskTile({
    required this.task,
    required this.onTap,
  });

  final Task task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final child = TaskTile(task: task, onTap: onTap);
    final ghost = TaskTile(task: task, onTap: null, enableDismiss: false);
    return LongPressDraggable<Task>(
      data: task,
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width - 56,
          child: Opacity(opacity: 0.92, child: ghost),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: ghost),
      child: child,
    );
  }
}
