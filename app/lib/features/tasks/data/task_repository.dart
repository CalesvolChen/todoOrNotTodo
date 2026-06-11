import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todo_app/core/network/dio_client.dart';
import 'package:todo_app/features/tasks/data/models/task.dart';

class TaskRepository {
  TaskRepository(this._dio);

  final Dio _dio;

  Future<List<Task>> fetchTasks({String? listId}) async {
    final res = await _dio.get(
      '/tasks',
      queryParameters: listId != null ? {'listId': listId} : null,
    );
    return (res.data as List<dynamic>)
        .map((e) => Task.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Task> createTask(String title) async {
    final res = await _dio.post('/tasks', data: {'title': title});
    return Task.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Task> toggleComplete(String id, bool completed) async {
    final res = await _dio.patch('/tasks/$id', data: {'completed': completed});
    return Task.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteTask(String id) async {
    await _dio.delete('/tasks/$id');
  }
}

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.watch(dioProvider));
});
