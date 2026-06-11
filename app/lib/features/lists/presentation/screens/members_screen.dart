import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todo_app/core/network/file_url.dart';
import 'package:todo_app/features/lists/data/list_repository.dart';
import 'package:todo_app/features/lists/data/models/group_member.dart';
import 'package:todo_app/features/lists/presentation/view_models/lists_controller.dart';

class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key, required this.listId});

  final String listId;

  void _refresh(WidgetRef ref) {
    ref.invalidate(listMembersProvider(listId));
    ref.invalidate(listsControllerProvider);
  }

  Future<void> _invite(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final controller = TextEditingController();
    final username = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('邀请协作'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '对方昵称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('邀请'),
          ),
        ],
      ),
    );
    if (username == null || username.isEmpty) return;
    try {
      await ref.read(listRepositoryProvider).invite(listId, username);
      messenger.showSnackBar(const SnackBar(content: Text('邀请已发送')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('邀请失败，请检查昵称')));
    }
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    GroupMember member,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(listRepositoryProvider).removeMember(listId, member.id);
      _refresh(ref);
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('移除失败')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(listMembersProvider(listId));

    return Scaffold(
      appBar: AppBar(title: const Text('分组成员')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _invite(context, ref),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('邀请'),
      ),
      body: membersAsync.when(
        data: (data) => RefreshIndicator(
          onRefresh: () async => _refresh(ref),
          child: ListView(
            children: [
              _MemberTile(member: data.owner, isOwner: true),
              const Divider(height: 1),
              if (data.members.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('暂无其他成员，点击下方按钮邀请'),
                  ),
                )
              else
                ...data.members.map(
                  (m) => _MemberTile(
                    member: m,
                    isOwner: false,
                    onRemove: () => _remove(context, ref, m),
                  ),
                ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.isOwner,
    this.onRemove,
  });

  final GroupMember member;
  final bool isOwner;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
            member.avatar != null ? NetworkImage(fileUrl(member.avatar)) : null,
        child: member.avatar == null
            ? Text(member.displayName.characters.first.toUpperCase())
            : null,
      ),
      title: Text(member.displayName),
      subtitle: Text(member.username ?? ''),
      trailing: isOwner
          ? const Chip(label: Text('拥有者'))
          : (onRemove != null
              ? IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: onRemove,
                )
              : null),
    );
  }
}
