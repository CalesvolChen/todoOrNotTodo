import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todo_app/features/tasks/data/models/task.dart';
import 'package:todo_app/features/tasks/presentation/view_models/tasks_controller.dart';

class TaskTile extends ConsumerWidget {
  const TaskTile({super.key, required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete, color: theme.colorScheme.onErrorContainer),
      ),
      onDismissed: (_) =>
          ref.read(tasksControllerProvider.notifier).remove(task),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          leading: Checkbox(
            value: task.completed,
            onChanged: (_) =>
                ref.read(tasksControllerProvider.notifier).toggle(task),
          ),
          title: Text(
            task.title,
            style: TextStyle(
              decoration:
                  task.completed ? TextDecoration.lineThrough : null,
              color: task.completed ? theme.disabledColor : null,
            ),
          ),
          subtitle: task.note != null
              ? Text(
                  task.note!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: task.important
              ? const Icon(Icons.star, color: Colors.amber)
              : null,
        ),
      ),
    );
  }
}
