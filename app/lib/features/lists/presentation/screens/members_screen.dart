import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todo_app/core/network/file_url.dart';
import 'package:todo_app/features/lists/data/list_repository.dart';
import 'package:todo_app/features/lists/data/models/group_member.dart';
import 'package:todo_app/features/lists/presentation/view_models/lists_controller.dart';
import 'package:todo_app/shared/widgets/animated_fab.dart';
import 'package:todo_app/shared/widgets/app_back_button.dart';
import 'package:todo_app/shared/widgets/app_pull_to_refresh.dart';
import 'package:todo_app/shared/widgets/app_snackbar.dart';
import 'package:todo_app/shared/widgets/fade_slide_in.dart';
import 'package:todo_app/shared/widgets/list_refresh.dart';

class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key, required this.listId});

  final String listId;

  Future<void> _refresh(WidgetRef ref) => refreshListMembers(ref, listId);

  Future<void> _invite(BuildContext context, WidgetRef ref) async {
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
      context.showAppSnackBar('邀请已发送', type: AppSnackBarType.success);
    } catch (_) {
      context.showAppSnackBar('邀请失败，请检查昵称', type: AppSnackBarType.error);
    }
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    GroupMember member,
  ) async {
    try {
      await ref.read(listRepositoryProvider).removeMember(listId, member.id);
      _refresh(ref);
    } catch (_) {
      context.showAppSnackBar('移除失败', type: AppSnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(listMembersProvider(listId));

    return Scaffold(
      appBar: secondaryAppBar(context, title: '分组成员'),
      floatingActionButton: AnimatedFab.extended(
        onPressed: () => _invite(context, ref),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('邀请'),
      ),
      body: AppPullToRefresh(
        onRefresh: () => _refresh(ref),
        child: membersAsync.when(
        data: (data) => ListView(
            physics: kAppListScrollPhysics,
            children: [
              FadeSlideIn(
                index: 0,
                child: _MemberTile(member: data.owner, isOwner: true),
              ),
              const Divider(height: 1),
              if (data.members.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('暂无其他成员，点击下方按钮邀请'),
                  ),
                )
              else
                ...data.members.asMap().entries.map(
                  (entry) => FadeSlideIn(
                    index: entry.key + 1,
                    child: _MemberTile(
                      member: entry.value,
                      isOwner: false,
                      onRemove: () => _remove(context, ref, entry.value),
                    ),
                  ),
                ),
            ],
          ),
        loading: () => AppPullToRefresh.scrollableEmpty(
          child: const Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => AppPullToRefresh.scrollableEmpty(
          child: Center(child: Text('加载失败：$e')),
        ),
      ),
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
