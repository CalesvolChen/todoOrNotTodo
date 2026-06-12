import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todo_app/core/audio/completion_sound.dart';
import 'package:todo_app/features/tasks/data/models/task.dart';
import 'package:todo_app/features/tasks/data/task_repository.dart';
import 'package:todo_app/features/tasks/presentation/view_models/tasks_controller.dart';

class ImportantTasksController extends AsyncNotifier<List<Task>> {
  TaskRepository get _repo => ref.read(taskRepositoryProvider);

  @override
  Future<List<Task>> build() async {
    final tasks = await _repo.fetchTasks(important: true, completed: false);
    return tasks.where((t) => t.important && !t.completed).toList();
  }

  Future<void> add(String title) async {
    if (title.trim().isEmpty) return;
    await _repo.createTask(title.trim(), important: true);
    ref.invalidateSelf();
    await future;
    ref.invalidate(tasksControllerProvider);
  }

  Future<void> toggle(Task task) async {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.where((t) => t.id != task.id).toList());
    }
    try {
      await _repo.toggleComplete(task.id, true);
      unawaited(CompletionSound.play());
      ref.invalidate(tasksControllerProvider);
    } catch (e) {
      ref.invalidateSelf();
      await future;
      rethrow;
    }
  }

  Future<void> toggleImportant(Task task) async {
    await _repo.setImportant(task.id, !task.important);
    ref.invalidateSelf();
    await future;
    ref.invalidate(tasksControllerProvider);
  }
}

final importantTasksControllerProvider =
    AsyncNotifierProvider<ImportantTasksController, List<Task>>(
  ImportantTasksController.new,
);
