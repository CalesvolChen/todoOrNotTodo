import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todo_app/core/network/dio_client.dart';
import 'package:todo_app/features/invitations/data/models/invitation.dart';

class InvitationRepository {
  InvitationRepository(this._dio);

  final Dio _dio;

  Future<List<Invitation>> fetch() async {
    final res = await _dio.get('/invitations');
    return (res.data as List<dynamic>)
        .map((e) => Invitation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> fetchPendingCount() async {
    final res = await _dio.get('/invitations/pending-count');
    final data = res.data;
    if (data is int) return data;
    if (data is Map) return data['count'] as int? ?? 0;
    return 0;
  }

  Future<void> accept(String id) async {
    await _dio.post('/invitations/$id/accept');
  }

  Future<void> decline(String id) async {
    await _dio.post('/invitations/$id/decline');
  }
}

final invitationRepositoryProvider = Provider<InvitationRepository>((ref) {
  return InvitationRepository(ref.watch(dioProvider));
});
