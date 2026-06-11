import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todo_app/features/tasks/data/models/task.dart';
import 'package:todo_app/features/tasks/presentation/view_models/tasks_controller.dart';
import 'package:todo_app/shared/widgets/app_error_dialog.dart';

class TaskTile extends ConsumerWidget {
  const TaskTile({
    super.key,
    required this.task,
    this.onTap,
    this.enableDismiss = true,
  });

  final Task task;
  final VoidCallback? onTap;
  final bool enableDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tile = AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          leading: Checkbox(
            value: task.completed,
            onChanged: (_) => runWithAppErrorDialog(
              context,
              () => ref.read(tasksControllerProvider.notifier).toggle(task),
            ),
          ),
          title: Text(
            task.title,
            style: TextStyle(
              decoration:
                  task.completed ? TextDecoration.lineThrough : null,
              color: task.completed ? theme.disabledColor : null,
            ),
          ),
          subtitle: _buildSubtitle(theme),
          trailing: IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: child,
              ),
              child: Icon(
                task.important ? Icons.star : Icons.star_border,
                key: ValueKey(task.important),
                color: task.important ? Colors.amber : theme.disabledColor,
              ),
            ),
            tooltip: '标记重要',
            onPressed: () => runWithAppErrorDialog(
              context,
              () =>
                  ref.read(tasksControllerProvider.notifier).toggleImportant(task),
            ),
          ),
        ),
      ),
    );

    if (!enableDismiss) return tile;

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
      onDismissed: (_) => runWithAppErrorDialog(
        context,
        () => ref.read(tasksControllerProvider.notifier).remove(task),
      ),
      child: tile,
    );
  }

  Widget? _buildSubtitle(ThemeData theme) {
    final parts = <String>[];
    final stepLabel = task.stepProgressLabel;
    if (stepLabel != null) parts.add(stepLabel);
    if (task.note != null && task.note!.isNotEmpty) parts.add(task.note!);
    if (parts.isEmpty) return null;
    return Text(
      parts.join(' · '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: task.steps.isNotEmpty
          ? TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 12,
            )
          : null,
    );
  }
}
