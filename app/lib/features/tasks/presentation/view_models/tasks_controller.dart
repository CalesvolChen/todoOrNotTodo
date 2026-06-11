import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    await _repo.toggleComplete(task.id, !task.completed);
    ref.invalidateSelf();
    await future;
  }

  Future<void> toggleImportant(Task task) async {
    await _repo.setImportant(task.id, !task.important);
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

/// 单个任务详情
final taskDetailProvider = FutureProvider.family<Task, String>((ref, id) {
  return ref.watch(taskRepositoryProvider).fetchTask(id);
});
