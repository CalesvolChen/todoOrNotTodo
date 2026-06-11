import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todo_app/core/network/dio_client.dart';
import 'package:todo_app/features/lists/data/models/group_member.dart';
import 'package:todo_app/features/lists/data/models/task_list.dart';

class ListRepository {
  ListRepository(this._dio);

  final Dio _dio;

  Future<List<TaskList>> fetchLists() async {
    final res = await _dio.get('/lists');
    return (res.data as List<dynamic>)
        .map((e) => TaskList.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TaskList> createList(String name) async {
    final res = await _dio.post('/lists', data: {'name': name});
    return TaskList.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TaskList> renameList(String id, String name) async {
    final res = await _dio.patch('/lists/$id', data: {'name': name});
    return TaskList.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteList(String id) async {
    await _dio.delete('/lists/$id');
  }

  Future<GroupMembers> fetchMembers(String listId) async {
    final res = await _dio.get('/lists/$listId/members');
    return GroupMembers.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> invite(String listId, String username) async {
    await _dio.post('/lists/$listId/invite', data: {'username': username});
  }

  Future<void> removeMember(String listId, String userId) async {
    await _dio.delete('/lists/$listId/members/$userId');
  }
}

final listRepositoryProvider = Provider<ListRepository>((ref) {
  return ListRepository(ref.watch(dioProvider));
});
