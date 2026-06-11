import 'package:flutter/material.dart';

import 'package:todo_app/features/tasks/data/models/task.dart';
import 'package:todo_app/features/tasks/presentation/widgets/task_tile.dart';

/// 列表底部的「已完成」分组（随列表滚动，默认收起）
class CompletedTasksSection extends StatefulWidget {
  const CompletedTasksSection({
    super.key,
    required this.tasks,
    required this.onTaskTap,
    this.padding = const EdgeInsets.fromLTRB(0, 16, 0, 0),
  });

  final List<Task> tasks;
  final void Function(Task task) onTaskTap;
  final EdgeInsets padding;

  @override
  State<CompletedTasksSection> createState() => _CompletedTasksSectionState();
}

class _CompletedTasksSectionState extends State<CompletedTasksSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.tasks.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Padding(
      padding: widget.padding,
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    AnimatedRotation(
                      turns: _expanded ? 0 : -0.25,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      child: const Icon(Icons.expand_more),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '已完成',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    Text(
                      '${widget.tasks.length}',
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
              child: _expanded
                  ? Column(
                      children: widget.tasks
                          .map(
                            (task) => Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                              child: TaskTile(
                                task: task,
                                onTap: () => widget.onTaskTap(task),
                              ),
                            ),
                          )
                          .toList(),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}
