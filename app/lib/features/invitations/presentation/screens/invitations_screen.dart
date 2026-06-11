import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todo_app/core/errors/app_error_message.dart';
import 'package:todo_app/features/invitations/presentation/view_models/invitations_controller.dart';
import 'package:todo_app/shared/widgets/app_error_dialog.dart';
import 'package:todo_app/shared/widgets/app_back_button.dart';
import 'package:todo_app/shared/widgets/app_pull_to_refresh.dart';
import 'package:todo_app/shared/widgets/empty_placeholder.dart';
import 'package:todo_app/shared/widgets/fade_slide_in.dart';
import 'package:todo_app/shared/widgets/list_refresh.dart';

class InvitationsScreen extends ConsumerWidget {
  const InvitationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitationsAsync = ref.watch(invitationsControllerProvider);
    final notifier = ref.read(invitationsControllerProvider.notifier);

    return Scaffold(
      appBar: secondaryAppBar(context, title: '协作邀请'),
      body: AppPullToRefresh(
        onRefresh: () => runWithAppErrorDialog(
          context,
          () => refreshInvitations(ref),
        ),
        child: invitationsAsync.when(
        data: (invitations) {
          if (invitations.isEmpty) {
            return AppPullToRefresh.scrollableEmpty(
              child: const EmptyPlaceholder(
                icon: Icons.mark_email_read_outlined,
                message: '暂无待处理邀请',
              ),
            );
          }
          return ListView.separated(
            physics: kAppListScrollPhysics,
            padding: const EdgeInsets.all(16),
            itemCount: invitations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final inv = invitations[index];
              return FadeSlideIn(
                index: index,
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.group_add_outlined),
                    title: Text(inv.listName),
                    subtitle: Text('${inv.inviterName} 邀请你加入'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          tooltip: '接受',
                          onPressed: () => runWithAppErrorDialog(
                            context,
                            () => notifier.accept(inv.id),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          tooltip: '拒绝',
                          onPressed: () => runWithAppErrorDialog(
                            context,
                            () => notifier.decline(inv.id),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => AppPullToRefresh.scrollableEmpty(
          child: const Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => AppPullToRefresh.scrollableEmpty(
          child: Center(child: Text('加载失败：${messageFromError(e)}')),
        ),
      ),
      ),
    );
  }
}
