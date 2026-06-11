import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todo_app/features/invitations/data/invitation_repository.dart';
import 'package:todo_app/features/invitations/data/models/invitation.dart';
import 'package:todo_app/features/lists/presentation/view_models/lists_controller.dart';

class InvitationsController extends AsyncNotifier<List<Invitation>> {
  InvitationRepository get _repo => ref.read(invitationRepositoryProvider);

  @override
  Future<List<Invitation>> build() => _repo.fetch();

  Future<void> accept(String id) async {
    await _repo.accept(id);
    ref.invalidate(listsControllerProvider);
    ref.invalidateSelf();
    await future;
  }

  Future<void> decline(String id) async {
    await _repo.decline(id);
    ref.invalidateSelf();
    await future;
  }
}

final invitationsControllerProvider =
    AsyncNotifierProvider<InvitationsController, List<Invitation>>(
  InvitationsController.new,
);
