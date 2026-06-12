import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todo_app/features/invitations/presentation/view_models/invitations_badge_provider.dart';

/// 首页菜单按钮（有待处理邀请时显示红点角标）
class HomeMenuButton extends ConsumerWidget {
  const HomeMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount =
        ref.watch(pendingInvitationsCountProvider).valueOrNull ?? 0;

    return IconButton(
      icon: Badge(
        isLabelVisible: pendingCount > 0,
        smallSize: 8,
        child: const Icon(Icons.menu),
      ),
      tooltip: '菜单',
      onPressed: () {
        refreshPendingInvitationsBadge(ref);
        Scaffold.of(context).openDrawer();
      },
    );
  }
}
