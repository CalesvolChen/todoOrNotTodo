import 'package:flutter/material.dart';

import 'package:todo_app/features/tasks/data/models/task.dart';
import 'package:todo_app/features/tasks/presentation/widgets/completed_tasks_section.dart';
import 'package:todo_app/features/tasks/presentation/widgets/task_tile.dart';
import 'package:todo_app/shared/widgets/fade_slide_in.dart';

/// 单分组任务列表：进行中在上，底部固定「已完成」
class TasksListBody extends StatelessWidget {
  const TasksListBody({
    super.key,
    required this.tasks,
    required this.onTaskTap,
  });

  final List<Task> tasks;
  final void Function(Task task) onTaskTap;

  @override
  Widget build(BuildContext context) {
    final split = splitTasksByCompletion(tasks);
    if (split.active.isEmpty && split.completed.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (var i = 0; i < split.active.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i < split.active.length - 1 ? 8 : 0),
            child: FadeSlideIn(
              index: i,
              child: TaskTile(
                task: split.active[i],
                onTap: () => onTaskTap(split.active[i]),
              ),
            ),
          ),
        CompletedTasksSection(
          tasks: split.completed,
          onTaskTap: onTaskTap,
          padding: EdgeInsets.only(top: split.active.isEmpty ? 0 : 16),
        ),
      ],
    );
  }
}
