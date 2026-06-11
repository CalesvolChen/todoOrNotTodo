import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:todo_app/features/lists/data/models/task_list.dart';
import 'package:todo_app/features/tasks/data/models/task.dart';
import 'package:todo_app/features/tasks/presentation/widgets/task_tile.dart';

/// 按分组折叠展示任务（用于「全部任务」视图）
class TasksGroupedList extends StatefulWidget {
  const TasksGroupedList({
    super.key,
    required this.tasks,
    required this.lists,
  });

  final List<Task> tasks;
  final List<TaskList> lists;

  @override
  State<TasksGroupedList> createState() => _TasksGroupedListState();
}

class _TasksGroupedListState extends State<TasksGroupedList> {
  final Map<String, bool> _expanded = {};

  bool _isExpanded(String key) => _expanded[key] ?? true;

  void _toggle(String key) {
    setState(() => _expanded[key] = !_isExpanded(key));
  }

  @override
  Widget build(BuildContext context) {
    final listById = {for (final l in widget.lists) l.id: l};
    final grouped = <String, List<Task>>{};

    for (final task in widget.tasks) {
      final key = task.listId ?? '_ungrouped';
      grouped.putIfAbsent(key, () => []).add(task);
    }

    // 按分组列表顺序排列，未分组放最后
    final orderedKeys = <String>[
      ...widget.lists
          .where((l) => grouped.containsKey(l.id))
          .map((l) => l.id),
      if (grouped.containsKey('_ungrouped')) '_ungrouped',
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orderedKeys.length,
      itemBuilder: (context, index) {
        final key = orderedKeys[index];
        final sectionTasks = grouped[key]!;
        final title = key == '_ungrouped'
            ? '未分组'
            : (listById[key]?.name ?? '分组');
        final expanded = _isExpanded(key);

        return Padding(
          padding: EdgeInsets.only(bottom: index < orderedKeys.length - 1 ? 12 : 0),
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                InkWell(
                  onTap: () => _toggle(key),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          expanded
                              ? Icons.expand_more
                              : Icons.chevron_right,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        Text(
                          '${sectionTasks.length}',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                if (expanded)
                  ...sectionTasks.map(
                    (task) => Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: TaskTile(
                        task: task,
                        onTap: () => context.go('/task/${task.id}'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
