import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todo_app/features/lists/data/list_repository.dart';
import 'package:todo_app/features/lists/data/models/group_member.dart';
import 'package:todo_app/features/lists/data/models/task_list.dart';

/// 当前选中的分组 id，null 表示「全部任务」
final selectedListIdProvider = StateProvider<String?>((ref) => null);

class ListsController extends AsyncNotifier<List<TaskList>> {
  ListRepository get _repo => ref.read(listRepositoryProvider);

  @override
  Future<List<TaskList>> build() => _repo.fetchLists();

  Future<TaskList> create(String name) async {
    final list = await _repo.createList(name);
    ref.invalidateSelf();
    await future;
    return list;
  }

  Future<void> rename(String id, String name) async {
    await _repo.renameList(id, name);
    ref.invalidateSelf();
    await future;
  }

  Future<void> remove(String id) async {
    await _repo.deleteList(id);
    if (ref.read(selectedListIdProvider) == id) {
      ref.read(selectedListIdProvider.notifier).state = null;
    }
    ref.invalidateSelf();
    await future;
  }
}

final listsControllerProvider =
    AsyncNotifierProvider<ListsController, List<TaskList>>(ListsController.new);

/// 某分组的成员信息
final listMembersProvider =
    FutureProvider.family<GroupMembers, String>((ref, listId) {
  return ref.watch(listRepositoryProvider).fetchMembers(listId);
});
