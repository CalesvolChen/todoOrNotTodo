import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todo_app/features/tasks/data/models/task.dart';
import 'package:todo_app/features/tasks/data/task_repository.dart';

class TasksController extends AsyncNotifier<List<Task>> {
  TaskRepository get _repo => ref.read(taskRepositoryProvider);

  @override
  Future<List<Task>> build() => _repo.fetchTasks();

  Future<void> add(String title) async {
    if (title.trim().isEmpty) return;
    await _repo.createTask(title.trim());
    ref.invalidateSelf();
    await future;
  }

  Future<void> toggle(Task task) async {
    await _repo.toggleComplete(task.id, !task.completed);
    ref.invalidateSelf();
    await future;
  }

  Future<void> remove(Task task) async {
    await _repo.deleteTask(task.id);
    ref.invalidateSelf();
    await future;
  }
}

final tasksControllerProvider =
    AsyncNotifierProvider<TasksController, List<Task>>(TasksController.new);
