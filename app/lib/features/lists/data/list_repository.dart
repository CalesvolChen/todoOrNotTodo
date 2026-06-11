import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todo_app/core/network/dio_client.dart';
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
}

final listRepositoryProvider = Provider<ListRepository>((ref) {
  return ListRepository(ref.watch(dioProvider));
});
