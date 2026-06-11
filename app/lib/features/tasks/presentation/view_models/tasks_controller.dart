import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todo_app/core/audio/completion_sound.dart';
import 'package:todo_app/features/lists/presentation/view_models/lists_controller.dart';
import 'package:todo_app/features/tasks/data/models/task.dart';
import 'package:todo_app/features/tasks/data/task_repository.dart';

class TasksController extends AsyncNotifier<List<Task>> {
  TaskRepository get _repo => ref.read(taskRepositoryProvider);

  @override
  Future<List<Task>> build() {
    final listId = ref.watch(selectedListIdProvider);
    return _repo.fetchTasks(listId: listId);
  }

  Future<void> add(String title) async {
    if (title.trim().isEmpty) return;
    final listId = ref.read(selectedListIdProvider);
    await _repo.createTask(title.trim(), listId: listId);
    ref.invalidateSelf();
    await future;
  }

  Future<void> toggle(Task task) async {
    final markingComplete = !task.completed;
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(
        current
            .map(
              (t) => t.id == task.id
                  ? t.copyWith(
                      completed: markingComplete,
                      completedAt:
                          markingComplete ? DateTime.now() : null,
                    )
                  : t,
            )
            .toList(),
      );
    }
    try {
      await _repo.toggleComplete(task.id, markingComplete);
      if (markingComplete) {
        unawaited(CompletionSound.play());
      }
    } catch (_) {
      ref.invalidateSelf();
      await future;
    }
  }

  Future<void> toggleImportant(Task task) async {
    await _repo.setImportant(task.id, !task.important);
    ref.invalidateSelf();
    await future;
  }

  Future<void> moveToList(Task task, String? listId) async {
    if (task.listId == listId) return;
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(
        current
            .map((t) => t.id == task.id ? t.copyWith(listId: listId) : t)
            .toList(),
      );
    }
    try {
      await _repo.moveTask(task.id, listId: listId);
    } catch (_) {
      ref.invalidateSelf();
      await future;
    }
  }

  Future<void> remove(Task task) async {
    final current = state.valueOrNull;
    if (current != null) {
      // Dismissible 要求 onDismissed 后立刻从树中移除，先乐观更新 UI
      state = AsyncData(
        current.where((t) => t.id != task.id).toList(),
      );
    }
    try {
      await _repo.deleteTask(task.id);
    } catch (_) {
      ref.invalidateSelf();
      await future;
    }
  }
}

final tasksControllerProvider =
    AsyncNotifierProvider<TasksController, List<Task>>(TasksController.new);

/// 单个任务详情
final taskDetailProvider = FutureProvider.family<Task, String>((ref, id) {
  return ref.watch(taskRepositoryProvider).fetchTask(id);
});
