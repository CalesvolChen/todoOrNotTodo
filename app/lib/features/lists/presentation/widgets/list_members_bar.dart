import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todo_app/core/network/file_url.dart';
import 'package:todo_app/features/lists/data/models/group_member.dart';
import 'package:todo_app/features/lists/presentation/view_models/lists_controller.dart';

/// 分组顶部协作者头像条（拥有者 + 成员）
class ListMembersBar extends ConsumerWidget {
  const ListMembersBar({super.key, required this.listId});

  final String listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(listMembersProvider(listId));

    return membersAsync.when(
      data: (data) {
        final people = [data.owner, ...data.members];
        if (people.isEmpty) return const SizedBox.shrink();

        return Material(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.group_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '协作者',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: people.map((m) => _MemberAvatar(member: m)).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.member});

  final GroupMember member;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: member.displayName,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: member.avatar != null
                  ? NetworkImage(fileUrl(member.avatar))
                  : null,
              child: member.avatar == null
                  ? Text(
                      member.displayName.characters.first.toUpperCase(),
                      style: const TextStyle(fontSize: 14),
                    )
                  : null,
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 44,
              child: Text(
                member.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
