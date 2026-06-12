import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todo_app/features/invitations/data/invitation_repository.dart';

/// 待处理协作邀请数量（轻量接口，用于菜单角标）
final pendingInvitationsCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(invitationRepositoryProvider).fetchPendingCount();
});

void refreshPendingInvitationsBadge(WidgetRef ref) {
  ref.invalidate(pendingInvitationsCountProvider);
}
