import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:todo_app/core/network/dio_client.dart';
import 'package:todo_app/core/network/multipart_util.dart';
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

  Future<Task> fetchTask(String id) async {
    final res = await _dio.get('/tasks/$id');
    return Task.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Task> updateTask(String id, {String? title, String? note}) async {
    final res = await _dio.patch('/tasks/$id', data: {
      if (title != null) 'title': title,
      if (note != null) 'note': note,
    });
    return Task.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TaskStep> addStep(String taskId, String title) async {
    final res = await _dio.post('/tasks/$taskId/steps', data: {'title': title});
    return TaskStep.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TaskStep> toggleStep(
    String taskId,
    String stepId,
    bool completed,
  ) async {
    final res = await _dio.patch(
      '/tasks/$taskId/steps/$stepId',
      data: {'completed': completed},
    );
    return TaskStep.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteStep(String taskId, String stepId) async {
    await _dio.delete('/tasks/$taskId/steps/$stepId');
  }

  Future<Task> moveTask(String id, {String? listId}) async {
    final res = await _dio.patch('/tasks/$id', data: {'listId': listId});
    return Task.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Task> createTask(String title, {String? listId}) async {
    final res = await _dio.post('/tasks', data: {
      'title': title,
      if (listId != null) 'listId': listId,
    });
    return Task.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Task> toggleComplete(String id, bool completed) async {
    final res = await _dio.patch('/tasks/$id', data: {'completed': completed});
    return Task.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Task> setImportant(String id, bool important) async {
    final res = await _dio.patch('/tasks/$id', data: {'important': important});
    return Task.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteTask(String id) async {
    await _dio.delete('/tasks/$id');
  }

  Future<void> uploadAttachment(
    String taskId, {
    XFile? xFile,
    String? filePath,
    DioMediaType? contentType,
  }) async {
    final mime = xFile?.mimeType ?? '';
    final nameHint = xFile?.name ?? filePath ?? 'upload';
    final multipart = await buildMultipartFile(
      xFile: xFile,
      filePath: filePath,
      filename: nameHint.split(RegExp(r'[/\\]')).last,
      contentType: contentType ?? guessImageMediaType(mime, nameHint),
    );
    final form = FormData.fromMap({'file': multipart});
    await _dio.post('/tasks/$taskId/attachments', data: form);
  }

  Future<void> deleteAttachment(String attachmentId) async {
    await _dio.delete('/attachments/$attachmentId');
  }
}

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.watch(dioProvider));
});
